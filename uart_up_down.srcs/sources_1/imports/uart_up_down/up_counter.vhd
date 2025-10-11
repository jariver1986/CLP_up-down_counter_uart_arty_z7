library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity up_counter is
  port(
    clk     : in  std_logic;
    rst_n   : in  std_logic;                 -- activo en 0
    enable  : in  std_logic;                 -- cuenta libre si '1'
    step    : in  std_logic;                 -- pulso: incrementa una vez
    clear   : in  std_logic;                 -- pulso: pone a cero
    q       : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of up_counter is
  signal cnt : unsigned(3 downto 0) := (others=>'0');
  signal step_d : std_logic := '0';
begin
  q <= std_logic_vector(cnt);

  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        cnt    <= (others=>'0');
        step_d <= '0';
      else
        step_d <= step;
        if clear = '1' then
          cnt <= (others=>'0');
        elsif (enable = '1') or (step = '1' and step_d = '0') then
          -- cuenta libre o flanco de subida en 'step'
          cnt <= cnt + 1;
        end if;
      end if;
    end if;
  end process;
end architecture;
