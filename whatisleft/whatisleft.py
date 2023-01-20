import pytest
import glob
from pathlib import Path
from distutils.dir_util import copy_tree
from multiprocessing import Process
from codefile import CodeFile

def copy_repo():
    dest = Path('testdir') 
    dest.mkdir()
    copy_tree('.', dest)

    return dest
    

def main():
    dest = copy_repo()
    files = glob.glob(dest / '*.py')

    for file in files:
        with open(file, 'r') as code_file:
            code = CodeFile(code_file.read())


        while(True):
            try:
                code.remove_line()
                # print("\n".join(code.content))
                run_tests = Process(target=pytest.main)
                run_tests.start()
                run_tests.join()
                # ret = pytest.main(['-qq', '--no-header', '--no-summary'])
                # if ret != 0:
                    # code.revert_remove()
            except Exception as e:
                print(e)
                break

if __name__ == '__main__':
    main()
