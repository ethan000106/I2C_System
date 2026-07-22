`timescale 1ns/1ps

module i2c_slave (
    input  logic       clk,
    input  logic       rst,
    input  logic       ack_out,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       ack_in,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data,
    input  logic       scl,
    inout  wire        sda
);
    logic sda_in;
    assign sda_in = sda;
    assign sda    = 1'bz;

    logic scl_d1, scl_d2, scl_d3;
    logic sda_d1, sda_d2, sda_d3;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_d1<=1; scl_d2<=1; scl_d3<=1;
            sda_d1<=1; sda_d2<=1; sda_d3<=1;
        end else begin
            scl_d1<=scl;    scl_d2<=scl_d1; scl_d3<=scl_d2;
            sda_d1<=sda_in; sda_d2<=sda_d1; sda_d3<=sda_d2;
        end
    end

    
    logic scl_rise, scl_fall, sda_fall, sda_rise;
    assign scl_rise = (~scl_d3) & scl_d2;
    assign scl_fall = scl_d3 & (~scl_d2);
    assign sda_fall = sda_d3 & (~sda_d2);
    assign sda_rise = (~sda_d3) & sda_d2;

    
    logic start_cond, stop_cond;
    assign start_cond = scl_d2 & sda_fall;  
    assign stop_cond  = scl_d2 & sda_rise;  

    // FSM
    typedef enum logic [1:0] {
        IDLE, ADDR, DATA, ACK
    } state_e;
    state_e state;

    logic [7:0] shift_reg;
    logic [7:0] rx_data_r;
    logic [3:0] bit_cnt; 

    assign rx_data = rx_data_r;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            shift_reg <= 0;
            rx_data_r <= 0;
            bit_cnt   <= 0;
            ack_in    <= 1;
        end else begin
            if (start_cond) begin
                state   <= ADDR;
                bit_cnt <= 0;
                shift_reg <= 0;
            end else if (stop_cond) begin
                state <= IDLE;
            end else begin
                case (state)
                    IDLE: begin

                    end

                    ADDR: begin
                        if (scl_rise) begin
                            if (bit_cnt == 7) begin
                                state   <= ACK;
                                bit_cnt <= 0;
                                shift_reg <= 0;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end

                    ACK: begin
                        if (scl_rise) begin
                            state   <= DATA;
                            bit_cnt <= 0;
                            shift_reg <= 0;
                        end
                    end

                    DATA: begin
                        if (scl_rise) begin
                            shift_reg <= {shift_reg[6:0], sda_d2};
                            if (bit_cnt == 7) begin
                                rx_data_r <= {shift_reg[6:0], sda_d2};
                                state     <= IDLE;
                                bit_cnt   <= 0;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                endcase
            end
        end
    end

    fnd_controller U_FND (
        .fnd_in_data({6'd0, rx_data_r}),
        .clk(clk),
        .reset(rst),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

endmodule


module fnd_controller (
    input [13:0] fnd_in_data,  // WDATA
    input clk,
    input reset,
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);
    wire [1:0] w_digit_sel;
    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
    wire [3:0] w_mux_4_1_out;
    wire w_1kz;

    clk_div U_CLK_DIV (
        .clk(clk),
        .reset(reset),
        .o_1khz(w_1kz)
    );


    counter_4 U_COUNTER_4 (
        .clk(w_1kz),
        .reset(reset),
        .digit_sel(w_digit_sel)
    );

    decoder_2_4 U_DECODER_2_4 (
        .btn(w_digit_sel),
        .fnd_digit(fnd_digit)
    );


    digit_splitter U_DIGIT_SPL (
        .in_data(fnd_in_data),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );


    mux4_1 U_MUX_4_1 (
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .sel(w_digit_sel),
        .mux_out(w_mux_4_1_out)
    );



    bcd U_BCD (
        .bcd(w_mux_4_1_out),
        .fnd_data(fnd_data)
    );


endmodule

module clk_div (
    input clk,
    input reset,
    output reg o_1khz
);
    reg [16:0] counter_r;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 1'b0;
            o_1khz <= 1'b0;
        end else begin
            if (counter_r == 99999) begin
                counter_r <= 0;
                o_1khz <= 1'b1;
            end else begin
                counter_r <= counter_r + 1;
                o_1khz <= 1'b0;
            end
        end


    end

endmodule

module counter_4 (
    input        clk,
    input        reset,
    output [1:0] digit_sel
);
    reg [1:0] counter_r;

    assign digit_sel = counter_r;

    always @(posedge clk, posedge reset) begin
        if (reset) counter_r <= 0;
        else begin
            counter_r <= counter_r + 1;
        end
    end



endmodule



module decoder_2_4 (
    input [1:0] btn,
    output reg [3:0] fnd_digit
);

    always @(btn) begin
        case (btn)
            2'b00:   fnd_digit = 4'b1110;
            2'b01:   fnd_digit = 4'b1101;
            2'b10:   fnd_digit = 4'b1011;
            default: fnd_digit = 4'b0111;
        endcase
    end

endmodule


module mux4_1 (
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    input [1:0] sel,
    output reg [3:0] mux_out
);


    always @(*) begin
        case (sel)
            2'b00:   mux_out = digit_1;
            2'b01:   mux_out = digit_10;
            2'b10:   mux_out = digit_100;
            default: mux_out = digit_1000;
        endcase


    end



endmodule





module digit_splitter (
    input  [13:0] in_data,    // 최대 16383까지 입력 가능
    output [ 3:0] digit_1,    // 1의 자리
    output [ 3:0] digit_10,   // 10의 자리
    output [ 3:0] digit_100,  // 100의 자리
    output [ 3:0] digit_1000  // 1000의 자리
);

    assign digit_1    =  in_data % 10;
    assign digit_10   = (in_data / 10) % 10;
    assign digit_100  = (in_data / 100) % 10;
    assign digit_1000 = (in_data / 1000) % 10;

endmodule


module bcd (
    input      [3:0] bcd,
    output reg [7:0] fnd_data
);

    always @(bcd) begin
        case (bcd)
            // 4'd0: fnd_data = 8'hC0;
            // 4'd1: fnd_data = 8'hf9;
            // 4'd2: fnd_data = 8'ha4;
            // 4'd3: fnd_data = 8'hB0;
            // 4'd4: fnd_data = 8'h99;
            // 4'd5: fnd_data = 8'h92;
            // 4'd6: fnd_data = 8'h82;
            // 4'd7: fnd_data = 8'hf8;
            // 4'd8: fnd_data = 8'h80;
            // 4'd9: fnd_data = 8'h90;
            // default: fnd_data = 8'hFF;
            4'h0: fnd_data = 8'hC0;  // 0
            4'h1: fnd_data = 8'hF9;  // 1
            4'h2: fnd_data = 8'hA4;  // 2
            4'h3: fnd_data = 8'hB0;  // 3
            4'h4: fnd_data = 8'h99;  // 4
            4'h5: fnd_data = 8'h92;  // 5
            4'h6: fnd_data = 8'h82;  // 6
            4'h7: fnd_data = 8'hF8;  // 7 
            4'h8: fnd_data = 8'h80;  // 8
            4'h9: fnd_data = 8'h90;  // 9
            4'hA: fnd_data = 8'h88;  // A
            4'hB: fnd_data = 8'h83;  // b (소문자)
            4'hC: fnd_data = 8'hC6;  // C
            4'hD: fnd_data = 8'hA1;  // d (소문자)
            4'hE: fnd_data = 8'h86;  // E
            4'hF: fnd_data = 8'h8E;  // F
            default: fnd_data = 8'hFF;  // 화면 끄기 (All OFF)
        endcase
    end
endmodule