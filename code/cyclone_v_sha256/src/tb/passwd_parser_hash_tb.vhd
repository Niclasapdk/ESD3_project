library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity passwd_parser_hash_tb is
end passwd_parser_hash_tb;

architecture Behavioral of passwd_parser_hash_tb is
    signal clk  : STD_LOGIC := '0';
    signal com_clk  : STD_LOGIC := '0';
    signal reset : std_logic := '0';
    signal passwd : std_logic_vector(0 to 511) := (others => '0');
    signal passwd_valid : std_logic := '0';
    signal r_nw     : STD_LOGIC := '0'; -- R/not_W signal (read active high) (as seen by the master)
    signal addr_bus : STD_LOGIC_VECTOR(1 downto 0) := "10";
    signal data_tx  : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal tx_success : std_logic;
    signal data_bus : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal data_rx  : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    type pkt_ar_t is array(0 to 1) of std_logic_vector(0 to 527);
    constant pkt : pkt_ar_t := (
        x"024170706c6561626364656667686a696b6c6d6e6f70800000000000000000000000000000000000000000000000000000000000000000000000000000000000a803",
        x"0249636520637265616d61626364656667686a696b6c6d6e6f708000000000000000000000000000000000000000000000000000000000000000000000000000c803"
    );
    constant CLK_PERIOD : time := 40 ns;
    constant COM_CLK_PERIOD : time := 1 ms;
    signal hash : std_logic_vector(255 downto 0) := (others => '0');
    signal hash_done : std_logic := '0';
    signal rounds : unsigned(31 downto 0) := x"00000002";
    signal pidx : unsigned(0 downto 0) := "0";
    signal cur_pkt : std_logic_vector(0 to 527);
    -- Clock Synchronization
	signal rising_trig  : std_logic := '0';
	signal falling_trig : std_logic := '0';
begin
    clk <= not clk after CLK_PERIOD/2;
    com_clk <= not com_clk after COM_CLK_PERIOD/2;

    CSM : entity work.clock_sync_mod
    port map(
                sys_clk      => clk,
                sync_clk     => com_clk,
                rising_trig  => rising_trig,
                falling_trig => falling_trig
            );

    PBSC : entity work.plusbus_slave_controller
    generic map(ADDR         => "10")
    port map(
                clk          => clk,
                rising_trig  => rising_trig,
				falling_trig => falling_trig,
                r_nw         => r_nw,
                addr_bus     => addr_bus,
                data_tx      => data_tx,
                data_bus     => data_bus,
                data_rx      => data_rx,
                tx_success   => tx_success
            );

    PP : entity work.passwd_parser
    port map(
                clk          => clk,
                rising_trig  => rising_trig,
				falling_trig => falling_trig,
                passwd       => passwd,
                reset        => reset,
                output_valid => passwd_valid,
                data_in      => data_rx
            );

    C1 : entity work.sha256_core
    port map (
                clk       => clk,
                start     => passwd_valid,
                reset     => reset,
                passwd_in => passwd,
                hash_out  => hash,
                hash_done => hash_done
             );


    cur_pkt <= pkt(to_integer(pidx));
    process(com_clk)
        variable idx : integer := 0;
    begin
        if rising_edge(com_clk) then
            if idx = 528 then
                idx := 0;
                pidx <= not pidx;
            end if;

            data_bus <= cur_pkt(idx to idx+7);
            idx := idx + 8;
        end if;
    end process;
end Behavioral;
