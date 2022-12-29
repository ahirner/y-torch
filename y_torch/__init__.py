import sys

def main():
    returns = 0
    try:
        import numpy as np
    except ImportError as e:
        print(e)
        returns = 1
    else:
        np.show_config()
        print()
    try:
        import torch
    except ImportError as e:
        print(e)
        returns = 1
    else:
        print(*torch.__config__.show().split("\n"), sep="\n")
        print(*torch.__config__.parallel_info().split("\n"), sep="\n")

    sys.exit(returns)
