library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
	port(
		clk     : in  std_logic;
		reset_n : in  std_logic;
		read    : out std_logic;
		write   : out std_logic;
		address : out std_logic_vector(15 downto 0);
		rddata  : in  std_logic_vector(31 downto 0);
		wrdata  : out std_logic_vector(31 downto 0)
	);
end controller;

architecture synth of controller is
begin
end synth;

library ieee;
use ieee.std_logic_1164.all;

entity FSM is
	port(
		clk                : in  std_logic;
		reset_n            : in  std_logic;
		length_is_zero     : in  std_logic;
		rddata_low_is_zero : in  std_logic;
		read               : out std_logic;
		write              : out std_logic;
		sel_ROMaddr        : out std_logic;
		sel_rdaddr         : out std_logic;
		sel_wraddr         : out std_logic;
		ROMaddr_inc        : out std_logic;
		rdaddr_load        : out std_logic;
		rdaddr_inc         : out std_logic;
		wraddr_load        : out std_logic;
		wraddr_inc         : out std_logic;
		length_load        : out std_logic;
		length_dec         : out std_logic
	);
end FSM;

architecture boulogne of FSM is
	type state is (S0, S1, S2, S3, S4, S5);
	signal cur : state;
	signal nex : state;
begin
	dff : process (clk, reset_n) is
	begin
		if reset_n = '0' then
			read        <= '0';
			write       <= '0';
			sel_ROMaddr <= '0';
			sel_rdaddr  <= '0';
			sel_wraddr  <= '0';
			ROMaddr_inc <= '0';
			rdaddr_load <= '0';
			rdaddr_inc  <= '0';
			wraddr_load <= '0';
			wraddr_inc  <= '0';
			length_load <= '0';
			length_dec  <= '0';
			cur         <= S0;
		elsif rising_edge(clk) then
			cur <= nex;
		end if;
	end process;

	next_state : process (cur, length_is_zero, rddata_low_is_zero) is
	begin
		read        <= '0';
		write       <= '0';
		sel_ROMaddr <= '0';
		sel_rdaddr  <= '0';
		sel_wraddr  <= '0';
		ROMaddr_inc <= '0';
		rdaddr_load <= '0';
		rdaddr_inc  <= '0';
		wraddr_load <= '0';
		wraddr_inc  <= '0';
		length_load <= '0';
		length_dec  <= '0';
		case cur is
			when S0 =>
				read        <= '1';
				sel_ROMaddr <= '1';
				ROMaddr_inc <= '1';
				nex         <= S1;
			when S1 =>
				if rddata_low_is_zero = '1' then
					nex <= S5;
				elsif rddata_low_is_zero = '0' then
					read        <= '1';
					sel_ROMaddr <= '1';
					ROMaddr_inc <= '1';
					length_load <= '1';
					nex         <= S2;
				end if;
			when S2 =>
				rdaddr_load <= '1';
				wraddr_load <= '1';
				nex         <= S3;
			when S3 =>
				if length_is_zero = '0' then
					read       <= '1';
					sel_rdaddr <= '1';
					rdaddr_inc <= '1';
					length_dec <= '1';
					nex        <= S4;
				elsif length_is_zero = '0' then
					nex <= S0;
				end if;
			when S4 =>
				write      <= '1';
				sel_wraddr <= '1';
				wraddr_inc <= '1';
				nex        <= S3;
			when S5 =>
				nex <= S5;
		end case;
	end process;
end boulogne;

