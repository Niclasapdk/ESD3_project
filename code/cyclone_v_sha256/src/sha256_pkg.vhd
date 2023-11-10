library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package sha256_pkg is
    type kw_type is array(0 to 63) of std_logic_vector(31 downto 0);
    type passwd_type is array(0 to 15) of std_logic_vector(31 downto 0);
    type saved_vars_type is array(0 to 1) of std_logic_vector(31 downto 0);

    function SIGMA_EXTEND_0(x : std_logic_vector(31 downto 0)) return std_logic_vector;
    function SIGMA_EXTEND_1(x : std_logic_vector(31 downto 0)) return std_logic_vector;

    --function definitions
    function ROTR (a : std_logic_vector(31 downto 0); n : natural) return std_logic_vector;
    function ROTL (a : std_logic_vector(31 downto 0); n : natural) return std_logic_vector;
    function SHR (a : std_logic_vector(31 downto 0); n : natural) return std_logic_vector;

    function SIGMA_COMPRESS_0(x : std_logic_vector(31 downto 0)) return std_logic_vector;
    function SIGMA_COMPRESS_1(x : std_logic_vector(31 downto 0)) return std_logic_vector;

    -- pad hash digest (for multi-round hashing)
    function pad_hash_digest(hash : std_logic_vector(255 downto 0)) return std_logic_vector;
end package;

package body sha256_pkg is

    function ROTR (a : std_logic_vector(31 downto 0); n : natural) return std_logic_vector is
    begin
        return (std_logic_vector(shift_right(unsigned(a), n))) or std_logic_vector((shift_left(unsigned(a), (32-n))));
    end function;

    function ROTL (a : std_logic_vector(31 downto 0); n : natural) return std_logic_vector is
    begin
        return (std_logic_vector(shift_left(unsigned(a), n))) or std_logic_vector((shift_right(unsigned(a), (32-n))));
    end function;

    function SHR (a : std_logic_vector(31 downto 0); n : natural) return std_logic_vector is
    begin
        return std_logic_vector(shift_right(unsigned(a), n));
    end function;

    function SIGMA_EXTEND_0(x : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return ROTR(x,7) xor ROTR(x,18) xor SHR(x,3);
    end function;

    function SIGMA_EXTEND_1(x : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return ROTR(x,17) xor ROTR(x,19) xor SHR(x,10);
    end function;

    function SIGMA_COMPRESS_0(x : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return ROTR(x,2) xor ROTR(x,13) xor ROTR(x,22);
    end function;

    function SIGMA_COMPRESS_1(x : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return ROTR(x,6) xor ROTR(x,11) xor ROTR(x,25);
    end function;

    function pad_hash_digest(hash : std_logic_vector(255 downto 0)) return std_logic_vector is
    begin
        return hash & x"80" & x"0000000000000000000000000000000000000000000000" & x"0000000000000100";
    end function;
end package body;
