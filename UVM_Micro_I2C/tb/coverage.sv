`ifndef COVERAGE_SV
`define COVERAGE_SV

`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "seq_item.sv"

class I2C_coverage extends uvm_subscriber #(I2C_seq_item);
    `uvm_component_utils(I2C_coverage)
    
    I2C_seq_item tx;
    
    logic [7:0] active_data; 

    covergroup I2C_cg;
        
        cp_addr: coverpoint tx.addr[6:0] {
            bins general_call = {7'h00};            
            bins target_slave = {7'h5A};             
            bins others       = {[7'h01:7'h59], [7'h5B:7'h7F]}; 
        }

        cp_dir: coverpoint tx.is_write {
            bins write_op = {1'b1};
            bins read_op  = {1'b0};
        }

        cp_data: coverpoint active_data {
            bins all_zeros = {8'h00};
            bins all_ones  = {8'hFF};
            bins alt_a     = {8'hAA}; 
            bins alt_5     = {8'h55}; 
            bins others    = default; 
        }

        cx_addr_dir : cross cp_addr, cp_dir;

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        I2C_cg = new();
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void write(I2C_seq_item t);
        tx = t;
        active_data = tx.is_write ? tx.wdata[7:0] : tx.rdata[7:0];
        
        I2C_cg.sample(); 
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "\n===== I2C Coverage Summary =====", UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Overall Coverage : %.1f%%", I2C_cg.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Address Cover    : %.1f%%", I2C_cg.cp_addr.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Direction Cover  : %.1f%%", I2C_cg.cp_dir.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Data Cover       : %.1f%%", I2C_cg.cp_data.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Cross(Addr x Dir): %.1f%%", I2C_cg.cx_addr_dir.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), "==================================\n", UVM_LOW);
    endfunction

endclass  // I2C_coverage

`endif