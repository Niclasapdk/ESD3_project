library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.plusbus_pkg.ALL;

entity rounds_expander is
    port(
            -- Outputs
            rounds : out unsigned(31 downto 0);
            esc : out std_logic;

            -- Inputs
            clk : in std_logic; -- System clock
            data_in : in std_logic_vector(7 downto 0);
            rising_trig : in std_logic;
            falling_trig : in std_logic;
            reset : in std_logic
        );
end rounds_expander;

architecture Behaviorial of rounds_expander is
    type rounds_expander_state_type is (IDLE, STOP, START, ESCAPE, DATA);
    signal current_state : rounds_expander_state_type := IDLE;
    signal next_state : rounds_expander_state_type := IDLE;

begin

    -- Next state logic	
    process(current_state, data_in, reset)
    begin
        case current_state is
            when IDLE =>
                if (data_in = PLUSBUS_RDS) then
                    next_state <= START;
                else
                    next_state <= IDLE;
                end if;
            when STOP =>
                if (data_in = PLUSBUS_RDS) then
                    next_state <= START;
                else
                    next_state <= STOP;
                end if;
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
        variable idx : unsigned(4 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            -- com_clk rising edge
            if (rising_trig = '1') then
                current_state <= next_state;
                case current_state is
                    when START =>
                        idx := (others => '0');
                        rounds(to_integer(idx)+7 downto to_integer(idx)) <= unsigned(data_in);
                        idx := idx + 8;
                    when DATA =>
                        if (idx /= "00000") then
                            if (data_in /= PLUSBUS_DLE) then
                                rounds(to_integer(idx)+7 downto to_integer(idx)) <= unsigned(data_in);
                                idx := idx + 8;
                            end if;
                        end if;
                    when ESCAPE =>
                        rounds(to_integer(idx)+7 downto to_integer(idx)) <= unsigned(data_in);
                        idx := idx + 8;
                    when others =>
                end case;
            end if;
        end if;
    end process;
    esc <= '1' when current_state = ESCAPE else '0';

end Behaviorial;
