// ### 1. PULP Register Interface (Slave Control Path) #########################
//
// typedef struct packed {                  // dma_reg_req_i (CPU -> DMA)
//     logic [AddrWidth-1:0]   addr;        // Register address offset
//     logic                   write;       // 1 = Write, 0 = Read
//     logic [DataWidth-1:0]   wdata;       // Write data (32-bit)
//     logic [DataWidth/8-1:0] wstrb;       // Byte-enable strobes
//     logic                   valid;       // Request valid
// } reg_req_t;
//
// typedef struct packed {                  // dma_reg_rsp_o (DMA -> CPU)
//     logic [DataWidth-1:0]   rdata;       // Read data (32-bit)
//     logic                   error;       // 1 = Error, 0 = OK
//     logic                   ready;       // Response ready (handshake)
// } reg_rsp_t;
//############################################################################

//dma acts as a slave, reg_pulp interface issues from CPU to DMA regs reg_req_t: register address. write/not_read, wdata on 32 bits(if writing)
//strobe for byte enables, valid signal to ensure transaction is valid.
//Dma regs respond with reg_rsp_t: rdata if data is read, error if address is not mapped, ready signal back to CPU
//to indicate completion of the transaction. Master hangs communication until ready signal is asserted.
//if processing a request requires multiple cycles, ready signal is not asserted until the transaction is complete. 
//This prevents CPU from hanging while waiting for a response.



// ### 2. AXI4 Master Interface (Data Path - Read Channels Highlighted) ########
//
// typedef struct packed {                  // bus_req_o_r (DMA -> Memory)
//     aw_chan_t               aw;          // [Unused on Read Master]
//     logic                   aw_valid;    // [Tie to 1'b0]
//     w_chan_t                w;           // [Unused on Read Master]
//     logic                   w_valid;     // [Tie to 1'b0]
//     logic                   b_ready;     // [Tie to 1'b0]
//     struct packed {                      // ar: Address Read Channel
//         id_t                id;          //   Transaction ID
//         addr_t              addr;        //   Target memory address (64-bit)
//         axi_pkg::len_t      len;         //   Burst length (0 = 1 beat)
//         axi_pkg::size_t     size;        //   Bytes per beat (3'b011 = 8B)
//         axi_pkg::burst_t    burst;       //   Burst type (2'b01 = INCR)
//         logic               lock;        //   Atomic access
//         axi_pkg::cache_t    cache;       //   Memory attributes
//         axi_pkg::prot_t     prot;        //   Access permissions
//         axi_pkg::qos_t      qos;         //   Quality of Service
//         axi_pkg::region_t   region;      //   Region identifier
//         user_t              user;        //   User-defined signal
//     } ar;
//     logic                   ar_valid;    // AR channel valid (handshake)
//     logic                   r_ready;     // R channel ready  (handshake)
// } axi_mst_req_t;
//
//after receiving the data from the reg_req_t from CPU, DMA is configured to send read packets to memory.
//default fields: 
//ar.id = 0 (id of transaction, should be 0-15), 
//addr = 64 bit address from the memory space to read from (so also peripheral address space)
//len = 0 (burst lenght, how many transactions in a single burst? 0 = 1 beat, 1 = 2 beats, 2 = 3 beats, etc.)
//size = 3'b011 (bytes per beat, 3'b011 = 8 bytes(we suppose memory is 64 bit wide)),
//burst = 2'b01 (burst type, 2'b01 = INCR, so the address increments by size for each beat in the burst of size (8 bytes))
//lock = 0 (atomic access y/n)
//cache = 4'b0011 (memory attributes, 4'b0011 = normal, non-cacheable, bufferable, modifiable)
//prot = 3'b000 (access permissions, 3'b000 = privileged, secure, data access)
//qos = 4'b0000 (quality of service, 4'b0000 = no QoS) (?)
//region = 4'b0000 (region identifier, 4'b0000 = no region) (?)
//user = 1'b 0 (user-defined signal, 1'b0 = no user-defined signal) (?)


