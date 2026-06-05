# Copyright 2026 Politecnico di Torino
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author(s): David Mallasen
# Description: Generic (default) configuration for X-HEEP

from xalp import XAlp
from cpu.cv32e20 import cv32e20

def config():
    system = XAlp()

    system.set_cpu(cv32e20())
    return system
