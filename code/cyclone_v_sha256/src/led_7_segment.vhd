library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity led_7_segment is
    port(
        clk : in std_logic;
        led_7_segment : out std_logic_vector(41 downto 0)
        );
end led_7_segment;

architecture Behavioral of led_7_segment is
    signal ctr : unsigned(26 downto 0) := (others => '0');
    type haha is array(natural range <>) of std_logic_vector(7 downto 0);
    constant msg : haha := (x"41", x"42", x"43", x"44");
    signal led_internal : std_logic_vector(41 downto 0);
    signal msg_buf : haha := (x"00", x"00", x"00", x"00", x"00", x"00");
begin
    process(clk)
    begin
        if rising_edge(clk) then
            ctr <= to_unsigned(to_integer(ctr) + 1, 27);
            if (ctr = "000100000000000000000000000") then
                led_7_segment <= led_internal;
            end if;
        end if;
    end process;
end Behavioral;
