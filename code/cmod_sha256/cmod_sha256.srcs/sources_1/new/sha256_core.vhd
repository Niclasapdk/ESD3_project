----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 22.09.2023 09:20:39
-- Design Name:
-- Module Name: sha256_core - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.sha256_pkg.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sha256_core is
    port(
        clk : in std_logic;
        start : in std_logic;
        reset : in std_logic;
        passwd_in : in std_logic_vector(511 downto 0);
        hash_out : out std_logic_vector(255 downto 0);
        hash_done: out std_logic
        );
end sha256_core;


architecture Behavioral of sha256_core is

    signal h0 : std_logic_vector(31 downto 0) := x"6a09e667";
    signal h1 : std_logic_vector(31 downto 0) := x"bb67ae85";
    signal h2 : std_logic_vector(31 downto 0) := x"3c6ef372";
    signal h3 : std_logic_vector(31 downto 0) := x"a54ff53a";
    signal h4 : std_logic_vector(31 downto 0) := x"510e527f";
    signal h5 : std_logic_vector(31 downto 0) := x"9b05688c";
    signal h6 : std_logic_vector(31 downto 0) := x"1f83d9ab";
    signal h7 : std_logic_vector(31 downto 0) := x"5be0cd19";

    signal a : std_logic_vector(31 downto 0) := x"00000000";
    signal b : std_logic_vector(31 downto 0) := x"00000000";
    signal c : std_logic_vector(31 downto 0) := x"00000000";
    signal d : std_logic_vector(31 downto 0) := x"00000000";
    signal e : std_logic_vector(31 downto 0) := x"00000000";
    signal f : std_logic_vector(31 downto 0) := x"00000000";
    signal g : std_logic_vector(31 downto 0) := x"00000000";
    signal h : std_logic_vector(31 downto 0) := x"00000000";

    constant k : kw_type := (
        X"428a2f98", X"71374491", X"b5c0fbcf", X"e9b5dba5",
        X"3956c25b", X"59f111f1", X"923f82a4", X"ab1c5ed5",
        X"d807aa98", X"12835b01", X"243185be", X"550c7dc3",
        X"72be5d74", X"80deb1fe", X"9bdc06a7", X"c19bf174",
        X"e49b69c1", X"efbe4786", X"0fc19dc6", X"240ca1cc",
        X"2de92c6f", X"4a7484aa", X"5cb0a9dc", X"76f988da",
        X"983e5152", X"a831c66d", X"b00327c8", X"bf597fc7",
        X"c6e00bf3", X"d5a79147", X"06ca6351", X"14292967",
        X"27b70a85", X"2e1b2138", X"4d2c6dfc", X"53380d13",
        X"650a7354", X"766a0abb", X"81c2c92e", X"92722c85",
        X"a2bfe8a1", X"a81a664b", X"c24b8b70", X"c76c51a3",
        X"d192e819", X"d6990624", X"f40e3585", X"106aa070",
        X"19a4c116", X"1e376c08", X"2748774c", X"34b0bcb5",
        X"391c0cb3", X"4ed8aa4a", X"5b9cca4f", X"682e6ff3",
        X"748f82ee", X"78a5636f", X"84c87814", X"8cc70208",
        X"90befffa", X"a4506ceb", X"bef9a3f7", X"c67178f2"
    );
    signal w : kw_type := (
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000"
    );
    signal w_buf : kw_type := (
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000"
    );
    
    type sha256_core_state_type is (IDLE, RST, READ_MSG, PREP_MSG_0, PREP_MSG_1, PREP_MSG_2, PREP_MSG_3, HASH_1, HASH_2a, HASH_2b, HASH_2c, HASH_3, DONE);
    signal current_state : sha256_core_state_type := IDLE;
    signal next_state : sha256_core_state_type := IDLE;

    signal passwd : passwd_type := (x"00000000",x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000");
    signal passwd_internal : passwd_type := (x"00000000",x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000");

    signal compression_counter : unsigned(6 downto 0) := "0000000";

begin
    -- Current state logic.
    process(clk)
    begin
        if (clk'event and clk = '1') then
            current_state <= next_state;
        end if;
    end process;
    -- Next state logic.
    process(current_state, compression_counter, start, reset)
    begin
        case current_state is
            when IDLE =>
                if (reset = '1') then
                    next_state <= RST;
                elsif (start = '1') then
                    next_state <= READ_MSG;
                else
                    next_state <= IDLE;
                end if;
            when RST =>
                next_state <= IDLE;
            when READ_MSG =>
                next_state <= PREP_MSG_0;
            when PREP_MSG_0 =>
                next_state <= PREP_MSG_1;
            when PREP_MSG_1 =>
                next_state <= PREP_MSG_2;
            when PREP_MSG_2 =>
                next_state <= PREP_MSG_3;
            when PREP_MSG_3 =>
                next_state <= HASH_1;
            when HASH_1 =>
                next_state <= HASH_2a;
            when HASH_2a =>
                if(compression_counter = 64) then
                    next_state <= HASH_3;
                else
                    next_state <= HASH_2b;
                end if;
            when HASH_2b =>
                next_state <= HASH_2c;
            when HASH_2c =>
                next_state <= HASH_2a;
            when HASH_3 =>
                next_state <= DONE;
            when DONE =>
                next_state <= DONE;
            when others =>
        end case;
    end process;

    -- Hash logic.
    process(clk, current_state)
        variable temp1, temp2 : std_logic_vector(31 downto 0);
    begin
        if (clk'event and clk = '1') then
            a <= a; b <= b; c <= c; d <= d; e <= e; f <= f; g <= g; h <= h;
            temp1 := temp1; temp2 := temp2; w <= w;
            passwd <= passwd; compression_counter <= compression_counter;
            case current_state is
                when IDLE =>
                when RST =>
                    h0 <= x"6a09e667";
                    h1 <= x"bb67ae85";
                    h2 <= x"3c6ef372";
                    h3 <= x"a54ff53a";
                    h4 <= x"510e527f";
                    h5 <= x"9b05688c";
                    h6 <= x"1f83d9ab";
                    h7 <= x"5be0cd19";
                    compression_counter <= "0000000";
                when READ_MSG =>
                    passwd <= passwd_internal;
                when PREP_MSG_0 =>
                    w(0 to 15) <= w_buf(0 to 15);
                when PREP_MSG_1 =>
                    w(16 to 31) <= w_buf(16 to 31);
                when PREP_MSG_2 =>
                    w(32 to 47) <= w_buf(32 to 47);
                when PREP_MSG_3 =>
                    w(48 to 63) <= w_buf(48 to 63);
                when HASH_1 =>
                    a <= h0;
                    b <= h1;
                    c <= h2;
                    d <= h3;
                    e <= h4;
                    f <= h5;
                    g <= h6;
                    h <= h7;
                when HASH_2a =>
                    if (compression_counter = 64) then
                        compression_counter <= "0000000";
                    else
                        temp1 := std_logic_vector(unsigned(h) + unsigned(SIGMA_COMPRESS_1(e)) + unsigned((e and f) xor ((not e) and g)) + unsigned(k(to_integer(compression_counter))) + unsigned(w(to_integer(compression_counter))));
                        temp2 := std_logic_vector(unsigned(SIGMA_COMPRESS_0(a)) + unsigned((a and b) xor (a and c) xor (b and c)));
                    end if;
                when HASH_2b =>
                    h <= g;
                    g <= f;
                    f <= e;
                    e <= std_logic_vector(unsigned(d) + unsigned(temp1));
                    d <= c;
                    c <= b;
                    b <= a;
                    a <= std_logic_vector(unsigned(temp1) + unsigned(temp2));
                when HASH_2c =>
                    compression_counter <= compression_counter + 1;
                when HASH_3 =>
                    h0 <= std_logic_vector(unsigned(h0) + unsigned(a));
                    h1 <= std_logic_vector(unsigned(h1) + unsigned(b));
                    h2 <= std_logic_vector(unsigned(h2) + unsigned(c));
                    h3 <= std_logic_vector(unsigned(h3) + unsigned(d));
                    h4 <= std_logic_vector(unsigned(h4) + unsigned(e));
                    h5 <= std_logic_vector(unsigned(h5) + unsigned(f));
                    h6 <= std_logic_vector(unsigned(h6) + unsigned(g));
                    h7 <= std_logic_vector(unsigned(h7) + unsigned(h));
                when DONE =>
                when others =>
            end case;
        end if;
    end process;

    READ_PASSWD:
    for i in 0 to 15 generate
        -- Read password from input to internal array.
        passwd_internal(i) <= passwd_in((i+1)*32-1 downto i*32);
    end generate;

    POPULATE_W_BUF_0:
    for i in 0 to 15 generate
        -- Read password into first 16 words into w buffer. :)
        w_buf(i) <= passwd(i);
    end generate;

    POPULATE_W_BUF_1:
    for i in 16 to 63 generate
        -- Populate the remaining part of w_buf
        w_buf(i) <= std_logic_vector(unsigned(SIGMA_EXTEND_1(w_buf(i-2))) + unsigned(w_buf(i-7)) + unsigned(SIGMA_EXTEND_0(w_buf(i-15))) + unsigned(w_buf(i-16)));
    end generate;

    hash_done <= '1' when current_state = DONE else '0';
    hash_out <= h0 & h1 & h2 & h3 & h4 & h5 & h6 & h7;

end Behavioral;
