`timescale 1ns / 1ps
module controller(input [15:0] instruction,
                  input is_one_hot_or_zero,
                  output [20:0] ctrlWord
                  );

reg Load_PC,branch, Load_C_Flag, Load_Z_Flag, Load_RegFile, alu_op_bit, sel_MuxPCIncr,Load_LW,DMem_wr;
reg [1:0] sel_ALUInp2, sel_RegFileAddrOut, sel_RegFileInp, sel_RegFileAddrInp, sel_MuxPCIn,sel_ALUInp1;

assign ctrlWord = {sel_ALUInp1[1:0],branch,DMem_wr,Load_LW,Load_PC, Load_C_Flag, Load_Z_Flag, Load_RegFile, sel_RegFileAddrOut[1:0], alu_op_bit,sel_ALUInp2[1:0], sel_RegFileAddrInp[1:0], sel_RegFileInp[1:0], sel_MuxPCIncr, sel_MuxPCIn[1:0]};

//control signals
always @(instruction,is_one_hot_or_zero) begin

    // reset values
    {sel_ALUInp1[1:0],branch,DMem_wr,Load_LW,Load_C_Flag, Load_Z_Flag, Load_RegFile, sel_RegFileAddrOut[1:0], alu_op_bit, sel_ALUInp2[1:0], sel_RegFileAddrInp[1:0], sel_RegFileInp[1:0], sel_MuxPCIncr} <=19'b0;
    // default control signals
    Load_PC<=1'b1;                      // used in WB
    sel_MuxPCIn<= 2'b01;                // PC<- PC+1
    // control signals used in register read stage
    case(instruction[15:12])
        4'b0000: begin                  // ADD,ADC,ADZ
            // used in RR		  
            sel_RegFileAddrOut<=2'b11;  // IR[11:9]->RF_addr1,IR[8:6]->RF_addr2
            // used in EX
            Load_Z_Flag<=1'b1;           
            Load_C_Flag<=1'b1;	        // load flags by default 
            // used in WB
            sel_RegFileAddrInp<=2'b11;  // IR[5:3]->RF_addr_inp
            sel_RegFileInp<=2'b11;      // ALU_out->RF_data_inp
            Load_RegFile<=1'b1;            
        end
        4'b0001: begin                  // ADI
            // used in RR		
            sel_RegFileAddrOut[1]<=1'b1;// IR[11:9]->RF_addr1
            sel_ALUInp2<=2'b11;         // Imm6->ALU_inp2
            // used in EX
            Load_Z_Flag<=1'b1;          
            Load_C_Flag<=1'b1;	        // load flags by default  
            // used in WB
            sel_RegFileAddrInp<=2'b00;  // IR[8:6]->RF_addr_inp
            sel_RegFileInp<=2'b11;      // ALU_out->RF_data_inp
            Load_RegFile<=1'b1;
        end
        4'b0010: begin                  // NDU,NDC,NDZ 
            // used in RR		
            sel_RegFileAddrOut<=2'b11;  // IR[11:9]->RF_addr1,IR[8:6]->RF_addr2
            // used in EX
            alu_op_bit<=1'b1;           // nand operation by ALU
            Load_Z_Flag<=1'b1;          // load zero flag by default
            // used in WB
            sel_RegFileAddrInp<=2'b11;  // IR[5:3]->RF_addr_inp
            sel_RegFileInp<=2'b11;      // ALU_out->RF_data_inp
            Load_RegFile<=1'b1;
        end
        4'b0011: begin                  // LHI
            // used in WB
            sel_RegFileAddrInp<=2'b10;  // IR[11:9]->RF_addr_inp
            sel_RegFileInp<=2'b0;       // {IR[8:0],7'b0}->RF_data_inp
            Load_RegFile<=1'b1;
        end
        4'b1100: begin					    // BEQ
            branch<=1'b1;
            sel_RegFileAddrOut<=2'b11;  // IR[11:9]->RF_addr1,IR[8:6]->RF_addr2
            sel_MuxPCIncr<=1'b1;
        end
        4'b0101: begin                  // SW
            sel_ALUInp2<=2'b11;
            DMem_wr<=1'b1;              // DMem write enable
        end
	    4'b1001: begin					    // JLR
			sel_MuxPCIn<=2'b11;			    //Data_Out1 In PC
			sel_RegFileInp<=2'b11;
			sel_RegFileAddrInp<=2'b10;     // PC+1 In IR[11:9]
			sel_ALUInp1<=2'b11;			    // PC_Out in alu_1
			sel_ALUInp2<=2'b10;			    // +1 in alu_2
			Load_RegFile<=1'b1;
		end
		4'b1000: begin					       //JAL
			sel_MuxPCIn<=2'b00;			    //PC_Adder In PC
			sel_MuxPCIncr<=1'b0;	   	    // Though it is not required	
			sel_RegFileInp<=2'b11;
			sel_RegFileAddrInp<=2'b10;     // PC+1 In IR[11:9]
			sel_ALUInp1<=2'b11;			    // PC_Out in alu_1
			sel_ALUInp2<=2'b10;			    // +1 in alu_2
			Load_RegFile<=1'b1;
		end	
        4'b0100: begin                  // LW
            // used in EX
            sel_ALUInp2<=2'b11;
            // used in MEM
            Load_LW<=1'b1;              
	        Load_Z_Flag<=1'b1;	          // load zero flag
            // used in WB
            sel_RegFileInp<=2'b01;      // data_memory_reg->RF_data_inp
            sel_RegFileAddrInp<=2'b10;  // IR[11:9]->RF_addr_inp
            Load_RegFile<=1'b1;
        end
        4'b0110: begin                  // LM
            // used in RR
            sel_RegFileAddrOut[1]<=1'b1;// IR[11:9]->RF_addr1
            // used in EX
            sel_ALUInp1<=2'b01;         // MEM_alu_out -> alu_1(for other times)
                                        // first time handled in cpu
            sel_ALUInp2<=2'b10;         // 1 -> alu_2 (for other times)
            // used in WB
            sel_RegFileAddrInp<=2'b01;  // pe_out->RF_addr_inp
            sel_RegFileInp<=2'b01;      // data_memory_reg->RF_data_inp
            Load_PC<=is_one_hot_or_zero;
            Load_RegFile<=1'b1;
        end
        4'b0111: begin                  // SM
            // used in RR
            sel_RegFileAddrOut[1]<=1'b1;// IR[11:9]->RF_addr1, pe_out->RF_addr2
            // used in EX
            sel_ALUInp1<=2'b01;         // MEM_alu_out -> alu_1(for other times)
                                        // first time handled in cpu
            sel_ALUInp2<=2'b10;         // 1 -> alu_2 (for other times)
            // used in MEM
            DMem_wr<=1'b1;              // write to memory
            Load_PC<=is_one_hot_or_zero;				
        end
        default:                        // other instructions don't use R_READ
            sel_RegFileAddrOut<=2'b00;
    endcase
	 end
endmodule
