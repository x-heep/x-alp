# Peripheral Subsystem

from typing import List, Optional

from .abstractions import Peripheral, PeripheralDomain


class PeripheralSubsystem(PeripheralDomain):
    """
    Base class for all peripheral subsystems.

    A peripheral subsystem is a group of peripherals that is connected to the
    system bus as an independent node. Each subsystem can be assigned to a
    power domain and can support clock gating, so that subsystems can be
    grouped and switched off or clock gated together.

    Unlike the abstract :class:`PeripheralDomain`, this class is concrete:
    arbitrary subsystems can be instantiated and connected to the bus of a
    bus-centric system (see :class:`XAlp`). The base and user peripheral
    domains inherit from this class.

    :param str name: The name of the subsystem. Convention : starts with a capital letter and is in singular form.
    :param int start_address: The start address of the subsystem.
    :param int length: The length of the subsystem.
    :param str power_domain: The name of the power domain the subsystem belongs to. `None` means the subsystem is always-on. Subsystems sharing the same power domain name are switched on/off together.
    :param bool clock_gating: `True` if the subsystem supports clock gating.
    """

    def __init__(
        self,
        name: str,
        start_address: int,
        length: int,
        power_domain: Optional[str] = None,
        clock_gating: bool = False,
        peripherals: Optional[List[Peripheral]] = None,
    ):
        """
        Initialize the peripheral subsystem.
        """
        super().__init__(
            name=name,
            start_address=start_address,
            length=length,
            peripherals=peripherals,
        )
        if power_domain is not None and type(power_domain) is not str:
            raise TypeError(
                f"PeripheralSubsystem.power_domain should be of type str not {type(power_domain)}"
            )
        if type(clock_gating) is not bool:
            raise TypeError(
                f"PeripheralSubsystem.clock_gating should be of type bool not {type(clock_gating)}"
            )
        self._power_domain = power_domain
        self._clock_gating = clock_gating

    def get_name(self):
        """
        :return: The name of the peripheral subsystem.
        :rtype: str
        """
        return self._name

    # ------------------------------------------------------------
    # Peripherals
    # ------------------------------------------------------------

    def add_peripheral(self, peripheral: Peripheral):
        """
        Add a peripheral to the subsystem. The peripheral should be fully
        configured when added. If the peripheral has no offset, it will be
        automatically computed during build.

        :param Peripheral peripheral: The peripheral to add.
        :raise ValueError: when peripheral is not a Peripheral.
        """
        if not isinstance(peripheral, Peripheral):
            raise ValueError("Peripheral is not a Peripheral")
        self._peripherals.append(peripheral)

    def remove_peripheral(self, peripheral: Peripheral):
        """
        Remove a peripheral from the subsystem.

        :param Peripheral peripheral: The peripheral to remove.
        """
        if peripheral not in self._peripherals:
            print(
                f"Warning : Peripheral {peripheral.get_name()} is not in the subsystem {self._name}"
            )
            return
        self._peripherals.remove(peripheral)

    # ------------------------------------------------------------
    # Power / Clock-Gating Domain
    # ------------------------------------------------------------

    def set_power_domain(self, power_domain: Optional[str]):
        """
        Assign the subsystem to a power domain. Subsystems sharing the same
        power domain name are switched on/off together.

        :param str power_domain: The name of the power domain. `None` means always-on.
        :raise TypeError: when power_domain is of incorrect type.
        """
        if power_domain is not None and type(power_domain) is not str:
            raise TypeError(
                f"PeripheralSubsystem.power_domain should be of type str not {type(power_domain)}"
            )
        self._power_domain = power_domain

    def get_power_domain(self):
        """
        :return: The name of the power domain the subsystem belongs to, `None` if always-on.
        :rtype: str
        """
        return self._power_domain

    def has_power_domain(self) -> bool:
        """
        :return: `True` if the subsystem belongs to a switchable power domain, `False` if always-on.
        :rtype: bool
        """
        return self._power_domain is not None

    def is_always_on(self) -> bool:
        """
        :return: `True` if the subsystem is always-on (no switchable power domain).
        :rtype: bool
        """
        return self._power_domain is None

    def set_clock_gating(self, clock_gating: bool):
        """
        Enable or disable clock gating support for the subsystem.

        :param bool clock_gating: `True` if the subsystem supports clock gating.
        :raise TypeError: when clock_gating is of incorrect type.
        """
        if type(clock_gating) is not bool:
            raise TypeError(
                f"PeripheralSubsystem.clock_gating should be of type bool not {type(clock_gating)}"
            )
        self._clock_gating = clock_gating

    def has_clock_gating(self) -> bool:
        """
        :return: `True` if the subsystem supports clock gating.
        :rtype: bool
        """
        return self._clock_gating
