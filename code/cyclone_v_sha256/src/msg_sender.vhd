library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.plusbus_pkg.ALL;

entity msg_sender is
    port(
        -- Inputs
        clk : in std_logic;
        rising_trig : in std_logic;
        falling_trig : in std_logic;
        passwd : in std_logic_vector(0 to 439);
        reset : in std_logic;

        -- flags
        passwd_valid : in std_logic;
        ready_for_passwd : in std_logic;
        tx_success : in std_logic;

        -- Outputs
        data_tx : out std_logic_vector(7 downto 0)
        );
end msg_sender;

architecture Behavioral of msg_sender is
    type msg_sender_state_t is (IDLE, RST, START, DATA, STOP);
    signal current_state : msg_sender_state_t := IDLE;
    signal next_state : msg_sender_state_t := IDLE;

    signal passwd_valid_latch : std_logic := '0';
    signal passwd_buf : std_logic_vector(0 to 439) := (others => '0');
    signal idx : integer range 0 to 440 := 0;

    signal flags : std_logic_vector(7 downto 0);
begin
    -- Next state logic
    process(current_state, passwd_valid_latch, passwd_buf, idx, tx_success, reset)
    begin
        case current_state is
            when IDLE =>
                if (passwd_valid_latch = '1') then
                    next_state <= START;
                else
                    next_state <= IDLE;
                end if;
            when RST =>
                next_state <= IDLE;
            when START =>
                if (tx_success = '1') then
                    next_state <= DATA;
                else
                    next_state <= START;
                end if;
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
        if (reset = '1') then
            next_state <= RST;
        end if;
    end process;

    -- Combinatorial and current state logic
    flags <= "10" & ready_for_passwd & "00000";
    process(clk, rising_trig, current_state, next_state, passwd_buf, passwd, idx, tx_success, flags)
    begin
        if (rising_edge(clk)) then
            -- Latch passwd_valid high for next com_clk cycle
            if (current_state = RST) then
                passwd_valid_latch <= '0';
            elsif (passwd_valid = '1') then
                passwd_valid_latch <= '1';
            end if;

            -- com_clk rising edge
            if (rising_trig = '1') then
                -- Current state logic
                current_state <= next_state;

                case current_state is
                    when START =>
                        passwd_buf <= passwd(0 to 439);
                        idx <= 0;
                    when DATA =>
                        if (tx_success = '1') then
                            idx <= idx + 8;
                        end if;
                    when STOP =>
                        passwd_valid_latch <= '0';
                        idx <= 0;
                    when others =>
                        idx <= 0;
                end case;
            end if;
        end if;
    end process;

    -- Moore outputs
    process(current_state, passwd_buf, idx, flags)
    begin
        case current_state is
            when IDLE =>
                data_tx <= flags;
            when START =>
                data_tx <= PLUSBUS_STX;
            when DATA =>
                data_tx <= passwd_buf(idx to idx+7);
            when STOP =>
                data_tx <= PLUSBUS_ETX;
            when RST =>
                data_tx <= x"55";
        end case;
   end process;
end Behavioral;
