import os

from fw_fanctrl.dto.command_result.CommandResult import CommandResult
from fw_fanctrl.enum.CommandStatus import CommandStatus


class ConfigurationReloadCommandResult(CommandResult):
    def __init__(self, strategy, default):
        super().__init__(CommandStatus.SUCCESS)
        self.strategy = strategy
        self.default = default

    def __str__(self):
        return f"Reloaded with success! Strategy in use: '{self.strategy}'{os.linesep}" f"Default: {self.default}"
