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
    signal data_bus : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal data_rx  : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    type pkt_ar_t is array(0 to 1) of std_logic_vector(0 to 527);
    constant pkt : pkt_ar_t := (
        x"02414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141418000000000000001b803",
        x"0249636520637265616d61626364656667686a696b6c6d6e6f708000000000000000000000000000000000000000000000000000000000000000000000000000c803"
    );
    constant CLK_PERIOD : time := 10 ns;
    constant COM_CLK_PERIOD : time := 1 us;
    signal pidx : unsigned(0 downto 0) := "0";
    signal cur_pkt : std_logic_vector(0 to 527);
begin
    clk <= not clk after CLK_PERIOD/2;
    com_clk <= not com_clk after COM_CLK_PERIOD/2;

    DUT : entity work.slave_top
    port map(
        -- inputs
        clk      => clk,
        com_clk  => com_clk,
        r_nw     => r_nw,
        addr_bus => addr_bus,
        data_tx  => data_tx,
        -- inout
        data_bus => data_bus,
        data_rx  => data_rx
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
