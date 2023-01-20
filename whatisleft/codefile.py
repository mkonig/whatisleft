import logging

logger = logging.Logger(name='whatisleft')

class CodeFile:
    """Handles the removal of lines."""
    def __init__(self, content: str):
        """Init."""
        self.content = content.split('\n')
        self.current_line_index = 0
        self.last_removed_line = ""

    def remove_line(self):
        """Remove a line. Save the line number."""
        try:
            self.last_removed_line = self.content[self.current_line_index]
            del self.content[self.current_line_index]
            logger.debug("Removing line %s: %s", self.current_line_index, self.last_removed_line)
        except IndexError:
            raise EOFError

    def revert_remove(self):
        """Revert the last removal"""
        self.content.insert(self.current_line_index, self.last_removed_line)
        self.current_line_index += 1


