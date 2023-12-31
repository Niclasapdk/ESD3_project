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
        idle : out std_logic;
        hash_out : out std_logic_vector(255 downto 0);
        hash_done: out std_logic
        );
end multi_round_hasher;

architecture Behavioral of multi_round_hasher is
    signal core_done : std_logic;
    signal core_hash : std_logic_vector(255 downto 0);
    signal core_in : std_logic_vector(0 to 511);
    signal core_start : std_logic;

    type multi_round_state_t is (IDLE_RESET, START_CORE, RUNNING_CORE_READY, RUNNING_CORE_WAIT, DONE, DONE_CORE_WAIT);
    signal current_state : multi_round_state_t := IDLE_RESET;
    signal next_state : multi_round_state_t := IDLE_RESET;

    signal rounds_internal : unsigned(31 downto 0);
    signal rounds_ctr : unsigned(31 downto 0);

    -- Counter to not continue from waiting too soon
    -- set to 1 when starting core and not continuing until wait_ctr = 0
    signal wait_ctr : unsigned(2 downto 0) := "001";
begin
    HC : entity work.sha256_core
    port map (
                 clk       => clk,
                 start     => core_start,
                 reset     => reset,
                 passwd_in => core_in,
                 hash_out  => core_hash,
                 hash_done => core_done
             );

    -- Current state logic
    process(clk)
    begin
        if rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Next-state logic
    process(current_state, rounds_internal, rounds_ctr, reset, start, core_done, wait_ctr)
    begin
        case current_state is
            when IDLE_RESET =>
                if start = '1' then
                    next_state <= START_CORE;
                else
                    next_state <= IDLE_RESET;
                end if;

            when START_CORE =>
                next_state <= RUNNING_CORE_WAIT;

            when RUNNING_CORE_WAIT =>
                if rounds_internal = rounds_ctr then
                    next_state <= DONE_CORE_WAIT;
                elsif core_done = '1' and wait_ctr = "000" then
                    next_state <= RUNNING_CORE_READY;
                else
                    next_state <= RUNNING_CORE_WAIT;
                end if;

            when RUNNING_CORE_READY =>
                next_state <= RUNNING_CORE_WAIT;

            when DONE_CORE_WAIT =>
                if core_done = '1' and wait_ctr = "000" then
                    next_state <= DONE;
                else
                    next_state <= DONE_CORE_WAIT;
                end if;

            when DONE =>
                next_state <= DONE;

            end case;

            if (reset = '1') then
                next_state <= IDLE_RESET;
            end if;
    end process;

    -- Real logic
    process(clk, core_done)
    begin
        if rising_edge(clk) then
            case current_state is
                when IDLE_RESET =>
                    rounds_ctr <= (others => '0');
                when START_CORE =>
                    core_start <= '1';
                    rounds_ctr <= x"00000001";
                    rounds_internal <= rounds;
                    core_in <= passwd_in;
                    wait_ctr <= "001";
                when RUNNING_CORE_WAIT =>
                    core_start <= '0';
                    if (wait_ctr /= "000") then
                        wait_ctr <= to_unsigned(to_integer(wait_ctr)+1, 3);
                    end if;
                when RUNNING_CORE_READY =>
                    core_start <= '1';
                    core_in <= pad_hash_digest(core_hash);
                    rounds_ctr <= to_unsigned(to_integer(rounds_ctr) + 1, 32);
                    wait_ctr <= "001";
                when DONE_CORE_WAIT =>
                    core_start <= '0';
                    if (wait_ctr /= "000") then
                        wait_ctr <= to_unsigned(to_integer(wait_ctr)+1, 3);
                    end if;
                when DONE =>
             end case;
        end if;

    end process;

    idle <= '1' when current_state = IDLE_RESET else '0';

    hash_done <= '1' when current_state = DONE else '0';
    hash_out <= core_hash;
end Behavioral;
