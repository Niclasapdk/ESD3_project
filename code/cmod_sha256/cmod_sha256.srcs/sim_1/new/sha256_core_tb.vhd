----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/25/2023 09:58:52 AM
-- Design Name: 
-- Module Name: sha256_core_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sha256_core_tb is
--  Port ( );
end sha256_core_tb;

architecture Behavioral of sha256_core_tb is
    constant CLK_PERIOD : time := 10 ns;
    signal clk        : std_logic := '0'; -- clock signal
    signal start      : std_logic;        -- start signal (enable high)
    signal rst        : std_logic;        -- reset signal (enable high)
    signal passwd     : std_logic_vector(511 downto 0) := x"414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141418000000000000001b8";
    signal hash       : std_logic_vector(255 downto 0);
    signal done       : std_logic;
    -- Expected hash: 8963cc0afd622cc7574ac2011f93a3059b3d65548a77542a1559e3d202e6ab00
begin
    clk <= not clk after CLK_PERIOD/2;
    -- rst <= '1', '0' after CLK_PERIOD;

    uut : entity work.sha256_core
    port map (
        clk       => clk,
        start     => start,
        reset     => rst,
        passwd_in => passwd,
        hash_out  => hash,
        hash_done => done
     );

    -- stimulus : process
    -- begin
        start <= '1';
        -- wait until done = '1';
    -- end process;


end Behavioral;
