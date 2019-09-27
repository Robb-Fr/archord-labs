library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shift_unit is
  port(
    a  : in  std_logic_vector(31 downto 0);
    b  : in  std_logic_vector(4 downto 0);
    op : in  std_logic_vector(2 downto 0);
    r  : out std_logic_vector(31 downto 0)
    );
end shift_unit;

architecture synth of shift_unit IS
  SIGNAL res : std_logic_vector(31 DOWNTO 0);
BEGIN
  
  shift : process(a, b, op)
    VARIABLE v : std_logic_vector(31 DOWNTO 0);
  BEGIN
    v := a;
    CASE op IS
      WHEN "000" =>
        FOR i IN 0 TO 4 LOOP
          IF (b(i) = '1') THEN
            v := v(31 - (2 ** i) DOWNTO 0) & v(31 DOWNTO 32 - (2 ** i));
          END if;
        END loop;
      WHEN "001" =>
        FOR i IN 0 TO 4 LOOP
          IF (b(i) = '1') THEN
            v := v((2 ** i) - 1 DOWNTO 0) & v(31 DOWNTO (2 ** i));
          END if;
        END loop;
      WHEN "010" =>
        FOR i IN 0 TO 4 LOOP
          IF (b(i) = '1') THEN
            v := v(31 - (2 ** i) DOWNTO 0) & ((2 ** i) - 1 DOWNTO 0 => '0');
          END if;
        END loop;
      WHEN "011" =>
        FOR i IN 0 TO 4 LOOP
          IF (b(i) = '1') THEN
            v := ((2 ** i) - 1 DOWNTO 0 => '0') & v(31 DOWNTO (2 ** i));
          END if;
        END loop;
      WHEN "111" =>
        FOR i IN 0 TO 4 LOOP
          IF (b(i) = '1') AND (a(31) = '0') THEN
            v := ((2 ** i) - 1 DOWNTO 0 => '0') & v(31 DOWNTO (2 ** i));
          ELSIF (b(i) = '1') AND (a(31) = '1') THEN
            v := ((2 ** i) - 1 DOWNTO 0 => '1') & v(31 DOWNTO (2 ** i));
          END if;
        END loop;
      WHEN OTHERS =>
        res <= a;                       --shift ignored
    END case;
    res <= v;
  END process;
  r <= res;
end synth;
