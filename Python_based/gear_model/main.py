"""Main entry point for the Gear Model Python application."""
from __future__ import annotations

import sys

from PySide6.QtWidgets import QApplication

from gear_model.ui.main_window import MainWindow


def main() -> int:
    app = QApplication.instance() or QApplication(sys.argv)
    app.setApplicationName("Gear Model")
    win = MainWindow()
    win.show()
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
