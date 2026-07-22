`ifndef I2C_SCOREBOARD_SV
`define I2C_SCOREBOARD_SV

`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

class I2C_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(I2C_scoreboard)

    uvm_analysis_imp #(I2C_seq_item, I2C_scoreboard) ap_imp;

    logic [31:0] ref_mem[logic [31:0]];

    int num_tx = 0;
    int num_errors = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp", this);
    endfunction

    function void write(I2C_seq_item tx);
        num_tx++;

        if (tx.is_write) begin
            if (tx.addr == 32'h8) begin
                `uvm_info("SCB_IGNORE",
                          $sformatf("Addr: 0x8 = Read-Only ignored the Write"),
                          UVM_HIGH)
            end

            ref_mem[tx.addr] = tx.wdata;
            `uvm_info("SCB_WRITE",
                      $sformatf(
                          "메모리 업데이트 - Addr: 0x%0x, Data: 0x%0x",
                          tx.addr, tx.wdata), UVM_LOW)
        end else begin
            if (tx.addr == 32'h8 || tx.addr == 32'h4) begin
                `uvm_info(
                    "SCB_SKIP",
                    $sformatf(
                        "Addr: 0x%0x는 직접 비교 생략 (Status/FIFO Reg)",
                        tx.addr), UVM_HIGH)
                return;
            end
            if (!ref_mem.exists(tx.addr)) begin
                `uvm_warning(
                    "SCB_WARN",
                    $sformatf(
                        "초기화되지 않은 주소(0x%0x) Read 시도! (Reset 값 검사 생략)",
                        tx.addr))
                return;
            end else if (ref_mem[tx.addr] === tx.rdata) begin
                `uvm_info(
                    "SCB_PASS",
                    $sformatf(
                        "PASS! Addr: 0x%0x | 기대값: 0x%0x, 실제값: 0x%0x",
                        tx.addr, ref_mem[tx.addr], tx.rdata), UVM_LOW)
            end else begin
                num_errors++;
                `uvm_error("SCB_FAIL", $sformatf(
                           "FAIL! Addr: 0x%0x | 기대값: 0x%0x, 실제값: 0x%0x",
                           tx.addr,
                           ref_mem[tx.addr],
                           tx.rdata
                           ))
            end
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        string result = (num_errors == 0 && num_tx > 0) ? "*** PASS ***" : "*** FAIL ***";

        `uvm_info(get_type_name(),
                  "\n=========== Scoreboard Summary ==========", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Test Result    : %s", result),
                  UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total Transact : %0d", num_tx),
                  UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total Errors   : %0d", num_errors
                  ), UVM_LOW)
        `uvm_info(get_type_name(),
                  "=========================================\n", UVM_LOW)
    endfunction

endclass  // I2C_scoreboard

`endif
