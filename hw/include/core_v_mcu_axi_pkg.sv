package core_v_mcu_axi_pkg;

  // AXI configuration parameters

  localparam int unsigned AxiIdWidth = 4;
  localparam int unsigned AxiAddrWidth = 64;
  localparam int unsigned AxiDataWidth = 64;
  localparam int unsigned AxiUserWidth = 64;

  // AXI channel typedefs

  typedef struct packed {
    logic [AxiIdWidth-1:0]   id;
    logic [AxiAddrWidth-1:0] addr;
    axi_pkg::len_t            len;
    axi_pkg::size_t           size;
    axi_pkg::burst_t          burst;
    logic                     lock;
    axi_pkg::cache_t          cache;
    axi_pkg::prot_t           prot;
    axi_pkg::qos_t            qos;
    axi_pkg::region_t         region;
    logic [AxiUserWidth-1:0] user;
  } axi_ar_chan_t;

  typedef struct packed {
    logic [AxiIdWidth-1:0]   id;
    logic [AxiAddrWidth-1:0] addr;
    axi_pkg::len_t            len;
    axi_pkg::size_t           size;
    axi_pkg::burst_t          burst;
    logic                     lock;
    axi_pkg::cache_t          cache;
    axi_pkg::prot_t           prot;
    axi_pkg::qos_t            qos;
    axi_pkg::region_t         region;
    axi_pkg::atop_t           atop;
    logic [AxiUserWidth-1:0] user;
  } axi_aw_chan_t;

  typedef struct packed {
    logic [AxiDataWidth-1:0]     data;
    logic [(AxiDataWidth/8)-1:0] strb;
    logic                         last;
    logic [AxiUserWidth-1:0]     user;
  } axi_w_chan_t;

  typedef struct packed {
    logic [AxiIdWidth-1:0]   id;
    axi_pkg::resp_t           resp;
    logic [AxiUserWidth-1:0] user;
  } b_chan_t;

  typedef struct packed {
    logic [AxiIdWidth-1:0]   id;
    logic [AxiDataWidth-1:0] data;
    axi_pkg::resp_t           resp;
    logic                     last;
    logic [AxiUserWidth-1:0] user;
  } r_chan_t;

  // AXI request and response typedefs

  typedef struct packed {
    axi_aw_chan_t aw;
    logic         aw_valid;
    axi_w_chan_t  w;
    logic         w_valid;
    logic         b_ready;
    axi_ar_chan_t ar;
    logic         ar_valid;
    logic         r_ready;
  } axi_req_t;

  typedef struct packed {
    logic    aw_ready;
    logic    ar_ready;
    logic    w_ready;
    logic    b_valid;
    b_chan_t b;
    logic    r_valid;
    r_chan_t r;
  } axi_resp_t;

endpackage : core_v_mcu_axi_pkg
