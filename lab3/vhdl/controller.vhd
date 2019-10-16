library ieee;
use ieee.std_logic_1164.all;

entity controller is
	port(
		clk        : in  std_logic;
		reset_n    : in  std_logic;
		-- instruction opcode
		op         : in  std_logic_vector(5 downto 0);
		opx        : in  std_logic_vector(5 downto 0);
		-- activates branch condition
		branch_op  : out std_logic;
		-- immediate value sign extention
		imm_signed : out std_logic;
		-- instruction register enable
		ir_en      : out std_logic;
		-- PC control signals
		pc_add_imm : out std_logic;
		pc_en      : out std_logic;
		pc_sel_a   : out std_logic;
		pc_sel_imm : out std_logic;
		-- register file enable
		rf_wren    : out std_logic;
		-- multiplexers selections
		sel_addr   : out std_logic;
		sel_b      : out std_logic;
		sel_mem    : out std_logic;
		sel_pc     : out std_logic;
		sel_ra     : out std_logic;
		sel_rC     : out std_logic;
		-- write memory output
		read       : out std_logic;
		write      : out std_logic;
		-- alu op
		op_alu     : out std_logic_vector(5 downto 0)
	);
end controller;

architecture synth of controller is
	-- state of the controller fsm
	type state is (FETCH1, FETCH2, DECODE, R_OP, R_OP_IMM, STORE, BREAK, LOAD1, LOAD2, I_OP_S, I_OP_U, BRANCH, CALL, CALLR, JUMP, JUMPI);
	signal currState, nextState : state;

	constant alu_add  : std_logic_vector(5 downto 0) := "000000";
	constant alu_sub  : std_logic_vector(5 downto 0) := "001000";
	constant alu_leqs : std_logic_vector(5 downto 0) := "011001";
	constant alu_mos  : std_logic_vector(5 downto 0) := "011010";
	constant alu_diff : std_logic_vector(5 downto 0) := "011011";
	constant alu_eq   : std_logic_vector(5 downto 0) := "011100";
	constant alu_lequ : std_logic_vector(5 downto 0) := "011101";
	constant alu_mou  : std_logic_vector(5 downto 0) := "011110";
	constant alu_nor  : std_logic_vector(5 downto 0) := "100000";
	constant alu_and  : std_logic_vector(5 downto 0) := "100001";
	constant alu_or   : std_logic_vector(5 downto 0) := "100010";
	constant alu_xnor : std_logic_vector(5 downto 0) := "100011";
	constant alu_rol  : std_logic_vector(5 downto 0) := "110000";
	constant alu_ror  : std_logic_vector(5 downto 0) := "110001";
	constant alu_sll  : std_logic_vector(5 downto 0) := "110010";
	constant alu_srl  : std_logic_vector(5 downto 0) := "110011";
	constant alu_sra  : std_logic_vector(5 downto 0) := "110111";

	signal bit8op  : std_logic_vector(7 downto 0);
	signal bit8opx : std_logic_vector(7 downto 0);
