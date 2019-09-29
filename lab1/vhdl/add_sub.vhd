library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add_sub is
  port(
    a        : in  std_logic_vector(31 downto 0);
    b        : in  std_logic_vector(31 downto 0);
    sub_mode : in  std_logic;
    carry    : out std_logic;
    zero     : out std_logic;
    r        : out std_logic_vector(31 downto 0)
    );
end add_sub;

architecture synth of add_sub IS
  SIGNAL a_nbr, b_nbr, r_nbr : unsigned(32 DOWNTO 0);
BEGIN
  a_nbr <= unsigned("0"&a);
  b_nbr <= unsigned("0"&b) WHEN sub_mode = '0' ELSE
           unsigned("0"&(b XOR std_logic_vector(to_signed(-1, 32))))+to_unsigned(1, 33);
  r_nbr <= a_nbr + b_nbr;

  carry <= '1' WHEN r_nbr(32) = '1' ELSE
           '0';

  zero <= '1' WHEN r_nbr(31 DOWNTO 0) = to_unsigned(0, 32) ELSE
          '0';

  r <= std_logic_vector(r_nbr(31 DOWNTO 0));
end synth;
