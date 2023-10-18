library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;

entity data_link is
    port(
        -- inputs
        clk      : in STD_LOGIC; -- system clock
        com_clk  : in STD_LOGIC;
        r_nw     : in STD_LOGIC; -- R/not_W signal (read active high)
        addr     : in STD_LOGIC_VECTOR(1 downto 0);
        data_tx  : in STD_LOGIC_VECTOR(7 downto 0);
        data_rx  : in STD_LOGIC_VECTOR(7 downto 0);
        -- outputs
        data_out  : out STD_LOGIC_VECTOR(7 downto 0);
        r_nw_out : out STD_LOGIC; -- mirrored R/now_W signal
        );
end data_link;

architecture Behavioral of data_link is
begin
    process(clk, com_clk, r_nw)
        variable recv_data : STD_LOGIC := '1'; -- flag, high when data has not been received this com_clk cycle
    begin
        if rising_edge(clk) then
            -- not correct
            if com_clk = '1' and recv_data = '1' then
                data_out <= data_rx;
                recv_data := '0';
            elsif com_clk = '0' then
                recv_data := '1';
            else
                data_out <= data_out;
            end if;
        end if;
    end process;
end Behavioral;
