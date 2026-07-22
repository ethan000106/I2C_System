`ifndef I2C_DRIVER_SV
`define I2C_DRIVER_SV

`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "seq_item.sv"

class I2C_driver extends uvm_driver #(I2C_seq_item);
    `uvm_component_utils(I2C_driver)

    virtual I2C_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual I2C_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Driver에서 vif config_db 에러 발생!!!")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        init_signals();
        
        // Reset 대기 (rst_n이 1이 될 때까지 대기)
        wait(vif.rst_n == 1'b1);
        `uvm_info(get_type_name(), "Driver 초기화 완료 (AXI 모드), Transaction 대기 중...", UVM_MEDIUM)

        forever begin
            I2C_seq_item tx;
            seq_item_port.get_next_item(tx);

            // Write/Read 플래그에 따라 AXI 통신 분기
            if (tx.is_write == 1'b1) begin
                drive_axi_write(tx);
            end else begin
                drive_axi_read(tx);
            end

            seq_item_port.item_done();
        end
    endtask

    // 1. AXI 신호 초기화
    task init_signals();
        vif.s00_axi_awvalid <= 1'b0;
        vif.s00_axi_wvalid  <= 1'b0;
        vif.s00_axi_bready  <= 1'b0;
        vif.s00_axi_arvalid <= 1'b0;
        vif.s00_axi_rready  <= 1'b0;
    endtask

    // 2. AXI Write 통신 (SW가 I2C IP의 레지스터에 값을 쓸 때)
    task drive_axi_write(I2C_seq_item tx);
        `uvm_info(get_type_name(), $sformatf("[AXI WRITE 시작] Addr: 0x%0x, Data: 0x%0x", tx.addr, tx.wdata), UVM_LOW)
        
        @(posedge vif.clk);
        vif.s00_axi_awaddr  <= tx.addr;
        vif.s00_axi_awvalid <= 1'b1;
        
        vif.s00_axi_wdata   <= tx.wdata;
        vif.s00_axi_wstrb   <= 4'hF; // 32bit 모두 유효함
        vif.s00_axi_wvalid  <= 1'b1;
        
        vif.s00_axi_bready  <= 1'b1;

        // awready와 wready가 모두 1이 되어 IP가 데이터를 받을 때까지 대기
        wait(vif.s00_axi_awready == 1'b1 && vif.s00_axi_wready == 1'b1);
        
        @(posedge vif.clk);
        vif.s00_axi_awvalid <= 1'b0;
        vif.s00_axi_wvalid  <= 1'b0;

        // bvalid (응답) 대기
        wait(vif.s00_axi_bvalid == 1'b1);
        tx.resp = vif.s00_axi_bresp; // 응답 상태 저장
        
        @(posedge vif.clk);
        vif.s00_axi_bready  <= 1'b0;
        
        `uvm_info(get_type_name(), "[AXI WRITE 완료]", UVM_HIGH)
    endtask

    // 3. AXI Read 통신 (SW가 I2C IP의 레지스터에서 값을 읽을 때)
    task drive_axi_read(I2C_seq_item tx);
        `uvm_info(get_type_name(), $sformatf("[AXI READ 시작] Addr: 0x%0x", tx.addr), UVM_LOW)
        
        @(posedge vif.clk);
        vif.s00_axi_araddr  <= tx.addr;
        vif.s00_axi_arvalid <= 1'b1;
        vif.s00_axi_rready  <= 1'b1;

        // arready 대기
        wait(vif.s00_axi_arready == 1'b1);
        @(posedge vif.clk);
        vif.s00_axi_arvalid <= 1'b0;

        // rvalid (데이터 도착) 대기
        wait(vif.s00_axi_rvalid == 1'b1);
        tx.rdata = vif.s00_axi_rdata; // 읽어온 데이터 저장
        tx.resp  = vif.s00_axi_rresp;
        
        @(posedge vif.clk);
        vif.s00_axi_rready  <= 1'b0;
        
        `uvm_info(get_type_name(), $sformatf("[AXI READ 완료] 읽은 Data: 0x%0x", tx.rdata), UVM_HIGH)
    endtask

endclass  // I2C_driver

`endif