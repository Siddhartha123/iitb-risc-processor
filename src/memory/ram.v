`timescale 1ns / 1ps

module ram(inp,address,load,clk,outp);
    input [15:0] address;
    input load,clk;
    output [15:0] outp;
    input [15:0] inp;
    reg [15:0] mem [255:0];
    integer i;
    initial
        $readmemh("src/memory/ram.txt",mem);
        always @(mem) begin
            // for(i = 0;i< = 255;i = i+1)
            // $display ("RAM[%d] = %h",i,mem[i]);
        end
		assign outp = mem[address];
		always @(posedge clk) begin
			if (load) begin
				mem[address] = inp;
				$display ("RAM,%d,%d",address,inp);
		end
    end
endmodule
