library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.plusbus_pkg.ALL;

entity passwd_parser is
    port(
            -- Outputs
            passwd : out std_logic_vector(0 to 511);
            output_valid : out std_logic;
            esc : out std_logic;

            -- Inputs
            clk : in std_logic; -- System clock
            data_in : in std_logic_vector(7 downto 0);
            rising_trig : in std_logic;
            falling_trig : in std_logic;
            reset : in std_logic
        );
end passwd_parser;

architecture Behaviorial of passwd_parser is
    type passwd_parser_state_type is (IDLE, STOP, START, ESCAPE, DATA);
    signal current_state : passwd_parser_state_type := IDLE;
    signal next_state : passwd_parser_state_type := IDLE;

begin

    -- Next state logic	
    process(current_state, data_in, reset)
    begin
        output_valid <= '0';
        case current_state is
            when IDLE =>
                if (data_in = PLUSBUS_STX) then
                    next_state <= START;
                else
                    next_state <= IDLE;
                end if;
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
        if (reset = '1') then
            next_state <= IDLE;
        end if;
    end process;

    -- Combinatorial and current state logic
    process(clk, rising_trig, current_state, next_state, data_in) is
        variable idx : unsigned(8 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            -- com_clk rising edge
            if (rising_trig = '1') then
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
    esc <= '1' when current_state = ESCAPE else '0';

end Behaviorial;
