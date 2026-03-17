from .cpu import CPU


class cva6(CPU):
    """
    Represents the CVA6 (Ariane) 64-bit RISC-V CPU configuration.
    """

    def __init__(self):
        super().__init__("cva6")
