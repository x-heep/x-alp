`include "axi/typedef.svh"
`include "register_interface/typedef.svh"

package core_v_mcu_pkg;

    //-----------
    // BUS Config
    //-----------
    localparam int unsigned NumMasters = 1;

    localparam int unsigned NumAxiSlaves = 2;
    localparam int unsigned NumRegSlaves = 4;
    localparam int unsigned NumSlaves = NumAxiSlaves + NumRegSlaves;

    // AXI configuration parameters
    localparam int unsigned AxiMstIdWidth = 4;
    localparam int unsigned AxiSlvIdWidth = AxiMstIdWidth + $clog2(NumMasters);
    localparam int unsigned AxiAddrWidth = 64;
    localparam int unsigned AxiDataWidth = 64;
    localparam int unsigned AxiUserWidth = 64;

    // AXI type definitions

    localparam type addr_t = logic [AxiAddrWidth-1:0];
    localparam type axi_data_t = logic [AxiDataWidth   -1:0];
    localparam type axi_strb_t = logic [AxiDataWidth/8 -1:0];
    localparam type axi_user_t = logic [AxiUserWidth   -1:0];
    localparam type axi_mst_id_t = logic [AxiMstIdWidth  -1:0];
    localparam type axi_slv_id_t = logic [AxiSlvIdWidth  -1:0];

    `AXI_TYPEDEF_ALL_CT(axi_mst, axi_mst_req_t, axi_mst_rsp_t, addr_t, axi_mst_id_t, axi_data_t,
                        axi_strb_t, axi_user_t)
    `AXI_TYPEDEF_ALL_CT(axi_slv, axi_slv_req_t, axi_slv_rsp_t, addr_t, axi_slv_id_t, axi_data_t,
                        axi_strb_t, axi_user_t)

    `REG_BUS_TYPEDEF_ALL(reg, addr_t, logic [31:0], logic [3:0])

    typedef struct packed {
        int unsigned idx;
        addr_t start_addr;
        addr_t end_addr;
    } rule_t;

    // Master indexes
    localparam int unsigned CPU_BUS_IDX = 0;

    // Slave indexes
    localparam int unsigned MEM_BUS_IDX = 0;
    localparam int unsigned PERIPH_BUS_IDX = 1;

    // Slave addresses
    localparam addr_t MEM_BUS_BASE_ADDR = 64'h0000_0000_0000_0000;
    localparam addr_t MEM_BUS_SIZE = 64'h0000_0000_1000_0000;
    localparam addr_t MEM_BUS_END_ADDR = MEM_BUS_BASE_ADDR + MEM_BUS_SIZE;
    localparam addr_t PERIPH_BUS_BASE_ADDR = 64'h0000_0000_1000_0000;
    localparam addr_t PERIPH_BUS_SIZE = 64'h0000_0000_0FFF_FFFF;
    localparam addr_t PERIPH_BUS_END_ADDR = PERIPH_BUS_BASE_ADDR + PERIPH_BUS_SIZE;

    // Register indexes
    localparam int unsigned SOC_CTRL_REG_IDX = 0;
    localparam int unsigned BOOT_ROM_REG_IDX = 1;
    localparam int unsigned FAST_INTR_CTRL_REG_IDX = 2;
    localparam int unsigned UART_REG_IDX = 3;

    // Register addresses
    localparam addr_t SOC_CTRL_REG_START_ADDR = PERIPH_BUS_BASE_ADDR + 64'h0000_0000_0000_0000;
    localparam addr_t SOC_CTRL_REG_SIZE = 64'h0000_0000_0000_1000;
    localparam addr_t SOC_CTRL_REG_END_ADDR = SOC_CTRL_REG_START_ADDR + SOC_CTRL_REG_SIZE;
    localparam addr_t BOOT_ROM_REG_START_ADDR = SOC_CTRL_REG_END_ADDR;
    localparam addr_t BOOT_ROM_REG_SIZE = 64'h0000_0000_0000_1000;
    localparam addr_t BOOT_ROM_REG_END_ADDR = BOOT_ROM_REG_START_ADDR + BOOT_ROM_REG_SIZE;
    localparam addr_t FAST_INTR_CTRL_REG_START_ADDR = BOOT_ROM_REG_END_ADDR;
    localparam addr_t FAST_INTR_CTRL_REG_SIZE = 64'h0000_0000_0000_1000;
    localparam addr_t FAST_INTR_CTRL_REG_END_ADDR = FAST_INTR_CTRL_REG_START_ADDR + FAST_INTR_CTRL_REG_SIZE;
    localparam addr_t UART_REG_START_ADDR = FAST_INTR_CTRL_REG_END_ADDR;
    localparam addr_t UART_REG_SIZE = 64'h0000_0000_0000_1000;
    localparam addr_t UART_REG_END_ADDR = UART_REG_START_ADDR + UART_REG_SIZE;

    // Address mapping rules
    localparam rule_t [NumAxiSlaves-1:0] addr_rules = '{
        '{idx : PERIPH_BUS_IDX, start_addr : PERIPH_BUS_BASE_ADDR, end_addr : PERIPH_BUS_END_ADDR},
        '{idx : MEM_BUS_IDX, start_addr : MEM_BUS_BASE_ADDR, end_addr : MEM_BUS_END_ADDR}
    };

    localparam rule_t [NumRegSlaves-1:0] RegMap = '{
        '{
            idx : SOC_CTRL_REG_IDX,
            start_addr : SOC_CTRL_REG_START_ADDR,
            end_addr : SOC_CTRL_REG_END_ADDR
        },
        '{
            idx : BOOT_ROM_REG_IDX,
            start_addr : BOOT_ROM_REG_START_ADDR,
            end_addr : BOOT_ROM_REG_END_ADDR
        },
        '{
            idx : FAST_INTR_CTRL_REG_IDX,
            start_addr : FAST_INTR_CTRL_REG_START_ADDR,
            end_addr : FAST_INTR_CTRL_REG_END_ADDR
        },
        '{idx : UART_REG_IDX, start_addr : UART_REG_START_ADDR, end_addr : UART_REG_END_ADDR}
    };

    // AXI Crossbar configuration
    localparam axi_pkg::xbar_cfg_t AxiXbarCfg = '{
        NoSlvPorts        : NumMasters,
        NoMstPorts        : NumAxiSlaves,
        MaxMstTrans       : 16,
        MaxSlvTrans       : 16,
        FallThrough       : 1'b1,
        LatencyMode       : 10'b0000001111,  // Low latency
        PipelineStages    : 1,
        AxiIdWidthSlvPorts: AxiSlvIdWidth,
        AxiIdUsedSlvPorts : AxiSlvIdWidth,
        UniqueIds         : 1'b1,
        AxiAddrWidth     : AxiAddrWidth,
        AxiDataWidth     : AxiDataWidth,
        NoAddrRules      : NumAxiSlaves
    };

    // Boot address
    localparam addr_t BOOT_ADDR = BOOT_ROM_REG_START_ADDR;

endpackage : core_v_mcu_pkg
