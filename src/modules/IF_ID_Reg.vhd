LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;
ENTITY IF_ID_Reg IS
	PORT (
		clk, resetn, load : IN STD_LOGIC;
		data_input1_16bit : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_input2_16bit : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_input1_1bit : IN STD_LOGIC; -- valid bit
		data_output1_16bit : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_output2_16bit : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_output1_1bit : OUT STD_LOGIC
	);
END ENTITY IF_ID_Reg;

ARCHITECTURE arch OF IF_ID_Reg IS

BEGIN
	PROCESS (clk)
	BEGIN
		IF (resetn = '0') THEN
			data_output1_16bit <= (15 | 14 | 13 | 12 => '1', OTHERS => '0');
			data_output2_16bit <= (OTHERS => '0');
			data_output1_1bit <= '1';
		ELSIF (clk'Event AND clk = '1') THEN
			IF (load = '1') THEN
				data_output1_16bit <= data_input1_16bit;
				data_output2_16bit <= data_input2_16bit;
				data_output1_1bit <= data_input1_1bit;
			END IF;
		END IF;
	END PROCESS;
END ARCHITECTURE arch;