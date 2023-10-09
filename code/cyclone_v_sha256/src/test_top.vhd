library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity test_top is
    Port ( B1 : in STD_LOGIC;
           B2 : in STD_LOGIC;
           B3 : in STD_LOGIC;
           LED1 : out STD_LOGIC;
           LED2 : out STD_LOGIC;
           LED3 : out STD_LOGIC);
end test_top;

architecture Behavioral of test_top is

begin

LED1 <= B1;
LED2 <= B2;
LED3 <= B3;

end Behavioral;

