library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;

entity data_link is
    -- Constants
    generic(ADDR : STD_LOGIC_VECTOR(1 downto 0) := "00");
    port(
        -- inputs
        clk      : in STD_LOGIC; -- system clock
        rising_trig : in std_logic;
        falling_trig : in std_logic;
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
    signal addr_latch : std_logic_vector(1 downto 0);
    signal r_nw_latch : std_logic;
    signal drive_data : std_logic := '0';
begin
    process(clk, rising_trig, falling_trig, addr_bus, r_nw, data_tx)
    begin
        if rising_edge(clk) then
            -- com_clk rising edge
            if (rising_trig = '1') then
                drive_data <= '0';
                addr_latch <= addr_bus;
                r_nw_latch <= r_nw;

                -- Data bus drive logic
                if addr_bus = ADDR then
                -- we are the ones being talked to
                    if r_nw = '1' then
                        -- slave will write to data bus
                        drive_data <= '1';
                    end if;
                end if;
            end if;

            -- com_clk falling edge
            if (falling_trig = '1') then
                if addr_latch = ADDR then
                    -- we are the ones being talked to
                    if r_nw_latch = '0' then
                        tx_success <= '0';
                        -- latch input from master
                        data_rx <= data_bus;
                    else
                        tx_success <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Moore outputs
    DATA_DRIVER : for i in 0 to 7 generate
        data_bus(i) <= '0' when drive_data = '1' and data_tx(i) = '0' else 'Z';
    end generate;
end Behavioral;
