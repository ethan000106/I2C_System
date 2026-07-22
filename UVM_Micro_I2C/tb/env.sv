`ifndef I2C_ENV_SV
`define I2C_ENV_SV

`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "agent.sv"
`include "scoreboard.sv"
`include "coverage.sv"

class I2C_env extends uvm_env;
    `uvm_component_utils(I2C_env)

    I2C_agent      agt;
    I2C_scoreboard scb;
    I2C_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agt = I2C_agent::type_id::create("agt", this);
        scb = I2C_scoreboard::type_id::create("scb", this);
        cov = I2C_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        agt.ap.connect(scb.ap_imp);
        agt.ap.connect(cov.analysis_export);
    endfunction

endclass  // I2C_env

`endif