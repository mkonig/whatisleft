import glob
import logging
import shutil
import subprocess
from pathlib import Path

from codefile import CodeFile

logger = logging.Logger(name='whatisleft')


def copy_repo(destdir: str):
    shutil.copytree('.', destdir, symlinks=True)

def main():
    destdir = '/tmp/testdir'
    if Path(destdir).exists:
        shutil.rmtree(destdir)
    copy_repo(destdir)
    files = glob.glob(f'{destdir}/whatisleft/*.py')

    for file in files:
        code = CodeFile(file)

        while(True):
            try:
                code.remove_line()
                code.write()
                complete = subprocess.run(['pytest', '-qq', '--no-header', '--no-summary', destdir])
                print(complete.returncode)
                if complete.returncode != 0:
                    logger.debug("Reverting line.")
                    code.revert_remove()
                    code.write()
            except Exception as e:
                print(e)
                break

if __name__ == '__main__':
    main()
