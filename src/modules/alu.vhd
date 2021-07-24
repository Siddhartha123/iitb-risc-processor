LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;
USE IEEE.Numeric_Std.ALL;

ENTITY alu IS
	PORT (
		op_bit : IN STD_LOGIC;
		alu_1, alu_2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		alu_out : OUT STD_LOGIC_VECTOR(16 DOWNTO 0)
	);
END ENTITY alu;

ARCHITECTURE arch OF alu IS
	SIGNAL Sum : INTEGER;
BEGIN
	Sum <= (To_Integer(Unsigned(alu_1)) + To_Integer(Unsigned(alu_2)));
	WITH op_bit SELECT
		alu_out <= '0' & (alu_1 NAND alu_2) WHEN '1',
		STD_LOGIC_VECTOR(To_Unsigned(Sum, 17)) WHEN OTHERS;
END ARCHITECTURE arch;