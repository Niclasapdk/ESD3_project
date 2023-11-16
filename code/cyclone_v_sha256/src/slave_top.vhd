library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.sha256_pkg.ALL;

entity slave_top is
    generic(
               slave_addr : in std_logic_vector(1 downto 0) := "10";
               target_hash : in std_logic_vector(255 downto 0) := x"ff7d9978045a76d74350c1b7866cf3cfe058a8c6249213a69aed843ba1e1680f"
           );
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
end slave_top;

architecture Behavioral of slave_top is
    signal passwd : std_logic_vector(511 downto 0);
    signal passwd_valid : std_logic;
    signal tx_success : std_logic;
    signal hash : std_logic_vector(255 downto 0) := (others => '0');
    signal hash_done : std_logic := '0';
    signal rounds : unsigned(31 downto 0) := x"00000002";
    signal cc_ready_for_passwd : std_logic;
    signal passwd_out : std_logic_vector(0 to 511);
    signal passwd_found : std_logic;
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

    CC : entity work.core_controller
    port map (
                 clk => clk,
                 passwd => passwd,
                 passwd_valid => passwd_valid,
                 rounds => rounds,
                 target_hash => target_hash,
                 ready_for_new_passwd => cc_ready_for_passwd,
                 passwd_out => passwd_out,
                 passwd_found => passwd_found
             );
end Behavioral;
