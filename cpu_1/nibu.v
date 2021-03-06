module nibu (
    clk,
    show,
    segment7_1,
    segment7_2,
    segment7_3,
    segment7_4,
    segment7_5,
    segment7_6,
    uart_empty,
    uart_full,
    uart_in,
    uart_out,
    uart_rdreq,
    uart_wrreq,
    fifo_wr_data,
    fifo_wr,
    fifo_wr_addr,
    fifo_wr_full,
    fifo_rd_data,
    fifo_rd,
    fifo_rd_addr,
    fifo_rd_empty);

    input clk;
    output [9:0] show;
    output [6:0] segment7_1;
    output [6:0] segment7_2;
    output [6:0] segment7_3;
    output [6:0] segment7_4;
    output [6:0] segment7_5;
    output [6:0] segment7_6;
    input uart_empty;
    input uart_full;
    input [7:0] uart_in;
    output [7:0] uart_out;
    output uart_wrreq;
    output uart_rdreq;
    output [15:0] fifo_wr_data;
    output fifo_wr;
    output [24:0] fifo_wr_addr;
    input fifo_wr_full;
    input [15:0] fifo_rd_data;
    output fifo_rd;
    output [24:0] fifo_rd_addr;
    input fifo_rd_empty;

    reg [31:0] show_buf;

    wire clken;
    wire [31:0] address;
    wire [31:0] pc_out;
    reg [31:0] address_buf = 32'b0;
    reg [31:0] address_buf2 = 32'b0;
    wire [31:0] next_address;
    wire [31:0] next_address_immjump;
    wire [31:0] next_address_jump;
    wire [31:0] chosen_next_address;
    reg [31:0] next_address_d1 = 32'b0;
    reg [31:0] next_address_d2 = 32'b0;
    wire [31:0] inst;
    wire [31:0] write_data;
    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] read_data1_fetched;
    wire [31:0] read_data2_fetched;
    reg [4:0] rsi1_buf;
    reg [4:0] rsi2_buf;
    wire [31:0] immediate;
    reg [31:0] immediate_buf;
    wire [31:0] operand1;
    wire [31:0] operand2;
    wire [31:0] alu_res;
    wire [31:0] mul_out;
    reg [31:0] alu_res_buf;
    wire [31:0] memory_read;
    wire [15:0] seg_io;
    wire [31:0] from_intreg;
    wire [31:0] from_mem;
    wire [31:0] into_mem;
    wire [31:0] into_intreg;
    wire [31:0] memory_write;
    reg [31:0] memory_write_d1;
    reg [31:0] alu_res_d1;

    reg [4:0] rdi_buffer [0:2];
    reg [2:0] funct3_buf [0:2];
    reg [31:0] result [0:2];
    wire [31:0] to_result [0:2];

    wire is_regwrite;
    wire is_use_imme;
    wire is_memtoreg;
    wire is_pc_toreg;
    wire is_branchop;
    wire is_cond_bra;
    wire is_fstoreop;
    wire is_memwrite;
    wire is_legal_op;
    wire is_hazard_0;
    wire is_from_fpu;
    wire is_multiply;
    wire is_jalr;
    wire is_auipc;
    wire is_lui;

    reg [2:0] is_regwrite_buf = 3'b0;
    reg [2:0] is_use_imme_buf = 3'b0;
    reg [2:0] is_memtoreg_buf = 3'b0;
    reg [2:0] is_pc_toreg_buf = 3'b0;
    reg [2:0] is_branchop_buf = 3'b0;
    reg [2:0] is_cond_bra_buf = 3'b0;
    reg [2:0] is_fstoreop_buf = 3'b0;
    reg [2:0] is_memwrite_buf = 3'b0;
    reg [2:0] is_legal_op_buf = 3'b0;
    reg [2:0] is_hazard_0_buf = 3'b0;
    reg [2:0] is_from_fpu_buf = 3'b0;
    reg [2:0] is_multiply_buf = 3'b0;
    reg [2:0] is_jalr_buf     = 3'b0;
    reg [2:0] is_auipc_buf    = 3'b0;
    reg [2:0] is_lui_buf      = 3'b0;


    wire reg_write_1;
    wire reg_write_2;
    wire [1:0] opcode_alu_ctrl;
    wire [3:0] alu_ctrl;
    reg [3:0] alu_ctrl_buf = 4'b0;
    wire do_branch;
    reg [2:0] do_branch_buf = 3'b0;
    wire rg1_forward_1;
    wire rg2_forward_1;
    wire rg1_forward_2;
    wire rg2_forward_2;

    wire fpu_hazard;
    wire alu_hazard;
    wire hazard;
    wire use_rs1;
    wire use_rs2;

    assign hazard = fpu_hazard | alu_hazard;

    assign show = {show_buf[5:0],4'b0};

    assign do_branch = is_branchop_buf[0] & is_legal_op_buf[0] & ((~is_cond_bra_buf[0])|alu_res[0]);
    assign is_legal_op = (~do_branch) & (~do_branch_buf[0]) & (~hazard);

    seg7 seg7_1(address[5:2],segment7_1);
    seg7 seg7_2(address[9:6],segment7_2);
    seg7 seg7_3(seg_io[3:0],segment7_3);
    seg7 seg7_4(seg_io[7:4],segment7_4);
    seg7 seg7_5(seg_io[11:8],segment7_5);
    seg7 seg7_6(seg_io[15:12],segment7_6);

    FPU FPU1(clken,clk,is_legal_op,inst,from_intreg,from_mem,into_mem,into_intreg,fpu_hazard);
    assign from_intreg = read_data1;
    assign from_mem = memory_read;
    mux mux_memwrite(read_data2,into_mem,memory_write,is_fstoreop_buf[0]);

    pc pc1(clken,clk,chosen_next_address,pc_out);
    add add1(address,32'b100,next_address);
    add add_jump(address_buf2,immediate_buf,next_address_immjump);//imm_buff is delay 2clk;
    mux mux_jalr(next_address_immjump,alu_res,next_address_jump,is_jalr_buf[0]);
    mux mux_pc(next_address,next_address_jump,chosen_next_address,do_branch);
    assign address = (hazard & (~do_branch_buf[0])) ? address_buf : pc_out;


    assign reg_write_2 = is_regwrite_buf[2] & is_legal_op_buf[2];
    assign reg_write_1 = is_regwrite_buf[1] & is_legal_op_buf[1];

    hazard_detect hazard_detect1(
        inst[19:15],
        inst[24:20],
        use_rs1,
        use_rs2,
        is_regwrite_buf[0],
        is_legal_op_buf[0],
        is_hazard_0_buf[0],
        rdi_buffer[0],
        alu_hazard
    );

    registers regs1(
        clken,
        clk,
        inst[19:15],
        inst[24:20],
        rdi_buffer[2],
        write_data,
        read_data1_fetched,
        read_data2_fetched,
        reg_write_2);

    forward_ctrl forward_ctrl1(
        rsi1_buf,
        rsi2_buf,
        rdi_buffer[1],
        reg_write_1,
        rdi_buffer[2],
        reg_write_2,
        rg1_forward_1,
        rg1_forward_2,
        rg2_forward_1,
        rg2_forward_2);

    mux_reg mux_readdata1(
        read_data1_fetched,
        result[1],
        write_data,
        read_data1,
        rg1_forward_1,
        rg1_forward_2,
        (rsi1_buf == 5'b0)
    );
    mux_reg mux_readdata2(
        read_data2_fetched,
        result[1],
        write_data,
        read_data2,
        rg2_forward_1,
        rg2_forward_2,
        (rsi2_buf == 5'b0)
    );
    

    immgen ig1(inst,immediate);
    control ctr1(
        inst[6:0],
        inst[31:25],
        is_regwrite,
        is_use_imme,
        opcode_alu_ctrl,
        is_memtoreg,
        is_branchop,
        is_pc_toreg,
        is_cond_bra,
        is_memwrite,
        is_from_fpu,
        is_multiply,
        is_jalr,
        is_auipc,
        is_lui,
        is_fstoreop,
        is_hazard_0,
        use_rs1,
        use_rs2);

    mod_readdata mod_readdata1(read_data1,address_buf2,is_auipc_buf[0],is_lui_buf[0],operand1);
    mux mux1(read_data2,immediate_buf,operand2,is_use_imme_buf[0]);
    alu_control ac1({inst[30],inst[14:12]},opcode_alu_ctrl,alu_ctrl);
    alu alu1(operand1,operand2,alu_res,alu_ctrl_buf);
    mul_unit mul_unit1(clken,clk,operand1,operand2,funct3_buf[0],mul_out);

    memory mem1(clk,
        funct3_buf[1],
        address,inst,
        alu_res_d1,memory_write_d1,memory_read, 
        is_memwrite_buf[1] & is_legal_op_buf[1],
        is_memtoreg_buf[1] & is_legal_op_buf[1],//readctrl
        uart_empty,
        uart_full,
        uart_in,
        uart_out,
        uart_wrreq,
        uart_rdreq,
        seg_io,
        clken,
        fifo_wr_data,
        fifo_wr,
        fifo_wr_addr,
        fifo_wr_full,
        fifo_rd_data,
        fifo_rd,
        fifo_rd_addr,
        fifo_rd_empty);

    assign to_result[1] = is_pc_toreg_buf[0] ? next_address_d2
                        : alu_res;
    assign to_result[2] = is_from_fpu_buf[1] ? into_intreg
                        : result[1];

    assign write_data   = is_memtoreg_buf[2] ? memory_read
                        : is_multiply_buf[2] ? mul_out
                        : result[2];

    /*
    mux_writedata mux_writedata1(
        alu_res_buf,
        next_address_d3,
        into_intreg,
        memory_read,
        is_pc_toreg_buf[1],
        enable_ftoi,
        is_memtoreg_buf[1],
        write_data);
    */


    always @ (posedge clk) begin
        if (clken) begin
            next_address_d1 <= next_address;
            next_address_d2 <= next_address_d1;
            address_buf <= address;
            address_buf2 <= address_buf;
            immediate_buf <= immediate;
            rsi1_buf <= inst[19:15];
            rsi2_buf <= inst[24:20];
            alu_ctrl_buf <= alu_ctrl;
            do_branch_buf <= {do_branch_buf[1:0],do_branch};
            alu_res_d1 <= alu_res;
            show_buf <= alu_res;

            memory_write_d1 <= memory_write;


            rdi_buffer[0] <= inst[11:7];
            rdi_buffer[1] <= rdi_buffer[0];
            rdi_buffer[2] <= rdi_buffer[1];

            funct3_buf[0] <= inst[14:12];
            funct3_buf[1] <= funct3_buf[0];
            funct3_buf[2] <= funct3_buf[1];

            result[0] <= to_result[0];
            result[1] <= to_result[1];
            result[2] <= to_result[2];

            is_regwrite_buf <= {is_regwrite_buf[1:0],is_regwrite};
            is_use_imme_buf <= {is_use_imme_buf[1:0],is_use_imme};
            is_memtoreg_buf <= {is_memtoreg_buf[1:0],is_memtoreg};
            is_pc_toreg_buf <= {is_pc_toreg_buf[1:0],is_pc_toreg};
            is_branchop_buf <= {is_branchop_buf[1:0],is_branchop};
            is_cond_bra_buf <= {is_cond_bra_buf[1:0],is_cond_bra};
            is_fstoreop_buf <= {is_fstoreop_buf[1:0],is_fstoreop};
            is_memwrite_buf <= {is_memwrite_buf[1:0],is_memwrite};
            is_legal_op_buf <= {is_legal_op_buf[1:0],is_legal_op};
            is_hazard_0_buf <= {is_hazard_0_buf[1:0],is_hazard_0};
            is_from_fpu_buf <= {is_from_fpu_buf[1:0],is_from_fpu};
            is_multiply_buf <= {is_multiply_buf[1:0],is_multiply};
            is_jalr_buf     <= {is_jalr_buf[1:0],is_jalr};
            is_auipc_buf    <= {is_auipc_buf[1:0],is_auipc};
            is_lui_buf      <= {is_lui_buf[1:0],is_lui};
        end
    end
endmodule