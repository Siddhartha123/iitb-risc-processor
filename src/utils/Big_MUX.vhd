LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;

ENTITY Big_MUX IS
	GENERIC (
		N : INTEGER := 4
	);
	PORT (
		sel_Line : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		data1, data2, data3, data4 : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
		data_out : OUT STD_LOGIC_VECTOR(N - 1 DOWNTO 0)
	);
END ENTITY Big_MUX;

ARCHITECTURE arch OF Big_MUX IS
BEGIN
	WITH sel_Line SELECT
		data_out <= data1 WHEN "11",
		data2 WHEN "10",
		data3 WHEN "01",
		data4 WHEN OTHERS;
END ARCHITECTURE arch;