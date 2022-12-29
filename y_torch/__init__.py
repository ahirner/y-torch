def main():
    try:
        import numpy as np
    except ImportError as e:
        print(e)
    else:
        np.show_config()
        print()
    try:
        import torch
    except ImportError as e:
        print(e)
    else:
        print(*torch.__config__.show().split("\n"), sep="\n")
        print(*torch.__config__.parallel_info().split("\n"), sep="\n")
