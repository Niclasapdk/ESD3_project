library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;

entity data_link is
    -- Constants
    generic(ADDR : STD_LOGIC_VECTOR(1 downto 0) := "00");
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
        data_rx  : out STD_LOGIC_VECTOR(7 downto 0)
        );
end data_link;

architecture Behavioral of data_link is
begin

    process(com_clk)
        variable addr_I : STD_LOGIC_VECTOR(1 downto 0);
        variable r_nw_I : STD_LOGIC;
    begin

        if rising_edge(com_clk) then
            addr_I := addr_bus;
            r_nw_I := r_nw;

            if r_nw_I = '1' then
                -- slave will write to data bus
                if addr_I = ADDR then
                    -- we are the ones being talked to
                    for i in 0 to 7 loop
                        if data_tx(i) = '1' then
                            data_bus(i) <= 'Z';
                        else
                            data_bus(i) <= '0';
                        end if;
                    end loop;
                end if;
            else
                data_bus <= "ZZZZZZZZ";
            end if;

        elsif falling_edge(com_clk) then
            if addr_I = ADDR then
                -- we are the ones being talked to
                if r_nw_I = '0' then
                    -- latch input from master
                    data_rx <= data_bus;
                end if;
            end if;
        end if;

    end process;
end Behavioral;
