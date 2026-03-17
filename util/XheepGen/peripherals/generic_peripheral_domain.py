# Generic Peripheral Domain - accepts any Peripheral subclass
from .abstractions import Peripheral, PeripheralDomain


class GenericPeripheralDomain(PeripheralDomain):
    """
    A generic peripheral domain that accepts any Peripheral subclass
    (both BasePeripheral and UserPeripheral).

    This is intended for systems like X-ALP that do not split peripherals
    into separate base/user domains.

    :param str name: The name of the peripheral domain.
    :param int start_address: The start address of the peripheral domain.
    :param int length: The length of the peripheral domain.
    """

    def __init__(
        self,
        name: str = "Generic",
        start_address: int = 0x00020000,
        length: int = 0x10000000,
    ):
        super().__init__(
            name=name,
            start_address=start_address,
            length=length,
        )

    def add_peripheral(self, peripheral: Peripheral):
        """
        Add a peripheral to the domain. Accepts any Peripheral subclass.

        :param Peripheral peripheral: The peripheral to add.
        """
        if not isinstance(peripheral, Peripheral):
            raise ValueError(f"Expected a Peripheral instance, got {type(peripheral)}")
        self._peripherals.append(peripheral)

    def remove_peripheral(self, peripheral: Peripheral):
        """
        Remove a peripheral from the domain.

        :param Peripheral peripheral: The peripheral to remove.
        """
        if peripheral not in self._peripherals:
            print(
                f"Warning : Peripheral {peripheral.get_name()} is not in the domain {self._name}"
            )
        self._peripherals.remove(peripheral)
