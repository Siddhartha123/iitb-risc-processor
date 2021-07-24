LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;

ENTITY reg_Nbit IS
	GENERIC (N : NATURAL := 16);
	PORT (
		clk, resetn, Load : IN STD_LOGIC;
		data_in : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
		data_out : OUT STD_LOGIC_VECTOR(N - 1 DOWNTO 0)
	);
END ENTITY reg_Nbit;

ARCHITECTURE arch OF reg_Nbit IS
BEGIN
	PROCESS
	BEGIN
		WAIT UNTIL clk'Event AND clk = '1';
		IF (resetn = '0') THEN
			data_out <= (OTHERS => '0');
		ELSIF (Load = '1') THEN
			data_out <= data_in;
		END IF;
	END PROCESS;
END ARCHITECTURE arch;