LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;
USE IEEE.Numeric_Std.ALL;
ENTITY pc_incrementer IS
	PORT (
		pc_out, mux_out : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		pc_in : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END ENTITY pc_incrementer;

ARCHITECTURE arch OF pc_incrementer IS
BEGIN
	pc_in <= STD_LOGIC_VECTOR(To_Unsigned((To_Integer(Unsigned(pc_out)) + To_Integer(Unsigned(mux_out))), 16));
END ARCHITECTURE arch;