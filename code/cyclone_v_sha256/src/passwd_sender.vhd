library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.plusbus_pkg.ALL;

entity passwd_sender is
    port(
        -- Inputs
        clk : in std_logic;
        com_clk  : in std_logic;
        passwd : in std_logic_vector(0 to 511);

        -- flags
        passwd_valid : in std_logic;
        ready_for_passwd : in std_logic;
        tx_success : in std_logic;

        -- Outputs
        data_tx : out std_logic_vector(7 downto 0)
        );
end passwd_sender;

architecture Behavioral of passwd_sender is
    type passwd_sender_state_t is (IDLE, START, DATA, STOP);
    signal current_state : passwd_sender_state_t := IDLE;
    signal next_state : passwd_sender_state_t := IDLE;

    signal passwd_buf : std_logic_vector(0 to 439) := (others => '0');
    signal idx : integer range 0 to 440 := 0;

    signal flags : std_logic_vector(7 downto 0);

    -- Clock synchronization
    signal r1_com_clk : std_logic;
    signal r2_com_clk : std_logic;
    signal r3_com_clk : std_logic;
begin
    -- Next state logic
    process(current_state, passwd_valid, passwd_buf, passwd, idx)
    begin
        case current_state is
            when IDLE =>
                if (passwd_valid = '1' and passwd_buf /= passwd) then
                    next_state <= START;
                end if;
            when START =>
                    next_state <= DATA;
            when DATA =>
                if (idx = 432) then
                    next_state <= STOP;
                else 
                    if (passwd_buf(idx+8 to idx+15) = x"80") then
                        next_state <= STOP;
                    else
                        next_state <= DATA;
                    end if;
                end if;
            when STOP =>
                next_state <= IDLE;
        end case;
    end process;

    -- Combinatorial and next state logic
    flags <= "10" & ready_for_passwd & "00000";
    process(clk, com_clk, current_state, next_state, passwd_buf, passwd, idx, tx_success, flags)
    begin
        if (rising_edge(clk)) then
            r1_com_clk <= com_clk;
            r2_com_clk <= r1_com_clk;
            r3_com_clk <= r2_com_clk;

            -- com_clk rising edge
            if r3_com_clk = '0' and r2_com_clk = '1' then
                current_state <= next_state;

                case current_state is
                    when IDLE =>
                        data_tx <= flags;
                    when START =>
                        passwd_buf <= passwd(0 to 439);
                        data_tx <= PLUSBUS_STX;
                        idx <= 0;
                    when DATA =>
                        if (tx_success = '1') then
                            idx <= idx + 8;
                        end if;
                        data_tx <= passwd_buf(idx to idx+7);
                    when STOP =>
                        data_tx <= PLUSBUS_ETX;
                        idx <= 0;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
