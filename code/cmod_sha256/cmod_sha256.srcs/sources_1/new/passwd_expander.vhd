library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity passwd_expander is
	generic(
				-- Constants
				stx : std_logic_vector(7 downto 0);
				etx : std_logic_vector(7 downto 0);
				dle : std_logic_vector(7 downto 0)
			);
    port(
            -- Outputs
            passwd : out std_logic_vector(511 downto 0);
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
		case current_state is
			when STOP =>
				if (data_in = stx) then
					next_state <= START;
				else
					next_state <= STOP;
				end if;
			when START =>
				next_state <= DATA;
			when ESCAPE =>
				next_state <= DATA;
			when DATA =>
				if (data_in = dle) then
					next_state <= ESCAPE;
                elsif (data_in = etx) then
					next_state <= STOP;
				else
					next_state <= DATA;
				end if;
		end case;
	end process;
	
	-- Combinatorial and current state logic
    process(clk, com_clk, current_state, data_in) is
		variable idx : integer := 0;
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
                        output_valid <= '0';
                        idx := 0;
                        passwd(idx+7 downto idx) <= data_in;
                        idx := idx + 8;
                    when DATA =>
                        if (idx < 512) then
                            if (data_in /= dle) then
                                passwd(idx+7 downto idx) <= data_in;
                                idx := idx + 8;
                            end if;
                        end if;
                    when ESCAPE =>
                        passwd(idx+7 downto idx) <= data_in;
                        idx := idx + 8;
                    when STOP =>
                        output_valid <= '1';
                    when others =>
                end case;
            end if;
        end if;
	end process;
	
end Behaviorial;
