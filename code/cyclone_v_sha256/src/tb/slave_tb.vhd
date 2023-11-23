library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity slave_tb is
end slave_tb;

architecture Behavioral of slave_tb is
    signal clk  : STD_LOGIC := '0';
    signal com_clk  : STD_LOGIC := '0';
    signal r_nw     : STD_LOGIC := '0'; -- R/not_W signal (read active high) (as seen by the master)
    signal addr_bus : STD_LOGIC_VECTOR(1 downto 0) := "10";
    signal data_tx  : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal data_bus : STD_LOGIC_VECTOR(7 downto 0) := x"ff";
    signal data_rx  : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    type pkt_ar_t is array(0 to 2) of std_logic_vector(0 to 527);
    constant pkt : pkt_ar_t := (
        x"0249636520637265616d61626364656667686a696b6c6d6e6f708000000000000000000000000000000000000000000000000000000000000000000000000000c803",
        x"02436f6666656561626364656667686a696b6c6d6e6f708000000000000000000000000000000000000000000000000000000000000000000000000000000000b003",
        x"02414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141418000000000000001b803"
    );
    constant CLK_PERIOD : time := 333 ns;
    constant COM_CLK_PERIOD : time := 1000 us;
    constant N_CORES : integer := 3;
    signal cores_running : std_logic_vector(0 to N_CORES-1) := (others => '0');
begin
    clk <= not clk after CLK_PERIOD/2;
    com_clk <= not com_clk after COM_CLK_PERIOD/2;

    DUT : entity work.slave
    generic map( N_CORES => N_CORES )
    port map(
        clk           => clk,
        com_clk       => com_clk,
        r_nw          => r_nw,
        addr_bus      => addr_bus,
        data_bus      => data_bus,
        cores_running => cores_running
        );

    process(com_clk)
        variable pidx : integer range 0 to 2 := 0;
        variable cur_pkt : std_logic_vector(0 to 527) := pkt(0);
        variable idx : integer := 0;
        variable read_from_slave : std_logic := '0';
        variable read_ctr : integer := 0;
    begin
        cur_pkt := pkt(pidx);
        if rising_edge(com_clk) then
            if (read_from_slave = '0') then
                if idx = 528 then
                    idx := 0;
                    if (pidx < 2) then
                        pidx := pidx + 1;
                    else
                        read_ctr := 0;
                        read_from_slave := '1';
                        pidx := 0;
                    end if;
                end if;

                data_bus <= cur_pkt(idx to idx+7);
                idx := idx + 8;
            else
                if (read_ctr > 20) then
                    read_ctr := 0;
                    read_from_slave := '0';
                else
                    read_ctr := read_ctr + 1;
                end if;
                data_bus <= "ZZZZZZZZ";
            end if;
        end if;

        if falling_edge(com_clk) then
            r_nw <= read_from_slave;
        end if;
    end process;
end Behavioral;
