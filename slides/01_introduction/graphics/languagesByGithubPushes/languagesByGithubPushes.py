"""Get the programming language popularity data and plot a diagram."""
import json
from collections import Counter
from math import ceil
from typing import Final

from matplotlib.artist import Artist  # type: ignore
from matplotlib.axes import Axes  # type: ignore
from matplotlib.lines import Line2D  # type: ignore
from moptipy.evaluation.axis_ranger import AxisRanger
from moptipy.utils.plot_defaults import (
    COLOR_BLACK,
    GRID_COLOR,
    create_line_style,
    distinct_colors,
)
from moptipy.utils.plot_utils import (
    create_figure,
    get_axes,
    label_box,
    save_figure,
)
from pycommons.io.console import logger
from pycommons.io.path import Path, file_path
from pycommons.io.temp import temp_dir
from pycommons.processes.shell import STREAM_FORWARD, Command


def time(year: int, quart: int) -> float:
    """
    Translate a year/quarter combination to a single time float.

    :param year: the year
    :param quart: the quarter
    :return: the time float
    """
    return year + quart / 5


#: The GitHut URL
GITHUT_URL: Final[str] = "https://github.com/madnight/githut/"


def get_data() -> tuple[tuple[
        str, tuple[float, ...], tuple[float, ...]], ...]:
    """
    Get the data regarding the programming language popularity.

    :return: the extracted data
    """
    logger("Downloading the dataset from GitHut 2.0.")
    with temp_dir() as td:
        Command(command=("git", "-C", td, "clone", "--depth", "1",
                         GITHUT_URL, td),
                working_dir=td,
                timeout=200,
                stdin=None,
                stdout=STREAM_FORWARD,
                stderr=STREAM_FORWARD).execute(True)
        return load_data(td.resolve_inside("src/data/gh-push-event.json"))


def load_data(file: str) -> tuple[tuple[
        str, tuple[float, ...], tuple[float, ...]], ...]:
    """
    Loading the data from a file.

    :param file: the file
    :return: the data, i.e., tuples of programming language name, date, and
        share fractions
    """
    logger("We got all the data, now we parse it in a very crude way")
    raw_data: Final[list[tuple[float, int, str]]] = [
        (time(int(res["year"]), int(res["quarter"])),
         int(res["count"]), str.strip(res["name"]))
        for res in json.loads(file_path(file).read_all_str())]
    logger("We got the data parsed, now we process it.")
    dates: Final[tuple[float, ...]] = tuple(sorted({
        entry[0] for entry in raw_data}))
    per_date: Final[dict[float, list[tuple[int, str]]]] = {
        d: sorted((entry[1], entry[2]) for entry in raw_data if entry[0] == d)
        for d in dates}

    # Decide which programming languages to plot
    min_count: int = 3
    while True:
        logger(f"Computing most popular languages "
               f"using {min_count}-best per quarter.")
        keeper: Counter[str] = Counter()
        for row in per_date.values():
            add: int = 1
            for i in range(-min_count, -1, 1):
                keeper[row[i][1]] += add
                add = add + add + 1
        charts: list[str] = sorted(
            keeper.keys(), key=keeper.__getitem__, reverse=True)
        if ("Python" in charts) and (list.__len__(charts) > 11):
            break
        min_count += 1

    charts.remove("Python")
    charts.insert(0, "Python")  # Python comes first
    while list.__len__(charts) > 12:
        del charts[-1]
    logger(f"Selected the following languages: {charts!r}.")

    # Get the normalization factor for the data per day
    day_sum: Final[Counter[float]] = Counter()
    for date, row in per_date.items():
        for v, _ in row:
            day_sum[date] += v

    logger("Now selecting the data to plot.")
    # get the data sequences
    data: dict[str, tuple[list[float], list[float]]] = {}
    for language in charts:
        x: list[float] = []
        y: list[float] = []
        for date, row in per_date.items():
            value: float | None = None
            for v, lang in row:
                if lang == language:
                    value = v / day_sum[date]
                    break
            if value is None:
                if list.__len__(x) > 0:
                    x.append(date)
                    y.append(0)
            else:
                x.append(date)
                y.append(value)
        data[language] = x, y

    logger("Finished selecting data.")
    return tuple((lang, tuple(data[lang][0]), tuple(
        data[lang][1])) for lang in charts)


def plot_data(data: tuple[tuple[str, tuple[
    float, ...], tuple[float, ...]], ...],
              dest_dir: str, dest_name: str) -> Path:
    """
    Plot the data.

    :param data: the data to plot
    :param dest_dir: the destination directory
    :param dest_name: the name of the file
    :return: the path to the file
    """
    logger("Now creating figure.")
    figure: Final = create_figure(6)
    axes: Final[Axes] = get_axes(figure)

    n: Final[int] = tuple.__len__(data)
    colors = distinct_colors(n)
    y: AxisRanger = AxisRanger(chosen_min=0, use_data_max=True)
    handles: list[Artist] = []
    for i in range(n - 1, -1, -1):
        row = data[i]
        logger(f"Plotting data {row[0]!r}.")
        yd = row[2]
        y.register_value(0.04 + int(ceil(10 * max(yd) * 1)) / 10)
        style = create_line_style()
        style["label"] = row[0]
        style["color"] = colors[i]
        style["linewidth"] = 2 if i > 0 else 3
        axes.plot(row[1], yd, **style)
        style["xdata"] = row[1]
        style["ydata"] = yd
        handles.insert(0, Line2D(**style))

    logger("Adding labels, legends, and grid, setting axes ranges.")
    y.apply(axes, "y")
    axes.grid(axis="x", color=GRID_COLOR, linewidth=0.5)
    axes.grid(axis="y", color=GRID_COLOR, linewidth=0.5)

    axes.legend(loc="upper right",
                ncol=2,
                handles=handles,
                labelcolor=[art.color if hasattr(art, "color")
                            else COLOR_BLACK for art in handles],
                fontsize=9)

    label_box(axes, "Fraction of GitHub Pushes", 0.35, 0.97, 13)
    label_box(axes, "Year", 0.99, 0.005, 10)
    label_box(axes, "Fraction of GitHub Pushes", 0.005, 0.99, 10, True)
    label_box(axes, f"Source: GitHut 2.0, {GITHUT_URL}", 0.01, 0.0025, 9)

    logger("Now saving figure.")
    path = save_figure(figure, dest_name, dest_dir, "pdf")[0]
    logger(f"Saved figure to {path!r}.")
    return path


def main() -> None:
    """Do the work."""
    logger("Starting up.")
    file: Final[Path] = file_path(__file__)
    name = file.basename()[:-3]
    plot_data(get_data(), file.up(1), name)
    logger("All done.")


# Execute the program
if __name__ == "__main__":
    main()
