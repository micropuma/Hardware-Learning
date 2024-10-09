module our(clk);
	input clk;
	always @(posedge clk)
		begin 
			$display("Hellow World"); $finish;
		end 
endmodule
		
