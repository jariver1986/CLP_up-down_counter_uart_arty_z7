library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_uart_counter is
  generic(
    CLK_FREQ : integer := 125_000_000;
    BAUD     : integer := 115_200
  );
  port(
    clk      : in  std_logic;
    rst_n    : in  std_logic;             -- activo en 0
    uart_rx  : in  std_logic;             -- desde TX del USB-UART externo
    uart_tx  : out std_logic;             -- hacia RX del USB-UART externo
    leds     : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of top_uart_counter is
  -- UART RX
  signal rx_data       : std_logic_vector(7 downto 0);
  signal rx_valid      : std_logic;

  -- UART TX
  signal tx_start      : std_logic := '0';
  signal tx_busy       : std_logic;
  signal tx_data       : std_logic_vector(7 downto 0) := (others=>'0');

  -- Control
  signal en_auto       : std_logic := '0';
  signal step_pulse    : std_logic := '0';
  signal step_dn_pulse : std_logic := '0';
  signal clr_pulse     : std_logic := '0';

  -- Tick ~10 Hz para modo automático
  constant TICK_HZ     : integer := 10;
  constant TICK_DIV    : integer := integer(real(CLK_FREQ)/real(TICK_HZ) + 0.5);
  signal tick_cnt      : integer range 0 to TICK_DIV-1 := 0;
  signal tick_10hz     : std_logic := '0';

  -- Señales del contador
  signal q4            : std_logic_vector(3 downto 0);
  signal q4_prev       : std_logic_vector(3 downto 0) := (others=>'0');

  -- Habilitación para el contador (para evitar warning de "actual no estático")
  signal enable_auto   : std_logic;

  -- función: nibble -> ASCII HEX
  function nibble_to_hex(n : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable u : unsigned(3 downto 0) := unsigned(n);
    variable a : std_logic_vector(7 downto 0);
  begin
    if u < 10 then
      a := std_logic_vector(to_unsigned(character'pos('0') + to_integer(u), 8));
    else
      a := std_logic_vector(to_unsigned(character'pos('A') + to_integer(u) - 10, 8));
    end if;
    return a;
  end function;

begin
  leds <= q4;

  -- UART RX
  u_rx: entity work.uart_rx
    generic map(CLK_FREQ => CLK_FREQ, BAUD => BAUD)
    port map(
      clk          => clk,
      rst_n        => rst_n,
      rx_i         => uart_rx,
      data_o       => rx_data,
      data_valid_o => rx_valid
    );

  -- UART TX
  u_tx: entity work.uart_tx
    generic map(CLK_FREQ => CLK_FREQ, BAUD => BAUD)
    port map(
      clk      => clk,
      rst_n    => rst_n,
      tx_start => tx_start,
      tx_data  => tx_data,
      tx_busy  => tx_busy,
      tx_o     => uart_tx
    );

  -- Generador de tick 10 Hz (auto)
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        tick_cnt  <= 0;
        tick_10hz <= '0';
      else
        if tick_cnt = TICK_DIV-1 then
          tick_cnt  <= 0;
          tick_10hz <= '1';
        else
          tick_cnt  <= tick_cnt + 1;
          tick_10hz <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Decodificación de comandos por UART
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        en_auto       <= '0';
        step_pulse    <= '0';
        step_dn_pulse <= '0';
        clr_pulse     <= '0';
      else
        step_pulse    <= '0';
        step_dn_pulse <= '0';
        clr_pulse     <= '0';

        if rx_valid = '1' then
          case character'val(to_integer(unsigned(rx_data))) is
            when '+' | 'i' => step_pulse    <= '1';
            when '-'       => step_dn_pulse <= '1';
            when 'z' | 'r' => clr_pulse     <= '1';
            when 's'       => en_auto       <= '1';
            when 'p'       => en_auto       <= '0';
            when others    => null;
          end case;
        end if;
      end if;
    end if;
  end process;

  -- Señal de enable combinando tick y modo auto
  enable_auto <= tick_10hz and en_auto;

  -- Contador up/down (auto = +1 por tick si en_auto=1)
  u_cnt: entity work.updown_counter
    port map(
      clk     => clk,
      rst_n   => rst_n,
      enable  => enable_auto,
      step_up => step_pulse,
      step_dn => step_dn_pulse,
      clear   => clr_pulse,
      q       => q4
    );

  -- ECO por TX: enviar HEX + LF cuando cambie q4
  process(clk)
    type txfsm_t is (E_IDLE, E_SEND_HEX, E_SEND_LF);
    variable st : txfsm_t := E_IDLE;
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        q4_prev  <= (others=>'0');
        tx_start <= '0';
        tx_data  <= (others=>'0');
        st       := E_IDLE;
      else
        tx_start <= '0'; -- por defecto

        case st is
          when E_IDLE =>
            if q4 /= q4_prev then
              q4_prev <= q4;
              if tx_busy = '0' then
                tx_data  <= nibble_to_hex(q4);
                tx_start <= '1';
                st       := E_SEND_HEX;
              end if;
            end if;

          when E_SEND_HEX =>
            if tx_busy = '0' then
              tx_data  <= x"0A"; -- LF
              tx_start <= '1';
              st       := E_SEND_LF;
            end if;

          when E_SEND_LF =>
            if tx_busy = '0' then
              st := E_IDLE;
            end if;
        end case;
      end if;
    end if;
  end process;

end architecture;
