library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.plusbus_pkg.ALL;

entity passwd_expander is
    port(
            -- Outputs
            passwd : out std_logic_vector(0 to 511);
            output_valid : out std_logic;

            -- Inputs
            clk : in std_logic; -- System clock
            data_in : in std_logic_vector(7 downto 0);
            com_clk : in std_logic
        );
end passwd_expander;

architecture Behaviorial of passwd_expander is

    type passwd_expander_state_type is (STOP, START, ESCAPE, DATA);
    signal current_state : passwd_expander_state_type := STOP;
    signal next_state : passwd_expander_state_type := STOP;

    -- Clock synchronization
    signal r1_com_clk : std_logic;
    signal r2_com_clk : std_logic;
    signal r3_com_clk : std_logic;

begin

    -- Next state logic	
    process(current_state, data_in)
    begin
        output_valid <= '0';
        case current_state is
            when STOP =>
                if (data_in = PLUSBUS_STX) then
                    next_state <= START;
                else
                    next_state <= STOP;
                end if;
                output_valid <= '1';
            when START =>
                next_state <= DATA;
            when ESCAPE =>
                next_state <= DATA;
            when DATA =>
                if (data_in = PLUSBUS_DLE) then
                    next_state <= ESCAPE;
                elsif (data_in = PLUSBUS_ETX) then
                    next_state <= STOP;
                else
                    next_state <= DATA;
                end if;
        end case;
    end process;

    -- Combinatorial and current state logic
    process(clk, com_clk, current_state, data_in) is
        variable idx : unsigned(8 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then

            r1_com_clk <= com_clk;
            r2_com_clk <= r1_com_clk;
            r3_com_clk <= r2_com_clk;

            -- com_clk rising edge
            if r3_com_clk = '0' and r2_com_clk = '1' then
                current_state <= next_state;
                case current_state is
                    when START =>
                        idx := (others => '0');
                        passwd(to_integer(idx) to to_integer(idx)+7) <= data_in;
                        idx := idx + 8;
                    when DATA =>
                        if (idx /= "000000000") then
                            if (data_in /= PLUSBUS_DLE) then
                                passwd(to_integer(idx) to to_integer(idx)+7) <= data_in;
                                idx := idx + 8;
                            end if;
                        end if;
                    when ESCAPE =>
                        passwd(to_integer(idx) to to_integer(idx)+7) <= data_in;
                        idx := idx + 8;
                    when others =>
                end case;
            end if;
        end if;
    end process;

end Behaviorial;
