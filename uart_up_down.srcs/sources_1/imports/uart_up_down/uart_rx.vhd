library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
  generic(
    CLK_FREQ : integer := 100_000_000; -- Hz
    BAUD     : integer := 115_200      -- bps
  );
  port(
    clk           : in  std_logic;
    rst_n         : in  std_logic;      -- activo en 0
    rx_i          : in  std_logic;      -- línea RX desde el pin
    data_o        : out std_logic_vector(7 downto 0);
    data_valid_o  : out std_logic       -- pulso 1 clk cuando data_o es válida
  );
end entity;

architecture rtl of uart_rx is
  constant OVS        : integer := 16; -- sobremuestreo x16
  constant BAUD_OVS   : integer := BAUD * OVS;
  constant DIVISOR    : integer := integer(real(CLK_FREQ) / real(BAUD_OVS) + 0.5); -- redondeo

  signal tick_cnt     : integer range 0 to DIVISOR-1 := 0;
  signal tick_ovs     : std_logic := '0';

  type state_t is (IDLE, START, DATA, STOP);
  signal state        : state_t := IDLE;
  signal sample_cnt   : integer range 0 to OVS-1 := 0;
  signal bit_idx      : integer range 0 to 7 := 0;
  signal sr           : std_logic_vector(7 downto 0) := (others=>'0');
  signal rx_sync0, rx_sync1 : std_logic := '1';
  signal data_valid_r : std_logic := '0';
begin
  data_o       <= sr;
  data_valid_o <= data_valid_r;

  -- Sincronizadores para rx_i (evitar metastabilidad)
  process(clk)
  begin
    if rising_edge(clk) then
      rx_sync0 <= rx_i;
      rx_sync1 <= rx_sync0;
    end if;
  end process;

  -- Generador de tick a BAUD*16
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        tick_cnt <= 0;
        tick_ovs <= '0';
      else
        if tick_cnt = DIVISOR-1 then
          tick_cnt <= 0;
          tick_ovs <= '1';
        else
          tick_cnt <= tick_cnt + 1;
          tick_ovs <= '0';
        end if;
      end if;
    end if;
  end process;

  -- FSM receptor
  process(clk)
  begin
    if rising_edge(clk) then
      data_valid_r <= '0';
      if rst_n = '0' then
        state      <= IDLE;
        sample_cnt <= 0;
        bit_idx    <= 0;
        sr         <= (others=>'0');
      else
        if tick_ovs = '1' then
          case state is
            when IDLE =>
              if rx_sync1 = '0' then             -- borde de inicio
                state      <= START;
                sample_cnt <= OVS/2;              -- muestreo al medio del bit
              end if;

            when START =>
              if sample_cnt = 0 then
                if rx_sync1 = '0' then            -- start válido
                  state      <= DATA;
                  sample_cnt <= OVS-1;
                  bit_idx    <= 0;
                else
                  state <= IDLE;                   -- falso inicio
                end if;
              else
                sample_cnt <= sample_cnt - 1;
              end if;

            when DATA =>
              if sample_cnt = 0 then
                -- muestrear bit de datos LSB primero
                sr(bit_idx) <= rx_sync1;
                if bit_idx = 7 then
                  state      <= STOP;
                else
                  bit_idx    <= bit_idx + 1;
                end if;
                sample_cnt <= OVS-1;
              else
                sample_cnt <= sample_cnt - 1;
              end if;

            when STOP =>
              if sample_cnt = 0 then
                -- comprobar bit de stop (opcional); se asume correcto
                data_valid_r <= '1';
                state        <= IDLE;
              else
                sample_cnt <= sample_cnt - 1;
              end if;
          end case;
        end if;
      end if;
    end if;
  end process;
end architecture;
