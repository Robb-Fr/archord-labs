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
		branch_op  : out std_logic;     --n
		-- immediate value sign extention
		imm_signed : out std_logic;
		-- instruction register enable
		ir_en      : out std_logic;
		-- PC control signals
		pc_add_imm : out std_logic;     --n
		pc_en      : out std_logic;     --n
		pc_sel_a   : out std_logic;     --n
		pc_sel_imm : out std_logic;     --n
		-- register file enable
		rf_wren    : out std_logic;
		-- multiplexers selections
		sel_addr   : out std_logic;
		sel_b      : out std_logic;
		sel_mem    : out std_logic;
		sel_pc     : out std_logic;     --n
		sel_ra     : out std_logic;     --n
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
	type state is (FETCH1, FETCH2, DECODE, R_OP, STORE, BREAK, LOAD1, LOAD2, I_OP);
	signal currState, nextState : state;
	-- constant for alu op codes 
	constant and_op             : std_logic_vector(5 downto 0) := "100001";
	constant srl_op             : std_logic_vector(5 downto 0) := "110011";
	constant add_op             : std_logic_vector(5 downto 0) := "000000";

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
				sel_b  <= '1';
				sel_rC <= '1';
			when STORE =>
				write   <= '1';
				rf_wren <= '1';
			when BREAK =>
				sel_rC <= '1';
			when LOAD1 =>
				read     <= '1';
				sel_addr <= '1';
			when LOAD2 =>
				sel_mem <= '1';
			when I_OP =>
				imm_signed <= '1';      -- currently there's ony I_OP operation and it is signed				
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

	compute_op_alu : process (op, opx) is
	begin
		if op = X"3A" and opx = X"0E" then
			op_alu <= and_op;
		elsif op = X"3A" and opx = X"1B" then
			op_alu <= srl_op;
		else
			op_alu <= add_op;           -- default state 
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
				if op = X"3A" and opx /= X"34" then
					nextState <= R_OP;
				elsif opx = X"34" then
					nextState <= BREAK;
				elsif op = X"04" then
					nextState <= I_OP;
				elsif op = X"17" then
					nextState <= LOAD1;
				elsif op = X"15" then
					nextState <= STORE;
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
			when I_OP =>
				-- we take care of imm_signed
				nextState <= FETCH1;
		end case;
	end process compute_next_state;

end synth;
