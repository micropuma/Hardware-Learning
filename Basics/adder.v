module top_module(
    input [31:0] a,
    input [31:0] b,
    output [31:0] sum
);
    wire carry_out;
    wire[15:0] sum_low, sum_high, sum_high1, sum_high2;
    
    add16 instance1(a[15:0], b[15:0], 1'b0, sum_low, carry_out);
    add16 instance2(a[31:16], b[31:16], 1'b0, sum_high1);
    add16 instance3(a[31:16], b[31:16], 1'b1, sum_high2);
    
    always @(*) begin 
        case(carry_out)
            1'b0: sum_high = sum_high1;
            1'b1: sum_high = sum_high2;
        endcase
    end
    
    assign sum = {sum_high, sum_low};
endmodule