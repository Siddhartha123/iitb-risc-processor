LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;

ENTITY hb_updater IS
	PORT (
		old_hb : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		EX_Found : IN STD_LOGIC;
		beq_status : IN STD_LOGIC_VECTOR(1 DOWNTO 0); ---branch & op
		new_hb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		write_bit : OUT STD_LOGIC
	);
END ENTITY hb_updater;

ARCHITECTURE arch OF hb_updater IS
BEGIN

	PROCESS (old_hb, beq_status, EX_Found) BEGIN
		IF (beq_status(1) = '1') THEN
			write_bit <= '1';
			new_hb <= "00";
			IF (EX_Found = '1' AND beq_status(0) = '1') THEN
				CASE old_hb IS
					WHEN "00" => new_hb <= "01";
					WHEN "01" => new_hb <= "10";
					WHEN "10" => new_hb <= "11";
					WHEN OTHERS => new_hb <= "11";
						write_bit <= '0';
				END CASE;
			ELSIF (EX_Found = '1' AND beq_status(0) = '0') THEN
				CASE old_hb IS
					WHEN "00" => new_hb <= "00";
						write_bit <= '0';
					WHEN "01" => new_hb <= "00";
					WHEN "10" => new_hb <= "01";
					WHEN OTHERS => new_hb <= "10";
				END CASE;
			ELSE
				new_hb <= '0' & beq_status(0);
				write_bit <= '1';
			END IF;
		ELSE
			write_bit <= '0';
			new_hb <= "00";
		END IF;
	END PROCESS;
END ARCHITECTURE arch;