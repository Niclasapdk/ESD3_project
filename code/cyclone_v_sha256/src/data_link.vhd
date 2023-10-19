library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;

entity data_link is
    port(
        -- inputs
        --clk      : in STD_LOGIC; -- system clock
        com_clk  : in STD_LOGIC;
        r_nw     : in STD_LOGIC; -- R/not_W signal (read active high) (as seen by the master)
        addr_bus : in STD_LOGIC_VECTOR(1 downto 0);
        data_tx  : in STD_LOGIC_VECTOR(7 downto 0);
        -- inout
        data_bus : inout STD_LOGIC_VECTOR(7 downto 0);
        -- outputs
        data_rx  : out STD_LOGIC_VECTOR(7 downto 0);

        -- debug
        dbg_int_r_nw : out STD_LOGIC
        );
end data_link;

architecture Behavioral of data_link is
begin
    process(com_clk)
        variable int_addr : STD_LOGIC_VECTOR(1 downto 0);
        variable int_r_nw : STD_LOGIC;
    begin
        if falling_edge(com_clk) then
            int_addr := addr_bus;
            int_r_nw := r_nw;
            dbg_int_r_nw <= not int_r_nw;
            if int_addr = "10" then -- we are the ones being talked to
                if int_r_nw = '1' then -- slave will write to data bus
                    data_bus <= data_tx; -- setup
                end if;
            else
                data_bus <= "ZZZZZZZZ";
            end if;
        elsif rising_edge(com_clk) then
            if int_addr = "10" then -- we are the ones being talked to
                if int_r_nw = '0' then -- master will have written data bus as last falling edge
                    data_rx <= data_bus; -- latch
                end if;
            end if;
        end if;
    end process;
end Behavioral;
