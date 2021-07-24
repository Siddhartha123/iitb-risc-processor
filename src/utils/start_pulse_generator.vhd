LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY start_pulse_generator IS
    PORT (
        clk, start : IN STD_LOGIC;
        r : BUFFER STD_LOGIC);
END start_pulse_generator;

ARCHITECTURE arch OF start_pulse_generator IS
    COMPONENT count_3bit_sync IS
        PORT (
            resetn, clk : IN STD_LOGIC;
            Q : BUFFER STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;
    SIGNAL g : STD_LOGIC := '0';
    SIGNAL Q : STD_LOGIC_VECTOR (2 DOWNTO 0);
BEGIN
    counter : count_3bit_sync PORT MAP(r, clk, Q);
    g <= ((NOT Q(2)) AND Q(0)) OR (Q(1) AND NOT Q(0)) OR (Q(2) AND NOT Q(1) AND NOT Q(0));
    r <= start OR g;
END arch;