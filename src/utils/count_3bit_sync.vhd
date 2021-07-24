LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY count_3bit_sync IS
    PORT (
        resetn, clk : IN STD_LOGIC;
        Q : BUFFER STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END count_3bit_sync;

ARCHITECTURE behaviour OF count_3bit_sync IS
BEGIN
    PROCESS (clk) BEGIN
        IF clk = '1' THEN
            IF resetn = '0' THEN
                Q <= "000";
            ELSIF resetn = '1' THEN
                Q <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(Q)) + 1, 3));
            ELSE
                Q <= "000";
            END IF;
        END IF;
    END PROCESS;
END behaviour;