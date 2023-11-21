library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.sha256_pkg.ALL;

entity core_controller is
    generic( N : in integer := 1); -- number of cores
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
    type core_controller_type_t is (CORE_SERVICE, PASSWD_RECV);
    signal current_state : core_controller_type_t := CORE_SERVICE;
    signal next_state : core_controller_type_t := CORE_SERVICE;

    signal ready_for_new_passwd_sig : std_logic := '1';

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

    signal passwd_buf : std_logic_vector(0 to 511) := (others => '0');
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
    process(current_state, passwd_valid, core_done_flags)
    begin
        case current_state is
            when CORE_SERVICE =>
                next_state <= CORE_SERVICE; -- default

                if (passwd_valid = '1') then
                    next_state <= PASSWD_RECV;
                end if;

            when PASSWD_RECV =>
                -- Always continue to CORE_SERVICE state
                next_state <= CORE_SERVICE;

        end case;
    end process;

    -- Real logic
    process(clk, current_state, core_done_flags, core_hash_ar, ready_for_new_passwd_sig, core_idle_flags, passwd_buf, passwd)
    begin
        if (rising_edge(clk)) then

            -- Check for done cores
            passwd_found <= '0';
            core_reset_flags <= (others => '0');
            core_start_flags <= (others => '0');
            for i in 0 to N-1 loop
                if (core_done_flags(i) = '1') then
                    core_reset_flags(i) <= '1';
                    if (core_hash_ar(i) = target_hash) then
                        passwd_out <= core_passwd_ar(i);
                        passwd_found <= '1';
                    end if;
                end if;
            end loop;

            case current_state is
                when CORE_SERVICE =>
                    if (ready_for_new_passwd_sig = '0') then
                        for i in 0 to N-1 loop
                            if (core_idle_flags(i) = '1') then
                                core_passwd_ar(i) <= passwd_buf;
                                core_start_flags(i) <= '1';
                                ready_for_new_passwd_sig <= '1';
                                exit;
                            end if;
                        end loop;
                    end if;
                when PASSWD_RECV =>
                    if (ready_for_new_passwd_sig = '1' and passwd_buf /= passwd) then
                        passwd_buf <= passwd;
                        ready_for_new_passwd_sig <= '0';
                    end if;
            end case;
        end if;
    end process;

    ready_for_new_passwd <= ready_for_new_passwd_sig;
end Behavioral;
