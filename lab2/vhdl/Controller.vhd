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

	component FSM
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
	end component FSM;

	signal length_dec, length_load, length_is_zero, rddata_low_is_zero, ROMaddr_inc                 : std_logic;
	signal wraddr_inc, wraddr_load, rdaddr_inc, rdaddr_load, sel_ROMaddr, sel_wraddr, sel_rdaddr    : std_logic;
	signal length, ROMaddr, wraddr, rdaddr, length_inter, wraddr_inter, rdaddr_inter, ROMaddr_inter : std_logic_vector(15 downto 0);

begin
	Pigalle : component FSM
		port map(
			clk                => clk,
			reset_n            => reset_n,
			length_is_zero     => length_is_zero,
			rddata_low_is_zero => rddata_low_is_zero,
			read               => read,
			write              => write,
			sel_ROMaddr        => sel_ROMaddr,
			sel_rdaddr         => sel_rdaddr,
			sel_wraddr         => sel_wraddr,
			ROMaddr_inc        => ROMaddr_inc,
			rdaddr_load        => rdaddr_load,
			rdaddr_inc         => rdaddr_inc,
			wraddr_load        => wraddr_load,
			wraddr_inc         => wraddr_inc,
			length_load        => length_load,
			length_dec         => length_dec
		);
	-- verifies that length is not zero 
	length_is_zero     <= '1' when length = X"0000" else '0';
	rddata_low_is_zero <= '1' when rddata(15 downto 0) = X"0000" else '0';
	wrdata             <= rddata;

	compute : process is
	begin
		-- Computes the next length 
		length_inter <= length;
		if length_dec = '1' then
			length_inter <= std_logic_vector(unsigned(length) - 1);
		elsif length_load = '1' then
			length_inter <= rddata(15 downto 0);
		end if;

		-- Computes the next write address
		wraddr_inter <= wraddr;
		if wraddr_inc = '1' then
			wraddr_inter <= std_logic_vector(unsigned(wraddr) + 4);
		elsif wraddr_load = '1' then
			wraddr_inter <= rddata(15 downto 0);
		end if;

		-- Computes the next read address 
		rdaddr_inter <= rdaddr;
		if rdaddr_inc = '1' then
			rdaddr_inter <= std_logic_vector(unsigned(rdaddr) + 4);
		elsif rdaddr_load = '1' then
			rdaddr_inter <= rddata(31 downto 16);
		end if;

	end process compute;

	-- Manages the length output and enables its change
	length_output : process(clk, reset_n) is
	begin
		if reset_n = '1' then
			length <= X"0000";
		elsif rising_edge(clk) then
			-- enable condition
			if length_dec = '1' or length_load = '1' then
				length <= length_inter;
			end if;
		end if;
	end process length_output;

	-- Manages the write address output and enables its change
	wraddr_output : process(clk, reset_n) is
	begin
		if reset_n = '1' then
			wraddr <= X"0000";
		elsif rising_edge(clk) then
			-- enable condition
			if wraddr_inc = '1' or wraddr_load = '1' then
				wraddr <= wraddr_inter;
			end if;
		end if;
	end process wraddr_output;

	-- Manages the write address output and enables its change
	rdaddr_output : process(clk, reset_n) is
	begin
		if reset_n = '1' then
			rdaddr <= X"0000";
		elsif rising_edge(clk) then
			-- enable condition
			if rdaddr_inc = '1' or rdaddr_load = '1' then
				rdaddr <= rdaddr_inter;
			end if;
		end if;
	end process rdaddr_output;

	name : process(clk, reset_n, ROMaddr) is
	begin
		ROMaddr_inter <= std_logic_vector(unsigned(ROMaddr) + 4);
		if reset_n = '1' then
			ROMaddr <= X"0000";
		elsif rising_edge(clk) then
			-- enable condition 
			if ROMaddr_inc = '1' then
				ROMaddr <= ROMaddr_inter;
			end if;
		end if;
	end process name;

	-- Decides which address to output between Rom, write and read
	address_output : process(sel_ROMaddr, sel_wraddr, sel_rdaddr, ROMaddr, rdaddr, wraddr) is
	begin
		address <= X"0000";

		if sel_ROMaddr = '1' then
			address <= ROMaddr;

		elsif sel_wraddr = '1' then
			address <= wraddr;

		elsif sel_rdaddr = '1' then
			address <= rdaddr;
		end if;
	end process address_output;

end synth;

-- Finite State Machine which manages whether we are reading, incrementing or writing

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
	dff : process(clk, reset_n) is
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

	next_state : process(cur, length_is_zero, rddata_low_is_zero) is
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

