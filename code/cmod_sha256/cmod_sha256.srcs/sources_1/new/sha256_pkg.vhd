----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.09.2023 10:55:23
-- Design Name: 
-- Module Name: sha256_pkg - Behavioral
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
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
package sha256_pkg is
    type kw_type is array(0 to 63) of std_logic_vector(31 downto 0);
    type passwd_type is array(0 to 15) of std_logic_vector(31 downto 0);
    
    function SIGMA_EXTEND_0(x : std_logic_vector(31 downto 0)) return std_logic_vector;
    function SIGMA_EXTEND_1(x : std_logic_vector(31 downto 0)) return std_logic_vector;
    
    --function definitions
    function ROTR (a : std_logic_vector(31 downto 0); n : natural) return std_logic_vector;
    function ROTL (a : std_logic_vector(31 downto 0); n : natural) return std_logic_vector;
    function SHR (a : std_logic_vector(31 downto 0); n : natural) return std_logic_vector;
    
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
end package body;