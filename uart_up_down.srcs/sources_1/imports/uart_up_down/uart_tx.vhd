library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
  generic(
    CLK_FREQ : integer := 125_000_000; -- Hz
    BAUD     : integer := 115_200      -- bps
  );
  port(
    clk      : in  std_logic;
    rst_n    : in  std_logic;          -- activo en 0
    tx_start : in  std_logic;          -- pulso 1 clk para iniciar envío
    tx_data  : in  std_logic_vector(7 downto 0); -- byte a enviar
    tx_busy  : out std_logic;          -- '1' mientras transmite
    tx_o     : out std_logic           -- línea TX (idle='1')
  );
end entity;

architecture rtl of uart_tx is
  constant DIVISOR : integer := integer(real(CLK_FREQ)/real(BAUD) + 0.5);

  type state_t is (IDLE, START, DATA, STOP);
  signal state    : state_t := IDLE;
  signal bit_cnt  : integer range 0 to 7 := 0;
  signal shreg    : std_logic_vector(7 downto 0) := (others=>'0');

  signal baud_cnt : integer range 0 to DIVISOR-1 := 0;
  signal baud_tick: std_logic := '0';

  signal tx_r     : std_logic := '1';
  signal busy_r   : std_logic := '0';
begin
  tx_o   <= tx_r;
  tx_busy<= busy_r;

  -- generador de tick a BAUD
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        baud_cnt  <= 0;
        baud_tick <= '0';
      else
        if baud_cnt = DIVISOR-1 then
          baud_cnt  <= 0;
          baud_tick <= '1';
        else
          baud_cnt  <= baud_cnt + 1;
          baud_tick <= '0';
        end if;
      end if;
    end if;
  end process;

  -- FSM de transmisión
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        state   <= IDLE;
        tx_r    <= '1';
        busy_r  <= '0';
        bit_cnt <= 0;
        shreg   <= (others=>'0');
      else
        case state is
          when IDLE =>
            busy_r <= '0';
            tx_r   <= '1';
            if tx_start = '1' then
              shreg   <= tx_data;
              bit_cnt <= 0;
              busy_r  <= '1';
              state   <= START;
            end if;

          when START =>
            if baud_tick = '1' then
              tx_r  <= '0';            -- start bit
              state <= DATA;
            end if;

          when DATA =>
            if baud_tick = '1' then
              tx_r <= shreg(bit_cnt);
              if bit_cnt = 7 then
                state   <= STOP;
              else
                bit_cnt <= bit_cnt + 1;
              end if;
            end if;

          when STOP =>
            if baud_tick = '1' then
              tx_r   <= '1';           -- stop bit
              state  <= IDLE;
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture;
