library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_round_hasher_tb is
end multi_round_hasher_tb;

architecture Behavioral of multi_round_hasher_tb is
    constant CLK_PERIOD : time := 10 ns;
    signal clk          : std_logic := '0'; -- clock signal
    signal start        : std_logic;        -- start signal (enable high)
    signal passwd       : std_logic_vector(511 downto 0) := x"414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141418000000000000001b8";
    signal hash         : std_logic_vector(255 downto 0);
    signal done         : std_logic;
    signal rounds       : unsigned(31 downto 0) := x"00001388";
    signal reset        : std_logic := '0';
    -- Expected hash: ff7d9978045a76d74350c1b7866cf3cfe058a8c6249213a69aed843ba1e1680f
begin
    clk <= not clk after CLK_PERIOD/2;

    DUT : entity work.multi_round_hasher
    port map (
        clk       => clk,
        start     => start,
        passwd_in => passwd,
        hash_out  => hash,
        hash_done => done,
        reset => reset,
        rounds => rounds
     );

    start <= '1';

end Behavioral;
