`timescale 1ns / 1ps
module pipeproc_tb;

// signals for uut
reg clk,resetn;
// wire [24:0] debug_cw;
// wire [2:0] debug_status_signals;
// wire [15:0] debug_reg_bus[0:7];
wire [15:0] pc;
reg [15:0] pc1,pc2,pc3,pc4,pc5;

// simulation variables
integer sim_file;
reg [15:0] r0,r1,r2,r3,r4,r5,r6,r7;

pipeproc uut (.clk(clk), .resetn(resetn)) ;

assign pc=pipeproc_tb.uut.CPU.pc_out;

initial begin
    // reset sequence
    clk=0;
    resetn=0;
    #30;
    clk=1;
    #10;
    resetn=1;

    // account for latency
    for(integer i=0;i<6;i++)
        #20  clk = ~clk;
    // open simulator output file
    sim_file = $fopen("sim_output.txt","r");
    if (!sim_file) begin
        $display("Could not open sim_output");
        $stop;
    end
    // run pc through 5 stages 
    while( !$feof(sim_file)) begin
        #20  clk = ~clk;
        if(clk==1'b1 && pc4!=pc5 && pipeproc_tb.uut.CPU.MEM_valid == 1'b1) begin 
            // $display("valid");
            // $display("mem_valid = %d",pipeproc_tb.uut.CPU.MEM_valid);
            $fscanf(sim_file, "%d,%d,%d,%d,%d,%d,%d,%d,%*d,%*d\n", r0,r1,r2,r3,r4,r5,r6,r7);
            // $display("%d  %d",r3,pipeproc_tb.uut.CPU.Reg_File.data_out[3]);
        end
    end
end

always @(posedge clk) begin
    pc5=pc4;
    pc4=pc3;
    pc3=pc2;
    pc2=pc1;
    pc1=pc;
end
endmodule