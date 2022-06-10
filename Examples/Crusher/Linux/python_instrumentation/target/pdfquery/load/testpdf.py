import atheris
import sys
from pathlib import Path
import os


with atheris.instrument_imports():
    import pdfquery
    from pdfquery.cache import FileCache

@atheris.instrument_func
def TestOneInput():
    pdf = pdfquery.PDFQuery(Path(str(sys.argv[-1])))
    pdf.load()
    os._exit(0)


def main():
    atheris.Run(TestOneInput)

if __name__ == "__main__":
    main()
