import sys
import atheris

with atheris.instrument_imports():
    import torch

uncaught_exceptions = (MemoryError, KeyboardInterrupt, RecursionError, AssertionError)

@atheris.instrument_func
def TestOneInput():
	try:
		torch.load(sys.argv[-1])
	except Exception as e:
		if isinstance(e, uncaught_exceptions):
			raise
		print(f"Caught exception: {e}")


if __name__ == "__main__":
	atheris.Crusher(TestOneInput)
