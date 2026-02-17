from copy import deepcopy
from typing import List, Optional
from .bus import Bus, BusType
from .cpu.cpu import CPU
from .peripherals.abstractions import PeripheralDomain
from .pads.pad_ring import PadRing


class System:
    """
    Represents a generic SoC system.

    This is the base class providing the common building blocks shared by all
    systems: CPU, bus, memory subsystem, peripheral domains, pad ring and a
    generic extension mechanism.

    Subclasses can extend or override :meth:`build` and :meth:`validate` to
    add system‑specific behaviour.

    :param Bus bus: The bus configuration for this system.
    :raise TypeError: when parameters are of incorrect type.
    """

    def __init__(self, bus: Bus):
        if not isinstance(bus, Bus):
            raise TypeError(f"System.bus should be of type Bus not {type(bus)}")

        self._cpu: Optional[CPU] = None
        self._bus: Bus = bus
        self._peripheral_domains: List[PeripheralDomain] = []
        self._padring: Optional[PadRing] = None
        self._extensions = {}

    # ------------------------------------------------------------
    # CPU
    # ------------------------------------------------------------

    def set_cpu(self, cpu: CPU):
        """
        Sets the CPU of the system.

        :param CPU cpu: The CPU to set.
        :raise TypeError: when cpu is of incorrect type.
        """
        if not isinstance(cpu, CPU):
            raise TypeError(f"System.cpu should be of type CPU not {type(cpu)}")
        self._cpu = cpu

    def cpu(self) -> Optional[CPU]:
        """
        :return: the configured CPU
        :rtype: Optional[CPU]
        """
        return self._cpu

    # ------------------------------------------------------------
    # Bus
    # ------------------------------------------------------------

    def set_bus(self, bus: Bus):
        """
        Replaces the bus configuration.

        :param Bus bus: The bus to set.
        :raise TypeError: when bus is of incorrect type.
        """
        if not isinstance(bus, Bus):
            raise TypeError(f"System.bus should be of type Bus not {type(bus)}")
        self._bus = bus

    def bus(self) -> Bus:
        """
        :return: the configured bus
        :rtype: Bus
        """
        return self._bus

    def bus_type(self) -> BusType:
        """
        Convenience accessor.

        :return: the bus type
        :rtype: BusType
        """
        return self._bus.bus_type

    # ------------------------------------------------------------
    # Peripheral Domains
    # ------------------------------------------------------------

    def add_peripheral_domain(self, domain: PeripheralDomain):
        """
        Add a peripheral domain to the system. A deepcopy is made to
        avoid side effects.

        :param PeripheralDomain domain: The domain to add.
        :raise TypeError: when domain is not a PeripheralDomain.
        """
        if not isinstance(domain, PeripheralDomain):
            raise TypeError(f"Expected a PeripheralDomain instance, got {type(domain)}")
        self._peripheral_domains.append(deepcopy(domain))

    def get_peripheral_domains(self) -> List[PeripheralDomain]:
        """
        Returns a deepcopy of the list of peripheral domains.

        :return: The list of peripheral domains.
        :rtype: List[PeripheralDomain]
        """
        return deepcopy(self._peripheral_domains)

    # ------------------------------------------------------------
    # Pad Ring
    # ------------------------------------------------------------

    def set_padring(self, pad_ring: PadRing):
        """
        Sets the pad ring of the system.

        :param PadRing pad_ring: The pad ring to set.
        :raise TypeError: when pad_ring is of incorrect type.
        """
        if not isinstance(pad_ring, PadRing):
            raise TypeError(
                f"System.padring should be of type PadRing not {type(pad_ring)}"
            )
        self._padring = pad_ring

    def get_padring(self):
        """
        :return: the configured pad ring
        :rtype: PadRing
        """
        return self._padring

    # ------------------------------------------------------------
    # Extensions
    # ------------------------------------------------------------

    def add_extension(self, name, extension):
        """
        Register an external extension or configuration (object, dict, etc.).

        :param str name: Name of the extension.
        :param Any extension: The extension object.
        """
        self._extensions[name] = extension

    def get_extension(self, name):
        """
        Retrieve a previously registered extension.

        :param str name: Name of the extension.
        :return: The extension object.
        :rtype: Any
        """
        return self._extensions.get(name, None)

    def is_extension_defined(self, name):
        """
        Check if an extension is defined.

        :param str name: Name of the extension.
        :return: `True` if the extension is defined, `False` otherwise.
        :rtype: bool
        """
        return name in self._extensions

    # ------------------------------------------------------------
    # Build and Validate
    # ------------------------------------------------------------

    def build(self):
        """
        Makes the system ready to be used.

        Subclasses should call ``super().build()`` when overriding.
        """
        for domain in self._peripheral_domains:
            domain.build()

    def validate(self):
        """
        Performs basic checks on the system configuration.

        This should be called before using the system object to generate the
        project.  Subclasses should call ``super().validate()`` and then add
        their own checks.

        :return: `True` if validation passes.
        :raise RuntimeError: when the configuration is invalid.
        """
        if not self.cpu():
            raise RuntimeError("[MCU-GEN] ERROR: A CPU must be configured")

        # Validate each peripheral domain
        for domain in self._peripheral_domains:
            domain.validate()

        # Validate bus (slave address overlap, unique indices, etc.)
        self._bus.validate()

        if not self._padring:
            raise RuntimeError("[MCU-GEN] ERROR: A padring must be configured")
        self._padring.validate()

        return True
