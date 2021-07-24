LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;
USE work.mypkg.ALL;

ENTITY pipeproc IS
	PORT (
		clk, resetn : IN STD_LOGIC
	);
END ENTITY pipeproc;

ARCHITECTURE struc OF pipeproc IS
	SIGNAL rom_data, ram_data_in, ram_data_out : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL rom_address, ram_address : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL DMem_wr : STD_LOGIC;
	COMPONENT ram IS
		PORT (
			inp : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			address : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			load, clk : IN STD_LOGIC;
			outp : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT ram;

	COMPONENT rom IS
		PORT (
			clk : IN STD_LOGIC;
			address : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			outp : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT rom;

BEGIN
	CPU : ENTITY work.cpu PORT MAP(clk, resetn, ram_data_out, rom_data, ram_address, rom_address, ram_data_in, DMem_wr);
	i : ram PORT MAP(inp => ram_data_in, address => ram_address, load => DMem_wr, clk => clk, outp => ram_data_out);
	j : rom PORT MAP(clk => clk, address => rom_address, outp => rom_data);
END ARCHITECTURE struc;