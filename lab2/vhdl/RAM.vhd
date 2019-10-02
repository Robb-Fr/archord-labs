library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
	port(
		clk     : in  std_logic;
		cs      : in  std_logic;
		read    : in  std_logic;
		write   : in  std_logic;
		address : in  std_logic_vector(9 downto 0);
		wrdata  : in  std_logic_vector(31 downto 0);
		rddata  : out std_logic_vector(31 downto 0));
end RAM;

architecture synth of RAM is
	type ram_type is array (0 to 1023) of std_logic_vector(31 downto 0);
	signal ram         : ram_type;
	signal address_FF  : std_logic_vector(9 downto 0);
	signal cs_FF       : std_logic;
	signal rd_selected : std_logic_vector(31 downto 0);
begin

	rddata <= rd_selected when cs_FF = '1' else (others => 'Z');

	address_val : process(clk) is
	begin
		if rising_edge(clk) then
			address_FF <= address;
		end if;
	end process;

	cs_val : process(clk) is
	begin
		if rising_edge(clk) then
			cs_FF <= read and cs;
		end if;
	end process;

	read_sel : process(clk, cs_FF) is
	begin
		if rising_edge(clk) and cs_FF = '1' then
			rd_selected <= ram(to_integer(unsigned(address_FF)));
		end if;
	end process;

	write_proc : process(clk, cs, write) is
	begin
		if write = '1' and cs = '1' and rising_edge(clk) then
			ram(to_integer(unsigned(address))) <= wrdata;
		end if;
	end process;

end synth;
