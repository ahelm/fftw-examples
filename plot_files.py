import pathlib
import click
import numpy as np
import matplotlib.pyplot as plt


def load_file(fname, column=None):
    path = pathlib.Path(fname)
    if column:
        if not column.split(",")[-1]:
            raise ValueError("Field specification can't end on comma")
        column = np.array(column.split(","), dtype=int)
    if not path.is_file:
        raise ValueError(f"Not a valid file - argument passed: {fname}")
    return np.loadtxt(path, usecols=column)


def plot_multi_data(data, symbol, label=""):
    for i in range(data.shape[-1]):
        plt.plot(data[:, i], marker=symbol, label=label + f" [{i+1}]")


def plot_line_data(data, symbol, label=""):
    plt.plot(data[:], marker=symbol, label=label)


@click.command()
@click.argument("fn", nargs=-1, metavar="file")
@click.option("--symbol", nargs=1, default=None)
@click.option("--columns", nargs=1, type=str, default=None)
@click.option("--diff", nargs=1, type=str, default=None)
@click.option("--log", default=False, is_flag=True)
@click.option("--title", nargs=1, default="", type=str)
def main(fn, symbol, columns, diff, log, title):
    for f in fn:
        data = load_file(f, column=columns)
        flabel = f

        if diff:
            diff_data = load_file(diff, column=columns)
            data -= diff_data
            flabel += " | " + diff

        if len(data.shape) > 1:
            plot_multi_data(data, symbol, label=flabel)
        else:
            plot_line_data(data, symbol, label=flabel)

    plt.legend()

    if log:
        plt.yscale("log")

    if title:
        plt.title(title)

    plt.show()


if __name__ == "__main__":
    main()
