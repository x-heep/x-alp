# Copyright 2026 Politecnico di Torino
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author(s): Luigi Giuffrida
# Description: X-ALP system class

from copy import deepcopy

from bus.bus import AxiMaster, Bus, AxiSlave
from cpu.cpu import CPU
from memory_ss.memory_ss import MemorySS
from peripherals.peripheral_domain import PeripheralDomain
from peripherals.base_peripherals.llc import LLC
from system import System
from bus_type import BusType


class XAlp(System):
    """
    Represents the whole X-ALP system.

    An instance of this class is passed to the mako templates.

    Inherits the generic system infrastructure from :class:`System`. The
    configuration is address-map centric: the configuration script declares
    the top-level :class:`AddressMap` regions and connects the components
    (CPU, debug subsystem, memory subsystem, domains). The AXI bus is not
    written by hand, it is derived from that configuration when
    :meth:`build` is called. Each domain is an independent bus node and can
    be grouped with others in power and clock-gating domains (see
    :class:`PeripheralDomain`).

    :param str platform_name: The name of the platform.
    """

    AVAILABLE_CPUS = ["cva6"]
    """Constant list of CPU names available for X-ALP."""

    AVAILABLE_PERIPHERALS = [
        "bootrom",
        "ext_peripheral",
        "fast_intr_ctrl",
        "pad_control",
        "soc_ctrl",
        "uart",
        "axi_llc",
    ]
    """Constant list of peripheral names available for X-ALP."""

    MINIMUM_PERIPHERALS = [
        "soc_ctrl",
        "bootrom",
    ]
    """Constant list of peripheral names that must be present in X-ALP."""

    MEMORY_START_ADDRESS = 0x00000000
    """Start address of the memory subsystem window on the bus."""

    def __init__(self, platform_name: str):
        super().__init__()
        self._platform_name = platform_name
        self._bus = None

    def platform_name(self) -> str:
        """
        :return: the name of the platform
        :rtype: str
        """
        return self._platform_name

    def bus(self) -> Bus:
        """
        :return: the bus derived from the configuration, `None` before :meth:`build` is called.
        :rtype: Bus
        """
        return self._bus

    def build(self):
        """
        Makes the system ready to be used and derives the bus from the
        configured address map and components.
        """
        super().build()
        self._bus = self._derive_bus()

    # ------------------------------------------------------------
    # Bus derivation
    # ------------------------------------------------------------

    def _derive_bus(self) -> Bus:
        """
        Builds the AXI bus out of the configured components and address map.

        Masters follow the connected components: a CPU master when a CPU is
        connected, a debug module master when a debug subsystem is set, and
        one master per master port of every peripheral that masters the bus.
        The external master port always exists and is tied off when unused.

        Slaves are the memory subsystem window (when a memory subsystem is
        connected) plus one node per address map region, keeping the region
        name. A region that covers a connected domain is added as that
        domain, so its register-interface peripherals become REG slaves
        nested in its window.

        :return: The derived bus.
        :rtype: Bus
        """
        bus = Bus(self.bus_type())

        if self.cpu() is not None:
            bus.add_master(AxiMaster("cpu"))
        if self.debug_ss() is not None:
            bus.add_master(AxiMaster("debug_module"))
        for peripheral in self.get_peripherals():
            for i in range(peripheral.get_num_master_ports()):
                bus.add_master(AxiMaster(f"{peripheral.get_name()}_{i}"))
        bus.add_master(AxiMaster("ext_master"))

        slaves = []
        if self.memory_ss() is not None:
            # A memory subsystem may answer several disjoint windows on a
            # single port (the LLC: its scratchpad and its cached region), so
            # the first window is the port and the rest are extra rules.
            windows = self.memory_ss().bus_windows(self.MEMORY_START_ADDRESS)
            name, base, size = windows[0]
            memory_slave = AxiSlave(name, base, size)
            for name, base, size in windows[1:]:
                memory_slave.add_window(name, base, size)
            slaves.append(memory_slave)

        domains = {domain.get_start_address(): domain for domain in self._domains}
        address_map = self.address_map()
        for region in address_map.get_regions() if address_map else []:
            domain = domains.get(region.get_start_address())
            if domain is not None:
                slaves.append(domain)
            else:
                slaves.append(
                    AxiSlave(
                        region.get_name(),
                        region.get_start_address(),
                        region.get_length(),
                    )
                )

        # Slaves are placed in the order they are added, so feed them to the
        # bus sorted by address.
        for slave in sorted(slaves, key=lambda slave: slave.get_start_address()):
            bus.add_slave(slave)
        bus.build_address_map()

        return bus

    # ------------------------------------------------------------
    # Component connections
    # ------------------------------------------------------------

    def connect_cpu(self, cpu: CPU):
        """
        Connects the CPU to the system.

        :param CPU cpu: The CPU to connect.
        :raise TypeError: when cpu is of incorrect type.
        :raise ValueError: when a CPU is already connected.
        """
        if not isinstance(cpu, CPU):
            raise TypeError(f"XAlp.cpu should be of type CPU not {type(cpu)}")
        if self._cpu is not None:
            raise ValueError(
                f"CPU {self._cpu.get_name()} is already connected to the bus. Only one CPU can be connected."
            )
        self.set_cpu(cpu)

    def connect_memory_ss(self, memory_ss: MemorySS):
        """
        Connects the memory subsystem to the system.

        :param MemorySS memory_ss: The memory subsystem to connect.
        :raise TypeError: when memory_ss is of incorrect type.
        """
        self.set_memory_ss(memory_ss)

    def connect_domain(self, domain: PeripheralDomain):
        """
        Connects a domain to the system. The domain should already contain
        all peripherals well configured. Its name must match the name of the
        address map region it is mapped to.

        Any number of domains can be connected, each one is an independent
        bus node and can be grouped with others in power / clock-gating
        domains.

        :param PeripheralDomain domain: The domain to connect.
        :raise TypeError: when domain is of incorrect type.
        :raise ValueError: when a domain with the same name is already connected.
        """
        self.add_domain(domain)

    def disconnect_domain(self, name: str):
        """
        Disconnects a domain from the system.

        :param str name: The name of the domain to disconnect.
        """
        self.remove_domain(name)

    def get_cache(self) -> LLC:
        """
        :return: the last-level cache when the memory subsystem is one, `None` otherwise.
        :rtype: LLC
        """
        memory_ss = self.memory_ss()
        return memory_ss if isinstance(memory_ss, LLC) else None

    # ------------------------------------------------------------
    # Power / Clock-Gating Domains
    # ------------------------------------------------------------

    def get_power_domains(self):
        """
        Groups the connected domains by power domain.

        :return: A dictionary mapping each power domain name to the list of domains belonging to it. Always-on domains (no power domain) are not included.
        :rtype: dict[str, list[PeripheralDomain]]
        """
        power_domains = {}
        for d in self._domains:
            if d.has_power_domain():
                power_domains.setdefault(d.get_power_domain(), []).append(deepcopy(d))
        return power_domains

    def get_always_on_domains(self):
        """
        :return: A deepcopy of the list of always-on domains (no switchable power domain).
        :rtype: list[PeripheralDomain]
        """
        return [deepcopy(d) for d in self._domains if d.is_always_on()]

    def get_clock_gated_domains(self):
        """
        :return: A deepcopy of the list of domains that support clock gating.
        :rtype: list[PeripheralDomain]
        """
        return [deepcopy(d) for d in self._domains if d.has_clock_gating()]
