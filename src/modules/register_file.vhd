LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;
USE IEEE.Numeric_Std.ALL;
USE work.mypkg.ALL;
ENTITY register_file IS
	PORT (
		clk, resetn, Load : IN STD_LOGIC;
		rf_add_out_1, rf_add_out_2, rf_add_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		data_inp : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_out1, data_out2 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		PC_In_Signals : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
		pc_out : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END ENTITY register_file;

ARCHITECTURE arch OF register_file IS
	SIGNAL data_out, data_in : reg_bus;
	SIGNAL PC_Load : STD_LOGIC;
	SIGNAL load_Nreg : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL PC_Input : STD_LOGIC_VECTOR(15 DOWNTO 0);

	-- PROCEDURE print(str : IN STRING) IS
	-- 	VARIABLE oline : line;
	-- BEGIN
	-- 	write(oline, str);
	-- 	writeline(output, oline);
	-- END PROCEDURE;

	COMPONENT debug_reg_file IS
		PORT (
			clk, Load : IN STD_LOGIC;
			rf_add_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
			data_inp : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT;

BEGIN
	gen_reg : FOR i IN 0 TO 6 GENERATE
		reg_16bit : ENTITY work.reg_Nbit GENERIC MAP(16) PORT MAP(clk, resetn, (load_Nreg(i) AND Load), data_inp, data_out(i));
	END GENERATE gen_reg;

	debug_reg : debug_reg_file PORT MAP(clk, Load, rf_add_in, data_inp);
	PC : ENTITY work.reg_Nbit GENERIC MAP(16) PORT MAP(clk, resetn, (PC_In_Signals(16) OR load_Nreg(7)), PC_Input, pc_out);

	WITH rf_add_in SELECT
		PC_Input <= data_inp WHEN "111",
		PC_In_Signals(15 DOWNTO 0) WHEN OTHERS;

	WITH rf_add_out_1 SELECT
		data_out1 <= data_out(0) WHEN "000",
		data_out(1) WHEN "001",
		data_out(2) WHEN "010",
		data_out(3) WHEN "011",
		data_out(4) WHEN "100",
		data_out(5) WHEN "101",
		data_out(6) WHEN "110",
		data_out(7) WHEN OTHERS;

	WITH rf_add_out_2 SELECT
		data_out2 <= data_out(0) WHEN "000",
		data_out(1) WHEN "001",
		data_out(2) WHEN "010",
		data_out(3) WHEN "011",
		data_out(4) WHEN "100",
		data_out(5) WHEN "101",
		data_out(6) WHEN "110",
		data_out(7) WHEN OTHERS;

	WITH rf_add_in SELECT
		load_Nreg <= "00000001" WHEN "000",
		"00000010" WHEN "001",
		"00000100" WHEN "010",
		"00001000" WHEN "011",
		"00010000" WHEN "100",
		"00100000" WHEN "101",
		"01000000" WHEN "110",
		"10000000" WHEN OTHERS;

	data_out(7) <= pc_out;

	-- monitor_content_process : PROCESS (clk) BEGIN
	-- 	IF Load = '1' THEN
	-- 		echo("REG," & INTEGER'image(to_integer(unsigned(rf_add_in))) & "," & INTEGER'image(to_integer(unsigned(data_inp))) & LF);
	-- 	END IF;
	-- END PROCESS;
END ARCHITECTURE arch;