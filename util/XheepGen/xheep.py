from copy import deepcopy
from typing import Optional
from .bus import Bus, BusType
from .cv_x_if import CvXIf
from .memory_ss.memory_ss import MemorySS
from .peripherals.abstractions import PeripheralDomain
from .peripherals.base_peripherals_domain import BasePeripheralDomain
from .peripherals.user_peripherals_domain import UserPeripheralDomain
from .system import System


class XHeep(System):
    """
    Represents the whole X-HEEP system.

    An instance of this class is passed to the mako templates.
    Inherits generic SoC functionality from :class:`System` and adds
    X-HEEP-specific features (CV-X-IF, memory subsystem, interleaved-memory
    bus checks, base/user peripheral domain management, etc.).

    :param Bus bus: The bus configuration for this system.
    :raise TypeError: when parameters are of incorrect type.
    """

    IL_COMPATIBLE_BUS_TYPES = [BusType.NtoM]
    """Constant set of bus types that support interleaved memory banks"""

    def __init__(
        self,
        bus: Bus,
    ):
        super().__init__(bus)
        self._xif: Optional[CvXIf] = None
        self._memory_ss: Optional[MemorySS] = None
        self._base_peripheral_domain: Optional[BasePeripheralDomain] = None
        self._user_peripheral_domain: Optional[UserPeripheralDomain] = None

    # ------------------------------------------------------------
    # CORE-V eXtension Interface (CV-X-IF)
    # ------------------------------------------------------------

    def set_xif(self, xif: CvXIf):
        """
        Sets the configuration of the CORE-V eXtension Interface (CV-X-IF).

        :param CvXIf xif: CV-X-IF instance with the desired paramters.

        :raise TypeError: when xif is of incorrect type.
        """
        if not isinstance(xif, CvXIf):
            raise TypeError(f"XHeep.xif should be of type CvXIf not {type(xif)}")
        self._xif = xif

    def xif(self) -> Optional[CvXIf]:
        """
        :return: the configured CV-X-IF
        :rtype: Optional[CvXIf]
        """
        return self._xif

    # ------------------------------------------------------------
    # Memory Subsystem (X-HEEP specific)
    # ------------------------------------------------------------

    def set_memory_ss(self, memory_ss: MemorySS):
        """
        Sets the memory subsystem.

        :param MemorySS memory_ss: The memory subsystem to set.
        :raise TypeError: when memory_ss is of incorrect type.
        """
        if not isinstance(memory_ss, MemorySS):
            raise TypeError(
                f"XHeep.memory_ss should be of type MemorySS not {type(memory_ss)}"
            )
        self._memory_ss = memory_ss

    def memory_ss(self) -> Optional[MemorySS]:
        """
        :return: the configured memory subsystem
        :rtype: Optional[MemorySS]
        """
        return self._memory_ss

    # ------------------------------------------------------------
    # Peripheral Domains (X-HEEP specific)
    # ------------------------------------------------------------

    def are_base_peripherals_configured(self) -> bool:
        """
        :return: `True` if the base peripherals are configured, `False` otherwise.
        :rtype: bool
        """
        return self._base_peripheral_domain is not None

    def are_user_peripherals_configured(self) -> bool:
        """
        :return: `True` if the user peripherals are configured, `False` otherwise.
        :rtype: bool
        """
        return self._user_peripheral_domain is not None

    def are_peripherals_configured(self) -> bool:
        """
        :return: `True` if both base and user peripherals are configured, `False` otherwise.
        :rtype: bool
        """
        return (
            self.are_base_peripherals_configured()
            and self.are_user_peripherals_configured()
        )

    def add_peripheral_domain(self, domain: PeripheralDomain):
        """
        Add a peripheral domain to the system. The domain should already
        contain all peripherals well configured. When adding a domain, a
        deepcopy is made to avoid side effects and the domain is also
        registered in the generic peripheral subsystems list.

        :param PeripheralDomain domain: The domain to add.
        """
        if isinstance(domain, BasePeripheralDomain):
            self._base_peripheral_domain = deepcopy(domain)
            super().add_peripheral_domain(domain)
        elif isinstance(domain, UserPeripheralDomain):
            self._user_peripheral_domain = deepcopy(domain)
            super().add_peripheral_domain(domain)
        else:
            raise ValueError(
                "Domain is neither a BasePeripheralDomain nor a UserPeripheralDomain"
            )

    def get_user_peripheral_domain(self):
        """
        Returns a deepcopy of the user peripheral domain.

        :return: The user peripheral domain.
        :rtype: UserPeripheralDomain
        """
        return deepcopy(self._user_peripheral_domain)

    def get_base_peripheral_domain(self):
        """
        Returns a deepcopy of the base peripheral domain.

        :return: The base peripheral domain.
        :rtype: BasePeripheralDomain
        """
        return deepcopy(self._base_peripheral_domain)

    # ------------------------------------------------------------
    # Build and Validate
    # ------------------------------------------------------------

    def build(self):
        """
        Makes the X-HEEP system ready to be used.

        Builds the memory subsystem, then delegates to the parent which
        builds all peripheral domains.
        """
        if self._memory_ss:
            self._memory_ss.build()
        super().build()

    def validate(self):
        """
        Does some basics checks on the X-HEEP configuration.

        Calls the parent :meth:`System.validate` first, then performs
        X-HEEP-specific checks (interleaved memory bus compatibility,
        base peripheral address constraint, CV-X-IF core compatibility).

        This should be called before using the XHeep object to generate the project.
        """
        super().validate()

        # Memory subsystem is required for X-HEEP
        if not self._memory_ss:
            raise RuntimeError("[MCU-GEN] ERROR: A memory subsystem must be configured")
        self._memory_ss.validate()

        # Interleaved memory requires a compatible bus type
        if self._memory_ss.has_il_ram() and (
            self.bus_type() not in self.IL_COMPATIBLE_BUS_TYPES
        ):
            raise RuntimeError(
                f"[MCU-GEN] ERROR: This system has a {self.bus_type()} bus, one of {self.IL_COMPATIBLE_BUS_TYPES} is required for interleaved memory"
            )

        # Base peripheral start address constraint
        if self.are_base_peripherals_configured():
            assert self._base_peripheral_domain is not None
            if (
                self._base_peripheral_domain.get_start_address() < 0x10000
            ):  # from mcu_gen.py
                raise RuntimeError(
                    f"[MCU-GEN] ERROR: Always on peripheral start address must be greater than 0x10000, current address is {self._base_peripheral_domain.get_start_address():#08X}."
                )

        # Check that the extension interface is enabled with a supported core
        cpu = self.cpu()
        assert cpu is not None  # guaranteed by super().validate()
        if self.xif() is not None and cpu.get_name() in ["cv32e40p"]:
            raise RuntimeError(
                f"[MCU-GEN] ERROR: CV-X-IF enabled (xheep.set_xif()) with incompatible CPU ({cpu.get_name()})."
            )

        return True
