from pathlib import Path

import click
import numpy as np
import matplotlib.pyplot as plt


def get_relative_time(direct, adv):
    # normalize to time to operations number
    direct[:, -1] /= direct[:, 0] * direct[:, 1]
    adv[:, -1] /= adv[:, 0] * adv[:, 1]

    return direct[:, 0], adv[:, -1] / direct[:, -1]


@click.command()
@click.argument("f1", nargs=1, metavar="benchmark_direct_method.txt")
@click.argument("f2", nargs=1, metavar="benchmark_advance_method.txt")
def main(f1, f2):
    benchFile_direct = Path(f1)
    benchFile_adv = Path(f2)

    benchData_direct = np.loadtxt(benchFile_direct, delimiter=",")
    benchData_adv = np.loadtxt(benchFile_adv, delimiter=",")

    # plot 1d vectors - selection should be equal for both
    vec1d = np.argwhere(benchData_direct[:, 2] == 1)[:, 0]
    vec3d = np.argwhere(benchData_direct[:, 2] == 3)[:, 0]
    vec6d = np.argwhere(benchData_direct[:, 2] == 6)[:, 0]

    case_direct_1d = benchData_direct[vec1d, :]
    case_direct_3d = benchData_direct[vec3d, :]
    case_direct_6d = benchData_direct[vec6d, :]

    case_adv_1d = benchData_adv[vec1d, :]
    case_adv_3d = benchData_adv[vec3d, :]
    case_adv_6d = benchData_adv[vec6d, :]

    plt.figure(figsize=(7, 3), dpi=300)
    for direct, advance, label in [
        (case_direct_1d, case_adv_1d, "1d vector"),
        (case_direct_3d, case_adv_3d, "3d vector"),
        (case_direct_6d, case_adv_6d, "6d vector"),
    ]:
        N, rel_time = get_relative_time(direct, advance)
        plt.plot(N, rel_time, "o", markerfacecolor="none", label=label)

    plt.xlabel("logical size N")
    plt.ylabel("relative time (advance/basic)")
    plt.ylim(1e-2, 1e2)
    plt.xscale("log")
    plt.yscale("log")
    plt.legend()
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    main()
