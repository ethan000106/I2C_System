`ifndef I2C_SEQUENCE_SV
`define I2C_SEQUENCE_SV

`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "seq_item.sv"


class I2C_base_seq extends uvm_sequence #(I2C_seq_item);
    `uvm_object_utils(I2C_base_seq)

    int num_loop = 10;

    function new(string name = "I2C_base_seq");
        super.new(name);
    endfunction


    task axi_write(logic [31:0] w_addr, logic [31:0] w_data);
        I2C_seq_item item = I2C_seq_item::type_id::create("item");
        start_item(item);

        if (!item.randomize() with {
                addr == w_addr;
                wdata == w_data;
                is_write == 1'b1;
            })
            `uvm_fatal(get_type_name(), "axi_write Randomize() fail!!!")

        finish_item(item);

        `uvm_info(get_type_name(), $sformatf(
                                       "[AXI WRITE] ADDR: 0x%0x, DATA: 0x%0x",
                                       w_addr, w_data), UVM_HIGH)
    endtask


    task axi_read(logic [31:0] r_addr, output logic [31:0] r_data);
        I2C_seq_item item = I2C_seq_item::type_id::create("item");
        start_item(item);

        if (!item.randomize() with {
                addr == r_addr;
                is_write == 1'b0;
            })
            `uvm_fatal(get_type_name(), "axi_read Randomize() fail!!!")

        finish_item(item);

        r_data = item.rdata;
        `uvm_info(get_type_name(), $sformatf(
                                       "[AXI READ] ADDR: 0x%0x, DATA: 0x%0x",
                                       r_addr, r_data), UVM_HIGH)
    endtask

    virtual task body();

    endtask
endclass


class i2c_directed_seq extends I2C_base_seq;
    `uvm_object_utils(i2c_directed_seq)

    function new(string name = "i2c_directed_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [31:0] read_val;

        `uvm_info(get_type_name(),
                  "Directed Sequence start (I2C 전송 시나리오)", UVM_LOW)

        axi_write(32'h0, 32'h00000003);  
        axi_read(32'h0, read_val);  

        `uvm_info(get_type_name(), "Directed Sequence finish", UVM_LOW)
    endtask
endclass


class i2c_rand_seq extends I2C_base_seq;
    `uvm_object_utils(i2c_rand_seq)

    function new(string name = "i2c_rand_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), "Random Sequence start...", UVM_LOW)

        for (int i = 0; i < num_loop; i++) begin
            I2C_seq_item item = I2C_seq_item::type_id::create("item");
            start_item(item);


            if (!item.randomize() with {
                    is_write dist {
                        1'b1 := 70,
                        1'b0 := 30
                    };
                })
                `uvm_fatal(get_type_name(), "Randomize() Fail!!!!!")

            finish_item(item);
            `uvm_info(get_type_name(), $sformatf(
                      "[%0d/%0d] random AXI complete", i + 1, num_loop),
                      UVM_HIGH)
        end

        `uvm_info(get_type_name(), "Random Sequence finish", UVM_LOW)
    endtask
endclass

`endif
