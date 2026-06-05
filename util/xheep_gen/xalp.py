import sys
from system import System
from peripherals.base_peripherals_domain import BasePeripheralDomain

class XAlp(System):
    """
    XAlp is a specific implementation of the System class, representing a particular system configuration.
    It inherits from the abstract base class System and provides concrete implementations for its methods.
    """
    
    def __init__(self):
        super().__init__()

        self.peripherals = []
        
    # ------------------------------------------------------------
    # Peripherals
    # ------------------------------------------------------------

    def set_peripherals(self, peripherals: BasePeripheralDomain):
        """
        Sets the peripherals of the system.

        :param BasePeripheralDomain peripherals: The peripherals to set.
        :raise TypeError: when peripherals is of incorrect type.
        """
        if not isinstance(peripherals, BasePeripheralDomain):
            raise TypeError(f"XAlp.peripherals should be of type BasePeripheralDomain not {type(peripherals)}")
        self.peripherals.append(peripherals)

    def get_peripherals(self) -> list[BasePeripheralDomain]:
        """
        :return: the configured peripherals
        :rtype: list[BasePeripheralDomain]
        """
        return self.peripherals
    
    def build(self):
        """
        Builds the system configuration based on the set parameters and peripherals.
        This method can be extended to include additional build steps as needed.
        """
        # Example build steps (to be implemented as needed)
        print("Building XAlp system configuration...")
        print(f"CPU: {self.cpu()}")
        print(f"CV-X-IF: {self.xif()}")
        print(f"Peripherals: {self.get_peripherals()}")

    def validate(self):
        """
        Validates the system configuration to ensure all required parameters and peripherals are set correctly.
        This method can be extended to include specific validation rules as needed.
        """
        # Example validation steps (to be implemented as needed)
        print("Validating XAlp system configuration...")
        if self.cpu() is None:
            raise ValueError("CPU is not configured.")

        print("XAlp system configuration is valid.")

