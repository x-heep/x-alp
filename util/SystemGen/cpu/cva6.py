from .cpu import CPU


class cva6(CPU):
    """
    Represents the CVA6 CPU configuration with optional parameters.
    """

    def __init__(
        self,
    ):
        super().__init__("cva6")

    def get_sv_str(self, param_name: str) -> str:
        """
        Get the string representation of the param_name parameter to be used in the SystemVerilog templates.
        :param param_name: Name of the parameter.
        :return: String representation of the parameter for SystemVerilog or an empty string if not defined.
        """
        if not self.is_defined(param_name):
            return ""

        value = self.params[param_name]
        return str(value)
