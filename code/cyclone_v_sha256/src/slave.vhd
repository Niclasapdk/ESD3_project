library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.plusbus_pkg.ALL;

entity slave is
    generic(
               N_CORES : in integer := 3;
               slave_addr : in std_logic_vector(1 downto 0) := "10"
           );
    port(
        -- inputs
        clk           : in STD_LOGIC; -- system clk (after PLL)
        com_clk       : in STD_LOGIC;
        r_nw          : in STD_LOGIC; -- R/not_W signal (read active high) (as seen by the master)
        addr_bus      : in STD_LOGIC_VECTOR(1 downto 0);
        -- inout
        data_bus      : inout STD_LOGIC_VECTOR(7 downto 0);
        -- outputs
        cores_running : out std_logic_vector(0 to N_CORES-1);
        flags_out     : out std_logic_vector(5 downto 0)
        );
end slave;

architecture Behavioral of slave is
    signal passwd : std_logic_vector(511 downto 0);
    signal passwd_valid : std_logic;
    signal target_hash : std_logic_vector(255 downto 0) := x"ec56a99b7b5c725a4a9e194f9fa784d6456272f00a1d44b8dddf6f095745628f"; -- 5000 rounds (passwd + salt < maxlen)
    signal hash : std_logic_vector(255 downto 0) := (others => '0');
    signal hash_done : std_logic := '0';
    signal rounds : unsigned(31 downto 0) := x"00001388";
    signal cc_ready_for_passwd : std_logic;
    signal passwd_out : std_logic_vector(0 to 511);
    signal passwd_found : std_logic;

    signal data_rx : std_logic_vector(7 downto 0);
    signal data_tx : std_logic_vector(7 downto 0);
    signal tx_success : std_logic;

    -- Clock Synchronization
    signal rising_trig  : std_logic := '0';
    signal falling_trig : std_logic := '0';
    signal reset        : std_logic := '0';
    signal escape_glob  : std_logic := '0';
    signal escape_pe    : std_logic := '0';
    signal escape_he    : std_logic := '0';
    signal escape_re    : std_logic := '0';
begin

    CSM : entity work.clock_sync_mod
    port map(
                sys_clk      => clk,
                sync_clk     => com_clk,
                rising_trig  => rising_trig,
                falling_trig => falling_trig
            );

    PBSC : entity work.plusbus_slave_controller
    generic map(ADDR         => slave_addr)
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
    reset <= '1' when data_rx = PLUSBUS_RST and escape_glob = '0' else '0';
    escape_glob <= escape_pe or escape_he or escape_re;

    HP : entity work.hash_parser
    port map(
                clk          => clk,
                rising_trig  => rising_trig,
                falling_trig => falling_trig,
                hash         => target_hash,
                esc          => escape_he,
                data_in      => data_rx,
                reset        => reset
            );

    RP : entity work.rounds_parser
    port map(
                clk          => clk,
                rising_trig  => rising_trig,
                falling_trig => falling_trig,
                rounds       => rounds,
                esc          => escape_re,
                data_in      => data_rx,
                reset        => reset
            );

    PP : entity work.passwd_parser
    port map(
                clk          => clk,
                rising_trig  => rising_trig,
                falling_trig => falling_trig,
                passwd       => passwd,
                esc          => escape_pe,
                output_valid => passwd_valid,
                data_in      => data_rx,
                reset        => reset
            );

    CC : entity work.core_controller
    generic map ( N => N_CORES )
    port map (
                 clk                  => clk,
                 passwd               => passwd,
                 passwd_valid         => passwd_valid,
                 rounds               => rounds,
                 target_hash          => target_hash,
                 reset                => reset,
                 ready_for_new_passwd => cc_ready_for_passwd,
                 passwd_out           => passwd_out,
                 passwd_found         => passwd_found,
                 cores_running        => cores_running
             );
    flags_out(0) <= cc_ready_for_passwd;
    flags_out(1) <= passwd_found;
    flags_out(2) <= reset;

    MS : entity work.msg_sender
    port map(
                clk              => clk,
                rising_trig      => rising_trig,
                falling_trig     => falling_trig,
                reset            => reset,
                passwd           => passwd_out(0 to 439),
                --passwd           => x"666c61677b79617979797d8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                passwd_valid     => passwd_found,
                --passwd_valid => '1',
                ready_for_passwd => cc_ready_for_passwd,
                tx_success       => tx_success,
                data_tx          => data_tx
            );
end Behavioral;
