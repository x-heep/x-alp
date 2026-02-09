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
    localparam int unsigned NumAxiMasters = ${xalp.bus.get_num_masters()};
    // localparam int unsigned NumExtAxiMasters = 1;

    localparam int unsigned totalAxiMasters = NumAxiMasters;

    localparam int unsigned NumAxiSlaves = ${xalp.bus.get_num_slaves()};
    // localparam int unsigned NumExtAxiSlaves = 1;

    localparam int unsigned totalAxiSlaves = NumAxiSlaves;

    localparam int unsigned NumRegSlaves = ${len(xalp.get_peripheral_domain("peripherals").get_peripherals())};
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
% for idx, a_master in enumerate(xalp.bus.masters):
    localparam int unsigned ${a_master.upper()}_M_BUS_IDX = ${idx};
% endfor

    // Slave indexes
% for idx, a_slave in enumerate(xalp.bus.slaves):
    localparam int unsigned ${a_slave.name.upper()}_S_BUS_IDX = ${idx};
% endfor
    

    // Slave addresses
% for a_slave in xalp.bus.slaves:
    localparam addr_t ${a_slave.name.upper()}_BUS_BASE_ADDR = 64'h${a_slave.get_start_address()};
    localparam addr_t ${a_slave.name.upper()}_BUS_SIZE = 64'h${a_slave.get_length()};
    localparam addr_t ${a_slave.name.upper()}_BUS_END_ADDR = 64'h${a_slave.get_end_address()};
% endfor

    // Code and Data memory zones (cacheable)
    localparam addr_t CODE_ZONE_BASE_ADDR = 64'h0000_0000_0000_0000;
    localparam addr_t CODE_ZONE_SIZE = 64'h0000_0000_0000_8000;
    localparam addr_t CODE_ZONE_END_ADDR = CODE_ZONE_BASE_ADDR + CODE_ZONE_SIZE;
    localparam addr_t DATA_ZONE_BASE_ADDR = 64'h0000_0000_0000_8000;
    localparam addr_t DATA_ZONE_SIZE = 64'h0000_0000_0000_8000;
    localparam addr_t DATA_ZONE_END_ADDR = DATA_ZONE_BASE_ADDR + DATA_ZONE_SIZE;

    // Register indexes
% for idx, a_peripheral in enumerate(xalp.get_peripheral_domain("peripherals").get_peripherals()):
    localparam int unsigned ${a_peripheral._name.upper()}_REG_IDX = ${idx};
% endfor

    // Register addresses
% for a_peripheral in xalp.get_peripheral_domain("peripherals").get_peripherals():
    localparam addr_t ${a_peripheral._name.upper()}_REG_BASE_ADDR = 64'h${f"{a_peripheral.get_address():08x}"};
    localparam addr_t ${a_peripheral._name.upper()}_REG_SIZE = 64'h${f"{a_peripheral.get_length():08x}"};
    localparam addr_t ${a_peripheral._name.upper()}_REG_END_ADDR = 64'h${f"{a_peripheral.get_address() + a_peripheral.get_length():08x}"};
% endfor

    // Address mapping rules
    localparam rule_t [totalAxiSlaves-1:0] addr_rules = '{
% for  idx, a_slave in enumerate(xalp.bus.slaves):
        '{
            idx : ${a_slave.name.upper()}_S_BUS_IDX,
            start_addr : ${a_slave.name.upper()}_BUS_BASE_ADDR,
            end_addr : ${a_slave.name.upper()}_BUS_END_ADDR
        }
% if (idx != len(xalp.bus.slaves) - 1):
             , 
% endif
% endfor
    };

    localparam rule_t [totalRegSlaves-1:0] RegMap = '{
% for  idx, a_peripheral in enumerate(xalp.get_peripheral_domain("peripherals").get_peripherals()):
        '{
            idx : ${a_peripheral._name.upper()}_REG_IDX,
            start_addr : ${a_peripheral._name.upper()}_REG_BASE_ADDR,
            end_addr : ${a_peripheral._name.upper()}_REG_END_ADDR
        }
% if (idx != len(xalp.get_peripheral_domain("peripherals").get_peripherals()) - 1):
             ,
% endif
% endfor
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
