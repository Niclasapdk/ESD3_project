library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package plusbus_pkg is
    -- Constants
    constant PLUSBUS_STX : std_logic_vector(7 downto 0) := x"02";
    constant PLUSBUS_ETX : std_logic_vector(7 downto 0) := x"03";
    constant PLUSBUS_DLE : std_logic_vector(7 downto 0) := x"10";
end package;