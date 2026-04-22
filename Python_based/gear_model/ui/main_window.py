"""Main application window (ported from Gear_Model.m)."""
from __future__ import annotations

from typing import List

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QMainWindow, QTabWidget, QVBoxLayout, QWidget,
)

from gear_model.ui.animation_tab import AnimationTab
from gear_model.ui.home_tab import HomeTab
from gear_model.ui.output_window import OutputWindow
from gear_model.ui.profile_tab import ProfileTab
from gear_model.utils.language_utils import LanguageUtils, LineCursor


class MainWindow(QMainWindow):
    """Main Gear Model application window."""

    def __init__(self) -> None:
        super().__init__()
        self.resize(640, 820)

        # Language
        self.language_utils = LanguageUtils("EN")
        self.language_utils.load(toothing_is_involute=True)

        # Output window (separate figure like the MATLAB OutputFigure)
        self.output_window = OutputWindow("Graphical output")

        # Central tabs
        central = QWidget(self)
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setContentsMargins(8, 8, 8, 8)

        self.tabs = QTabWidget(self)
        layout.addWidget(self.tabs)

        self.home_tab = HomeTab(self)
        self.profile_tab = ProfileTab(self, self.output_window)
        self.animation_tab = AnimationTab(self, self.output_window)

        self.tabs.addTab(self.home_tab, "Home")
        self.tabs.addTab(self.profile_tab, "Profile")
        self.tabs.addTab(self.animation_tab, "Animation")

        self.profile_tab.tt_group.buttonToggled.connect(self._reload_language_for_toothing)

        self._apply_all_translations()
        self.output_window.show()

    # ----------------------------------------------------------------
    def _apply_all_translations(self) -> None:
        lu = self.language_utils
        # Outer text
        outer = LineCursor(lu.outer_text)
        standby_text = outer.next("Waiting for user response.")
        main_title = outer.next("Gear Model")
        output_title = outer.next("Graphical output")
        home_tab_title = outer.next("Home")
        profile_tab_title = outer.next("Profile")
        animation_tab_title = (
            lu.animation_tab_text[0]
            if lu.animation_tab_text
            else "Animation"
        )

        self.setWindowTitle(main_title)
        self.output_window.setWindowTitle(output_title)
        self.output_window.set_standby_text(standby_text)

        self.tabs.setTabText(0, home_tab_title)
        self.tabs.setTabText(1, profile_tab_title)
        self.tabs.setTabText(2, animation_tab_title)

        # Home
        self.home_tab.apply_translations(lu.home_tab_text)

        # Profile
        is_inv = self.profile_tab.involute_rb.isChecked()
        cyc_angle = {
            "SK": "Polomer tvoriacej kružnice epicykloidy",
            "CZ": "Poloměr tvořící kružnice epicykloidy",
            "EN": "Radius of epicycloid generating circle",
        }.get(lu.language_choice, "Epicycloid radius")
        self.profile_tab.apply_translations(
            LineCursor(lu.profile_tab_text), lu.profile_tab_text, is_inv, cyc_angle,
        )

        # Animation
        self.animation_tab.apply_translations(lu.animation_tab_text)

    def _reload_language_for_toothing(self) -> None:
        is_inv = self.profile_tab.involute_rb.isChecked()
        self.language_utils.load(toothing_is_involute=is_inv)
        self._apply_all_translations()

    # ----------------------------------------------------------------
    def switch_language(self, code: str) -> None:
        if code not in ("SK", "CZ", "EN"):
            return
        self.language_utils.language_choice = code
        is_inv = self.profile_tab.involute_rb.isChecked()
        self.language_utils.load(toothing_is_involute=is_inv)
        self._apply_all_translations()

    # ----------------------------------------------------------------
    def closeEvent(self, event) -> None:  # noqa: N802
        try:
            self.output_window.close()
        except Exception:
            pass
        super().closeEvent(event)
