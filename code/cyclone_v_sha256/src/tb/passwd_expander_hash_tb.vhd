library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity passwd_expander_hash_tb is
end passwd_expander_hash_tb;

architecture Behavioral of passwd_expander_hash_tb is
    signal clk  : STD_LOGIC := '0';
    signal com_clk  : STD_LOGIC := '0';
    signal passwd : std_logic_vector(0 to 511) := (others => '0');
    signal passwd_valid : std_logic := '0';
    signal r_nw     : STD_LOGIC := '0'; -- R/not_W signal (read active high) (as seen by the master)
    signal addr_bus : STD_LOGIC_VECTOR(1 downto 0) := "10";
    signal data_tx  : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal tx_success : std_logic;
    signal data_bus : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal data_rx  : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    constant pkt : std_logic_vector(0 to 527) := x"024170706c6561626364656667686a696b6c6d6e6f70800000000000000000000000000000000000000000000000000000000000000000000000000000000000a803";
    constant CLK_PERIOD : time := 10 ns;
    constant COM_CLK_PERIOD : time := 1 us;
    signal hash : std_logic_vector(255 downto 0) := (others => '0');
    signal hash_done : std_logic := '0';
    signal rst_core : std_logic := '0';
    signal rounds : unsigned(31 downto 0) := x"00000002";
begin
    clk <= not clk after CLK_PERIOD/2;
    com_clk <= not com_clk after COM_CLK_PERIOD/2;
    DL : entity work.data_link
    generic map(ADDR => "10")
    port map(
                clk      => clk,
                com_clk  => com_clk,
                r_nw     => r_nw,
                addr_bus => addr_bus,
                data_tx  => data_tx,
                data_bus => data_bus,
                data_rx  => data_rx,
                tx_success => tx_success
            );

    PE : entity work.passwd_expander
    port map(
                clk          => clk,
                com_clk      => com_clk,
                passwd       => passwd,
                output_valid => passwd_valid,
                data_in      => data_rx
            );

    rst_core <= not passwd_valid;
    C1 : entity work.sha256_core
    port map (
                 rounds => rounds,
                 clk       => clk,
                 start     => passwd_valid,
                 reset     => rst_core,
                 passwd_in => passwd,
                 hash_out  => hash,
                 hash_done => hash_done
             );


    process(com_clk)
        variable idx : integer := 0;
    begin
        if rising_edge(com_clk) then
            if idx = 528 then
                idx := 0;
            end if;

            data_bus <= pkt(idx to idx+7);
            idx := idx + 8;
        end if;
    end process;
end Behavioral;
