`timescale 1ns / 1ps
module rom(clk, address, outp);
    input clk;
    input[15:0] address;
    output reg [15:0]  outp;
    reg [15:0] mem [0:255];
    integer i;
    
    initial
        $readmemb("memory/rom.txt",mem);
        initial begin
            //  for(i = 0;i< = 255;i = i+1)
            // 	$display ("ROM[%d] = %h",i,mem[i]);
        end
        always @(address)
            outp = mem[address];
endmodule