begin

	bit8op  <= "00" & op;
	bit8opx <= "00" & opx;

	op_alu <= alu_add when bit8op = X"04" or bit8op = X"17" or bit8op = X"15" or bit8opx = X"31"
	          else alu_sub when bit8opx = X"39"
	          else alu_leqs when bit8op = X"08" or bit8op = X"0E" or bit8opx = X"08"
	          else alu_mos when bit8op = X"10" or bit8op = X"16" or bit8opx = X"10"
	          else alu_diff when bit8op = X"18" or bit8op = X"1E" or bit8opx = "18"
	          else alu_eq when bit8op = X"20" or bit8op = X"06" or bit8op = X"26" or bit8opx = X"20"
	          else alu_lequ when bit8op = X"28" or bit8op = X"2E" or bit8opx = X"28"
	          else alu_mou when bit8op = X"30" or bit8op = X"36" or bit8opx = X"30"
	          else alu_nor when bit8opx = X"06"
	          else alu_and when bit8op = X"0C" or bit8opx = X"0E"
	          else alu_or when bit8op = X"14" or bit8opx = X"16"
	          else alu_xnor when bit8op = X"1C" or bit8opx = X"1E"
	          else alu_rol when bit8opx = X"02" or bit8opx = X"03"
	          else alu_ror when bit8opx = X"0B"
	          else alu_sll when bit8opx = X"12" or bit8opx = X"13"
	          else alu_srl when bit8opx = X"1A" or bit8opx = X"1B"
	          else alu_sra when bit8opx = X"3A" or bit8opx = X"3B"
	          else alu_add;

	-- process that outputs the correct control signals depending on the state
	compute_control_signals : process(currState) is
	begin
		branch_op  <= '0';
		imm_signed <= '0';
		ir_en      <= '0';
		pc_add_imm <= '0';
		pc_en      <= '0';
		pc_sel_a   <= '0';
		pc_sel_imm <= '0';
		rf_wren    <= '0';
		sel_addr   <= '0';
		sel_b      <= '0';
		sel_mem    <= '0';
		sel_pc     <= '0';
		sel_ra     <= '0';
		sel_rC     <= '0';
		read       <= '0';
		write      <= '0';

		case currState is
			when FETCH1 =>
				read <= '1';
			when FETCH2 =>
				pc_en <= '1';
				ir_en <= '1';
			when DECODE => null;
			when R_OP =>
				sel_b   <= '1';
				sel_rC  <= '1';
				rf_wren <= '1';
			when R_OP_IMM =>
				sel_rC  <= '1';
				rf_wren <= '1';
			when STORE =>
				write      <= '1';
				imm_signed <= '1';
				sel_addr   <= '1';
			when BREAK =>
				sel_rC <= '1';
			when LOAD1 =>
				read       <= '1';
				sel_addr   <= '1';
				imm_signed <= '1';
			when LOAD2 =>
				sel_mem <= '1';
				rf_wren <= '1';
			when I_OP_S =>
				imm_signed <= '1';
				rf_wren    <= '1';
			when I_OP_U =>
				rf_wren <= '1';
			when BRANCH =>
				branch_op  <= '1';
				pc_add_imm <= '1';
				sel_b      <= '1';
			when CALL =>
				rf_wren    <= '1';
				sel_pc     <= '1';
				sel_ra     <= '1';
				pc_en      <= '1';
				pc_sel_imm <= '1';
			when CALLR =>
				rf_wren  <= '1';
				sel_pc   <= '1';
				sel_ra   <= '1';
				pc_en    <= '1';
				pc_sel_a <= '1';
			when JUMP =>
				pc_en    <= '1';
				pc_sel_a <= '1';
			when JUMPI =>
				pc_en      <= '1';
				pc_sel_imm <= '1';
		end case;

	end process compute_control_signals;

	-- computes the next state and decodes the op and opx for adequate choice
	compute_next_state : process(currState, bit8op, bit8opx) is
	begin
		case currState is
			when FETCH1 =>
				nextState <= FETCH2;
			when FETCH2 =>
				nextState <= DECODE;
			when DECODE =>
				if bit8op = X"3A" and (bit8opx = X"31" or bit8opx = X"39" or bit8opx = X"08" or bit8opx = X"10" or bit8opx = X"06" or bit8opx = X"0E" or bit8opx = X"16" or bit8opx = X"1E" or bit8opx = X"13" or bit8opx = X"1B" or bit8opx = X"3B" or bit8opx = X"18" or bit8opx = X"20" or bit8opx = X"28" or bit8opx = X"30" or bit8opx = X"03" or bit8opx = X"0B") then
					nextState <= R_OP;
				elsif bit8op = X"3A" and (bit8opx = X"12" or bit8opx = X"1A" or bit8opx = X"3A" or bit8opx = X"02") then
					nextState <= R_OP_IMM;
				elsif bit8op = X"3A" and bit8opx = X"34" then
					nextState <= BREAK;
				elsif bit8op = X"04" or bit8op = X"08" or bit8op = X"10" or bit8op = X"18" or bit8op = X"20" then
					nextState <= I_OP_S;
				elsif bit8op = X"0C" or bit8op = X"14" or bit8op = X"1C" or bit8op = X"28" or bit8op = X"30" then
					nextState <= I_OP_U;
				elsif bit8op = X"17" then
					nextState <= LOAD1;
				elsif bit8op = X"15" then
					nextState <= STORE;
				elsif bit8op = X"06" or bit8op = X"0E" or bit8op = X"16" or bit8op = X"1E" or bit8op = X"26" or bit8op = X"2E" or bit8op = X"36" then
					nextState <= BRANCH;
				elsif (bit8op = X"00") then
					nextState <= CALL;
				elsif (bit8op = X"3A" and bit8opx = X"1D") then
					nextState <= CALLR;
				elsif bit8op = X"3A" and (bit8opx = X"05" or bit8opx = X"0D") then
					nextState <= JUMP;
				elsif bit8op = X"01" then
					nextState <= JUMPI;
				end if;
			when R_OP =>
				nextState <= FETCH1;
			when STORE =>
				nextState <= FETCH1;
			when BREAK =>
				nextState <= BREAK;
			when LOAD1 =>
				nextState <= LOAD2;
			when LOAD2 =>
				nextState <= FETCH1;
			when I_OP_S =>
				nextState <= FETCH1;
			when I_OP_U =>
				nextState <= FETCH1;
			when BRANCH =>
				nextState <= FETCH1;
			when CALL =>
				nextState <= FETCH1;
			when JUMP =>
				nextState <= FETCH1;
			when CALLR =>
				nextState <= FETCH1;
			when JUMPI =>
				nextState <= FETCH1;
			when R_OP_IMM =>
				nextState <= FETCH1;
		end case;
	end process compute_next_state;

	state_DFF : process(clk, reset_n) is
	begin
		if reset_n = '0' then
			currState <= FETCH1;
		elsif rising_edge(clk) then
			currState <= nextState;
		end if;
	end process state_DFF;

end synth;
