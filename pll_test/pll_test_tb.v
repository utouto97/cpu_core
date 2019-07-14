`timescale 1 ns /1 ps

module pll_test_tb();
	reg clk;
	wire out;
	
	pll_test u1(clk,out);
	
	
	initial begin
		#500 $finish;
	end
	
	initial clk = 1'b0;
	always #10	
		clk <= ~clk;
endmodule