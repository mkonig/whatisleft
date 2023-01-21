import pytest

from whatisleft.codefile import CodeFile

# pylint: disable=missing-function-docstring

@pytest.fixture
def code_file_content():
    """Returns a multi line string simulating a file."""
    return (
        'First line of the code\n'
        '\n'
        '\"\"\"A comment.\"\"\"\n'
        'Second line of the code'
    )


@pytest.fixture
def mock_open(mocker, code_file_content):
    mocked_py_file = mocker.mock_open(read_data=code_file_content)
    return mocker.patch('whatisleft.codefile.open', mocked_py_file)


@pytest.fixture
def prepare_test_files(tmp_path, code_file_content):
    with open(tmp_path / 'test.py', 'w', encoding='utf-8') as file:
        file.write(code_file_content)


@pytest.fixture
def code_file(tmp_path, prepare_test_files):
    return CodeFile(tmp_path / 'test.py')


@pytest.fixture
def code_file_first_line_removed(code_file):
    code_file.remove_line()

    yield code_file


def test_remove_line(code_file):
    """Remove a line and save the line number."""
    print(code_file.content)
    code_file.remove_line()

    assert code_file.current_line_index == 0
    assert code_file.content == ['', '\"\"\"A comment.\"\"\"', 'Second line of the code']


def test_revert_removed_line(code_file_first_line_removed, code_file_content):
    """Test reverting the last removal."""
    code_file_first_line_removed.revert_remove()

    assert code_file_first_line_removed.current_line_index == 1
    assert code_file_first_line_removed.content == code_file_content.split('\n')


def test_remove_line_revert_remove_next_line(code_file):
    code_file.remove_line()
    code_file.revert_remove()
    code_file.remove_line()

    assert code_file.current_line_index == 3
    assert code_file.content == ['First line of the code', '', '\"\"\"A comment.\"\"\"']


def test_raise_when_nothing_to_remove(code_file):
    code_file.remove_line()
    code_file.remove_line()

    with pytest.raises(EOFError):
        code_file.remove_line()


def test_write_changed_file(code_file_first_line_removed, code_file_content):
    code_file_first_line_removed.write()

    with open(code_file_first_line_removed.filename, 'r', encoding='utf-8') as written_file:
        new_content = written_file.read()
        assert new_content == '\n"""A comment."""\nSecond line of the code'
