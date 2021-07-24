LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;
ENTITY ID_RR_Reg IS
	PORT (
		clk, resetn, load : IN STD_LOGIC;
		data_input1_16bit : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_input2_16bit : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_input1_21bit : IN STD_LOGIC_VECTOR(20 DOWNTO 0);
		data_input1_3bit : IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- pe_out
		data_input1_1bit : IN STD_LOGIC; -- valid bit
		data_input2_3bit : IN STD_LOGIC_VECTOR(2 DOWNTO 0);--branch predictor 
		data_output1_16bit : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_output2_16bit : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_output1_21bit : OUT STD_LOGIC_VECTOR(20 DOWNTO 0);
		data_output1_3bit : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		data_output1_1bit : OUT STD_LOGIC;
		data_output2_3bit : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
	);
END ENTITY ID_RR_Reg;

ARCHITECTURE arch OF ID_RR_Reg IS

BEGIN
	PROCESS (clk)
	BEGIN
		IF (resetn = '0') THEN
			data_output1_16bit <= (OTHERS => '0');
			data_output2_16bit <= (15 | 14 | 13 | 12 => '1', OTHERS => '0');
			data_output1_21bit <= (0 | 15 => '1', OTHERS => '0');
			data_output1_1bit <= '1';
			data_output1_3bit <= (OTHERS => '0');
			data_output2_3bit <= "000";
		ELSIF (clk'Event AND clk = '1') THEN
			IF (load = '1') THEN
				data_output1_16bit <= data_input1_16bit;
				data_output2_16bit <= data_input2_16bit;
				data_output1_21bit <= data_input1_21bit;
				data_output1_3bit <= data_input1_3bit;
				data_output1_1bit <= data_input1_1bit;
				data_output2_3bit <= data_input2_3bit;
			END IF;
		END IF;
	END PROCESS;
END ARCHITECTURE arch;