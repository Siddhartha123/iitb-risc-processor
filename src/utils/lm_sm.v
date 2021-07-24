module lm_sm(is_one_hot_or_zero, instruction);
    output reg is_one_hot_or_zero;
    input [7:0] instruction;
    always @(instruction[7:0]) begin
        case(instruction[7:0])
            0,1,2,4,8,16,32,64,128:
            is_one_hot_or_zero <= 1'b1;
            default:
            is_one_hot_or_zero <= 1'b0;
        endcase
    end
endmodule
