LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;

ENTITY reg_status IS
	PORT (
		instruction : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		pe_out : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		src_1, src_2, dest : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		arith, branch, lw_ins, lhi_ins, lm_ins, cond_c_ins, cond_z_ins : OUT STD_LOGIC
	);
END ENTITY reg_status;

ARCHITECTURE arch OF reg_status IS
BEGIN

	PROCESS (instruction) BEGIN
		arith <= '0';
		branch <= '0';
		lw_ins <= '0';
		lhi_ins <= '0';
		lm_ins <= '0';
		cond_c_ins <= '0';
		cond_z_ins <= '0';
		CASE(instruction(15 DOWNTO 12)) IS
			WHEN "0000" | "0010" =>
			IF (instruction(1 DOWNTO 0) = "10") THEN
				cond_c_ins <= '1';
			ELSIF (instruction(1 DOWNTO 0) = "01") THEN
				cond_z_ins <= '1';
			END IF;
			WHEN "0110" =>
			lm_ins <= '1';
			WHEN "0011" =>
			lhi_ins <= '1';
			WHEN "0100" =>
			lw_ins <= '1';
			arith <= '1';
			WHEN "1001" | "1000" =>
			branch <= '1';
			WHEN "0101" | "0111" =>
			arith <= '1';
			WHEN "1100" =>
			branch <= '1';
			arith <= '1';
			WHEN OTHERS =>
			arith <= '0';
			branch <= '0';
			lw_ins <= '0';
			lhi_ins <= '0';
			lm_ins <= '0';
			cond_c_ins <= '0';
			cond_z_ins <= '0';
		END CASE;
	END PROCESS;

	PROCESS (instruction, pe_out) BEGIN
		src_1 <= "1000";
		src_2 <= "1000";
		dest <= "1111";
		CASE(instruction(15 DOWNTO 12)) IS
			WHEN "0000" | "0010" => ---ADD/NDU/ADC/ADZ/NDC/NDZ
			src_1 <= '0' & instruction(11 DOWNTO 9);
			src_2 <= '0' & instruction(8 DOWNTO 6);
			dest <= '0' & instruction(5 DOWNTO 3);
			WHEN "0001" => ---ADI
			src_1 <= '0' & instruction(11 DOWNTO 9);
			dest <= '0' & instruction(8 DOWNTO 6);
			WHEN "0011" | "1000" => ---LHI/JAL
			dest <= '0' & instruction(11 DOWNTO 9);
			WHEN "1001" | "0100" => ---JLR/LW
			src_1 <= '0' & instruction(8 DOWNTO 6);
			dest <= '0' & instruction(11 DOWNTO 9);
			WHEN "0101" => ---SW		
			src_2 <= '0' & instruction(11 DOWNTO 9); ----Value
			src_1 <= '0' & instruction(8 DOWNTO 6); -----Address
			WHEN "1100" => ---BEQ			
			src_1 <= '0' & instruction(11 DOWNTO 9);
			src_2 <= '0' & instruction(8 DOWNTO 6);
			WHEN "0110" => ---LM
			src_1 <= '0' & instruction(11 DOWNTO 9);
			dest <= '0' & pe_out;
			WHEN "0111" => ---SM
			src_1 <= '0' & instruction(11 DOWNTO 9); ---Address
			src_2 <= '0' & pe_out; ---Value
			WHEN OTHERS =>
			src_1 <= "1000";
			src_2 <= "1000";
			dest <= "1111";
		END CASE;
	END PROCESS;
END ARCHITECTURE arch;