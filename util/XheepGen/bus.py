from enum import Enum
from copy import deepcopy
from typing import List, Optional


class BusType(Enum):
    """Enumeration of all supported bus types"""

    onetoM = "onetoM"
    NtoM = "NtoM"


class BusSlave:
    """
    Represents a slave port on the bus, mapped to an address range.

    :param str name: Human-readable name (e.g. ``"ram"``, ``"ao_peripherals"``).
    :param int start_address: Start address of this slave's window.
    :param int length: Length of the address window in bytes.
    :param int idx: Bus-level slave index (position in the address map).
    """

    def __init__(self, name: str, start_address: int, length: int, idx: int):
        if not isinstance(name, str):
            raise TypeError(f"name should be str, got {type(name)}")
        if not isinstance(start_address, int):
            raise TypeError(f"start_address should be int, got {type(start_address)}")
        if not isinstance(length, int) or length <= 0:
            raise ValueError(f"length should be a positive int, got {length}")
        if not isinstance(idx, int):
            raise TypeError(f"idx should be int, got {type(idx)}")

        self._name = name
        self._start_address = start_address
        self._length = length
        self._idx = idx

    @property
    def name(self) -> str:
        return self._name

    @property
    def start_address(self) -> int:
        return self._start_address

    @property
    def length(self) -> int:
        return self._length

    @property
    def end_address(self) -> int:
        """Exclusive end address."""
        return self._start_address + self._length

    @property
    def idx(self) -> int:
        return self._idx

    def __repr__(self) -> str:
        return (
            f"BusSlave(name={self._name!r}, start=0x{self._start_address:08X}, "
            f"length=0x{self._length:08X}, idx={self._idx})"
        )


class BusMaster:
    """
    Represents a master port on the bus.

    :param str name: Human-readable name (e.g. ``"cpu_data"``, ``"cpu_instr"``).
    :param int idx: Bus-level master index.
    """

    def __init__(self, name: str, idx: int):
        if not isinstance(name, str):
            raise TypeError(f"name should be str, got {type(name)}")
        if not isinstance(idx, int):
            raise TypeError(f"idx should be int, got {type(idx)}")
        self._name = name
        self._idx = idx

    @property
    def name(self) -> str:
        return self._name

    @property
    def idx(self) -> int:
        return self._idx

    def __repr__(self) -> str:
        return f"BusMaster(name={self._name!r}, idx={self._idx})"


class Bus:
    """
    Describes the system bus configuration: its type, the slave address map
    and the master port indices.

    Both X-HEEP and X-ALP (or any future system) use this class to declare
    which address regions are routed to which slave port and which masters
    can initiate transactions.

    :param BusType bus_type: The bus topology / protocol variant.
    """

    def __init__(self, bus_type: BusType):
        if not isinstance(bus_type, BusType):
            raise TypeError(
                f"Bus.bus_type should be of type BusType, got {type(bus_type)}"
            )
        self._bus_type: BusType = bus_type
        self._slaves: List[BusSlave] = []
        self._masters: List[BusMaster] = []
        self._next_slave_idx: int = 0
        self._next_master_idx: int = 0

    # ---- type -------------------------------------------------

    @property
    def bus_type(self) -> BusType:
        return self._bus_type

    # ---- slaves -----------------------------------------------

    def add_slave(
        self,
        name: str,
        start_address: int,
        length: int,
        idx: Optional[int] = None,
    ) -> BusSlave:
        """
        Register a slave port in the address map.

        :param str name: Slave name.
        :param int start_address: Start of the address window.
        :param int length: Size of the address window.
        :param int idx: Explicit slave index.  When ``None`` the next
            available index is used automatically.
        :return: The created :class:`BusSlave`.
        """
        if idx is None:
            idx = self._next_slave_idx
        slave = BusSlave(name, start_address, length, idx)
        self._slaves.append(slave)
        if idx >= self._next_slave_idx:
            self._next_slave_idx = idx + 1
        return slave

    def get_slaves(self) -> List[BusSlave]:
        """Return a copy of the slave list."""
        return list(self._slaves)

    def num_slaves(self) -> int:
        return len(self._slaves)

    # ---- masters ----------------------------------------------

    def add_master(
        self,
        name: str,
        idx: Optional[int] = None,
    ) -> BusMaster:
        """
        Register a master port.

        :param str name: Master name.
        :param int idx: Explicit master index.  When ``None`` the next
            available index is used automatically.
        :return: The created :class:`BusMaster`.
        """
        if idx is None:
            idx = self._next_master_idx
        master = BusMaster(name, idx)
        self._masters.append(master)
        if idx >= self._next_master_idx:
            self._next_master_idx = idx + 1
        return master

    def get_masters(self) -> List[BusMaster]:
        """Return a copy of the master list."""
        return list(self._masters)

    def num_masters(self) -> int:
        return len(self._masters)

    # ---- validation -------------------------------------------

    def validate(self):
        """
        Check that no two slave windows overlap and that indices are unique.

        :raise RuntimeError: on overlapping address ranges or duplicate indices.
        """
        # Unique slave indices
        seen_idx: dict[int, str] = {}
        for s in self._slaves:
            if s.idx in seen_idx:
                raise RuntimeError(
                    f"[BUS] ERROR: Slave index {s.idx} is used by both "
                    f"'{seen_idx[s.idx]}' and '{s.name}'."
                )
            seen_idx[s.idx] = s.name

        # Non-overlapping address windows
        sorted_slaves = sorted(self._slaves, key=lambda s: s.start_address)
        for i in range(len(sorted_slaves) - 1):
            a = sorted_slaves[i]
            b = sorted_slaves[i + 1]
            if a.end_address > b.start_address:
                raise RuntimeError(
                    f"[BUS] ERROR: Slave '{a.name}' (0x{a.start_address:08X}–"
                    f"0x{a.end_address:08X}) overlaps with '{b.name}' "
                    f"(0x{b.start_address:08X}–0x{b.end_address:08X})."
                )

        # Unique master indices
        seen_midx: dict[int, str] = {}
        for m in self._masters:
            if m.idx in seen_midx:
                raise RuntimeError(
                    f"[BUS] ERROR: Master index {m.idx} is used by both "
                    f"'{seen_midx[m.idx]}' and '{m.name}'."
                )
            seen_midx[m.idx] = m.name
