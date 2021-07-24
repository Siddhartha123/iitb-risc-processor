LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;
USE work.mypkg.ALL;

ENTITY cpu IS
	PORT (
		clock, resetn : IN STD_LOGIC;
		ram_data_out, rom_data : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		ram_address, rom_address, ram_data_in : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0);
		DMEM_WR : OUT STD_LOGIC
	);
END ENTITY cpu;

ARCHITECTURE struct OF cpu IS
	COMPONENT controller IS
		PORT (
			instruction : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			is_one_hot_or_zero : IN STD_LOGIC;
			ctrlWord : OUT STD_LOGIC_VECTOR(20 DOWNTO 0)
		);
	END COMPONENT controller;
	COMPONENT lm_sm IS
		PORT (
			is_one_hot_or_zero : OUT STD_LOGIC;
			instruction : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	END COMPONENT lm_sm;

	SIGNAL MEM_CW, WB_CW, control_word, RR_CW, EX_CW : STD_LOGIC_VECTOR(20 DOWNTO 0);

	SIGNAL PC_In_Signals, alu_out : STD_LOGIC_VECTOR(16 DOWNTO 0);

	SIGNAL Imm_SE, Imm6, pc_plusone_input, beq_pc_in, pc_in, mux_pc_incr, pc_out, pc_plus_one, pc_incr_input, bta_out : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL data_inp, data_out1, data_out2, d, data_out1_reg, data_out2_reg, data_out_from_2, data_out_from_1 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL alu_1, alu_2, alu_inp_1, alu_inp_2, ram_data, mux_pc_reg, in_mux_pc_reg : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL EX_pc_out, EX_IR_Out, EX_data_out1, EX_data_out2, ex_out1, ex_out2, ID_IR_Out, ID_pc_out, RR_pc_out, RR_IR_Out, IF_IR_input : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL MEM_data_out2, MEM_alu_out, MEM_IR_Out, MEM_data, WB_data, WB_IR_Out, WB_alu_out, WB_dmemout : STD_LOGIC_VECTOR(15 DOWNTO 0);

	SIGNAL SE_10bit : STD_LOGIC_VECTOR(9 DOWNTO 0);

	SIGNAL rr_src_1, rr_src_2, ex_src_1, ex_src_2, mem_dest, ex_dest, wb_dest : STD_LOGIC_VECTOR(3 DOWNTO 0);

	SIGNAL BPB_ID, BPB_RR, BPB_EX, Updated_Bits : STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL rf_add_out_1, rf_add_out_2, rf_add_in, pe_out, RR_pe_out, EX_pe_out, MEM_pe_out, WB_pe_out : STD_LOGIC_VECTOR(2 DOWNTO 0);

	SIGNAL sel_MuxPCIn, x, sel_ALUInp1_mux, Load_Flags : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL fwd1, fwd2, fwd3, fwd4, history_out : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL EX_CFlag, EX_ZFlag, Op, MEM_valid, MEM_valid_next, WB_valid, MEM_CFlag, MEM_ZFlag, WB_CFlag, WB_ZFlag, Z_flag_in, mem_c_ins, mem_z_ins : STD_LOGIC;
	SIGNAL Load_IF_ID, Load_ID_RR, Load_RR_EX, Load_EX_MEM : STD_LOGIC := '1';
	SIGNAL Load_RegFile, EX_valid, EX_valid_next, Load_PC, EX_stall_out, sel_MuxPCIncr, EX_stall : STD_LOGIC;
	SIGNAL IF_valid_next, ID_valid, ID_valid_next, RR_valid, RR_valid_next, mem_lm, wb_lm, ex_lm : STD_LOGIC;
	SIGNAL IF_is_one_hot_or_zero, is_one_hot_or_zero, EX_is_one_hot_or_zero, EX_LSM_first_time, LSM_first_time : STD_LOGIC;
	SIGNAL LSM_first_flag, arith, jump, mem_lw_ins, wb_lw_ins, mem_lhi, wb_lhi, rr_out_1, rr_out_2 : STD_LOGIC;
	SIGNAL is_dest_r7, is_not_valid_pulse, entry_found : STD_LOGIC;
	ALIAS sel_RegFileInp IS WB_CW(4 DOWNTO 3);
	ALIAS sel_RegFileAddrInp IS WB_CW(6 DOWNTO 5);
	ALIAS sel_ALUInp2 IS EX_CW(8 DOWNTO 7);
	ALIAS alu_operation_bit IS EX_CW(9);
	ALIAS sel_RegFileAddrOut : STD_LOGIC_VECTOR(1 DOWNTO 0) IS RR_CW(11 DOWNTO 10);
	ALIAS Load_Z_Flag IS MEM_CW(13);
	ALIAS Load_C_Flag IS MEM_CW(14);
	ALIAS Load_LW IS MEM_CW(16);
	ALIAS branch IS EX_CW(18);
	ALIAS sel_ALUInp1 IS EX_CW(20 DOWNTO 19);
BEGIN
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------
	PC_In_Signals <= Load_PC & mux_pc_reg;
	ram_address <= MEM_alu_out;
	ram_data_in <= MEM_data_out2;
	DMEM_WR <= (MEM_CW(17) AND MEM_Valid);
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	---------Branch Predictor Unit-------
	--*** this should go to EX
	HB_UPDATER : ENTITY work.hb_updater PORT MAP(BPB_EX(2 DOWNTO 1), BPB_EX(0), branch & Op, Updated_Bits(2 DOWNTO 1), Updated_Bits(0));

	--*** this should go to ID
	branch_history_table : ENTITY work.branch_history_table PORT MAP(clock, resetn, Updated_Bits(0), ID_pc_out, EX_pc_out, pc_in, Updated_Bits(2 DOWNTO 1), bta_out, history_out, entry_found);
	BPB_ID <= history_out & entry_found;

	branch_predict_process : PROCESS (ID_IR_Out, ID_PC_out, pc_out, bta_out, entry_found, history_out) BEGIN
		pc_incr_input <= pc_out; -- default value
		rom_address <= pc_out; -- default value
		IF ID_IR_Out(15 DOWNTO 12) = "1100" THEN
			IF entry_found = '1' AND history_out(1) = '1' THEN
				pc_incr_input <= bta_out;
				rom_address <= bta_out;
			END IF;
		END IF;
	END PROCESS;
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	--------Data Forwarding Unit---------
	EX_REG_STATUS : ENTITY work.reg_status PORT MAP(EX_IR_OUT, EX_pe_out, ex_src_1, ex_src_2, ex_dest, arith, jump, lm_ins => ex_lm);
	MEM_REG_STATUS : ENTITY work.reg_status PORT MAP(instruction => MEM_IR_OUT, pe_out => MEM_pe_out, dest => mem_dest, lw_ins => mem_lw_ins, lhi_ins => mem_lhi, lm_ins => mem_lm, cond_c_ins => mem_c_ins, cond_z_ins => mem_z_ins);
	WB_REG_STATUS : ENTITY work.reg_status PORT MAP(instruction => WB_IR_OUT, pe_out => WB_pe_out, dest => wb_dest, lw_ins => wb_lw_ins, lhi_ins => wb_lhi, lm_ins => wb_lm);
	RR_REG_STATUS : ENTITY work.reg_status PORT MAP(RR_IR_OUT, RR_pe_out, rr_src_1, rr_src_2);
	DFU_EX : ENTITY work.forwarding_unit PORT MAP(rr_src_1, rr_src_2, ex_src_1, ex_src_2, mem_dest, wb_dest, arith, jump, mem_lw_ins, wb_lw_ins, MEM_valid, WB_valid, mem_lm, wb_lm, ex_lm, mem_c_ins, mem_z_ins, (WB_CFlag & WB_ZFlag), rr_out_1, rr_out_2, fwd1, fwd2, fwd3, fwd4, EX_stall);
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	-------FETCH--------
	-- *** logic for stalling fetch 
	IF_stall_process : PROCESS (ID_IR_Out, Load_ID_RR) BEGIN
		Load_IF_ID <= Load_ID_RR; -- default
	END PROCESS;

	one_hot_fetch : lm_sm PORT MAP(IF_is_one_hot_or_zero, IF_IR_input(7 DOWNTO 0));

	-- *** procedural implementation of IF_valid_next
	IF_valid_next_process : PROCESS (Op, branch, sel_ALUInp1, EX_Valid, BPB_EX) BEGIN
		IF_valid_next <= '1'; -- default
		IF branch = '1' AND EX_Valid = '1' THEN -- BEQ
			IF Op = '1' THEN ---------Actual is Taken
				IF (BPB_EX(0) = '0' OR (BPB_EX(0) = '1' AND BPB_EX(2) = '0')) THEN
					IF_valid_next <= '0';
				END IF;
			ELSE ---------------------Actual is Not Taken 
				IF (BPB_EX(0) = '1' AND BPB_EX(2) = '1') THEN
					IF_valid_next <= '0';
				END IF;
			END IF;
		ELSIF branch = '0' AND sel_ALUInp1 = "11" AND EX_Valid = '1' THEN --JLR/JAL
			IF_valid_next <= '0';
		END IF;
	END PROCESS;
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	-------IF/ID Register--------
	IF_ID_REG : ENTITY work.IF_ID_Reg PORT MAP(clock, resetn, Load_IF_ID, IF_IR_input, rom_address, IF_valid_next, ID_IR_Out, ID_pc_out, ID_valid);
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--------DECODE-------------
	-- *** logic for stalling decode 
	ID_stall_process : PROCESS (Load_RR_EX) BEGIN
		Load_ID_RR <= Load_RR_EX; -- default
	END PROCESS;

	Priority_Encoder : ENTITY work.priority_encoder PORT MAP(ID_IR_Out(7 DOWNTO 0), pe_out);

	mux_pe : ENTITY work.MUX_PE PORT MAP(pe_out, ID_IR_Out, d);

	one_hot : lm_sm PORT MAP(is_one_hot_or_zero, ID_IR_Out(7 DOWNTO 0));

	WITH (ID_IR_Out(15 DOWNTO 12) = "0110" OR ID_IR_Out(15 DOWNTO 12) = "0111") AND is_one_hot_or_zero = '0' SELECT
	IF_IR_input <= d WHEN True,
		rom_data WHEN False;

	CONTROL_LOGIC : controller PORT MAP(ID_IR_Out, is_one_hot_or_zero, control_word);

	-- *** procedural implementation of ID_valid_next
	ID_valid_next_process : PROCESS (ID_valid, Op, branch, sel_ALUInp1, EX_Valid, BPB_EX) BEGIN
		ID_valid_next <= '1'; -- default
		IF branch = '1' AND EX_Valid = '1' THEN -- BEQ
			IF Op = '1' THEN ---------Actual is Taken
				IF (BPB_EX(0) = '0' OR (BPB_EX(0) = '1' AND BPB_EX(2) = '0')) THEN
					ID_valid_next <= '0';
				END IF;
			ELSE ---------------------Actual is Not Taken 
				IF (BPB_EX(0) = '1' AND BPB_EX(2) = '1') THEN
					ID_valid_next <= '0';
				END IF;
			END IF;
		ELSIF branch = '0' AND sel_ALUInp1 = "11" AND EX_Valid = '1' THEN --JLR/JAL
			ID_valid_next <= '0';
		END IF;

		IF ID_valid = '0' THEN
			ID_valid_next <= '0';
		END IF;
	END PROCESS;

	---------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-------ID/RR Register----------
	ID_RR_REG : ENTITY work.ID_RR_Reg PORT MAP(clock, resetn, Load_ID_RR, ID_pc_out, ID_IR_Out, control_word, pe_out, ID_valid_next, BPB_ID, RR_pc_out, RR_IR_Out, RR_CW, RR_pe_out, RR_valid, BPB_RR);
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--------REG_READ-------------
	-- *** logic for stalling register read
	RR_stall_process : PROCESS (Load_EX_MEM, is_one_hot_or_zero) BEGIN
		Load_RR_EX <= Load_EX_MEM; -- default
	END PROCESS;

	-- *** Register File address(for data OUT)
	mux_sel_RegFileAddrOut : ENTITY work.Big_MUX GENERIC MAP(3) PORT MAP(sel_RegFileAddrOut, RR_IR_Out(8 DOWNTO 6), RR_pe_out, RR_IR_Out(11 DOWNTO 9), RR_IR_Out(11 DOWNTO 9), rf_add_out_2);
	WITH sel_RegFileAddrOut(1) SELECT
	rf_add_out_1 <= RR_IR_Out(11 DOWNTO 9) WHEN '1',
		RR_IR_Out(8 DOWNTO 6) WHEN OTHERS;

	-- *** Register File address(for data IN) Input			 
	mux_rf_add_in : ENTITY work.Big_MUX GENERIC MAP(3) PORT MAP(sel_RegFileAddrInp, WB_IR_Out(5 DOWNTO 3), WB_IR_Out(11 DOWNTO 9), WB_pe_out, WB_IR_Out(8 DOWNTO 6), rf_add_in);
	-- *** Register File Data input
	mux_sel_RegFileInp : ENTITY work.Big_MUX GENERIC MAP(16) PORT MAP(sel_RegFileInp, WB_alu_out, pc_plus_one, WB_dmemout, WB_IR_Out(8 DOWNTO 0) & "0000000", data_inp);

	Reg_File : ENTITY work.register_file PORT MAP(clock, resetn, Load_RegFile, rf_add_out_1, rf_add_out_2, rf_add_in, data_inp, data_out1, data_out2, PC_In_Signals, pc_out);

	-- *** procedural implementation of RR_valid_next
	RR_valid_next_process : PROCESS (RR_valid, Op, branch, sel_ALUInp1, EX_Valid, is_not_valid_pulse, BPB_EX) BEGIN
		RR_valid_next <= '1'; -- default
		IF branch = '1' AND EX_Valid = '1' THEN -- BEQ
			IF Op = '1' THEN ---------Actual is Taken
				IF (BPB_EX(0) = '0' OR (BPB_EX(0) = '1' AND BPB_EX(2) = '0')) THEN ------Predicted is Not Taken
					RR_valid_next <= '0';
				END IF;
			ELSE ---------------------Actual is Not Taken 
				IF (BPB_EX(0) = '1' AND BPB_EX(2) = '1') THEN --------Predicted is Taken
					RR_valid_next <= '0';
				END IF;
			END IF;
		ELSIF branch = '0' AND sel_ALUInp1 = "11" AND EX_Valid = '1' THEN --JLR/JAL
			RR_valid_next <= '0';
		END IF;
		IF (is_not_valid_pulse = '1') THEN -- ignore the next 5 instructions coming to execute stage
			RR_valid_next <= '0';
		END IF;
		IF RR_valid = '0' THEN
			RR_valid_next <= '0';
		END IF;
	END PROCESS;

	WITH EX_IR_Out(15 DOWNTO 12) = "0110" OR EX_IR_Out(15 DOWNTO 12) = "0111" SELECT
	LSM_first_time <= NOT EX_is_one_hot_or_zero WHEN true,
		'0' WHEN false;

	data_out_from_2 <= RR_pc_out WHEN rr_src_2 = "0111" ELSE
		data_out2;

	data_out_from_1 <= RR_pc_out WHEN rr_src_1 = "0111" ELSE
		data_out1;

	WITH rr_out_1 SELECT
		data_out1_reg <= data_inp WHEN '1',
		data_out_from_1 WHEN OTHERS;

	WITH rr_out_2 SELECT
		data_out2_reg <= data_inp WHEN '1',
		data_out_from_2 WHEN OTHERS;

	---------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-------RR/EX Register-------
	RR_EX_REG : ENTITY work.RR_EX_Reg PORT MAP(clock, resetn, Load_RR_EX, RR_pc_out, RR_IR_Out, RR_CW, data_out1_reg, data_out2_reg, RR_pe_out, RR_valid_next, LSM_first_time, BPB_RR, EX_pc_out, EX_IR_Out, EX_CW, EX_data_out1, EX_data_out2, EX_pe_out, EX_valid, EX_LSM_first_time, BPB_EX);
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-------EXECUTION-------
	-- *** logic for stalling execute
	Load_EX_MEM <= EX_stall_out OR ((NOT EX_stall) AND (NOT EX_stall_out));

	-- *** logic for R7 in destination of a valid instruction
	valid_pulse : ENTITY work.start_pulse_generator PORT MAP(clock, is_dest_r7, is_not_valid_pulse);

	WITH ex_dest = "0111" AND EX_valid = '1' SELECT
	is_dest_r7 <= '1' WHEN True,
		'0' WHEN False;

	load_PC_Proc : PROCESS (control_word(15), EX_IR_Out, IF_IR_input, IF_is_one_hot_or_zero, EX_stall, EX_stall_out, EX_Valid) BEGIN
		IF (EX_IR_Out(15 DOWNTO 12) = "1100" AND EX_Valid = '1') THEN
			Load_PC <= '1'; --BEQ
		ELSIF (EX_IR_Out(15 DOWNTO 12) = "1000" AND EX_Valid = '1') THEN
			Load_PC <= '1'; --JAL
		ELSIF (EX_IR_Out(15 DOWNTO 12) = "1001" AND EX_Valid = '1') THEN
			Load_PC <= '1'; --JLR
		ELSIF (IF_IR_input(15 DOWNTO 13) = "011") THEN
			Load_PC <= IF_is_one_hot_or_zero;
		ELSE
			Load_PC <= control_word(15) AND (EX_stall_out OR ((NOT EX_stall) AND (NOT EX_stall_out)));
		END IF;
	END PROCESS;

	LSM_first_flag <= (NOT EX_LSM_first_time) AND LSM_first_time;

	EX_one_hot : lm_sm PORT MAP(EX_is_one_hot_or_zero, EX_IR_Out(7 DOWNTO 0));

	-- *** ALU Input 1 -- can be combined into one process
	WITH LSM_first_flag SELECT
		sel_ALUInp1_mux <= "00" WHEN '1',
		sel_ALUInp1 WHEN OTHERS;
	mux_alu_1 : ENTITY work.Big_MUX GENERIC MAP(16) PORT MAP(sel_ALUInp1_mux, EX_pc_out, EX_data_out1, MEM_alu_out, EX_data_out1, alu_1);

	WITH mem_lhi SELECT
		MEM_data <= MEM_IR_Out(8 DOWNTO 0) & "0000000" WHEN '1',
		MEM_alu_out WHEN OTHERS;
	WITH wb_lhi SELECT
		WB_data <= WB_IR_Out(8 DOWNTO 0) & "0000000" WHEN '1',
		WB_alu_out WHEN OTHERS;

	mux_alu_inp_1 : ENTITY work.Big_MUX GENERIC MAP(16) PORT MAP(fwd1, MEM_data, WB_data, WB_dmemout, alu_1, alu_inp_1);
	mux_alu_inp_2 : ENTITY work.Big_MUX GENERIC MAP(16) PORT MAP(fwd2, MEM_data, WB_data, WB_dmemout, alu_2, alu_inp_2);
	mux_ex_data_out1 : ENTITY work.Big_MUX GENERIC MAP(16) PORT MAP(fwd3, MEM_data, WB_data, WB_dmemout, EX_data_out1, ex_out1);
	mux_ex_data_out2 : ENTITY work.Big_MUX GENERIC MAP(16) PORT MAP(fwd4, MEM_data, WB_data, WB_dmemout, EX_data_out2, ex_out2);

	ALU : ENTITY work.alu PORT MAP(alu_operation_bit, alu_inp_1, alu_inp_2, alu_out);
	Op <= '1' WHEN ex_out1 = ex_out2 ELSE
		'0';

	SE_10bit <= (OTHERS => EX_IR_Out(5));
	Imm_SE <= SE_10bit & EX_IR_Out(5 DOWNTO 0);
	WITH EX_IR_Out(15 DOWNTO 12) SELECT
	Imm6 <= Imm_SE WHEN "0001",
		"0000000000" & EX_IR_Out(5 DOWNTO 0) WHEN OTHERS;
	-- *** ALU Input 2
	mux_sel_ALUInp2 : ENTITY work.Big_MUX GENERIC MAP(16) PORT MAP(sel_ALUInp2 XOR (LSM_first_flag & LSM_first_flag), Imm6, (0 => '1', OTHERS => '0'), (OTHERS => '0'), EX_data_out2, alu_2);
	PC_Adder : ENTITY work.pc_incrementer PORT MAP(EX_pc_out, mux_pc_incr, pc_in);
	PC_Incr_One : ENTITY work.pcplusone PORT MAP(pc_plusone_input, pc_plus_one);

	WITH (x = "10" AND (BPB_EX(2) = '1' AND BPB_EX(0) = '1')) SELECT
	pc_plusone_input <= EX_PC_Out WHEN True,
		pc_incr_input WHEN OTHERS;

	sel_MuxPCIncr <= EX_CW(2) AND Branch;

	-- *** branch control signals
	x <= branch & Op;
	branch_mux_pc_control : PROCESS (x, EX_IR_Out, BPB_EX, EX_CW) BEGIN
		IF (x(1) = '1' AND BPB_EX(0) = '1') THEN
			IF (x(0) = '1' AND BPB_EX(2) = '1') THEN -----------Taken And Correct
				sel_MuxPCIn <= EX_CW(1 DOWNTO 0);
			ELSIF (x(0) = '0' AND BPB_EX(2) = '0') THEN -----------Not Taken And Correct
				sel_MuxPCIn <= EX_CW(1 DOWNTO 0); ------01
			ELSE
				sel_MuxPCIn <= "10"; ------------Not Taken And Incorrect/ Taken And Incorrect
			END IF;
		ELSIF (x(1) = '1' AND BPB_EX(0) = '0') THEN
			IF (x(0) = '1') THEN
				sel_MuxPCIn <= "10";
			ELSE
				sel_MuxPCIn <= EX_CW(1 DOWNTO 0);
			END IF;
		ELSE
			sel_MuxPCIn <= EX_CW(1 DOWNTO 0);
		END IF;
	END PROCESS;

	WITH (x = "11" AND (BPB_EX(2) = '0' OR BPB_EX(0) = '0')) SELECT
	beq_pc_in <= pc_in WHEN True,
		pc_plus_one WHEN OTHERS;

	-- *** MuxPCIncr
	WITH sel_MuxPCIncr SELECT
		mux_pc_incr <= ("0000000000" & EX_IR_Out(5 DOWNTO 0)) WHEN '1',
		("0000000" & EX_IR_Out(8 DOWNTO 0)) WHEN OTHERS;
	WITH EX_Valid SELECT
		mux_pc_reg <= pc_plus_one WHEN '0',
		in_mux_pc_reg WHEN OTHERS;

	-- *** MuxPC
	mux_sel_MuxPCIn : ENTITY work.Big_MUX GENERIC MAP(16) PORT MAP(sel_MuxPCIn, ex_out1, beq_pc_in, pc_plus_one, pc_in, in_mux_pc_reg);

	-- *** Zero flag from ALU
	Z_flag_in <= '1' WHEN (alu_out(15 DOWNTO 0) = "0000000000000000") ELSE
		'0';

	-- *** procedural implementation of EX_valid_next
	EX_valid_next_process : PROCESS (EX_valid) BEGIN
		EX_valid_next <= '1'; -- default
		IF EX_valid = '0' THEN
			EX_valid_next <= '0';
		END IF;
	END PROCESS;
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-------EX/MEM Register----------
	EX_MEM_REG : ENTITY work.EX_MEM_Reg PORT MAP(clock, resetn, EX_stall, Load_EX_MEM, EX_IR_Out, EX_CW, ex_out2, alu_out(15 DOWNTO 0), alu_out(16), Z_flag_in, EX_pe_out, EX_valid_next, MEM_IR_Out, MEM_CW, MEM_data_out2, MEM_alu_out, EX_CFlag, EX_ZFlag, MEM_valid, MEM_pe_out, EX_stall_out);
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-------MEM_ACC--------
	MEM_ZFlag <= '1' WHEN ram_data_out = "0000000000000000" AND load_LW = '1' ELSE
		EX_ZFlag;

	MEM_CFlag <= EX_CFlag;

	-- *** procedural implementation of MEM_valid_next
	MEM_valid_next_process : PROCESS (MEM_valid, MEM_IR_Out, WB_CFlag, WB_ZFlag) BEGIN
		MEM_valid_next <= '1'; -- default
		CASE MEM_IR_Out(15 DOWNTO 12) IS
			WHEN "0000" | "0010" =>
				IF MEM_IR_Out(1 DOWNTO 0) = "10" THEN -- ADC,NDC
					MEM_valid_next <= WB_CFlag;
				ELSIF MEM_IR_Out(1 DOWNTO 0) = "01" THEN -- ADZ,NDZ
					MEM_valid_next <= WB_ZFlag;
				END IF;
			WHEN OTHERS => MEM_valid_next <= '1';
		END CASE;

		IF MEM_valid = '0' THEN
			MEM_valid_next <= '0';
		END IF;
	END PROCESS;

	WITH MEM_valid_next SELECT
		Load_Flags <= Load_Z_Flag & Load_C_Flag WHEN '1',
		"00" WHEN OTHERS;
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-------MEM/WB Register----------
	MEM_WB_REG : ENTITY work.MEM_WB_Reg PORT MAP(clock, resetn, '1', Load_Flags, MEM_IR_Out, ram_data_out, MEM_alu_out, MEM_pe_out, MEM_valid_next, MEM_CFlag, MEM_ZFlag, MEM_CW, WB_IR_Out, WB_dmemout, WB_alu_out, WB_pe_out, WB_valid, WB_CW, WB_CFlag, WB_ZFlag);

	---------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-------WRITE_BACK--------
	Load_RegFile <= WB_CW(12) AND WB_valid;
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------
END ARCHITECTURE struct;