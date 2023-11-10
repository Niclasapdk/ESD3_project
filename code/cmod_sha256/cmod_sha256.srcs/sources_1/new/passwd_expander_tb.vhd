library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity passwd_expander_tb is
end passwd_expander_tb;

architecture Behavioral of passwd_expander_tb is
    signal clk  : STD_LOGIC := '0';
    signal com_clk  : STD_LOGIC := '0';
    signal passwd : std_logic_vector(511 downto 0) := (others => '0');
    signal output_valid : std_logic := '0';
    signal r_nw     : STD_LOGIC := '0'; -- R/not_W signal (read active high) (as seen by the master)
    signal addr_bus : STD_LOGIC_VECTOR(1 downto 0) := "10";
    signal data_tx  : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal data_bus : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal data_rx  : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    constant pkt : std_logic_vector(527 downto 0) := x"03a8000000000000000000000000000000000000000000000000000000000000000000000000000000000080706f6e6d6c6b696a6867666564636261656c70704102";
    constant CLK_PERIOD : time := 10 ns;
    constant COM_CLK_PERIOD : time := 1 ms;
begin
    clk <= not clk after CLK_PERIOD/2;
    com_clk <= not com_clk after COM_CLK_PERIOD/2;
    DL : entity work.data_link
    generic map(ADDR => "10")
    port map(
                clk => clk,
                com_clk => com_clk,
                r_nw => r_nw,
                addr_bus => addr_bus,
                data_tx => data_tx,
                data_bus => data_bus,
                data_rx => data_rx
            );

    PE : entity work.passwd_expander
    generic map(
                   stx => x"02",
                   etx => x"03",
                   dle => x"10"
               )
    port map(
                clk => clk,
                com_clk => com_clk,
                passwd => passwd,
                output_valid => output_valid,
                data_in => data_rx
            );

    process(com_clk)
        variable idx : integer := 0;
    begin
        if rising_edge(com_clk) then
            if idx = 528 then
                idx := 0;
            end if;

            data_bus <= pkt(idx+7 downto idx);
            idx := idx + 8;
        end if;
    end process;
end Behavioral;
