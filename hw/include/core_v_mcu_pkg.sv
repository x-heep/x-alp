// Copyright 2026 X-HEEP Contributors
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Package file for core_v_mcu parameters and type definitions.
// Author: Luigi Giuffrida <luigi.giuffrida@polito.it>
//

`include "axi/typedef.svh"
`include "register_interface/typedef.svh"

package core_v_mcu_pkg;

    //-----------
    // BUS Config
    //-----------
    localparam int unsigned NumAxiMasters = 3;
    // localparam int unsigned NumExtAxiMasters = 1;

    localparam int unsigned totalAxiMasters = NumAxiMasters;

    localparam int unsigned NumAxiSlaves = 4;
    // localparam int unsigned NumExtAxiSlaves = 1;

    localparam int unsigned totalAxiSlaves = NumAxiSlaves;

    localparam int unsigned NumRegSlaves = 5;
    // localparam int unsigned NumExtRegSlaves = 1;

    localparam int unsigned totalRegSlaves = NumRegSlaves;

    // AXI configuration parameters
    localparam int unsigned AxiMstIdWidth = 4;
    localparam int unsigned AxiSlvIdWidth = AxiMstIdWidth + $clog2(totalAxiMasters);
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

    localparam JTAG_IDCODE = 32'h10001c05;

    // Master indexes
    localparam int unsigned CPU_M_BUS_IDX = 0;
    localparam int unsigned DEBUG_MODULE_M_BUS_IDX = 1;
    localparam int unsigned EXT_MASTER_M_BUS_IDX = 2;

    // Slave indexes
    localparam int unsigned MEM_S_BUS_IDX = 0;
    localparam int unsigned DEBUG_MODULE_S_BUS_IDX = 1;
    localparam int unsigned PERIPHERALS_S_BUS_IDX = 2;
    localparam int unsigned EXT_SLAVE_S_BUS_IDX = 3;


    // Slave addresses
    localparam addr_t MEM_BUS_BASE_ADDR = 64'h0000000000000000;
    localparam addr_t MEM_BUS_SIZE = 64'h0000000000010000;
    localparam addr_t MEM_BUS_END_ADDR = MEM_BUS_BASE_ADDR + MEM_BUS_SIZE;
    localparam addr_t DEBUG_MODULE_BUS_BASE_ADDR = 64'h0000000000010000;
    localparam addr_t DEBUG_MODULE_BUS_SIZE = 64'h0000000000010000;
    localparam addr_t DEBUG_MODULE_BUS_END_ADDR = DEBUG_MODULE_BUS_BASE_ADDR + DEBUG_MODULE_BUS_SIZE;
    localparam addr_t PERIPHERALS_BUS_BASE_ADDR = 64'h0000000000020000;
    localparam addr_t PERIPHERALS_BUS_SIZE = 64'h0000000010000000;
    localparam addr_t PERIPHERALS_BUS_END_ADDR = PERIPHERALS_BUS_BASE_ADDR + PERIPHERALS_BUS_SIZE;
    localparam addr_t EXT_SLAVE_BUS_BASE_ADDR = 64'h0000000010020000;
    localparam addr_t EXT_SLAVE_BUS_SIZE = 64'h0000000000010000;
    localparam addr_t EXT_SLAVE_BUS_END_ADDR = EXT_SLAVE_BUS_BASE_ADDR + EXT_SLAVE_BUS_SIZE;

    // Code and Data memory zones (cacheable)
    localparam addr_t CODE_ZONE_BASE_ADDR = 64'h0000_0000_0000_0000;
    localparam addr_t CODE_ZONE_SIZE = 64'h0000_0000_0000_8000;
    localparam addr_t CODE_ZONE_END_ADDR = CODE_ZONE_BASE_ADDR + CODE_ZONE_SIZE;
    localparam addr_t DATA_ZONE_BASE_ADDR = 64'h0000_0000_0000_8000;
    localparam addr_t DATA_ZONE_SIZE = 64'h0000_0000_0000_8000;
    localparam addr_t DATA_ZONE_END_ADDR = DATA_ZONE_BASE_ADDR + DATA_ZONE_SIZE;

    // Register indexes
    localparam int unsigned SOC_CTRL_REG_IDX = 0;
    localparam int unsigned BOOTROM_REG_IDX = 1;
    localparam int unsigned FAST_INTR_CTRL_REG_IDX = 2;
    localparam int unsigned UART_REG_IDX = 3;
    localparam int unsigned EXT_PERIPHERAL_REG_IDX = 4;

    // Register addresses
    localparam addr_t SOC_CTRL_REG_BASE_ADDR = PERIPHERALS_BUS_BASE_ADDR + 64'h0000000000000000;
    localparam addr_t SOC_CTRL_REG_SIZE = 64'h0000000000001000;
    localparam addr_t SOC_CTRL_REG_END_ADDR = SOC_CTRL_REG_BASE_ADDR + SOC_CTRL_REG_SIZE;
    localparam addr_t BOOTROM_REG_BASE_ADDR = PERIPHERALS_BUS_BASE_ADDR + 64'h0000000000010000;
    localparam addr_t BOOTROM_REG_SIZE = 64'h0000000000010000;
    localparam addr_t BOOTROM_REG_END_ADDR = BOOTROM_REG_BASE_ADDR + BOOTROM_REG_SIZE;
    localparam addr_t FAST_INTR_CTRL_REG_BASE_ADDR = PERIPHERALS_BUS_BASE_ADDR +  64'h0000000000020000;
    localparam addr_t FAST_INTR_CTRL_REG_SIZE = 64'h0000000000001000;
    localparam addr_t FAST_INTR_CTRL_REG_END_ADDR = FAST_INTR_CTRL_REG_BASE_ADDR + FAST_INTR_CTRL_REG_SIZE;
    localparam addr_t UART_REG_BASE_ADDR = PERIPHERALS_BUS_BASE_ADDR + 64'h0000000000030000;
    localparam addr_t UART_REG_SIZE = 64'h0000000000001000;
    localparam addr_t UART_REG_END_ADDR = UART_REG_BASE_ADDR + UART_REG_SIZE;
    localparam addr_t EXT_PERIPHERAL_REG_BASE_ADDR = PERIPHERALS_BUS_BASE_ADDR +  64'h0000000000040000;
    localparam addr_t EXT_PERIPHERAL_REG_SIZE = 64'h0000000000001000;
    localparam addr_t EXT_PERIPHERAL_REG_END_ADDR = EXT_PERIPHERAL_REG_BASE_ADDR + EXT_PERIPHERAL_REG_SIZE;

    // Address mapping rules
    localparam rule_t [totalAxiSlaves-1:0] addr_rules = '{
        '{idx : MEM_S_BUS_IDX, start_addr : MEM_BUS_BASE_ADDR, end_addr : MEM_BUS_END_ADDR},
        '{
            idx : DEBUG_MODULE_S_BUS_IDX,
            start_addr : DEBUG_MODULE_BUS_BASE_ADDR,
            end_addr : DEBUG_MODULE_BUS_END_ADDR
        },
        '{
            idx : PERIPHERALS_S_BUS_IDX,
            start_addr : PERIPHERALS_BUS_BASE_ADDR,
            end_addr : PERIPHERALS_BUS_END_ADDR
        },
        '{
            idx : EXT_SLAVE_S_BUS_IDX,
            start_addr : EXT_SLAVE_BUS_BASE_ADDR,
            end_addr : EXT_SLAVE_BUS_END_ADDR
        }
    };

    localparam rule_t [totalRegSlaves-1:0] RegMap = '{
        '{
            idx : SOC_CTRL_REG_IDX,
            start_addr : SOC_CTRL_REG_BASE_ADDR,
            end_addr : SOC_CTRL_REG_END_ADDR
        },
        '{
            idx : BOOTROM_REG_IDX,
            start_addr : BOOTROM_REG_BASE_ADDR,
            end_addr : BOOTROM_REG_END_ADDR
        },
        '{
            idx : FAST_INTR_CTRL_REG_IDX,
            start_addr : FAST_INTR_CTRL_REG_BASE_ADDR,
            end_addr : FAST_INTR_CTRL_REG_END_ADDR
        },
        '{idx : UART_REG_IDX, start_addr : UART_REG_BASE_ADDR, end_addr : UART_REG_END_ADDR},
        '{
            idx : EXT_PERIPHERAL_REG_IDX,
            start_addr : EXT_PERIPHERAL_REG_BASE_ADDR,
            end_addr : EXT_PERIPHERAL_REG_END_ADDR
        }
    };


    localparam axi_pkg::xbar_cfg_t AxiXbarCfg = '{
        NoSlvPorts        : totalAxiMasters,
        NoMstPorts        : totalAxiSlaves,
        MaxMstTrans       : 16,
        MaxSlvTrans       : 16,
        FallThrough       : 1'b1,
        LatencyMode       : 10'b0000001111,  // Low latency
        PipelineStages    : 1,
        AxiIdWidthSlvPorts: AxiMstIdWidth,
        AxiIdUsedSlvPorts : AxiMstIdWidth,
        UniqueIds         : 1'b1,
        AxiAddrWidth     : AxiAddrWidth,
        AxiDataWidth     : AxiDataWidth,
        NoAddrRules      : totalAxiSlaves
    };

    // Boot address
    localparam addr_t BOOT_ADDR = BOOTROM_REG_BASE_ADDR;

endpackage : core_v_mcu_pkg
