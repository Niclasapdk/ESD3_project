library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;

entity data_link is
    -- Constants
    generic(ADDR : STD_LOGIC_VECTOR(1 downto 0) := "00");
    port(
        -- inputs
        clk      : in STD_LOGIC; -- system clock
        com_clk  : in STD_LOGIC;
        r_nw     : in STD_LOGIC; -- R/not_W signal (read active high) (as seen by the master)
        addr_bus : in STD_LOGIC_VECTOR(1 downto 0);
        data_tx  : in STD_LOGIC_VECTOR(7 downto 0);
        -- inout
        data_bus : inout STD_LOGIC_VECTOR(7 downto 0);
        -- outputs
        tx_success : inout std_logic; -- flag to show if data was sent
        data_rx  : out STD_LOGIC_VECTOR(7 downto 0)
        );
end data_link;

architecture Behavioral of data_link is
    -- Clock synchronization
    signal r1_com_clk : std_logic;
    signal r2_com_clk : std_logic;
    signal r3_com_clk : std_logic;

    signal addr_latch : std_logic_vector(1 downto 0);
    signal r_nw_latch : std_logic;
begin
    --data_bus(0) <= 'Z' when tx_success = '1' else '0'; --mht
    process(clk, com_clk, addr_bus, r_nw, data_tx)
    begin
        if rising_edge(clk) then
            r1_com_clk <= com_clk;
            r2_com_clk <= r1_com_clk;
            r3_com_clk <= r2_com_clk;

            -- com_clk rising edge
            if r3_com_clk = '0' and r2_com_clk = '1' then
                tx_success <= '0';
                addr_latch <= addr_bus;
                r_nw_latch <= r_nw;

                if addr_bus = ADDR then
                -- we are the ones being talked to
                    if r_nw = '1' then
                        -- slave will write to data bus
                        tx_success <= '1';
                        for i in 0 to 7 loop --mht
                            if data_tx(i) = '1' then
                                data_bus(i) <= 'Z';
                            else
                                data_bus(i) <= '0';
                            end if;
                        end loop;
                    else
                        data_bus <= "ZZZZZZZZ";
                    end if;
                else
                    data_bus <= "ZZZZZZZZ";
                end if;
            end if;

            -- com_clk falling edge
            if r3_com_clk = '1' and r2_com_clk = '0' then
                if addr_latch = ADDR then
                    -- we are the ones being talked to
                    if r_nw_latch = '0' then
                        -- latch input from master
                        data_rx <= data_bus;
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
