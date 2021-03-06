module uart_rcv(clk, rxd,data,receive);
    input clk,rxd;
    output data;
    output reg receive = 1'b0;

    reg [3:0] buffer = 4'b1111;
    reg [3:0] rcv_data = 3'b111;
    reg is_rcv = 1'b0;
    reg [1:0] clk_count = 2'b0;
    reg [4:0] data_count = 4'b0;
    reg [7:0] in_data = 8'b0;
    reg [7:0] data = 8'b0;


    always @(posedge clk ) begin
        buffer <= {buffer[2:0],rxd};
        rcv_data <= {rcv_data[2:0],buffer[3]};
        if( is_rcv == 1'b0) begin
            receive <= 1'b0;
            if (rcv_data[2:0] == 3'b000) begin
                is_rcv <= 1'b1;
                clk_count <= 2'b0;
            end
        end
        else begin
            clk_count <= (clk_count==2'b11) ? 2'b0: clk_count+2'b1;
            if(clk_count == 2'b01) begin
                in_data <= {rcv_data[2],in_data[7:1]};
                if (data_count == 4'b1001) begin
                    data <= in_data;
                    data_count <= 4'b0;
                    is_rcv <= 1'b0;
                    receive <= 1'b1;
                    end
                    else
                        data_count <= data_count + 4'b1;
            end
        end
    end

endmodule