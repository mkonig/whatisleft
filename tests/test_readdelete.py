import pytest
from whatisleft.codefile import CodeFile


@pytest.fixture
def code():
    """Returns a multiline string simulating a file."""
    return (
        "First line of the code\n"
        "Second line of the code"
    )


@pytest.fixture
def code_file_first_line_removed(code):
    code_file = CodeFile(code)
    code_file.remove_line()

    yield code_file
    

def test_remove_line(code):
    """Remove a line and save the line number."""
    code = CodeFile(code)
    code.remove_line()

    assert code.current_line_index == 0
    assert code.content == ["Second line of the code"]


def test_revert_removed_line(code_file_first_line_removed, code):
    """Test reverting the last removal."""
    code_file_first_line_removed.revert_remove()

    assert code_file_first_line_removed.current_line_index == 1
    assert code_file_first_line_removed.content == code.split('\n')


def test_remove_line_revert_remove_next_line(code):
    code = CodeFile(code)
    code.remove_line()
    code.revert_remove()
    code.remove_line()

    assert code.current_line_index == 1
    assert code.content == ["First line of the code"]

def test_raise_when_nothing_to_remove(code):
    code = CodeFile(code)
    code.remove_line()
    code.remove_line()

    with pytest.raises(EOFError):
        code.remove_line()
