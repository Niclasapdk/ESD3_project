library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sha256_core_tb is
end sha256_core_tb;

architecture Behavioral of sha256_core_tb is
    constant CLK_PERIOD : time := 10 ns;
    signal clk          : std_logic := '0'; -- clock signal
    signal start        : std_logic;        -- start signal (enable high)
    signal passwd       : std_logic_vector(511 downto 0) := x"4a6f686e2073746f70206c696674696e6720746f206d696c6420646973636f6d666f72742c20646f20736d7468207520646f6e6b6579218000000000000001b8";
    signal hash         : std_logic_vector(255 downto 0);
    signal done         : std_logic;
    -- Expected hash: 8963cc0afd622cc7574ac2011f93a3059b3d65548a77542a1559e3d202e6ab00
    signal reset        : std_logic := '0';
begin
    clk <= not clk after CLK_PERIOD/2;

    DUT : entity work.sha256_core
    port map (
        clk       => clk,
        start     => start,
        reset     => reset,
        passwd_in => passwd,
        hash_out  => hash,
        hash_done => done
     );

    start <= '1';

end Behavioral;
