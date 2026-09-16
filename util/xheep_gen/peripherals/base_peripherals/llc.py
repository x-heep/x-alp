# Copyright 2026 Politecnico di Torino
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author(s): Luigi Giuffrida
# Description: AXI last-level cache, used as the memory subsystem of X-ALP.

from memory_ss.linker_section import LinkerSection
from memory_ss.memory_ss import MemorySS

from ..abstractions import BasePeripheral


class LLC(BasePeripheral, MemorySS):
    """
    The AXI last-level cache.

    The LLC is two things at once and the distinction matters when reading the
    address map:

    * a *memory subsystem*: instead of on-chip RAM banks it gives the system
      two windows, its scratchpad (SPM, whose size is fixed by the cache
      geometry) and the cached region it backs with the DRAM hanging off its
      master port. Both windows answer on a single crossbar port. Connect it
      with :meth:`System.set_memory_ss`.
    * a *peripheral*, i.e. a register-interface node inside a peripheral
      domain. ``offset``/``length`` describe that configuration register
      window. Add the same object to the peripheral domain to get it.

    Every parameter of the cache is configurable here: the geometry
    (``set_assoc``, ``num_lines``, ``num_blocks``, ``data_width``) drives the
    ``axi_llc`` instance in the RTL and fixes the SPM size, while
    ``spm_start``, ``cached_start`` and ``cached_size`` place the two windows.

    Unless the configuration adds linker sections of its own, the whole SPM
    and the whole cached region are declared as sections, which is what marks
    them cacheable and executable for the CPU.

    :param int offset: Offset of the configuration register window in its domain. `None` places it automatically.
    :param int length: Size of the configuration register window in bytes.
    :param int set_assoc: Number of ways.
    :param int num_lines: Number of lines per way.
    :param int num_blocks: Number of blocks per line.
    :param int data_width: AXI data width in bits (one block).
    :param int spm_start: Base address of the SPM window.
    :param int cached_start: Base address of the cached (DRAM) window.
    :param int cached_size: Size of the cached (DRAM) window in bytes.
    """

    _name = "axi_llc"

    def __init__(
        self,
        offset: int = None,
        length: int = 0x10000,
        set_assoc: int = 16,
        num_lines: int = 256,
        num_blocks: int = 8,
        data_width: int = 64,
        spm_start: int = 0x10000000,
        cached_start: int = 0x80000000,
        cached_size: int = 0x10000000,
    ):
        MemorySS.__init__(self)
        BasePeripheral.__init__(self, offset=offset, length=length)

        for name, value in (
            ("set_assoc", set_assoc),
            ("num_lines", num_lines),
            ("num_blocks", num_blocks),
            ("data_width", data_width),
            ("spm_start", spm_start),
            ("cached_start", cached_start),
            ("cached_size", cached_size),
        ):
            if type(value) is not int or value <= 0:
                raise ValueError(f"LLC.{name} should be a strictly positive integer")
        if data_width % 8 != 0:
            raise ValueError("LLC.data_width should be a whole number of bytes")

        self._set_assoc = set_assoc
        self._num_lines = num_lines
        self._num_blocks = num_blocks
        self._data_width = data_width
        self._spm_start = spm_start
        self._cached_start = cached_start
        self._cached_size = cached_size

    # ------------------------------------------------------------
    # Cache geometry
    # ------------------------------------------------------------

    def get_set_assoc(self) -> int:
        """:return: the number of ways."""
        return self._set_assoc

    def get_num_lines(self) -> int:
        """:return: the number of lines per way."""
        return self._num_lines

    def get_num_blocks(self) -> int:
        """:return: the number of blocks per line."""
        return self._num_blocks

    # ------------------------------------------------------------
    # Address windows
    # ------------------------------------------------------------

    def get_spm_size(self) -> int:
        """
        :return: the size of the SPM window in bytes. Every way is usable as
            scratchpad, so this is the whole cache capacity.
        """
        return (
            self._set_assoc * self._num_lines * self._num_blocks * self._data_width // 8
        )

    def build(self):
        """
        Declares the whole SPM and the whole cached region as linker sections
        when the configuration did not add any of its own, then finalizes the
        memory subsystem.
        """
        if not self._linker_sections:
            for name, base, size in self.bus_windows(self._spm_start):
                self.add_linker_section(LinkerSection(name, base, base + size))
        MemorySS.build(self)

    def validate(self):
        """
        Validate the cache configuration.

        The LLC is not backed by RAM banks, so the RAM bank checks of
        :meth:`MemorySS.validate` do not apply; what has to hold is that the
        cache geometry is a usable one and that the two address regions it
        answers do not overlap.

        :raise RuntimeError: when the geometry or the address regions are invalid.
        """
        for name, value in (
            ("set_assoc", self._set_assoc),
            ("num_lines", self._num_lines),
            ("num_blocks", self._num_blocks),
        ):
            if value & (value - 1) != 0:
                raise RuntimeError(
                    f"[MCU-GEN - LLC] ERROR: {name} should be a power of two, got {value}"
                )

        regions = sorted(self.bus_windows(self._spm_start), key=lambda w: w[1])
        for (name, base, size), (next_name, next_base, _) in zip(regions, regions[1:]):
            if base + size > next_base:
                raise RuntimeError(
                    f"[MCU-GEN - LLC] ERROR: The {name} region (ends at {base + size:#010X}) "
                    f"overlaps {next_name} (starts at {next_base:#010X})."
                )
