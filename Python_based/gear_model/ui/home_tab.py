"""Home tab: language selection and informational text."""
from __future__ import annotations

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QHBoxLayout, QLabel, QPushButton, QVBoxLayout, QWidget,
)


class HomeTab(QWidget):
    """Simple home tab with language selector and an HTML-ish description."""

    def __init__(self, parent_window) -> None:
        super().__init__()
        self.window_ref = parent_window

        outer = QVBoxLayout(self)

        lang_row = QHBoxLayout()
        lang_row.addStretch(1)
        self.sk_btn = QPushButton("SK")
        self.cz_btn = QPushButton("CZ")
        self.en_btn = QPushButton("EN")
        for btn in (self.sk_btn, self.cz_btn, self.en_btn):
            btn.setFixedWidth(50)
            lang_row.addWidget(btn)
        self.sk_btn.clicked.connect(lambda: self._switch("SK"))
        self.cz_btn.clicked.connect(lambda: self._switch("CZ"))
        self.en_btn.clicked.connect(lambda: self._switch("EN"))
        outer.addLayout(lang_row)

        self.info_label = QLabel("")
        self.info_label.setWordWrap(True)
        self.info_label.setTextFormat(Qt.RichText)
        self.info_label.setOpenExternalLinks(True)
        self.info_label.setAlignment(Qt.AlignTop)
        outer.addWidget(self.info_label, 1)

        self.copyright_label = QLabel("© 2026 Richard Timko | v1.1.0 (Python port)")
        self.copyright_label.setAlignment(Qt.AlignRight | Qt.AlignBottom)
        outer.addWidget(self.copyright_label)

    def _switch(self, code: str) -> None:
        self.window_ref.switch_language(code)

    def apply_translations(self, home_text_lines: list[str]) -> None:
        # home_tab file is a single HTML-like paragraph joined back together
        if home_text_lines:
            self.info_label.setText("\n".join(home_text_lines))
