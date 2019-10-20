library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC is
	port(
		clk     : in  std_logic;
		reset_n : in  std_logic;
		en      : in  std_logic;
		sel_a   : in  std_logic;
		sel_imm : in  std_logic;
		add_imm : in  std_logic;
		imm     : in  std_logic_vector(15 downto 0);
		a       : in  std_logic_vector(15 downto 0);
		addr    : out std_logic_vector(31 downto 0)
	);
end PC;

architecture synth of PC is
	signal cur, nxt : std_logic_vector(31 downto 0);
begin
	addr <= cur(31 downto 2) & "00";

	dff : process(clk, reset_n) is
	begin
		if reset_n = '0' then
			cur <= (others => '0');
		elsif rising_edge(clk) then
			if en = '1' then
				cur <= nxt;
			end if;
		end if;
	end process;

	next_state : process(cur, a, add_imm, imm, sel_a, sel_imm) is
	begin
		if add_imm = '1' and sel_a = '0' and sel_imm = '0' then
			nxt <= std_logic_vector((signed(cur) + signed(imm)));
		elsif add_imm = '0' and sel_a = '0' and sel_imm = '1' then
			nxt <= std_logic_vector(X"000" & "00" & (imm(15 downto 0) & "00"));
		elsif add_imm = '0' and sel_a = '1' and sel_imm = '0' then
			nxt <= std_logic_vector(X"0000" & (a(15 downto 0)));
		else
			nxt <= std_logic_vector((unsigned(cur) + 4));
		end if;
	end process;

end synth;
