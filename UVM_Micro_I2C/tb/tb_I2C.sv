`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "test.sv"
`include "interface.sv"

module tb_I2C;

    logic aclk;
    logic aresetn;

    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    initial begin
        aresetn = 0;
        #100 aresetn = 1;
    end

    wire scl_bus;
    wire sda_bus;

    pullup (scl_bus);
    pullup (sda_bus);

    I2C_if i2c_vif (
        .clk  (aclk),
        .rst_n(aresetn)
    );

    assign i2c_vif.scl = scl_bus;
    assign i2c_vif.sda = sda_bus;

    i2c_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(4)
    ) u_dut (
        .scl(scl_bus),
        .sda(sda_bus),

        .s00_axi_aclk   (aclk),
        .s00_axi_aresetn(aresetn),

        .s00_axi_awaddr (i2c_vif.s00_axi_awaddr),
        .s00_axi_awprot (i2c_vif.s00_axi_awprot),
        .s00_axi_awvalid(i2c_vif.s00_axi_awvalid),
        .s00_axi_awready(i2c_vif.s00_axi_awready),

        .s00_axi_wdata (i2c_vif.s00_axi_wdata),
        .s00_axi_wstrb (i2c_vif.s00_axi_wstrb),
        .s00_axi_wvalid(i2c_vif.s00_axi_wvalid),
        .s00_axi_wready(i2c_vif.s00_axi_wready),

        .s00_axi_bresp (i2c_vif.s00_axi_bresp),
        .s00_axi_bvalid(i2c_vif.s00_axi_bvalid),
        .s00_axi_bready(i2c_vif.s00_axi_bready),

        .s00_axi_araddr (i2c_vif.s00_axi_araddr),
        .s00_axi_arprot (i2c_vif.s00_axi_arprot),
        .s00_axi_arvalid(i2c_vif.s00_axi_arvalid),
        .s00_axi_arready(i2c_vif.s00_axi_arready),

        .s00_axi_rdata (i2c_vif.s00_axi_rdata),
        .s00_axi_rresp (i2c_vif.s00_axi_rresp),
        .s00_axi_rvalid(i2c_vif.s00_axi_rvalid),
        .s00_axi_rready(i2c_vif.s00_axi_rready)
    );

    logic [7:0] slv_tx_data, slv_rx_data;
    logic [3:0] slv_fnd_digit;
    logic [7:0] slv_fnd_data;
    logic       slv_ack_in, slv_ack_out;

    i2c_slave u_slave (
        .clk      (aclk),
        .rst      (!aresetn),     
        .scl      (scl_bus),
        .sda      (sda_bus),
        .ack_out  (slv_ack_out),
        .tx_data  (slv_tx_data),
        .rx_data  (slv_rx_data),
        .ack_in   (slv_ack_in),
        .fnd_digit(slv_fnd_digit),
        .fnd_data (slv_fnd_data)
    );

    initial begin
        uvm_config_db#(virtual I2C_if)::set(null, "*", "vif", i2c_vif);
        run_test();
    end

    initial begin
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, tb_I2C, "+all");
    end

endmodule