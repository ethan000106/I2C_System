`ifndef I2C_AGENT_SV
`define I2C_AGENT_SV

`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "seq_item.sv"
`include "driver.sv"
`include "monitor.sv"

typedef uvm_sequencer#(I2C_seq_item) I2C_sequencer;

class I2C_agent extends uvm_agent;
    `uvm_component_utils(I2C_agent)

    I2C_driver    drv;
    I2C_monitor   mon;
    I2C_sequencer sqr;

    uvm_analysis_port #(I2C_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        ap = new("ap", this);

        mon = I2C_monitor::type_id::create("mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            drv = I2C_driver::type_id::create("drv", this);
            sqr = I2C_sequencer::type_id::create("sqr", this);
            `uvm_info(get_type_name(), "Agent가 ACTIVE 모드로 구성되었습니다 (Driver, Sequencer 생성)", UVM_LOW)
        end else begin
            `uvm_info(get_type_name(), "Agent가 PASSIVE 모드로 구성되었습니다 (Monitor만 생성)", UVM_LOW)
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        mon.ap.connect(this.ap);

        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass  // I2C_agent

`endif