//MAIN IDEA: prepare the read packet, setup ar_valid to 1 to indicate read packet is valid, prepare the address 
//to the next descriptor to read, fetch either 1 word( 1 beat, 8 bytes) or 4 words (4 beats, 32 bytes) depending on the length of the descriptor.
//setup burst to INCR, so the address increments by size for each beat in the burst of size (8 bytes).
//id is set to 0, as we only have one transaction at a time.
// bus_req_o_r.ar_valid = 1'b1;  // Assert address valid!
// bus_req_o_r.ar.addr  = descriptor_addr;
// bus_req_o_r.ar.len   = 8'h0;  // Fetch 1 beat
// bus_req_o_r.ar.size  = 3'b011;  // 8 bytes (64-bit)
// bus_req_o_r.ar.burst = 2'b01;  // INCR
// bus_req_o_r.ar.id    = 4'h0;


// typedef struct packed {                  // bus_rsp_i_r (Memory -> DMA)
//     logic                   aw_ready;    // [Unused on Read Master]
//     logic                   ar_ready;    // AR channel ready (handshake)
//     logic                   w_ready;     // [Unused on Read Master]
//     logic                   b_valid;     // [Unused on Read Master]
//     b_chan_t                b;           // [Unused on Read Master]
//     logic                   r_valid;     // R channel valid  (handshake)
//     struct packed {                      // r: Read Data Channel
//         id_t                id;          //   Transaction ID
//         data_t              data;        //   Read payload (64-bit)
//         axi_pkg::resp_t     resp;        //   Read response (OKAY/SLVERR/etc.)
//         logic               last;        //   1 = Final beat of burst
//         user_t              user;        //   User-defined signal
//     } r;
// } axi_mst_rsp_t;
// ################

