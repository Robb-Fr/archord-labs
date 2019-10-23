library ieee;
use ieee.std_logic_1164.all;

entity ROM is
	port(
		clk     : in  std_logic;
		cs      : in  std_logic;
		read    : in  std_logic;
		address : in  std_logic_vector(9 downto 0);
		rddata  : out std_logic_vector(31 downto 0)
	);
end ROM;

architecture synth of ROM is
	component ROM_Block
		port(
			address : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
			clock   : IN  STD_LOGIC;
			q       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
		);
	end component ROM_Block;
	signal cs_FF       : std_logic;
	signal rd_selected : std_logic_vector(31 downto 0);

begin
	rddata <= rd_selected when cs_FF = '1' else (others => 'Z');

	cs_val : process(clk) is
	begin
		if rising_edge(clk) then
			cs_FF <= read and cs;
		end if;
	end process;

	mem_block : ROM_Block
		port map(
			address => address, --Warning : it was address_FF
			clock   => clk,
			q       => rd_selected
		);
end synth;
