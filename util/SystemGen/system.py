from copy import deepcopy
from abc import ABC, abstractmethod
from .cpu.cpu import CPU
from .peripherals.abstractions import PeripheralDomain
from .peripherals.base_peripherals_domain import BasePeripheralDomain
from .peripherals.user_peripherals_domain import UserPeripheralDomain
from .pads.PadRing import PadRing


class System(ABC):
    # ------------------------------------------------------------
    # CPU
    # ------------------------------------------------------------

    def __init__(self):
        self._cpu = None
        self._peripheral_domains = {}
        self._extensions = {}

    def set_cpu(self, cpu: CPU):
        """
        Sets the CPU of the system.

        :param CPU cpu: The CPU to set.
        :raise TypeError: when cpu is of incorrect type.
        """
        if not isinstance(cpu, CPU):
            raise TypeError(f"XHeep.cpu should be of type CPU not {type(self._cpu)}")
        self._cpu = cpu

    def cpu(self) -> CPU:
        """
        :return: the configured CPU
        :rtype: CPU
        """
        return self._cpu

    # ------------------------------------------------------------
    # Peripherals
    # ------------------------------------------------------------

    def _default_domain_name(self, domain: PeripheralDomain):
        if isinstance(domain, BasePeripheralDomain):
            return "base"
        if isinstance(domain, UserPeripheralDomain):
            return "user"
        return None

    def add_peripheral_domain(self, domain: PeripheralDomain, name: str = None):
        """
        Add a peripheral domain to the system. The domain should already contain all peripherals well configured. When adding a domain, a deepcopy is made to avoid side effects.

        :param PeripheralDomain domain: The domain to add.
        :param str name: Name of the domain. If not provided, defaults are used for base/user domains.
        """
        if not isinstance(domain, PeripheralDomain):
            raise TypeError(
                f"System.add_peripheral_domain expects a PeripheralDomain not {type(domain)}"
            )
        if name is None:
            name = self._default_domain_name(domain)
        if name is None:
            raise ValueError("Peripheral domain name must be provided for this type")
        if name in self._peripheral_domains:
            raise ValueError(f"Peripheral domain '{name}' already exists")
        self._peripheral_domains[name] = deepcopy(domain)

    def has_peripheral_domain(self, name: str) -> bool:
        """
        :return: `True` if the domain is configured, `False` otherwise.
        :rtype: bool
        """
        return name in self._peripheral_domains

    def get_peripheral_domain(self, name: str):
        """
        Returns a deepcopy of a peripheral domain by name.

        :param str name: Name of the domain.
        :return: The peripheral domain or None if missing.
        :rtype: PeripheralDomain
        """
        domain = self._peripheral_domains.get(name)
        return deepcopy(domain) if domain is not None else None

    def peripheral_domains(self):
        """
        Returns a deepcopy of all configured peripheral domains.

        :return: Mapping of domain names to domains.
        :rtype: dict
        """
        return {
            name: deepcopy(domain) for name, domain in self._peripheral_domains.items()
        }

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
                f"xheep.get_padring() should be of type PadRing not {type(self._padring)}"
            )
        self._padring = pad_ring

    def get_padring(self):
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

    # ------------------------------------------------------------
    # Build and Validate
    # ------------------------------------------------------------

    @abstractmethod
    def build(self):
        """
        Makes the system ready to be used.
        """

    @abstractmethod
    def validate(self) -> bool:
        """
        Does some basics checks on the configuration

        This should be called before using the System object to generate the project.

        :return: the validity of the configuration
        :rtype: bool
        """