module dma_subsystem (
    input logic clk_i,
    input logic rst_ni,

    input  core_v_mcu_pkg::reg_req_t dma_reg_req_i,  //pulp register interface.
    output core_v_mcu_pkg::reg_rsp_t dma_reg_rsp_o,

    // AXI bus Request Master Read
    output core_v_mcu_pkg::axi_mst_req_t bus_req_o_r,  //this is a master read!
    // AXI bus response Master Read
    input  core_v_mcu_pkg::axi_mst_rsp_t bus_rsp_i_r,

    output core_v_mcu_pkg::axi_mst_req_t bus_req_o_w,  //this is a master write!
    input  core_v_mcu_pkg::axi_mst_rsp_t bus_rsp_i_w
);
    //TODO this will need to be moved into header files
    typedef struct packed {
        logic [core_v_mcu_pkg::AxiAddrWidth-1:0] src_addr;
        logic [core_v_mcu_pkg::AxiAddrWidth-1:0] dst_addr;
        logic [core_v_mcu_pkg::AxiAddrWidth-1:0] next_desc_addr;
        logic [31:0] flags;  //todo change this
    } dma_descriptor_t;
    //TODO ditto
    dma_descriptor_t [ 1:0] descriptor_memory;  // 4 descriptors in memory stack
    dma_descriptor_t        current_descriptor;  // Current descriptor being processed
    logic            [ 1:0] descriptor_index;  // Index for descriptor memory stack

    logic            [63:0] memory_rdata;


    // 1. Prevent CPU Hangs: Always acknowledge register reads/writes immediately
    //Should i change this? IDK, ideally the peripheral should always be able to respond
    assign dma_reg_rsp_o.ready = 1'b1;
    assign dma_reg_rsp_o.rdata = '0;
    assign dma_reg_rsp_o.error = 1'b0;

    // Tie off unused write master port to prevent undefined behavior
    assign bus_req_o_w         = '0;

    typedef enum logic [1:0] {
        IDLE,     // Wait for a new chain to start. NO NEXT DESCRIPTOR HAS BEEN PROVIDED
        SEND_AR,  // Send AXI Read Address for current descriptor
        WAIT_R    // Wait for AXI Read Data
    } state_e;

    state_e currstate, next_state;
    logic [core_v_mcu_pkg::AxiAddrWidth-1:0] descriptor_addr, next_descriptor_addr;

    always_comb begin : READ_FSM
        next_state           = currstate;
        next_descriptor_addr = descriptor_addr;  // Hold value by default

        case (currstate)
            IDLE: begin
                if (dma_reg_req_i.valid && dma_reg_req_i.write && dma_reg_req_i.wdata != 32'h0) begin
                    //isssued a valid address for the descriptor.
                    next_state = SEND_AR;
                    next_descriptor_addr = {32'h0, dma_reg_req_i.wdata};  // Safely set next address
                    //this means there is a valid next descriptor address to fetch.
                end
            end
            SEND_AR: begin
                // Wait for the memory to accept our read address (AXI handshake)
                if (bus_rsp_i_r.ar_ready) begin //bus_rsp_i_r -> master read port, ar_ready is the signal from the slave that it has accepted the read address
                    next_state = WAIT_R;
                end
            end
            WAIT_R: begin
                // Wait for the read data to come back (AXI handshake)
                if (bus_rsp_i_r.r_valid) begin
                    // next_descriptor_addr = bus_rsp_i_r.r.data[31:0]; // Example for linked list
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    ;

    always_comb begin : FSM_AXI_MASTER_READ
        bus_req_o_r          = '0;  // Clear all valid flags and structs
        bus_req_o_r.ar.addr  = '0;
        bus_req_o_r.ar.len   = 8'h0;  // Fetch 1 beat
        bus_req_o_r.ar.size  = '0;
        bus_req_o_r.ar.burst = '0;  // INCR
        bus_req_o_r.ar.id    = 4'h0;

        case (currstate)
            SEND_AR: begin
                bus_req_o_r.ar_valid = 1'b1;  // Assert address valid!
                bus_req_o_r.ar.addr  = descriptor_addr;
                bus_req_o_r.ar.len   = 8'h3;  // Fetch 4 beat
                bus_req_o_r.ar.size  = 3'b011;  // 8 bytes (64-bit) // 
                bus_req_o_r.ar.burst = 2'b01;  // INCR
                bus_req_o_r.ar.id    = 4'h0;
            end
            WAIT_R: begin
                bus_req_o_r.r_ready = 1'b1;  // Tell memory we are ready to receive data!
            end
            IDLE: begin
                if (bus_rsp_i_r.r_valid) begin
                    bus_req_o_r.r_ready = 1'b1;  // Tell memory we are ready to receive data!
                    memory_rdata        = bus_rsp_i_r.r.data;  // Capture the read data
                    //TODO this will always stay high!, i need to have a counter for N_beeats and deactivate it 
                end else begin
                    bus_req_o_r.r_ready = 1'b0;  // Tell memory we are NOT ready to receive data!
                    // Do nothing, wait for the next descriptor to be provided
                end
            end
            //do nothing, wait for the next descriptor to be provided
            default: begin
                // catch-all for undefined 2-bit states to satisfy Verilator
            end
        endcase
    end
    ;

    always_ff @(posedge clk_i or negedge rst_ni) begin : FSM_SEQ
        if (!rst_ni) begin
            currstate <= IDLE;
        end else begin
            currstate <= next_state;
        end
    end
    ;

    always_ff @(posedge clk_i or negedge rst_ni) begin : DESCRIPTOR_ADDR_SEQ
        if (!rst_ni) begin
            descriptor_addr <= '0;
        end else begin
            // Simply update the flip-flop with the combinatorial output
            descriptor_addr <= next_descriptor_addr;
        end
    end
    ;

    /* verilator lint_off PINCONNECTEMPTY */
    /* verilator lint_off PINMISSING      */

endmodule
;
