library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_top is
    port(
        -- inputs
        clk      : in STD_LOGIC; -- system clock
        com_clk  : in STD_LOGIC;
        r_nw     : in STD_LOGIC; -- R/not_W signal (read active high) (as seen by the master)
        addr_bus : in STD_LOGIC_VECTOR(1 downto 0);
        data_tx  : in STD_LOGIC_VECTOR(7 downto 0);
        -- inout
        data_bus : inout STD_LOGIC_VECTOR(7 downto 0);
        data_rx  : inout STD_LOGIC_VECTOR(7 downto 0)
        );
end test_top;

architecture Behavioral of test_top is
    signal passwd : std_logic_vector(511 downto 0);
    signal passwd_valid : std_logic;
    signal tx_success : std_logic;
    signal rst_core : std_logic := '0';
    signal hash : std_logic_vector(255 downto 0) := (others => '0');
    signal hash_done : std_logic := '0';
    signal rounds : unsigned(31 downto 0) := x"00000002";
begin

    DL : entity work.data_link
    generic map(ADDR => "10")
    port map(
                clk => clk,
                com_clk => com_clk,
                r_nw => r_nw,
                addr_bus => addr_bus,
                data_tx => data_tx,
                data_bus => data_bus,
                data_rx => data_rx,
                tx_success => tx_success
            );

    PE : entity work.passwd_expander
    port map(
                clk => clk,
                com_clk => com_clk,
                passwd => passwd,
                output_valid => passwd_valid,
                data_in => data_rx
            );

    rst_core <= not passwd_valid;
    C1 : entity work.sha256_core
    port map (
                 clk       => clk,
                 start     => passwd_valid,
                 reset     => rst_core,
                 passwd_in => passwd,
                 hash_out  => hash,
                 hash_done => hash_done
             );
end Behavioral;
