// Copyright 2025 Politecnico di Torino.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version  2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// File: dma_tb_wrapper.sv
// Author(s):
//   Matteo Caroleo
// Date: 06/12/2025
// Description: Wrapper for Verilator TB


// TODO:    -check if parametrization can be done 
//          while instantiating the wrapper.
//          


`define SLOT_NUM_TB 3


// wrapper module: unwraps the user types
module dma_tb_wrapper 
    import obi_pkg::*; 
    import fifo_pkg::*; 
    import reg_pkg::*;
    import dma_reg_pkg::*;
(
  /* Basic signals */
  input logic clk_i,
  input logic rst_ni,
 
  /* Dma controller control signal */
  input logic ext_dma_stop_i, // overrides the read &/o write done
  input logic hw_fifo_done_i, // should only be relevant in HW_FIFO_MODE
  
  /* Register Interface (configuration registers) */ 
  // To unwrap
  // input  reg_req_t reg_req_i, // goes to register part (dma_reg_top)
  // output reg_rsp_t reg_rsp_o, // comes from register part (dma_reg_top)
  input  logic        reg_valid_i,
  input  logic        reg_write_i,
  input  logic [ 3:0] reg_wstrb_i,
  input  logic [31:0] reg_addr_i,
  input  logic [31:0] reg_wdata_i,
  
  output logic        reg_error_o,
  output logic        reg_ready_o,
  output logic [31:0] reg_rdata_o,



  /* OBI interfaces  */
  
  // read unit interface -> GOES TO MEMORY TO READ
  output logic        obi_read_req_o,    // address transfer request 
  output logic        obi_read_we_o,     // write enable 
  output logic [ 3:0] obi_read_be_o,     // byte enable
  output logic [31:0] obi_read_addr_o,   // address for memory access
  output logic [31:0] obi_read_wdata_o,  // write data
  
  input logic        obi_read_gnt_i,    // grant (ready to accept address transfer)
  input logic        obi_read_rvalid_i, // response transfer valid
  input logic [31:0] obi_read_rdata_i,  // read data
  
  // write unit interface -> GOES TO MEMORY TO WRITE
  output  logic        obi_write_req_o,      // idem          
  output  logic        obi_write_we_o,       // idem 
  output  logic [ 3:0] obi_write_be_o,       // idem 
  output  logic [31:0] obi_write_addr_o,     // idem 
  output  logic [31:0] obi_write_wdata_o,    // idem 
  
  input logic        obi_write_gnt_i,      // idem 
  input logic        obi_write_rvalid_i,   // idem 
  input logic [31:0] obi_write_rdata_i,    // idem 

  // addr unit interface -> GOES TO MEMORY (what does it do?)
  output  logic        obi_addr_req_o,     // idem
  output  logic        obi_addr_we_o,     // idem
  output  logic [ 3:0] obi_addr_be_o,     // idem
  output  logic [31:0] obi_addr_addr_o,     // idem
  output  logic [31:0] obi_addr_wdata_o,     // idem
  
  input logic        obi_addr_gnt_i,      // idem
  input logic        obi_addr_rvalid_i,   // idem
  input logic [31:0] obi_addr_rdata_i,    // idem
  
  /* HW Fifo signals ->  USED FOR TC ACCELERATOR */
  output logic          fifo_pop_o, 
  output logic          fifo_push_o,
  output logic          fifo_flush_o,
  output logic [31:0]   fifo_data_o,

  input logic           fifo_empty_i,
  input logic           fifo_full_i,
  input logic           fifo_alm_full_i,
  input logic [31:0]    fifo_data_i,

  /* Trigger slot */
  input logic [`SLOT_NUM_TB-1:0] trigger_slot_i,

  /* New input signal */
  
  // status reg unwrapping: ready.d and window_done.d
  input logic external_hw2reg_status_ready_d_i,
  input logic external_hw2reg_status_window_done_d_i,
  // window count reg unwrapping: d [7:0] and de
  input logic [7:0] external_hw2reg_window_count_d_i,
  input logic external_hw2reg_window_count_de_i,
  // transaction ifr reg unwrapping: d
  input logic external_hw2reg_transaction_ifr_d_i,
  // window ifr reg unwrapping : d
  input logic external_hw2reg_window_ifr_d_i,     

  
  /* Output signals */
  output dma_done_intr_o,
  output dma_window_intr_o,
  output dma_done_o,   
  output dma_ready_o
);

    /* Internal signals */

    // obi for each unit
    obi_pkg::obi_req_t dma_read_req;
    obi_pkg::obi_resp_t dma_read_rsp;
    
    obi_pkg::obi_req_t dma_write_req;
    obi_pkg::obi_resp_t dma_write_rsp;
    
    obi_pkg::obi_req_t dma_addr_req;
    obi_pkg::obi_resp_t dma_addr_rsp;
 
    // register interface internal structs
    reg_pkg::reg_req_t reg_req;
    reg_pkg::reg_rsp_t reg_rsp;

    // hw fifo signals of possible tc accel 
    fifo_pkg::fifo_req_t hw_fifo_req;
    fifo_pkg::fifo_resp_t hw_fifo_rsp;

    // dma external hw2reg signals
    dma_reg_pkg::dma_hw2reg_t external_hw2reg;

    // is set to enable: not guaranteed (see dma.sv:162)
    logic clk_gate_en_n = 'b1;
    

    /* OBI requests: every unit has obi */
    always_comb begin : obi_wrapping
        
        // read unit
        obi_read_req_o      = dma_read_req.req;            
        obi_read_we_o       = dma_read_req.we;
        obi_read_be_o       = dma_read_req.be;
        obi_read_addr_o     = dma_read_req.addr;    
        obi_read_wdata_o    = dma_read_req.wdata;    
        
        dma_read_rsp.gnt      = obi_read_gnt_i;               
        dma_read_rsp.rvalid   = obi_read_rvalid_i;    
        dma_read_rsp.rdata    = obi_read_rdata_i;    

        // write unit
        obi_write_req_o     = dma_write_req.req;                     
        obi_write_we_o      = dma_write_req.we;
        obi_write_be_o      = dma_write_req.be;    
        obi_write_addr_o    = dma_write_req.addr;        
        obi_write_wdata_o   = dma_write_req.wdata;            
        
        dma_write_rsp.gnt     = obi_write_gnt_i;               
        dma_write_rsp.rvalid  = obi_write_rvalid_i;    
        dma_write_rsp.rdata   = obi_write_rdata_i;    
        
        // addr unit
        obi_addr_req_o = dma_addr_req.req;
        obi_addr_we_o = dma_addr_req.we;
        obi_addr_be_o = dma_addr_req.be;
        obi_addr_addr_o = dma_addr_req.addr;
        obi_addr_wdata_o = dma_addr_req.wdata;
        
        dma_addr_rsp.gnt      = obi_addr_gnt_i;               
        dma_addr_rsp.rvalid   = obi_addr_rvalid_i;    
        dma_addr_rsp.rdata    = obi_addr_rdata_i;    

    end

    /* from Fifo */
    assign hw_fifo_rsp = '{
        empty:      fifo_empty_i,
        full:       fifo_full_i,
        alm_full:   fifo_alm_full_i,
        data:       fifo_data_i
    };

    /* To Fifo */
    assign fifo_pop_o = hw_fifo_req.pop;
    assign fifo_push_o = hw_fifo_req.push;
    assign fifo_flush_o = hw_fifo_req.flush;
    assign fifo_data_o = hw_fifo_req.data;

    /* Register interface request */
 
    // Driven by dma wrapper
    assign reg_req = '{
        valid:  reg_valid_i,
        write:  reg_write_i,
        wstrb:  reg_wstrb_i,
        addr:   reg_addr_i,
        wdata:  reg_wdata_i
    };
    
    // Driven by dma    
    assign reg_error_o = reg_rsp.error;
    assign reg_ready_o = reg_rsp.ready;
    assign reg_rdata_o = reg_rsp.rdata;
    
    /* Hw fifo signals for tc accel*/
    always_comb begin : hwfifo_wrapping
        fifo_pop_o = hw_fifo_req.pop;
        fifo_push_o = hw_fifo_req.push;
        fifo_flush_o = hw_fifo_req.flush;
        fifo_data_o = hw_fifo_req.data;
       
        hw_fifo_rsp.empty   = fifo_empty_i;
        hw_fifo_rsp.full    = fifo_full_i;
        hw_fifo_rsp.alm_full= fifo_alm_full_i;
        hw_fifo_rsp.data    = fifo_data_i;
    end

    /* hw2reg wrapping */ 
        /* hw2reg wrapping */ 
  assign external_hw2reg = '{
    // 1. Registri di Status (Quelli che l'hardware aggiorna davvero)
    status: '{
        ready:       '{d: external_hw2reg_status_ready_d_i},
        window_done: '{d: external_hw2reg_status_window_done_d_i}
    },
    window_count: '{
        d:  external_hw2reg_window_count_d_i,
        de: external_hw2reg_window_count_de_i// Ricorda: serve il .de per scrivere!
    },
    
    // 2. Interrupt Flags
    transaction_ifr: '{d: external_hw2reg_transaction_ifr_d_i},
    window_ifr:      '{d: external_hw2reg_window_ifr_d_i},

    // 3. Tutti gli altri 24 campi della struct
    // Usiamo default: '0 per evitare l'errore "missed initializing elements"
    default: '0
};
    /* Dma obi instance: parametrization is currently 
       fixed by wrapper */

    dma #(
        .FIFO_DEPTH    (4), // default value in dma.sv
        .SLOT_NUM      (`SLOT_NUM_TB), 
        .reg_req_t     (reg_pkg::reg_req_t),
        .reg_rsp_t     (reg_pkg::reg_rsp_t),
        .obi_req_t     (obi_pkg::obi_req_t),
        .obi_resp_t     (obi_pkg::obi_resp_t)
    ) u_dma_obi
    (
        .clk_i,
        .rst_ni,
        .clk_gate_en_ni (clk_gate_en_n),

        .ext_dma_stop_i,
        .hw_fifo_done_i, 
        
        .reg_req_i (reg_req),
        .reg_rsp_o (reg_rsp),

        .dma_read_req_o (dma_read_req),
        .dma_read_resp_i (dma_read_rsp),
        .dma_write_req_o (dma_write_req),
        .dma_write_resp_i (dma_write_rsp),
        .dma_addr_req_o (dma_addr_req),
        .dma_addr_resp_i (dma_addr_rsp),
        
        .hw_fifo_resp_i (hw_fifo_rsp),
        .hw_fifo_req_o (hw_fifo_req),

        .trigger_slot_i,

        .external_hw2reg_i (external_hw2reg),
        .dma_ready_o,
        .dma_done_intr_o,
        .dma_window_intr_o,
        .dma_done_o 
    );
    
endmodule // dma_tb_wrapper
