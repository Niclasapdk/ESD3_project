-- Clock Synchronization Module (CSM)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_sync_mod is
    port(
            sys_clk      : in std_logic; -- Fast system clock
            sync_clk     : in std_logic; -- Slow clock to be synced (significantly slower)
            rising_trig  : out std_logic;
            falling_trig : out std_logic
        );
end clock_sync_mod;

architecture Behavioral of clock_sync_mod is
    signal r1_sync_clk : std_logic;
    signal r2_sync_clk : std_logic;
    signal r3_sync_clk : std_logic;
begin
    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            -- Reset triggers
            rising_trig <= '0';
            falling_trig <= '0';

            -- Sample sync_clk
            r1_sync_clk <= sync_clk;
            r2_sync_clk <= r1_sync_clk;
            r3_sync_clk <= r2_sync_clk;

            -- sync_clk rising edge
            if r3_sync_clk = '0' and r2_sync_clk = '1' then
                rising_trig <= '1';
            end if;

            -- sync_clk falling edge
            if r3_sync_clk = '1' and r2_sync_clk = '0' then
                falling_trig <= '1';
            end if;
        end if;
    end process;
end Behavioral;
