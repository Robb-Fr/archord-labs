library ieee;
use ieee.std_logic_1164.all;

entity decoder is
	port(
		address    : in  std_logic_vector(15 downto 0);
		cs_LEDS    : out std_logic;
		cs_RAM     : out std_logic;
		cs_ROM     : out std_logic;
		cs_buttons : OUT std_logic
	);
end decoder;
architecture synth of decoder is
begin

	check : process(address)
	begin
		cs_LEDS    <= '0';
		cs_ROM     <= '0';
		cs_RAM     <= '0';
		cs_buttons <= '0';

		if address <= X"0FFC" then
			cs_ROM <= '1';
		elsif address >= X"1000" and address <= X"1FFC" then
			cs_RAM <= '1';
		elsif address >= X"2000" and address <= X"200C" then
			cs_LEDS <= '1';
		elsif address >= X"2030" and address <= X"2034" then
			cs_buttons <= '1';
		end if;
	end process;

end synth;
