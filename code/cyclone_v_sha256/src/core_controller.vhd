library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.sha256_pkg.ALL;

entity core_controller is
    generic( N : in integer := 0); -- number of cores
    port(
            -- Inputs
            clk : in std_logic;
            passwd : in std_logic_vector(0 to 511);
            passwd_valid : in std_logic;
            rounds : in unsigned(31 downto 0);
            target_hash : in std_logic_vector(255 downto 0);

            -- Outputs
            ready_for_new_passwd : out std_logic;
            passwd_out : out std_logic_vector(0 to 511);
            passwd_found : out std_logic
        );
end core_controller;

architecture Behavioral of core_controller is
    type core_controller_type_t is (IDLE, PASSWD_RECV, CORE_DONE);
    signal current_state : core_controller_type_t := IDLE;
    signal next_state : core_controller_type_t := IDLE;

    -- Core flags arrays
    type core_flag_ar_t is array(0 to N-1) of std_logic;
    signal core_start_flags : core_flag_ar_t := (others => '0');
    signal core_idle_flags : core_flag_ar_t := (others => '0');
    signal core_reset_flags : core_flag_ar_t := (others => '0');
    signal core_done_flags : core_flag_ar_t := (others => '0');

    -- Core output hash arrays
    type core_hash_ar_t is array(0 to N-1) of std_logic_vector(255 downto 0);
    signal core_hash_ar : core_hash_ar_t := (others => (others => '0'));

    type core_passwd_ar_t is array(0 to N-1) of std_logic_vector(0 to 511);
    signal core_passwd_ar : core_passwd_ar_t := (others => (others => '0'));
begin

    -- Instantiate hash cores
    CREATE_CORES : for i in 0 to N-1 generate
        MRH : entity work.multi_round_hasher
        port map (
            clk       => clk,
            start     => core_start_flags(i),
            passwd_in => core_passwd_ar(i),
            hash_out  => core_hash_ar(i),
            hash_done => core_done_flags(i),
            reset     => core_reset_flags(i),
            idle      => core_idle_flags(i),
            rounds    => rounds
         );
    end generate;

    -- Current State Logic
    process(clk, next_state)
    begin
        if (rising_edge(clk)) then
            current_state <= next_state;
        end if;
    end process;

    -- Next State Logic
    process(current_state, passwd_valid)
    begin
        if (rising_edge(clk)) then
            case current_state is
                when IDLE =>
                    next_state <= IDLE;
                    for i in 0 to N-1 loop
                        if (core_done_flags(i) = '1') then
                            next_state <= CORE_DONE;
                        end if;
                    end loop;
                when others =>
            end case;
        end if;
    end process;

    -- Clock sensitive logic
    process(clk, current_state, core_done_flags, core_hash_ar)
    begin
        if (rising_edge(clk)) then
            case current_state is
                when IDLE =>
                when PASSWD_RECV =>
                when CORE_DONE =>
            end case;
        end if;
    end process;

    -- Clock insensitive logic
    process(core_done_flags, core_hash_ar, target_hash)
    begin
        for i in 0 to N-1 loop
            if (core_done_flags(i) = '1') then
                if (core_hash_ar(i) = target_hash) then
                    passwd_out <= core_passwd_ar(i);
                    passwd_found <= '1';
                end if;
            end if;
        end loop;
    end process;
end Behavioral;
