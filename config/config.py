from SystemGen.cpu.cva6 import cva6
from SystemGen.peripherals.base_peripherals import Fast_intr_ctrl
from SystemGen.peripherals.user_peripherals.riscv_debug import UART
from SystemGen.peripherals.base_peripherals.Boot_room import Bootrom
from SystemGen.peripherals.base_peripherals.SOC_ctl import SOC_ctrl

from xalp import Bus
from xalp import Peripherals
from xalp import XAlp
from xalp import Slave
from xalp import ext_peripipheral

def config():
    system = XAlp()

    system.set_cpu(cva6())

    bus = Bus()

    bus.add_master("CPU")
    bus.add_master("DEBUG_MODULE")
    bus.add_master("EXT_MASTER")

    bus.add_slave(Slave("MEM", 0x00000000, 0x10000))
    bus.add_slave(Slave("DEBUG_MODULE", bus.get_slave("MEM").end_address, 0x10000))
    bus.add_slave(Slave("PERIPHERALS", bus.get_slave("DEBUG_MODULE").end_address, 0x10000000))
    bus.add_slave(Slave("EXT_SLAVE", bus.get_slave("PERIPHERALS").end_address, 0x10000))

    system.set_bus(bus)

    peripheral_domain = Peripherals("peripherals", )
    peripheral_domain.add_peripheral(SOC_ctrl(0x0, 0x1000))
    peripheral_domain.add_peripheral(Bootrom(0x10000, 0x10000))
    peripheral_domain.add_peripheral(Fast_intr_ctrl(0x20000, 0x1000))
    peripheral_domain.add_peripheral(UART(0x10000000, 0x1000))
    peripheral_domain.add_peripheral(ext_peripipheral(0x11000000, 0x1000))

    system.add_peripheral_domain(peripheral_domain, "peripherals")

    system.validate()

    return system
