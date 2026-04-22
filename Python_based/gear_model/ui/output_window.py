"""Separate window that hosts the main Matplotlib output figure.

Mirrors the MATLAB app's second top-level figure (OutputFigure).
"""
from __future__ import annotations

from PySide6.QtCore import Qt
from PySide6.QtWidgets import QMainWindow, QVBoxLayout, QWidget

from gear_model.ui.mpl_canvas import MplCanvas


class OutputWindow(QMainWindow):
    """Holds the output Matplotlib canvas."""

    def __init__(self, title: str = "Graphical output", parent=None) -> None:
        super().__init__(parent)
        self.setWindowTitle(title)
        self.resize(900, 900)

        central = QWidget(self)
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setContentsMargins(0, 0, 0, 0)

        self.canvas = MplCanvas(self)
        layout.addWidget(self.canvas)

        self._standby_text = ""
        self._standby_artist = None

    def set_standby_text(self, text: str) -> None:
        self._standby_text = text
        self._update_standby()

    def _update_standby(self) -> None:
        ax = self.canvas.ax
        # Remove the old annotation if present
        if self._standby_artist is not None:
            try:
                self._standby_artist.remove()
            except Exception:
                pass
            self._standby_artist = None

        if not ax.get_visible() and self._standby_text:
            fig = self.canvas.figure
            self._standby_artist = fig.text(
                0.5, 0.5, self._standby_text,
                ha="center", va="center",
                fontsize=22, fontweight="bold",
            )
        self.canvas.draw_idle()

    def show_standby(self, show: bool = True) -> None:
        ax = self.canvas.ax
        if show:
            ax.set_visible(False)
        self._update_standby()

    def hide_standby(self) -> None:
        if self._standby_artist is not None:
            try:
                self._standby_artist.remove()
            except Exception:
                pass
            self._standby_artist = None
        self.canvas.draw_idle()
