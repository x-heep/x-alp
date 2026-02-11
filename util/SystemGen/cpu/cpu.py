class CPU:
    """
    Represents a CPU configuration.
    """

    def __init__(self, name: str):
        self.name = name

        # Dictionary to hold optional parameter values
        self.params = {}

    def get_name(self) -> str:
        """
        Get the name of the CPU.
        :return: Name of the CPU.
        """
        return self.name

    def is_defined(self, param_name: str) -> bool:
        """
        Check if a given parameter is defined.
        :param param_name: Name of the parameter to check.
        :return: True if the parameter is defined, False otherwise.
        """
        return param_name in self.params

    def get_param(self, param_name: str):
        """
        Get the value of a given parameter.
        :param param_name: Name of the parameter to get.
        :return: Value of the parameter or None if not defined.
        """
        return self.params.get(param_name, None)
