library ieee;
use ieee.std_logic_1164.all;

entity comparator is
  port(
    a_31    : in  std_logic;
    b_31    : in  std_logic;
    diff_31 : in  std_logic;
    carry   : in  std_logic;
    zero    : in  std_logic;
    op      : in  std_logic_vector(2 downto 0);
    r       : out std_logic
    );
end comparator;

architecture synth of comparator is

begin

  r <= (a_31 and not(b_31)) OR ((a_31 xnor b_31) AND (diff_31 OR zero)) WHEN op = "001"
       ELSE (b_31 and not(a_31)) OR ((a_31 xnor b_31) AND (not(diff_31) AND not(zero))) WHEN op = "010"
       ELSE not(zero)                                                                   WHEN op = "011"
       ELSE not(carry) or zero                                                          WHEN op = "101"
       ELSE carry and not(zero)                                                         WHEN op = "110"
       ELSE zero;


end synth;
