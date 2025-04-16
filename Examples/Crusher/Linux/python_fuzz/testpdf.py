import atheris
import sys
from pathlib import Path


with atheris.instrument_imports():
    import pdfquery

uncaught_exceptions = (MemoryError, KeyboardInterrupt, RecursionError, AssertionError)

def test():
    pdf = pdfquery.PDFQuery(Path(str(sys.argv[-1])))
    pdf.load()

@atheris.instrument_func
def TestOneInput():
    try:
        test()
    except Exception as e:
        if isinstance(e, uncaught_exceptions):
            raise
        print(f"Caught exception: {e}")


if __name__ == "__main__":
    atheris.Crusher(TestOneInput)
