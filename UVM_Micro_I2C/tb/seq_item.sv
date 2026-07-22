`ifndef I2C_SEQ_ITEM_SV
`define I2C_SEQ_ITEM_SV

`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

class I2C_seq_item extends uvm_sequence_item;


    rand logic [31:0] addr;      
    rand logic [31:0] wdata;     
    rand logic        is_write;  


    logic [31:0] rdata;          
    logic [1:0]  resp;           


    constraint addr_align_c {
        addr inside {32'h0, 32'h4, 32'h8, 32'hC};
    }

    // UVM Factory Registration & Field Macros
    `uvm_object_utils_begin(I2C_seq_item)
        `uvm_field_int(addr,     UVM_ALL_ON)
        `uvm_field_int(wdata,    UVM_ALL_ON)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(rdata,    UVM_ALL_ON)
        `uvm_field_int(resp,     UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor
    function new(string name = "I2C_seq_item");
        super.new(name);
    endfunction

    
    virtual function string convert2string();
        string dir = is_write ? "WRITE" : "READ ";
        if (is_write)
            return $sformatf("[%s] ADDR: 0x%08x | WDATA: 0x%08x | RESP: %0b", dir, addr, wdata, resp);
        else
            return $sformatf("[%s] ADDR: 0x%08x | RDATA: 0x%08x | RESP: %0b", dir, addr, rdata, resp);
    endfunction

endclass

`endif