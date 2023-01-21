import logging
import re

logger = logging.Logger(name='whatisleft')

class CodeFile:
    """Handles the removal of lines."""
    def __init__(self, filename: str):
        """Init."""
        self.filename = filename
        with open(filename, 'r', encoding='utf-8') as code:
            self.content = code.read().splitlines()
        self.current_line_index = 0
        self.last_removed_line = ""

    def remove_line(self):
        """Remove a line. Save the line number."""
        try:
            self._skip_non_code_lines()
            self.last_removed_line = self.content[self.current_line_index]
            del self.content[self.current_line_index]
            logger.debug("Removing line %s: %s", self.current_line_index, self.last_removed_line)
        except IndexError:
            raise EOFError


    def _is_non_code_line(self, line: str):
        if line == "":
            return True

        comment = re.compile(' *"""')
        if comment.match(line):
            return True

        return False

    def _skip_non_code_lines(self):
        while self._is_non_code_line(self.content[self.current_line_index]):
            self.current_line_index += 1

    def revert_remove(self):
        """Revert the last removal."""
        self.content.insert(self.current_line_index, self.last_removed_line)
        self.current_line_index += 1

    def write(self):
        """Write content to file."""
        logger.debug("Writing content to file %s", self.filename)
        print(self.filename)
        with open(self.filename, 'w', encoding='utf-8') as code:
            code.write("\n".join(self.content))
