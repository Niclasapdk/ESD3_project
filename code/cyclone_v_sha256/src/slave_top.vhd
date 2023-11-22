library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity slave_top is
    generic(
               N_CORES : in integer := 3;
               slave_addr : in std_logic_vector(1 downto 0) := "10";
               --target_hash : in std_logic_vector(255 downto 0) := x"ff7d9978045a76d74350c1b7866cf3cfe058a8c6249213a69aed843ba1e1680f" -- 2 rounds
               --target_hash : in std_logic_vector(255 downto 0) := x"bf23c3b7661e33d361c1b1b89389349a941313f5b2ff1c57b2c2204313e2f316" -- 5000 rounds (55 A's)
               target_hash : in std_logic_vector(255 downto 0) := x"ec56a99b7b5c725a4a9e194f9fa784d6456272f00a1d44b8dddf6f095745628f" -- 5000 rounds (passwd + salt < maxlen)
           );
    port(
        -- inputs
        clk50         : in STD_LOGIC; -- external oscillator (50 MHz)
        com_clk       : in STD_LOGIC;
        r_nw          : in STD_LOGIC; -- R/not_W signal (read active high) (as seen by the master)
        addr_bus      : in STD_LOGIC_VECTOR(1 downto 0);
        -- inout
        data_bus      : inout STD_LOGIC_VECTOR(7 downto 0);
        -- outputs
        cores_running : out std_logic_vector(0 to N_CORES-1);
        blink         : out std_logic -- sign-of-life
        );
end slave_top;

architecture Behavioral of slave_top is
    signal passwd : std_logic_vector(511 downto 0);
    signal passwd_valid : std_logic;
    signal hash : std_logic_vector(255 downto 0) := (others => '0');
    signal hash_done : std_logic := '0';
    signal rounds : unsigned(31 downto 0) := x"00001388";
    signal cc_ready_for_passwd : std_logic;
    signal passwd_out : std_logic_vector(0 to 511);
    signal passwd_found : std_logic;

    signal data_rx : std_logic_vector(7 downto 0);
    signal data_tx : std_logic_vector(7 downto 0);
    signal tx_success : std_logic;

    signal clk : std_logic;

    signal pll_rst : std_logic;
    signal pll_lock : std_logic;
    component pll_0002 is
        port (
                 refclk   : in  std_logic := 'X'; -- clk
                 rst      : in  std_logic := 'X'; -- reset
                 outclk_0 : out std_logic;        -- clk
                 locked   : out std_logic         -- export
             );
    end component pll_0002;
begin

    pll_inst : component pll_0002
    port map (
                 refclk   => clk50, --  refclk.clk
                 rst      => pll_rst,   --   reset.reset
                 outclk_0 => clk,   -- outclk0.clk
                 locked   => pll_lock -- (terminated)
             );

    LIFE : entity work.sign_of_life
    port map(
                clk => clk,
                blink => blink
            );

    DL : entity work.data_link
    generic map(ADDR => slave_addr)
    port map(
                clk        => clk,
                com_clk    => com_clk,
                r_nw       => r_nw,
                addr_bus   => addr_bus,
                data_tx    => data_tx,
                data_bus   => data_bus,
                data_rx    => data_rx,
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

    CC : entity work.core_controller
    generic map ( N => N_CORES )
    port map (
                 clk                  => clk,
                 passwd               => passwd,
                 passwd_valid         => passwd_valid,
                 rounds               => rounds,
                 target_hash          => target_hash,
                 ready_for_new_passwd => cc_ready_for_passwd,
                 passwd_out           => passwd_out,
                 passwd_found         => passwd_found,
                 cores_running        => cores_running
             );

    PS : entity work.passwd_sender
    port map(
                clk              => clk,
                com_clk          => com_clk,
                passwd           => passwd_out,
                passwd_valid     => passwd_found,
                ready_for_passwd => cc_ready_for_passwd,
                tx_success       => tx_success,
                data_tx          => data_tx
            );
end Behavioral;
