module control(
    opcode,
    funct7,
    reg_write,
    imm_data,
    opcode_alu,
    mem_to_reg,
    branch,
    wb_pc,
    cond_b,
    store,
    is_from_fpu,
    is_multiply,
    jalr,
    auipc,
    lui,
    is_fstore,
    is_hazard_0,
    use_rs1,
    use_rs2);

    input [6:0] opcode;
    input [6:0] funct7;
    output reg reg_write;
    output reg imm_data;
    output reg [1:0] opcode_alu;
    output mem_to_reg;
    output reg branch;
    output reg wb_pc;
    output cond_b;
    output store;
    output is_from_fpu;
    output is_multiply;
    output jalr;
    output auipc;
    output lui;
    output is_fstore;
    output is_hazard_0;
    output reg use_rs1;
    output reg use_rs2;

    wire is_ftoi;
    wire is_itof;

    assign is_from_fpu = is_ftoi;

    assign cond_b = (opcode == 7'b1100011); 
    assign store = ((opcode == 7'b0100011)|(opcode == 7'b0100111));
    assign mem_to_reg = (opcode == 7'b0000011);//load
    assign jalr = (opcode == 7'b1100111);
    assign lui = (opcode == 7'b0110111);
    assign auipc = (opcode == 7'b0010111);
    assign is_fstore = (opcode == 7'b0100111);
    assign is_ftoi = (opcode == 7'b1010011) & ((funct7[6:2] == 5'b11100) | (funct7[6:2] == 5'b11010) | (funct7[6:2] == 5'b10100));
    assign is_hazard_0 = is_ftoi | mem_to_reg | is_multiply;

    assign is_itof = (opcode == 7'b1010011) & ((funct7[6:2] == 5'b11000) | (funct7[6:2] == 5'b11110));
    assign is_multiply = (opcode == 7'b0110011) & (funct7 == 7'b0000001);


    always @(*) begin
        case(opcode[6:2])
            5'b00100: reg_write <= 1'b1;//op_imm
            5'b01100: reg_write <= 1'b1;//op
            5'b11011: reg_write <= 1'b1;//JAL
            5'b11001: reg_write <= 1'b1;//JALR
            5'b00000: reg_write <= 1'b1;//LOAD
            5'b01101: reg_write <= 1'b1; //lui
            5'b00101: reg_write <= 1'b1; //auipc
            default: reg_write <= (is_ftoi ? 1'b1 : 1'b0);
        endcase
    end

    always @ (*) begin
        case(opcode[6:2])
            5'b11001: use_rs1 <= 1'b1; //jalr
            5'b11000: use_rs1 <= 1'b1; //branch
            5'b00000: use_rs1 <= 1'b1; //load
            5'b01000: use_rs1 <= 1'b1; //store
            5'b00100: use_rs1 <= 1'b1; //opimm
            5'b01100: use_rs1 <= 1'b1; //op
            5'b00001: use_rs1 <= 1'b1; //fload
            5'b01001: use_rs1 <= 1'b1; //fstore
            default:  use_rs1 <= is_itof;
        endcase
    end

    always @ (*) begin
        case(opcode[6:2])
            5'b11000: use_rs2 <= 1'b1; //branch
            5'b01000: use_rs2 <= 1'b1; //store
            5'b01100: use_rs2 <= 1'b1; //op
            5'b01001: use_rs2 <= 1'b1; //fstore
            default:  use_rs2 <= 1'b0;
        endcase
    end


    //jal use immediate directly.
    always @(*) begin
        case(opcode[6:2]) 
            5'b00100: imm_data <= 1'b1;//opimm
            5'b00000: imm_data <= 1'b1;//load
            5'b01000: imm_data <= 1'b1;//store
            5'b00001: imm_data <= 1'b1;//fload
            5'b01001: imm_data <= 1'b1;//fstore
            5'b11001: imm_data <= 1'b1;//jalr
            5'b01100: imm_data <= 1'b0;//op
            5'b01101: imm_data <= 1'b1; //lui
            5'b00101: imm_data <= 1'b1; //auipc
            default: imm_data <= 1'b0;
        endcase
    end

    // 2'b10 always alu add
    always @(*) begin
        case(opcode[6:2])
            5'b00100: opcode_alu <= 2'b01; //opimm
            5'b01100: opcode_alu <= 2'b11; // op
            5'b11000: opcode_alu <= 2'b00; //BRANCH
            5'b11001: opcode_alu <= 2'b10; //jalr
            default: opcode_alu <= 2'b10;
        endcase
    end


    always @(*) begin
        case(opcode[6:2])
            5'b11011: {branch,wb_pc} <= 2'b11; //jal
            5'b11001: {branch,wb_pc} <= 2'b11; //jalr
            5'b11000: {branch,wb_pc} <= 2'b10; //conditinoal branch
            default: {branch,wb_pc} <= 2'b00;
        endcase
    end



endmodule
