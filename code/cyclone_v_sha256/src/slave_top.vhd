library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity slave_top is
    generic(
               N_CORES : in integer := 3;
               slave_addr : in std_logic_vector(1 downto 0) := "10"
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
        flags_out     : out std_logic_vector(5 downto 0);
        blink         : out std_logic -- sign-of-life
        );
end slave_top;

architecture Behavioral of slave_top is
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

    SLAVE : entity work.slave
    generic map(
                   N_CORES     => N_CORES,
                   slave_addr  => slave_addr
               )
    port map(
                clk           => clk,
                com_clk       => com_clk,
                r_nw          => r_nw,
                addr_bus      => addr_bus,
                data_bus      => data_bus,
                cores_running => cores_running,
                flags_out     => flags_out
            );
end Behavioral;
