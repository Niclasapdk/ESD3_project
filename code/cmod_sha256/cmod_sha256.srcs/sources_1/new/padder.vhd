library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity padder is
    port(
            -- Outputs
            output_word : out std_logic_vector(0 to 511);

            -- Inputs
            passwd : in std_logic_vector(0 to 311);
            salt : in std_logic_vector(0 to 127);
            L : in unsigned(8 downto 0); -- length of passwd + salt
            K : in unsigned(8 downto 0); -- number of zeros (L + 1 + K + 64 = 512)
        );
end padder;

architecture Behavioral of padder is
begin
    for i in 503 to 511 loop
        output_word(i) <= L(i-503);
    end loop;
end Behavioral;
