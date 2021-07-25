LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;
USE work.mypkg.ALL;

ENTITY pipeproc_tb IS
END ENTITY pipeproc_tb;

ARCHITECTURE testbench OF pipeproc_tb IS
	SIGNAL clock, resetn : Std_Logic := '1';
BEGIN
	uut : ENTITY work.pipeproc PORT MAP(clock, resetn);
	clk_process : PROCESS BEGIN
		FOR i IN 1 TO 360 LOOP
			WAIT FOR 10 ns;
			clock <= NOT(clock);
		END LOOP;
		WAIT;
	END PROCESS clk_process;
	resetn <= '0' AFTER 19 ns, '1' AFTER 21 ns;
END ARCHITECTURE testbench;
