from ..abstractions import BasePeripheral

class LLC(BasePeripheral):
    """
    
    """

    _name = "axi_llc"

    def __init__(
        self,
        start: int = None,
        size: int = None
    ):
        
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
