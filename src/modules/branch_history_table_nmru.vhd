-- Branch History Table (NMRU)
-- The last updated entry comes to the top, so that when a new entry is added, last updated entry is not discarded
LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;

ENTITY branch_history_table IS
    GENERIC (N : INTEGER := 5);
    PORT (
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
    TYPE slv_arr16 IS ARRAY(N - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
    TYPE slv_arr2 IS ARRAY(N - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ins_addr_reg_out, bta : slv_arr16;
    SIGNAL history, hist_reg_in : slv_arr2;
    SIGNAL shift_rows, update_hist, found_inp : STD_LOGIC;
    SIGNAL load_history : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
BEGIN
    gen_row : FOR i IN 0 TO N - 1 GENERATE
        -- generate one row : addr,bta_addr,history
        -- load signal from decoder - wr works for now
        -- instantiate big_mux at input of next row
        first_row : IF i = 0 GENERATE
            ins_addr_reg : ENTITY work.reg_Nbit GENERIC MAP(16) PORT MAP(clk, resetn, shift_rows, ins_addr_inp, ins_addr_reg_out(i));
            bta_reg : ENTITY work.reg_Nbit GENERIC MAP(16) PORT MAP(clk, resetn, shift_rows, bta_inp, bta(i));
            history_reg : ENTITY work.reg_Nbit GENERIC MAP(2) PORT MAP(clk, resetn, load_history(i), history_inp, history(i));
        END GENERATE;
        other_rows : IF i > 0 GENERATE
            ins_addr_reg : ENTITY work.reg_Nbit GENERIC MAP(16) PORT MAP(clk, resetn, shift_rows, ins_addr_reg_out(i - 1), ins_addr_reg_out(i));
            bta_reg : ENTITY work.reg_Nbit GENERIC MAP(16) PORT MAP(clk, resetn, shift_rows, bta(i - 1), bta(i));
            history_reg : ENTITY work.reg_Nbit GENERIC MAP(2) PORT MAP(clk, resetn, load_history(i), hist_reg_in(i - 1), history(i));
            hist_reg_in(i - 1) <= (history(i - 1) AND (NOT (update_hist & update_hist))) OR (history_inp AND update_hist & update_hist);
        END GENERATE;
    END GENERATE gen_row;

    bta_history_out_process : PROCESS (ins_addr, ins_addr_reg_out, bta, history) BEGIN
        found <= '0';
        bta_out <= (OTHERS => '0');
        history_out <= (OTHERS => '0');
        FOR i IN 0 TO N - 1 LOOP
            IF ins_addr = ins_addr_reg_out(i) THEN
                bta_out <= bta(i);
                history_out <= history(i);
                found <= '1';
                EXIT;
            END IF;
        END LOOP;
    END PROCESS;

    -- shift only if entry not found
    shift_rows <= wr AND (NOT found_inp);

    -- select history_inp as history register inputs if entry already present
    update_hist <= wr AND found_inp;

    --load only one row if found is high, else load all(shift)
    bht_load_process : PROCESS (wr, ins_addr_inp, ins_addr_reg_out, shift_rows) BEGIN
        found_inp <= '0';
        FOR i IN 0 TO N - 1 LOOP
            load_history(i) <= shift_rows;
            IF ins_addr_inp = ins_addr_reg_out(i) THEN
                found_inp <= '1';
                load_history(i) <= wr;
            END IF;
        END LOOP;
    END PROCESS;

END arch;