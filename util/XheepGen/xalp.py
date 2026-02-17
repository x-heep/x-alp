from copy import deepcopy
from typing import Optional
from .bus import Bus, BusType
from .peripherals.abstractions import PeripheralDomain
from .system import System


class XAlp(System):
    """
    Represents the X-ALP system.

    Inherits generic SoC functionality from :class:`System` and adds
    X-ALP-specific features.  X-ALP uses a different memory subsystem
    from X-HEEP (to be defined), but shares the same :class:`Bus`-based
    slave map and master indices.

    :param Bus bus: The bus configuration for this system.
    :raise TypeError: when parameters are of incorrect type.
    """

    def __init__(self, bus: Bus):
        super().__init__(bus)

    # ------------------------------------------------------------
    # Build and Validate
    # ------------------------------------------------------------

    def build(self):
        """
        Makes the X-ALP system ready to be used.
        """
        super().build()

    def validate(self):
        """
        Performs X-ALP-specific validation after the parent checks.

        This should be called before using the XAlp object to generate the
        project.
        """
        super().validate()
        return True
