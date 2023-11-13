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

    type multi_round_state_t is (IDLE_RESET, START, RUNNING, DONE);
    signal current_state : multi_round_state_t := IDLE_RESET;
    signal next_state : multi_round_state_t := IDLE_RESET;

    type round_state_t is (WAIT_CORE, CORE_READY);
    signal current_round_state : multi_round_state_t := CORE_READY;
    signal next_round_state : multi_round_state_t := CORE_READY;

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
    process(current_state, rounds_internal, rounds_ctr, start, reset)
    begin
        case current_state is
            when IDLE_RESET =>
                if start = '1' then
                    next_state <= START;
                else
                    next_state <= IDLE_RESET;
                end if;
            when START =>
                next_state <= RUNNING;
            when RUNNING =>
                if rounds_internal = rounds_ctr+1 then
                    next_state <= DONE;
                else
                    next_state <= RUNNING;
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
