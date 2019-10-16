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
	type state is (FETCH1, FETCH2, DECODE, R_OP, STORE, BREAK, LOAD1, LOAD2, I_OP_S, I_OP_U, BRANCH, CALL, CALLR, JUMP, JUMPI);
	signal currState, nextState : state;
	-- constant for alu op codes 
	constant and_op             : std_logic_vector(5 downto 0) := "100001";
	constant srl_op             : std_logic_vector(5 downto 0) := "110011";
	constant addi_op            : std_logic_vector(5 downto 0) := "000000";
	constant leqs_op            : std_logic_vector(5 downto 0) := "011001";
	constant bigs_op            : std_logic_vector(5 downto 0) := "011010";
	constant diff_op            : std_logic_vector(5 downto 0) := "011011";
	constant eq_op              : std_logic_vector(5 downto 0) := "011100";
	constant lequ_op            : std_logic_vector(5 downto 0) := "011101";
	constant bigu_op            : std_logic_vector(5 downto 0) := "011110";

begin

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

	state_DFF : process(clk, reset_n) is
	begin
		if reset_n = '0' then
			currState <= FETCH1;
		elsif rising_edge(clk) then
			currState <= nextState;
		end if;
	end process state_DFF;

	compute_op_alu : process(op, opx) is
	begin
		if "00" & op = X"3A" and "00" & opx = X"0E" then -- and rC, rA, rB
			op_alu <= and_op;
		elsif "00" & op = X"3A" and "00" & opx = X"1B" then -- srl rC, rA, rB
			op_alu <= srl_op;
		elsif "00" & op = X"06" then    -- br label
			op_alu <= eq_op;
		elsif "00" & op = X"0E" then    -- ble rA, rB, label
			op_alu <= leqs_op;
		elsif "00" & op = X"016" then   -- bgt rA, rB, label
			op_alu <= bigs_op;
		elsif "00" & op = X"1E" then    -- bne rA, rB, label
			op_alu <= diff_op;
		elsif "00" & op = X"26" then    -- beq rA, rB, label
			op_alu <= eq_op;
		elsif "00" & op = X"2E" then    -- bleu rA, rB, label
			op_alu <= lequ_op;
		elsif "00" & op = X"36" then    -- bgtu rA, rB, label
			op_alu <= bigu_op;
		else                            -- addi rB, rA, imm
			op_alu <= addi_op;          -- default state 
		end if;

	end process compute_op_alu;

	-- computes the next state and decodes the op and opx for adequate choice
	compute_next_state : process(currState, op, opx) is
	begin
		case currState is
			when FETCH1 =>
				nextState <= FETCH2;
			when FETCH2 =>
				nextState <= DECODE;
			when DECODE =>
				if "00" & op = X"3A" and ("00" & opx = X"0E" or "00" & opx = X"1B") then
					nextState <= R_OP;
				elsif "00" & op = X"3A" and "00" & opx = X"34" then
					nextState <= BREAK;
				elsif "00" & op = X"04" then -- Detect I_OP better way
					nextState <= I_OP;
				elsif "00" & op = X"17" then
					nextState <= LOAD1;
				elsif "00" & op = X"15" then
					nextState <= STORE;
				elsif "00" & op = X"06" or "00" & op = X"0E" or "00" & op = X"16" or "00" & op = X"1E" or "00" & op = X"26" or "00" & op = X"2E" or "00" & op = X"36" then
					nextState <= BRANCH;
				elsif ("00" & op = X"00") then
					nextState <= CALL;
				elsif ("00" & op = X"3A" and "00" & opx = X"1D") then
					nextState <= CALLR;
				elsif "00" & op = X"3A" and ("00" & opx = X"05" or "00" & opx = X"0D") then
					nextState <= JUMP;
				elsif "00" & op = X"01" then
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
		end case;
	end process compute_next_state;

end synth;
