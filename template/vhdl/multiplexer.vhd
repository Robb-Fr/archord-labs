library ieee;
use ieee.std_logic_1164.all;

entity multiplexer is
    port(
        i0  : in  std_logic_vector(31 downto 0);
        i1  : in  std_logic_vector(31 downto 0);
        i2  : in  std_logic_vector(31 downto 0);
        i3  : in  std_logic_vector(31 downto 0);
        sel : in  std_logic_vector(1 downto 0);
        o   : out std_logic_vector(31 downto 0)
    );
end multiplexer;

architecture synth of multiplexer is
BEGIN
  o <= i0 WHEN sel = "00" ELSE
       i1 WHEN sel = "01" ELSE
       i2 WHEN sel = "10" ELSE
       i3 WHEN sel = "11" ELSE
       i0;
end synth;
