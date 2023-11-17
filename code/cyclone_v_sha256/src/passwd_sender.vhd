library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.sha256_pkg.ALL;

entity passwd_sender is
    port(
        -- Inputs
        clk : in std_logic;
        passwd : in std_logic_vector(0 to 511);
        passwd_valid : in std_logic;
        -- Outputs
        data_tx : out std_logic_vector(7 downto 0)
        );
end passwd_sender;

architecture Behavioral of passwd_sender is
    type passwd_sender_state_t is (IDLE, START, DATA, STOP);
    signal current_state : passwd_sender_state_t := IDLE;
    signal next_state : passwd_sender_state_t := IDLE;
begin
    -- Current state logic
    process(clk, next_state)
    begin
        if rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Next state logic
    process(current_state, passwd_valid)
    begin
        case current_state is
            when IDLE =>
            when START =>
            when DATA =>
            when STOP =>
    end process;
end Behavioral;
