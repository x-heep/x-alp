# Copyright 2026 Politecnico di Torino
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author(s): Luigi Giuffrida
# Description: AXI slave window on the bus (e.g. MEM, DEBUG_MODULE, EXT_SLAVE).


class AxiSlave:
    """
    A non-peripheral AXI slave window on the bus (e.g. MEM, DEBUG_MODULE,
    EXT_SLAVE).

    Exposes the same name/address accessors as peripherals and peripheral
    domains so the address generator can treat every AXI slave uniformly.

    A slave may own more than one disjoint address window while still being a
    single crossbar port: the LLC, for instance, answers both its SPM window
    and the cached (DRAM) window. The first window is the primary one used for
    automatic placement and for the ``<MACRO>_BUS_*`` parameters; any window
    added with :meth:`add_window` only contributes an extra decoder rule
    pointing at the same port index.

    :param str name: The name of the slave window.
    :param int base: The start address of the window.
    :param int size: The size of the window in bytes.
    """

    def __init__(self, name: str, base=None, size=None):
        if type(name) is not str or name == "":
            raise ValueError("BusSlave name should be a non-empty string")
        if base is not None and type(base) is not int:
            raise ValueError("BusSlave base should be a positive integer")
        if size is not None and type(size) is not int:
            raise ValueError("BusSlave size should be a strictly positive integer")
        self._name = name
        self._start_address = base
        self._length = size
        self._extra_windows = []

    def add_window(self, name: str, base: int, size: int):
        """
        Add a secondary address window decoded to this same crossbar port.

        :param str name: Name of the window (used for its address parameters).
        :param int base: The start address of the window.
        :param int size: The size of the window in bytes.
        """
        if type(name) is not str or name == "":
            raise ValueError("BusSlave window name should be a non-empty string")
        if type(base) is not int or base < 0:
            raise ValueError("BusSlave window base should be a positive integer")
        if type(size) is not int or size <= 0:
            raise ValueError(
                "BusSlave window size should be a strictly positive integer"
            )
        self._extra_windows.append({"name": name, "base": base, "size": size})

    def get_extra_windows(self):
        """:return: the secondary windows decoded to this slave, as ``{name, base, size}``."""
        return list(self._extra_windows)

    def get_name(self) -> str:
        """:return: the name of the slave window."""
        return self._name

    def get_start_address(self) -> int:
        """:return: the start address of the slave window."""
        return self._start_address

    def get_length(self) -> int:
        """:return: the size of the slave window in bytes."""
        return self._length

    def set_start_address(self, base: int):
        """:param int base: The start address of the window."""
        self._start_address = base

    def set_length(self, size: int):
        """:param int size: The size of the window in bytes."""
        self._length = size
