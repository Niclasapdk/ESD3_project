library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sign_of_life is
    port(
        clk : in std_logic;
        blink : out std_logic
        );
end sign_of_life;

architecture Behavioral of sign_of_life is
    signal ctr : unsigned(0 to 26) := (others => '0');
begin
    blink <= ctr(20);
    process(clk)
    begin
        if rising_edge(clk) then
            ctr <= to_unsigned(to_integer(ctr) + 1, 27);
        end if;
    end process;
end Behavioral;
