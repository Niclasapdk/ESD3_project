library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity test_top is
    port(
        -- inputs
        --clk      : in STD_LOGIC; -- system clock
        com_clk  : in STD_LOGIC;
        r_nw     : in STD_LOGIC; -- R/not_W signal (read active high) (as seen by the master)
        addr_bus : in STD_LOGIC_VECTOR(1 downto 0);
        data_tx  : in STD_LOGIC_VECTOR(7 downto 0);
        -- inout
        data_bus : inout STD_LOGIC_VECTOR(7 downto 0);
        -- outputs
        data_rx  : out STD_LOGIC_VECTOR(7 downto 0)
        );
end test_top;

architecture Behavioral of test_top is
begin

    DL : entity work.data_link
    generic map(ADDR => "10")
    port map(
            com_clk => com_clk,
            r_nw => r_nw,
            addr_bus => addr_bus,
            data_tx => data_tx,
            data_bus => data_bus,
            data_rx => data_rx
            );

end Behavioral;

