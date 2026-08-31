from ..abstractions import BasePeripheral


class LLC(BasePeripheral):
    """
    The AXI last-level cache.

    The LLC is two things at once and the distinction matters when reading the
    address map:

    * a *peripheral*, i.e. a register-interface node inside a peripheral
      domain. ``start``/``size`` describe that configuration register window.
    * an *AXI slave* answering two disjoint windows on the crossbar: its
      scratchpad (SPM) window, whose size is fixed by the cache geometry, and
      the cached window it backs with the DRAM hanging off its master port.

    :param int start: Offset of the configuration register window in its domain.
    :param int size: Size of the configuration register window in bytes.
    :param int set_assoc: Number of ways.
    :param int num_lines: Number of lines per way.
    :param int num_blocks: Number of blocks per line.
    :param int data_width: AXI data width in bits (one block).
    :param int spm_start: Base address of the SPM window; ``None`` places it automatically.
    :param int cached_start: Base address of the cached (DRAM) window.
    :param int cached_size: Size of the cached (DRAM) window in bytes.
    """

    _name = "axi_llc"

    def __init__(
        self,
        start: int = None,
        size: int = 0x10000,
        set_assoc: int = 16,
        num_lines: int = 256,
        num_blocks: int = 8,
        data_width: int = 64,
        spm_start: int = None,
        cached_start: int = 0x80000000,
        cached_size: int = 0x10000000,
    ):
        self._set_assoc = set_assoc
        self._num_lines = num_lines
        self._num_blocks = num_blocks
        self._data_width = data_width
        self._spm_start = spm_start
        self._cached_start = cached_start
        self._cached_size = cached_size

        super().__init__(
            start,
            size,
            False,
            0,
            True,
            1,
            True,
            1
        )

    def get_set_assoc(self) -> int:
        """:return: the number of ways."""
        return self._set_assoc

    def get_num_lines(self) -> int:
        """:return: the number of lines per way."""
        return self._num_lines

    def get_num_blocks(self) -> int:
        """:return: the number of blocks per line."""
        return self._num_blocks

    def get_spm_start(self) -> int:
        """:return: the base address of the SPM window, or `None` if auto-placed."""
        return self._spm_start

    def get_spm_size(self) -> int:
        """
        :return: the size of the SPM window in bytes. Every way is usable as
            scratchpad, so this is the whole cache capacity.
        """
        return (
            self._set_assoc * self._num_lines * self._num_blocks * self._data_width // 8
        )

    def get_cached_start(self) -> int:
        """:return: the base address of the cached (DRAM) window."""
        return self._cached_start

    def get_cached_size(self) -> int:
        """:return: the size of the cached (DRAM) window in bytes."""
        return self._cached_size
