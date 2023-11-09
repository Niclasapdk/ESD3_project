library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;
use work.sha256_core.ALL;

entity core_controller is
    port(
            clk : in std_logic;
        );
end core_controller;

architecture Behavioral of core_controller is
begin
    CORE1 : entity work.sha256_core
    port map(
                clk : in std_logic;
                start : in std_logic;
                reset : in std_logic;
                passwd_in : in std_logic_vector(0 to 511);
                hash_out : out std_logic_vector(255 downto 0);
                hash_done: out std_logic
            );
end Behavioral;
