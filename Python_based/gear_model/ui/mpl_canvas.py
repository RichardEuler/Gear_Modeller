"""Reusable Matplotlib canvas embedded in Qt."""
from __future__ import annotations

from matplotlib.backends.backend_qtagg import FigureCanvasQTAgg
from matplotlib.figure import Figure


class MplCanvas(FigureCanvasQTAgg):
    """Simple Matplotlib figure canvas with a single Axes."""

    def __init__(self, parent=None) -> None:
        self.figure = Figure(figsize=(6, 6), tight_layout=True)
        super().__init__(self.figure)
        if parent is not None:
            self.setParent(parent)
        self.ax = self.figure.add_subplot(111)
        self.ax.set_aspect("equal")
        self.ax.set_visible(False)

    def clear(self) -> None:
        self.ax.clear()
        self.ax.set_aspect("equal")
        self.ax.set_visible(False)
        self.draw_idle()
