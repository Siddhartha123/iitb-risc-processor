LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;
USE IEEE.Numeric_Std.ALL;
ENTITY pcplusone IS
	PORT (
		pc_out : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		pc_plus_one : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END ENTITY pcplusone;

ARCHITECTURE arch OF pcplusone IS
	SIGNAL one : STD_LOGIC_VECTOR(15 DOWNTO 0) := (0 => '1', OTHERS => '0');
BEGIN
	pc_plus_one <= STD_LOGIC_VECTOR(To_Unsigned((To_Integer(Unsigned(pc_out)) + To_Integer(Unsigned(one))), 16));
END ARCHITECTURE arch;