LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;

ENTITY branch_history_table IS
    GENERIC (N : INTEGER := 5);
    PORT (
        -- clk, resetn : IN STD_LOGIC;
        -- wr : IN STD_LOGIC;
        -- ins_addr_inp, bta_inp : IN STD_LOGIC_VECTOR(15 DOWNTO 0); ---first entry address and target address
        -- history_inp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

        -- ins_addr : IN STD_LOGIC_VECTOR(15 DOWNTO 0); ----- search address
        -- bta_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); ----- branch target address corresponding to search address
        -- history_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- history corresponding to search address
        -- found : OUT STD_LOGIC ---------------------------- 0 if search address not present in table

        clk, resetn, wr : IN STD_LOGIC;
        ins_addr : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -----already present address
        ins_addr_inp, bta_inp : IN STD_LOGIC_VECTOR(15 DOWNTO 0); ---first entry address and target address
        history_inp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        bta_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        history_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        found : OUT STD_LOGIC
    );
END branch_history_table;

ARCHITECTURE arch OF branch_history_table IS

    TYPE bht_entry_t IS RECORD
        pc_addr : STD_LOGIC_VECTOR(15 DOWNTO 0);
        bta : STD_LOGIC_VECTOR(15 DOWNTO 0);
        history : STD_LOGIC_VECTOR(1 DOWNTO 0);
    END RECORD bht_entry_t;

    TYPE bht_entry_t_arr IS ARRAY(0 TO N - 1) OF bht_entry_t;

    SIGNAL bht : bht_entry_t_arr;

BEGIN

    bta_history_out_process : PROCESS (ins_addr, bht) BEGIN
        found <= '0';
        bta_out <= (OTHERS => '0');
        history_out <= (OTHERS => '0');
        FOR i IN 0 TO N - 1 LOOP
            IF ins_addr = bht(i).pc_addr THEN
                bta_out <= bht(i).bta;
                history_out <= bht(i).history;
                found <= '1';
                EXIT;
            END IF;
        END LOOP;
    END PROCESS;

    --if not found, shift all entries
    -- else, shift the updated entry to top 
    bht_load_process : PROCESS (clk, resetn, wr, ins_addr_inp, bht, bta_inp, history_inp)
        VARIABLE required_entry : bht_entry_t;
        VARIABLE bht_var : bht_entry_t_arr;
        VARIABLE location : INTEGER;
    BEGIN
        bht_var := bht;
        location := N - 1;
        required_entry := bht(0);

        FOR i IN 0 TO N - 1 LOOP
            IF ins_addr_inp = bht_var(i).pc_addr THEN
                location := i;
                required_entry := bht_var(i);
            END IF;
        END LOOP;

        FOR i IN N - 1 DOWNTO 1 LOOP
            IF i <= location THEN
                bht_var(i) := bht_var(i - 1);
            END IF;
        END LOOP;
        required_entry.pc_addr := ins_addr_inp;
        required_entry.bta := bta_inp;
        required_entry.history := history_inp;
        bht_var(0) := required_entry;

        IF clk'event AND clk = '1' THEN
            IF wr = '1' THEN
                bht <= bht_var;
            END IF;
            IF resetn = '0' THEN
                FOR i IN 0 TO N - 1 LOOP
                    bht(i) <= (pc_addr => (OTHERS => '0'), bta => (OTHERS => '0'), history => (OTHERS => '0'));
                END LOOP;
            END IF;
        END IF;
    END PROCESS;

END arch;