// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

<%
    memory_ss = xheep.memory_ss()
%>

{ name: "power_manager_xheep",
  clock_primary: "clk_i",
  bus_interfaces: [
    { protocol: "reg_iface", direction: "device" }
  ],
  regwidth: "32",
  registers: [

% for channel in range(xheep.get_base_peripheral_domain().get_dma().get_num_channels()):
    { name:     "DMA_CH${channel}_CLK_GATE",
      desc:     "Clock-gates the DMA CH${channel}",
      resval:   "0x00000000"
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0", name: "DMA_CH${channel}_CLK_GATE", desc: "Clock-gates the DMA CH${channel}" }
      ]
    }
% endfor

% for bank in memory_ss.iter_ram_banks():
    { name:     "RAM_${bank.name()}_CLK_GATE",
      desc:     "Clock-gates the RAM_${bank.name()} domain",
      resval:   "0x00000000"
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0", name: "RAM_${bank.name()}_CLK_GATE", desc: "Clock-gates the RAM_${bank.name()} domain" }
      ]
    }

    { name:     "POWER_GATE_RAM_BLOCK_${bank.name()}_ACK",
      desc:     "Used by the ram ${bank.name()} switch to ack the power manager",
      resval:   "0x00000000"
      swaccess: "ro",
      hwaccess: "hrw",
      fields: [
        { bits: "0", name: "POWER_GATE_RAM_BLOCK_${bank.name()}_ACK", desc: "Power Gate Ram Block ${bank.name()} Ack Reg" }
      ]
    }

    { name:     "RAM_${bank.name()}_SWITCH",
      desc:     "Switch off the RAM_${bank.name()} domain",
      resval:   "0x00000000"
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0", name: "RAM_${bank.name()}_SWITCH", desc: "Switch off RAM_${bank.name()} domain" }
      ]
    }

    { name:     "RAM_${bank.name()}_WAIT_ACK_SWITCH_ON",
      desc:     "Wait for the RAM_${bank.name()} domain switch ack",
      resval:   "0x00000000"
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0", name: "RAM_${bank.name()}_WAIT_ACK_SWITCH_ON", desc: "Wait RAM_${bank.name()} domain switch ack" }
      ]
    }

    { name:     "RAM_${bank.name()}_ISO",
      desc:     "Set on the isolation of the RAM_${bank.name()} domain",
      resval:   "0x00000000"
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0", name: "RAM_${bank.name()}_ISO", desc: "Set on isolation of RAM_${bank.name()} domain" }
      ]
    }

    { name:     "RAM_${bank.name()}_RETENTIVE",
      desc:     "Set on retentive mode for the RAM_${bank.name()} domain",
      resval:   "0x00000000"
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0", name: "RAM_${bank.name()}_RETENTIVE", desc: "Set on retentive mode for RAM_${bank.name()} domain" }
      ]
    }
    
    { name:     "MONITOR_POWER_GATE_RAM_BLOCK_${bank.name()}",
      desc:     "Used to monitor the signals to power gate ram block ${bank.name()}",
      resval:   "0x00000000"
      swaccess: "ro",
      hwaccess: "hwo",
      fields: [
        { bits: "1:0", name: "MONITOR_POWER_GATE_RAM_BLOCK_${bank.name()}", desc: "Monitor Signals Power Gate Ram Block ${bank.name()} Reg" }
      ]
    }

% endfor
% for ext in range(external_domains):
    { name:     "EXTERNAL_${ext}_CLK_GATE",
      desc:     "Clock-gates the EXTERNAL_${ext} domain",
      resval:   "0x00000000"
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0", name: "EXTERNAL_${ext}_CLK_GATE", desc: "Clock-gates the EXTERNAL_${ext} domain" }
      ]
    }

    { name:     "POWER_GATE_EXTERNAL_${ext}_ACK",
      desc:     "Used by the external ${ext} switch to ack the power manager",
      resval:   "0x00000000"
      swaccess: "ro",
      hwaccess: "hrw",
      fields: [
        { bits: "0", name: "POWER_GATE_EXTERNAL_${ext}_ACK", desc: "Power Gate External ${ext} Ack Reg" }
      ]
    }

    { name:     "EXTERNAL_${ext}_RESET",
      desc:     "Reset the EXTERNAL_${ext} domain",
      resval:   "0x00000000"
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0", name: "EXTERNAL_${ext}_RESET", desc: "Reset EXTERNAL_${ext} domain" }
      ]
    }

    { name:     "EXTERNAL_${ext}_SWITCH",
      desc:     "Switch off the EXTERNAL_${ext} domain",
      resval:   "0x00000000"
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0", name: "EXTERNAL_${ext}_SWITCH", desc: "Switch off EXTERNAL_${ext} domain" }
      ]
    }

    { name:     "EXTERNAL_${ext}_WAIT_ACK_SWITCH_ON",
      desc:     "Wait for the EXTERNAL_${ext} domain switch ack",
      resval:   "0x00000000"
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0", name: "EXTERNAL_${ext}_WAIT_ACK_SWITCH_ON", desc: "Wait EXTERNAL_${ext} domain switch ack" }
      ]
    }

    { name:     "EXTERNAL_${ext}_ISO",
      desc:     "Set on the isolation of the EXTERNAL_${ext} domain",
      resval:   "0x00000000"
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0", name: "EXTERNAL_${ext}_ISO", desc: "Set on isolation of EXTERNAL_${ext} domain" }
      ]
    }

    { name:     "EXTERNAL_RAM_${ext}_RETENTIVE",
      desc:     "Set on retentive mode for external RAM_${ext} domain",
      resval:   "0x00000000"
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "0", name: "EXTERNAL_RAM_${ext}_RETENTIVE", desc: "Set on retentive mode of external RAM_${ext} domain" }
      ]
    }

    { name:     "MONITOR_POWER_GATE_EXTERNAL_${ext}",
      desc:     "Used to monitor the signals to power gate external ${ext}",
      resval:   "0x00000000"
      swaccess: "ro",
      hwaccess: "hwo",
      fields: [
        { bits: "2:0", name: "MONITOR_POWER_GATE_EXTERNAL_${ext}", desc: "Monitor Signals Power Gate External ${ext} Reg" }
      ]
    }

% endfor

   ]
}