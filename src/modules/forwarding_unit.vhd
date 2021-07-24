LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;

ENTITY forwarding_unit IS
	PORT (
		rr_1, rr_2, src_1, src_2, dest_mem, dest_wb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		arith, branch, mem_lw, wb_lw, mem_valid, wb_valid, mem_lm, wb_lm, ex_lm, mem_c_ins, mem_z_ins : IN STD_LOGIC;
		wb_flags : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		out1, out2 : OUT STD_LOGIC;
		mx_alu_1, mx_alu_2, mx_alu_3, mx_alu_4 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		stall : OUT STD_LOGIC
	);
END ENTITY forwarding_unit;

ARCHITECTURE arch OF forwarding_unit IS
	SIGNAL stall_1, stall_2, stall_3, stall_4 : STD_LOGIC := '0';
BEGIN
	stall <= stall_1 OR stall_2 OR stall_3 OR stall_4;

	-----For Instructions in Register Read Stage------------------------------------------------------------------------
	PROCESS (rr_1, dest_wb, wb_valid) BEGIN
		IF (rr_1 = dest_wb AND wb_valid = '1') THEN
			out1 <= '1';
		ELSE
			out1 <= '0';
		END IF;
	END PROCESS;

	PROCESS (rr_2, dest_wb, wb_valid) BEGIN
		IF (rr_2 = dest_wb AND wb_valid = '1') THEN
			out2 <= '1';
		ELSE
			out2 <= '0';
		END IF;
	END PROCESS;
	-------For Instrcutions in Execution Stage-----------------------------------------------------------------------------
	PROCESS (branch, src_1, dest_mem, dest_wb, wb_valid, mem_valid, mem_lw, wb_lw, ex_lm, mem_lm, wb_lm, mem_c_ins, mem_z_ins, wb_flags) BEGIN
		IF (src_1 = dest_mem AND branch = '0' AND mem_lw = '0' AND mem_valid = '1' AND (mem_lm = '0' OR ex_lm = '0')) THEN
			mx_alu_1 <= "11";
		ELSIF (src_1 = dest_mem AND branch = '0' AND mem_lw = '1' AND mem_valid = '1' AND (mem_lm = '0' OR ex_lm = '0')) THEN
			stall_1 <= '1';
		ELSIF (src_1 = dest_wb AND branch = '0' AND wb_lw = '0' AND wb_valid = '1' AND (wb_lm = '0' OR ex_lm = '0')) THEN
			mx_alu_1 <= "10";
		ELSIF (src_1 = dest_wb AND branch = '0' AND wb_lw = '1' AND wb_valid = '1' AND (wb_lm = '0' OR ex_lm = '0')) THEN
			mx_alu_1 <= "01";
		ELSE
			mx_alu_1 <= "00";
		END IF;
		IF ((src_1 = dest_mem OR src_1 = dest_wb) AND ((mem_lm = '1' AND ex_lm = '0') OR(wb_lm = '1' AND ex_lm = '0'))) THEN
			mx_alu_1 <= "01";
		END IF;
		IF (src_1 = dest_mem AND mem_c_ins = '1' AND wb_flags(1) = '0' AND mem_valid = '1') THEN
			mx_alu_1 <= "00";
		ELSIF (src_1 = dest_mem AND mem_z_ins = '1' AND wb_flags(0) = '0' AND mem_valid = '1') THEN
			mx_alu_1 <= "00";
		END IF;
	END PROCESS;

	PROCESS (arith, src_2, dest_mem, dest_wb, wb_valid, mem_valid, mem_lw, wb_lw, ex_lm, mem_lm, wb_lm, mem_c_ins, mem_z_ins, wb_flags) BEGIN
		IF (src_2 = dest_mem AND arith = '0' AND mem_lw = '0' AND mem_valid = '1' AND (mem_lm = '0' OR ex_lm = '0')) THEN
			mx_alu_2 <= "11";
		ELSIF (src_2 = dest_mem AND arith = '0' AND mem_lw = '1' AND mem_valid = '1' AND (mem_lm = '0' OR ex_lm = '0')) THEN
			stall_2 <= '1';
		ELSIF (src_2 = dest_wb AND arith = '0' AND wb_lw = '0' AND wb_valid = '1' AND (wb_lm = '0' OR ex_lm = '0')) THEN
			mx_alu_2 <= "10";
		ELSIF (src_2 = dest_wb AND arith = '0' AND wb_lw = '1' AND wb_valid = '1' AND (wb_lm = '0' OR ex_lm = '0')) THEN
			mx_alu_2 <= "01";
		ELSE
			mx_alu_2 <= "00";
		END IF;
		IF ((src_2 = dest_mem OR src_2 = dest_wb) AND ((mem_lm = '1' AND ex_lm = '0') OR(wb_lm = '1' AND ex_lm = '0'))) THEN
			mx_alu_2 <= "01";
		END IF;
		IF (src_2 = dest_mem AND mem_c_ins = '1' AND wb_flags(1) = '0' AND mem_valid = '1') THEN
			mx_alu_2 <= "00";
		ELSIF (src_2 = dest_mem AND mem_z_ins = '1' AND wb_flags(0) = '0' AND mem_valid = '1') THEN
			mx_alu_2 <= "00";
		END IF;
	END PROCESS;

	PROCESS (branch, src_1, dest_mem, dest_wb, wb_valid, mem_valid, mem_lw, wb_lw, mem_c_ins, mem_z_ins, wb_flags) BEGIN
		IF (src_1 = dest_mem AND branch = '1' AND mem_lw = '0' AND mem_valid = '1') THEN
			mx_alu_3 <= "11";
		ELSIF (src_1 = dest_mem AND branch = '1' AND mem_lw = '1' AND mem_valid = '1') THEN
			stall_3 <= '1';
		ELSIF (src_1 = dest_wb AND branch = '1' AND wb_lw = '0' AND wb_valid = '1') THEN
			mx_alu_3 <= "10";
		ELSIF (src_1 = dest_wb AND branch = '1' AND wb_lw = '1' AND wb_valid = '1') THEN
			mx_alu_3 <= "01";
		ELSE
			mx_alu_3 <= "00";
		END IF;
		IF (src_1 = dest_mem AND branch = '1' AND mem_c_ins = '1' AND wb_flags(1) = '0' AND mem_valid = '1') THEN
			mx_alu_3 <= "00";
		ELSIF (src_1 = dest_mem AND branch = '1' AND mem_z_ins = '1' AND wb_flags(0) = '0' AND mem_valid = '1') THEN
			mx_alu_3 <= "00";
		END IF;
	END PROCESS;

	PROCESS (arith, src_2, dest_mem, dest_wb, wb_valid, mem_valid, mem_lw, wb_lw, mem_c_ins, mem_z_ins, wb_flags) BEGIN
		IF (src_2 = dest_mem AND arith = '1' AND mem_lw = '0' AND mem_valid = '1') THEN
			mx_alu_4 <= "11";
		ELSIF (src_2 = dest_mem AND arith = '1' AND mem_lw = '1' AND mem_valid = '1') THEN
			stall_4 <= '1';
		ELSIF (src_2 = dest_wb AND arith = '1' AND wb_lw = '0' AND wb_valid = '1') THEN
			mx_alu_4 <= "10";
		ELSIF (src_2 = dest_wb AND arith = '1' AND wb_lw = '1' AND wb_valid = '1') THEN
			mx_alu_4 <= "01";
		ELSE
			mx_alu_4 <= "00";
		END IF;
		IF (src_2 = dest_mem AND arith = '1' AND mem_c_ins = '1' AND wb_flags(1) = '0' AND mem_valid = '1') THEN
			mx_alu_4 <= "00";
		ELSIF (src_2 = dest_mem AND arith = '1' AND mem_z_ins = '1' AND wb_flags(0) = '0' AND mem_valid = '1') THEN
			mx_alu_4 <= "00";
		END IF;
	END PROCESS;

END ARCHITECTURE arch;