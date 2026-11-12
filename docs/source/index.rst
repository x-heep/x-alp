X-ALP
=====

``X-ALP`` (eXtendable Application Level Platform) is a RISC-V application-class platform described in SystemVerilog. It is the application-level sibling of `X-HEEP <https://github.com/x-heep/x-heep>`_: it reuses the X-HEEP generation flow, software stack and tooling, but replaces the 32-bit microcontroller with a 64-bit application-class core with an MMU, an AXI interconnect and a last-level cache backed by external DRAM.

As in X-HEEP, the goal is to provide a ready-to-use system that you can extend with your own accelerators without modifying it, just instantiating it in your design. The whole platform is generated from a Python description (see :doc:`/Configuration/index`), and firmware is built with CMake and the RISC-V GCC or Clang toolchains.

X-ALP is currently simulated with Verilator. You are welcome to explore the `X-ALP repository <https://github.com/x-heep/x-alp>`_.

.. _architecture:

Architecture
^^^^^^^^^^^^

The default configuration (``configs/soc.py``) generates the following system::

                                 +--------------------+
                                 |  CVA6 (RV64GC)     |       ext_mst_req_i
     JTAG --> Debug module --+   |  I$ 16K / D$ 32K   |            |
                             |   +---------+----------+            |
                             |             | AXI                   |
                             v             v                       v
             +--------------------------------------------------------------+
             |                AXI crossbar (64-bit addr / data)             |
             +----+-----------------+-------------------+--------------+----+
                  |                 |                   |              |
              0x0000_0000       0x1000_0000         0x2000_0000    0xF000_0000
              debug ROM        LLC SPM / cached     peripheral     ext_slv_req_o
                               DRAM (0x8000_0000)   domain (REG)
                                    |                   |
                                AXI LLC            SOC_CTRL, BOOTROM, UART,
                                    |              FAST_INTR_CTRL, AXI_LLC cfg,
                              ext_llc_req_o        EXT_PERIPHERAL (ext_reg_req_o)
                               (to DRAM)

The full, generated address map is in :doc:`/Configuration/AddressMap`.

CPU subsystem
^^^^^^^^^^^^^

The CPU subsystem is based on the OpenHW Group `CVA6 <https://github.com/openhwgroup/cva6>`_, a 64-bit, six-stage, in-order application-class core. The default X-ALP configuration (``hw/include/cva6_config_pkg.sv``) enables the RV64GC ISA together with the bit-manipulation (B), Zicond and Zcb extensions, an Sv39 MMU, 8 PMP entries, a 16 KiB 4-way instruction cache and a 32 KiB 8-way write-through data cache. The core accesses the system through a single AXI master port and boots from the boot ROM.

Memory subsystem
^^^^^^^^^^^^^^^^

Unlike X-HEEP, X-ALP has no on-chip RAM banks. The memory subsystem is the PULP `AXI last-level cache (LLC) <https://github.com/pulp-platform/axi_llc>`_. It answers two address regions on a single crossbar port:

* a **scratchpad (SPM)** window, at ``0x1000_0000`` by default. Every way of the cache can be locked as scratchpad memory, so its size is the whole cache capacity (256 KiB by default);
* a **cached region**, at ``0x8000_0000`` by default (256 MiB), backed by the DRAM connected to the LLC master port (``ext_llc_req_o``).

The cache geometry and the two regions are configured in Python (see :doc:`/Configuration/MemoryConfiguration`). The LLC configuration registers are exposed in the peripheral domain.

Peripheral domain
^^^^^^^^^^^^^^^^^

The peripheral domain groups the register-interface peripherals. It is connected to the crossbar through a single AXI port, which is bridged to the register interface and decoded a second time to reach each peripheral. The default domain contains the SoC controller, the boot ROM, the fast interrupt controller, a UART, the LLC configuration registers and a port for an external register-interface peripheral (see :doc:`/Peripherals/index`).

Debug subsystem
^^^^^^^^^^^^^^^

The `RISC-V debug module <https://github.com/pulp-platform/riscv-dbg>`_ provides run-control debugging over JTAG. It is both an AXI slave (its ROM and registers are mapped at ``0x0000_0000``) and an AXI master (system bus access), so OpenOCD and GDB can load and debug programs (see :doc:`/How_to/Debug`).

External interfaces
^^^^^^^^^^^^^^^^^^^

The ``x_alp`` top level exposes the interfaces used to extend the platform: an AXI slave window (``ext_slv``), an AXI master port (``ext_mst``), a register-interface peripheral port (``ext_reg``) and the LLC master port to DRAM (``ext_llc``). See :doc:`/Extending/index`.

Index
^^^^^

.. toctree::
   :maxdepth: 2

   /GettingStarted/index
   /How_to/index
   /Configuration/index
   /Extending/index
   /Testing/index
   /Peripherals/index
