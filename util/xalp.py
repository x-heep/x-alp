from SystemGen.system import System
from SystemGen.peripherals.abstractions import Peripheral, PeripheralDomain

class Slave:
    def __init__(self, name: str, start_address: int, length: int):
        self.name = name
        self.start_address = start_address
        self.length = length
        self.end_address = start_address + length

    def get_start_address(self):
        return f"0x{self.start_address:016x}"

    def get_length(self):
        return f"0x{self.length:016x}"
    
    def get_end_address(self):
        return f"0x{self.end_address:016x}"


class Bus:
    def __init__(self):
        self.masters = []
        self.slaves = []

    def add_master(self, master):
        self.masters.append(master)

    def add_slave(self, slave: Slave):
        self.slaves.append(slave)
    
    def get_slave(self, name: str) -> Slave:
        for slave in self.slaves:
            if slave.name == name:
                return slave
        raise ValueError(f"No slave found with name {name}")
    
    def get_num_slaves(self):
        return len(self.slaves)
    
    def get_num_masters(self):
        return len(self.masters)
    
    def get_slaves(self):
        return self.slaves

    def get_masters(self):
        return self.masters

class Peripherals(PeripheralDomain):
    def __init__(self, start_address: int = 0x20000000, length: int = 0x00100000):
        """
        Initialize the base peripheral domain.
        Start address : 0x20000000
        Length :       0x00100000

        At the beginning, there is no base peripheral. All non-added peripherals will be added during build().
        """
        super().__init__(
            name="Base",
            start_address=start_address,
            length=length,
        )

    def add_peripheral(self, peripheral: Peripheral):
        """
        Add a peripheral to the domain if it is a BasePeripheral. If not, raise an error.

        :param Peripheral peripheral: The peripheral to add.
        """
        if not isinstance(peripheral, Peripheral):
            raise ValueError("Peripheral is not a Peripheral")
        self._peripherals.append(peripheral)

    def remove_peripheral(self, peripheral: Peripheral):
        """
        Remove a peripheral from the domain if it is a BasePeripheral.

        :param Peripheral peripheral: The peripheral to remove.
        """
        if peripheral not in self._peripherals:
            print(
                f"Warning : Peripheral {peripheral.get_name()} is not in the domain {self._name}"
            )
        self._peripherals.remove(peripheral)

class ext_peripipheral(Peripheral):
    def __init__(self, start_address: int, length: int):
        super().__init__(
            offset=start_address,
            length=length,
        )
        self._name = f"ext_peripheral"


class XAlp(System):

    def __init__(self):
        super().__init__()
        self._name = "XAlp"
        self.peripheral_domain = Peripherals()

    def set_bus(self, bus: Bus):
        self.bus = bus

    def build(self):
        return True
    
    def validate(self):
        # Check that the bus is configured
        if not hasattr(self, "bus"):
            raise ValueError("Bus is not configured")

        # Check that the CPU is configured
        if self.cpu() is None:
            raise ValueError("CPU is not configured")

        # Check that the peripheral domains are configured
        if len(self._peripheral_domains) == 0:
            raise ValueError("No peripheral domain configured")

        return True

    