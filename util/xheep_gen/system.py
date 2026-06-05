from abc import ABC, abstractmethod
from memory_ss.memory_ss import MemorySS
from cpu.cpu import CPU
from cv_x_if import CvXIf
from peripherals.abstractions import PeripheralDomain
from pads.pad_ring import PadRing


class System(ABC):
    """
    Abstract base class for the system.
    
    """

    @abstractmethod
    def __init__(self):

        self._cpu = None

        self._xif: CvXIf = None

        self._memory_ss = None

        self._padring: PadRing = None

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
            raise TypeError(f"XHeep.cpu should be of type CPU not {type(self._cpu)}")
        self._cpu = cpu

    def cpu(self) -> CPU:
        """
        :return: the configured CPU
        :rtype: CPU
        """
        return self._cpu
    
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

    def xif(self) -> CvXIf:
        """
        :return: the configured CV-X-IF
        :rtype: CvXIf
        """
        return self._xif

    # ------------------------------------------------------------
    # Memory
    # ------------------------------------------------------------

    def set_memory_ss(self, memory_ss: MemorySS):
        """
        Sets the memory subsystem of the system.

        :param MemorySS memory_ss: The memory subsystem to set.
        :raise TypeError: when memory_ss is of incorrect type.
        """
        if not isinstance(memory_ss, MemorySS):
            raise TypeError(
                f"XHeep.memory_ss should be of type MemorySS not {type(self._memory_ss)}"
            )
        self._memory_ss = memory_ss

    def memory_ss(self) -> MemorySS:
        """
        :return: the configured memory subsystem
        :rtype: MemorySS
        """
        return self._memory_ss

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

    def is_extension_defined(self, name):
        """
        Check if an extension is defined.

        :param str name: Name of the extension.
        :return: `True` if the extension is defined, `False` otherwise.
        :rtype: bool
        """
        return name in self._extensions

