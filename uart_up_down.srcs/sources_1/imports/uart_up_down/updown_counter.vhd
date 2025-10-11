library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity updown_counter is
  port(
    clk     : in  std_logic;
    rst_n   : in  std_logic;                 -- activo en 0
    enable  : in  std_logic;                 -- auto (+1 por tick, como antes)
    step_up : in  std_logic;                 -- pulso: +1
    step_dn : in  std_logic;                 -- pulso: -1
    clear   : in  std_logic;                 -- pulso: pone a 0
    q       : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of updown_counter is
  signal cnt       : unsigned(3 downto 0) := (others=>'0');
  signal step_up_d : std_logic := '0';
  signal step_dn_d : std_logic := '0';
begin
  q <= std_logic_vector(cnt);

  process(clk)
  begin
    if rising_edge(clk) then
      -- detectores de flanco
      step_up_d <= step_up;
      step_dn_d <= step_dn;

      if rst_n = '0' then
        cnt <= (others=>'0');

      elsif clear = '1' then
        cnt <= (others=>'0');

      elsif enable = '1' then
        -- auto: igual que antes (solo +1 por tick)
        if cnt = "1111" then cnt <= (others=>'0'); else cnt <= cnt + 1; end if;

      elsif (step_up = '1' and step_up_d = '0') then
        if cnt = "1111" then cnt <= (others=>'0'); else cnt <= cnt + 1; end if;

      elsif (step_dn = '1' and step_dn_d = '0') then
        if cnt = "0000" then cnt <= "1111"; else cnt <= cnt - 1; end if;

      end if;
    end if;
  end process;
end architecture;
