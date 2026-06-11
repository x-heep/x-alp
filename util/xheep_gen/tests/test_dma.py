# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for peripherals.base_peripherals.DMA: parameter accessors, xbar
array generation and validation rules."""

import pytest

from peripherals.base_peripherals import DMA


class TestDefaults:
    def test_default_construction(self):
        dma = DMA()
        assert dma.get_name() == "dma"
        assert dma.get_ch_length() == 0x100
        assert dma.get_num_channels() == 1
        assert dma.get_num_master_ports() == 1
        assert dma.get_num_channels_per_master_port() == 1
        assert dma.get_fifo_depth() == 4
        assert dma.get_addr_mode() == 1
        assert dma.get_subaddr_mode() == 1
        assert dma.get_hw_fifo_mode() == 1
        assert dma.get_zero_padding() == 1
        assert dma.get_is_included() == 1

    def test_not_included(self):
        assert DMA(is_included="no").get_is_included() == 0

    def test_no_modes_constructor(self):
        dma = DMA(
            addr_mode="no", subaddr_mode="no", hw_fifo_mode="no", zero_padding="no"
        )
        assert dma.get_addr_mode() == 0
        assert dma.get_subaddr_mode() == 0
        assert dma.get_hw_fifo_mode() == 0
        assert dma.get_zero_padding() == 0


class TestAccessors:
    def test_ch_length(self):
        dma = DMA()
        dma.set_ch_length(0x200)
        assert dma.get_ch_length() == 0x200

    def test_num_channels(self):
        dma = DMA()
        dma.set_num_channels(4)
        assert dma.get_num_channels() == 4

    def test_num_master_ports_updates_has_master_ports(self):
        dma = DMA()
        dma.set_num_master_ports(2)
        assert dma.get_num_master_ports() == 2
        assert dma._has_master_ports

    def test_num_channels_per_master_port(self):
        dma = DMA()
        dma.set_num_channels_per_master_port(2)
        assert dma.get_num_channels_per_master_port() == 2

    def test_fifo_depth(self):
        dma = DMA()
        dma.set_fifo_depth(8)
        assert dma.get_fifo_depth() == 8

    @pytest.mark.parametrize(
        "setter,getter",
        [
            ("set_addr_mode", "get_addr_mode"),
            ("set_subaddr_mode", "get_subaddr_mode"),
            ("set_hw_fifo_mode", "get_hw_fifo_mode"),
            ("set_zero_padding", "get_zero_padding"),
        ],
    )
    def test_yes_no_modes(self, setter, getter):
        dma = DMA()
        getattr(dma, setter)("no")
        assert getattr(dma, getter)() == 0
        getattr(dma, setter)("yes")
        assert getattr(dma, getter)() == 1
        with pytest.raises(ValueError):
            getattr(dma, setter)("maybe")


class TestXbarArray:
    def make(self, channels, ports, per_port):
        return DMA(
            num_channels=channels,
            num_master_ports=ports,
            num_channels_per_master_port=per_port,
        )

    def test_single_master_port(self):
        assert self.make(1, 1, 1).get_xbar_array() == "default: 1"

    def test_single_master_port_mismatch_exits(self):
        with pytest.raises(SystemExit):
            self.make(2, 1, 1).get_xbar_array()

    def test_even_split(self):
        assert self.make(4, 2, 2).get_xbar_array() == "2, 2"

    def test_uneven_split(self):
        assert self.make(3, 2, 2).get_xbar_array() == "2, 1"

    def test_exact_product_with_fewer_full_ports(self):
        # floor(4/2) = 2 full xbars < 3 ports and 2*2 == 4 channels, so one
        # full xbar is given back to spread channels over all ports.
        assert self.make(4, 3, 2).get_xbar_array() == "2, 1, 1"

    def test_all_single_channel_ports(self):
        assert self.make(4, 4, 4).get_xbar_array() == "1, 1, 1, 1"

    def test_impossible_distribution_exits(self):
        with pytest.raises(SystemExit):
            self.make(3, 3, 2).get_xbar_array()


class TestValidate:
    def test_valid_configuration(self):
        DMA(
            num_channels=4, num_master_ports=2, num_channels_per_master_port=2
        ).validate()

    @pytest.mark.parametrize("channels", [0, 257])
    def test_invalid_channel_count(self, channels):
        with pytest.raises(RuntimeError, match="channels"):
            DMA(num_channels=channels).validate()

    @pytest.mark.parametrize("ports", [0, 3])
    def test_invalid_master_port_count(self, ports):
        dma = DMA(num_channels=2)
        dma.set_num_master_ports(ports)
        with pytest.raises(RuntimeError, match="master ports"):
            dma.validate()

    @pytest.mark.parametrize("per_port", [0, 3])
    def test_invalid_channels_per_master_port(self, per_port):
        with pytest.raises(RuntimeError, match="per system bus"):
            DMA(
                num_channels=2,
                num_master_ports=2,
                num_channels_per_master_port=per_port,
            ).validate()

    def test_per_port_above_channels_allowed_for_single_channel(self):
        DMA(num_channels=1, num_channels_per_master_port=2).validate()
