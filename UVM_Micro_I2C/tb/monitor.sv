`ifndef MONITOR_SV
`define MONITOR_SV

`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "seq_item.sv"

class I2C_monitor extends uvm_monitor;
    `uvm_component_utils(I2C_monitor)

    uvm_analysis_port #(I2C_seq_item) ap;
    virtual I2C_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual I2C_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Monitor에서 virtual interface(vif)를 가져오지 못했습니다.")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "AXI Bus Monitoring 시작", UVM_MEDIUM)

        // Reset 대기
        wait(vif.rst_n == 1'b1);

        forever begin
            @(posedge vif.clk);
            
            // 1. AXI Write Handshake 감지 (awvalid & awready)
            if (vif.s00_axi_awvalid === 1'b1 && vif.s00_axi_awready === 1'b1) begin
                I2C_seq_item tx = I2C_seq_item::type_id::create("tx");
                tx.is_write = 1'b1;
                tx.addr = vif.s00_axi_awaddr;
                
                // 데이터가 써질 때까지(wvalid & wready) 대기
                while (!(vif.s00_axi_wvalid === 1'b1 && vif.s00_axi_wready === 1'b1)) begin
                    @(posedge vif.clk);
                end
                tx.wdata = vif.s00_axi_wdata;
                
                `uvm_info(get_type_name(), $sformatf("AXI WRITE 캡처 완료 - Addr: 0x%0x, wData: 0x%0x", tx.addr, tx.wdata), UVM_LOW)
                ap.write(tx); // 스코어보드로 전송
            end
            
            // 2. AXI Read Handshake 감지 (arvalid & arready)
            else if (vif.s00_axi_arvalid === 1'b1 && vif.s00_axi_arready === 1'b1) begin
                I2C_seq_item tx = I2C_seq_item::type_id::create("tx");
                tx.is_write = 1'b0;
                tx.addr = vif.s00_axi_araddr;
                
                // 데이터가 읽혀질 때까지(rvalid & rready) 대기
                while (!(vif.s00_axi_rvalid === 1'b1 && vif.s00_axi_rready === 1'b1)) begin
                    @(posedge vif.clk);
                end
                tx.rdata = vif.s00_axi_rdata;
                
                `uvm_info(get_type_name(), $sformatf("AXI READ 캡처 완료  - Addr: 0x%0x, rData: 0x%0x", tx.addr, tx.rdata), UVM_LOW)
                ap.write(tx); // 스코어보드로 전송
            end
        end
    endtask

endclass  // I2C_monitor

`endif