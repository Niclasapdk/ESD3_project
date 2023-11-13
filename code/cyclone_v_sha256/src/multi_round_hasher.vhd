library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.sha256_pkg.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_round_hasher is
    port(
        -- inputs
        clk : in std_logic;
        start : in std_logic;
        reset : in std_logic;
        passwd_in : in std_logic_vector(0 to 511);
        rounds : in unsigned(31 downto 0);
        -- outputs
        hash_out : out std_logic_vector(255 downto 0);
        hash_done: out std_logic
        );
end multi_round_hasher;

architecture Behavioral of multi_round_hasher is
    signal core_done : std_logic;
    signal core_hash : std_logic_vector(255 downto 0);
    signal core_in : std_logic_vector(0 to 511);
    signal core_rst : std_logic;
    signal core_start : std_logic;

    type multi_round_state_t is (IDLE_RESET, START_WAIT_CORE, RUNNING, RUNNING_CORE_READY, RUNNING_CORE_WAIT, START_CORE_READY, DONE, DONE_CORE_WAIT);
    signal current_state : multi_round_state_t := IDLE_RESET;
    signal next_state : multi_round_state_t := IDLE_RESET;

    signal rounds_internal : unsigned(31 downto 0);
    signal rounds_ctr : unsigned(31 downto 0);
begin
    HC : entity work.sha256_core
    port map (
                 clk       => clk,
                 start     => core_start,
                 reset     => core_rst,
                 passwd_in => core_in,
                 hash_out  => core_hash,
                 hash_done => core_done
             );

    -- Current state logic
    process(clk)
    begin
        if rising_edge(clk) then
            current_state <= next_state;
            current_round_state <= next_round_state;
        end if;
    end process;

    -- Next-state logic
    process(current_state, rounds_internal, rounds_ctr, reset, start, core_done)
    begin
        case current_state is
            when IDLE_RESET =>
                if start = '1' then
                    next_state <= START_CORE_WAIT;
                else
                    next_state <= IDLE_RESET;
                end if;
            when START_CORE_WAIT =>
                if core_done = '1' then
                    next_state <= START_CORE_READY;
                else
                    next_state <= START_CORE_WAIT;
                end if;
            when START_CORE_READY =>
                next_state <= RUNNING_CORE_WAIT;
            when RUNNING_CORE_WAIT =>
                if rounds_internal = rounds_ctr + 1 then
                    next_state <= DONE_CORE_WAIT;
                elsif core_done = '1' then
                    next_state <= RUNNING_CORE_READY;
                else
                    next_state <= RUNNING_CORE_WAIT;
                end if;
            when RUNNING_CORE_READY =>
                next_state <= RUNNING_CORE_WAIT;
            when DONE_CORE_WAIT =>
                if core_done = '1' then
                    next_state <= DONE;
                else
                    next_state <= DONE_CORE_WAIT;
                end if;
            when DONE =>
                if reset = '1' then
                    next_state <= IDLE_RESET;
                else
                    next_state <= DONE;
                end if;
    end process;

    -- Real logic
    process(clk, core_done)
    begin
        if rising_edge(clk) then
            case current_state is
                when IDLE_RESET =>
                    rounds_ctr <= (others => '0');
                when START =>
                    rounds_internal <= rounds;
                    rounds_ctr <= (others => '0');
                    core_in <= passwd_in;
                when RUNNING =>
        end if;
    end process;

    hash_done <= '1' when current_state = DONE else '0';
end Behavioral;
