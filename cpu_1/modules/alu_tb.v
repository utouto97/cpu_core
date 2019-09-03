`timescale 1 ns/ 1ps
module alu_tb();
    reg [31:0] data1;
    reg [31:0] data2;
    reg [3:0] ctrl;
    wire [31:0] out;

    alu u1(data1, data2, out,ctrl);

    initial begin
        ctrl <= 4'd0;
        #10;
        data1 <= -32'd1023;
        data2 <= 32'b11000011;
        #10;
        ctrl <= 4'd11;
        #10;
        ctrl <= 4'd12;
        #10;
        ctrl <= 4'd13;
    end
endmodule