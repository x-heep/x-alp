// Copyright 2021 Thales DIS design services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Jean-Roch COULON - Thales
//
// Copyright 2023 Commissariat a l'Energie Atomique et aux Energies
//                Alternatives (CEA)
//
// Author: Cesar Fuguet - CEA
// Date: August, 2023
// Description: CVA6 configuration package using the HPDcache as cache subsystem


package cva6_config_pkg;

    localparam int CVA6ConfigXlen = 64;

    localparam int CVA6ConfigRVF = 1;
    localparam int CVA6ConfigRVD = 1;
    localparam int CVA6ConfigF16En = 0;
    localparam int CVA6ConfigF16AltEn = 0;
    localparam int CVA6ConfigF8En = 0;
    localparam int CVA6ConfigFVecEn = 0;

    localparam int CVA6ConfigCvxifEn = 1;
    localparam int CVA6ConfigCExtEn = 1;
    localparam int CVA6ConfigZcbExtEn = 1;
    localparam int CVA6ConfigZcmpExtEn = 0;
    localparam int CVA6ConfigAExtEn = 1;
    localparam int CVA6ConfigBExtEn = 1;
    localparam int CVA6ConfigVExtEn = 0;
    localparam int CVA6ConfigHExtEn = 0;
    localparam int CVA6ConfigRVZiCond = 1;

    localparam int CVA6ConfigAxiIdWidth = core_v_mcu_pkg::AxiMstIdWidth;
    localparam int CVA6ConfigAxiAddrWidth = core_v_mcu_pkg::AxiAddrWidth;
    localparam int CVA6ConfigAxiDataWidth = core_v_mcu_pkg::AxiDataWidth;
    localparam int CVA6ConfigFetchUserEn = 0;
    localparam int CVA6ConfigFetchUserWidth = CVA6ConfigXlen;
    localparam int CVA6ConfigDataUserEn = 0;
    localparam int CVA6ConfigDataUserWidth = CVA6ConfigXlen;

    localparam int CVA6ConfigIcacheByteSize = 16384;
    localparam int CVA6ConfigIcacheSetAssoc = 4;
    localparam int CVA6ConfigIcacheLineWidth = 128;
    localparam int CVA6ConfigDcacheByteSize = 32768;
    localparam int CVA6ConfigDcacheSetAssoc = 8;
    localparam int CVA6ConfigDcacheLineWidth = 128;

    localparam logic CVA6ConfigDcacheFlushOnFence = 1'b0;
    localparam logic CVA6ConfigDcacheInvalidateOnFlush = 1'b0;

    localparam int CVA6ConfigDcacheIdWidth = 3;
    localparam int CVA6ConfigMemTidWidth = CVA6ConfigAxiIdWidth;

    localparam int CVA6ConfigWtDcacheWbufDepth = 8;

    localparam int CVA6ConfigNrScoreboardEntries = 8;

    localparam int CVA6ConfigNrLoadPipeRegs = 1;
    localparam int CVA6ConfigNrStorePipeRegs = 0;
    localparam int CVA6ConfigNrLoadBufEntries = 8;

    localparam int CVA6ConfigRASDepth = 2;
    localparam int CVA6ConfigBTBEntries = 32;
    localparam int CVA6ConfigBHTEntries = 128;

    localparam int CVA6ConfigTvalEn = 1;

    localparam int CVA6ConfigNrPMPEntries = 8;

    localparam int CVA6ConfigPerfCounterEn = 1;

    localparam config_pkg::cache_type_t CVA6ConfigDcacheType = config_pkg::WT;

    localparam int CVA6ConfigMmuPresent = 0;

    localparam int CVA6ConfigRvfiTrace = 1;

    localparam config_pkg::cva6_user_cfg_t cva6_cfg = '{
        XLEN: unsigned'(CVA6ConfigXlen),
        VLEN: unsigned'(64),
        FpgaEn: bit'(0),  // for Xilinx and Altera
        FpgaAlteraEn: bit'(0),  // for Altera (only)
        TechnoCut: bit'(0),
        SuperscalarEn: bit'(0),
        ALUBypass: bit'(0),
        NrCommitPorts: unsigned'(2),
        AxiAddrWidth: unsigned'(CVA6ConfigAxiAddrWidth),
        AxiDataWidth: unsigned'(CVA6ConfigAxiDataWidth),
        AxiIdWidth: unsigned'(CVA6ConfigAxiIdWidth),
        AxiUserWidth: unsigned'(CVA6ConfigDataUserWidth),
        MemTidWidth: unsigned'(CVA6ConfigMemTidWidth),
        NrLoadBufEntries: unsigned'(CVA6ConfigNrLoadBufEntries),
        RVF: bit'(CVA6ConfigRVF),
        RVD: bit'(CVA6ConfigRVD),
        XF16: bit'(CVA6ConfigF16En),
        XF16ALT: bit'(CVA6ConfigF16AltEn),
        XF8: bit'(CVA6ConfigF8En),
        RVA: bit'(CVA6ConfigAExtEn),
        RVB: bit'(CVA6ConfigBExtEn),
        ZKN: bit'(1),
        RVV: bit'(CVA6ConfigVExtEn),
        RVC: bit'(CVA6ConfigCExtEn),
        RVH: bit'(CVA6ConfigHExtEn),
        RVZCB: bit'(CVA6ConfigZcbExtEn),
        RVZCMP: bit'(CVA6ConfigZcmpExtEn),
        RVZCMT: bit'(0),
        XFVec: bit'(CVA6ConfigFVecEn),
        CvxifEn: bit'(CVA6ConfigCvxifEn),
        CoproType: config_pkg::COPRO_NONE,
        RVZiCond: bit'(CVA6ConfigRVZiCond),
        RVZicntr: bit'(1),
        RVZihpm: bit'(1),
        NrScoreboardEntries: unsigned'(CVA6ConfigNrScoreboardEntries),
        PerfCounterEn: bit'(CVA6ConfigPerfCounterEn),
        MmuPresent: bit'(CVA6ConfigMmuPresent),
        RVS: bit'(1),
        RVU: bit'(1),
        SoftwareInterruptEn: bit'(1),
        HaltAddress: 64'h800,
        ExceptionAddress: 64'h808,
        RASDepth: unsigned'(CVA6ConfigRASDepth),
        BTBEntries: unsigned'(CVA6ConfigBTBEntries),
        BPType: config_pkg::BHT,
        BHTEntries: unsigned'(CVA6ConfigBHTEntries),
        BHTHist: unsigned'(3),
        DmBaseAddress: 64'h0,
        TvalEn: bit'(CVA6ConfigTvalEn),
        DirectVecOnly: bit'(0),
        NrPMPEntries: unsigned'(CVA6ConfigNrPMPEntries),
        PMPCfgRstVal: {64{64'h0}},
        PMPAddrRstVal: {64{64'h0}},
        PMPEntryReadOnly: 64'd0,
        PMPNapotEn: bit'(1),
        NOCType: config_pkg::NOC_TYPE_AXI4_ATOP,
        NrNonIdempotentRules: unsigned'(1),
        NonIdempotentAddrBase:
        1024'(
        {
            core_v_mcu_pkg::SOC_CTRL_REG_START_ADDR,
            core_v_mcu_pkg::FAST_INTR_CTRL_REG_START_ADDR,
            core_v_mcu_pkg::UART_REG_START_ADDR
        }
        ),
        NonIdempotentLength:
        1024'(
        {
            core_v_mcu_pkg::SOC_CTRL_REG_SIZE,
            core_v_mcu_pkg::FAST_INTR_CTRL_REG_SIZE,
            core_v_mcu_pkg::UART_REG_SIZE
        }
        ),
        NrExecuteRegionRules: unsigned'(2),
        ExecuteRegionAddrBase:
        1024'(
        {core_v_mcu_pkg::BOOT_ROM_REG_START_ADDR, core_v_mcu_pkg::MEM_BUS_BASE_ADDR}
        ),
        ExecuteRegionLength:
        1024'(
        {core_v_mcu_pkg::BOOT_ROM_REG_SIZE, core_v_mcu_pkg::MEM_BUS_SIZE}
        ),
        NrCachedRegionRules: unsigned'(1),
        CachedRegionAddrBase: 1024'({core_v_mcu_pkg::MEM_BUS_BASE_ADDR}),
        CachedRegionLength: 1024'({core_v_mcu_pkg::MEM_BUS_SIZE}),
        MaxOutstandingStores: unsigned'(7),
        DebugEn: bit'(1),
        SDTRIG: bit'(0),
        Mcontrol6: bit'(0),
        Icount: bit'(0),
        Etrigger: bit'(0),
        Itrigger: bit'(0),
        AxiBurstWriteEn: bit'(0),
        IcacheByteSize: unsigned'(CVA6ConfigIcacheByteSize),
        IcacheSetAssoc: unsigned'(CVA6ConfigIcacheSetAssoc),
        IcacheLineWidth: unsigned'(CVA6ConfigIcacheLineWidth),
        DCacheType: CVA6ConfigDcacheType,
        DcacheByteSize: unsigned'(CVA6ConfigDcacheByteSize),
        DcacheSetAssoc: unsigned'(CVA6ConfigDcacheSetAssoc),
        DcacheLineWidth: unsigned'(CVA6ConfigDcacheLineWidth),
        DcacheFlushOnFence: bit'(CVA6ConfigDcacheFlushOnFence),
        DcacheInvalidateOnFlush: bit'(CVA6ConfigDcacheInvalidateOnFlush),
        DataUserEn: unsigned'(CVA6ConfigDataUserEn),
        WtDcacheWbufDepth: int'(CVA6ConfigWtDcacheWbufDepth),
        FetchUserWidth: unsigned'(CVA6ConfigFetchUserWidth),
        FetchUserEn: unsigned'(CVA6ConfigFetchUserEn),
        InstrTlbEntries: int'(16),
        DataTlbEntries: int'(16),
        UseSharedTlb: bit'(0),
        SharedTlbDepth: int'(64),
        NrLoadPipeRegs: int'(CVA6ConfigNrLoadPipeRegs),
        NrStorePipeRegs: int'(CVA6ConfigNrStorePipeRegs),
        DcacheIdWidth: int'(CVA6ConfigDcacheIdWidth)
    };

endpackage
