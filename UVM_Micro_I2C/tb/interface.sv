`ifndef I2C_IF_SV
`define I2C_IF_SV

interface I2C_if (
    input logic clk,
    input logic rst_n
);

    wire scl; 
    wire sda;

    logic [31:0] s00_axi_awaddr;
    logic [2:0]  s00_axi_awprot;
    logic        s00_axi_awvalid;
    logic        s00_axi_awready;
    
    logic [31:0] s00_axi_wdata;
    logic [3:0]  s00_axi_wstrb;
    logic        s00_axi_wvalid;
    logic        s00_axi_wready;
    
    logic [1:0]  s00_axi_bresp;
    logic        s00_axi_bvalid;
    logic        s00_axi_bready;
    
    logic [31:0] s00_axi_araddr;
    logic [2:0]  s00_axi_arprot;
    logic        s00_axi_arvalid;
    logic        s00_axi_arready;
    
    logic [31:0] s00_axi_rdata;
    logic [1:0]  s00_axi_rresp;
    logic        s00_axi_rvalid;
    logic        s00_axi_rready;


endinterface  // I2C_if

`endif