"""Port of +Utils/languageUtils.m.

Manages language selection and loads the per-language text files.
Each text-file is stored as a list of lines to preserve the original
line-index lookup convention (seq() counter).
"""
from __future__ import annotations

from pathlib import Path
from typing import Dict, List

from gear_model.resources.paths import text_path


LANGUAGE_MAP: Dict[str, tuple[str, str]] = {
    "EN": ("English", "EN"),
    "CZ": ("Czech", "CZ"),
    "SK": ("Slovak", "SK"),
}


def _read_lines(path: Path) -> List[str]:
    """Read a text file into a list of lines (without trailing newlines)."""
    if not path.exists():
        return []
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = path.read_text(encoding="latin-1")
    # MATLAB's readlines keeps every line separately, including an empty
    # one after a trailing newline. We mimic that behaviour.
    lines = text.split("\n")
    return [ln.rstrip("\r") for ln in lines]


class LanguageUtils:
    """Loads and holds all language-dependent text resources."""

    def __init__(self, choice: str = "EN") -> None:
        if choice not in LANGUAGE_MAP:
            raise ValueError(f"Unknown language: {choice}")
        self.language_choice = choice

        self.outer_text: List[str] = []
        self.home_tab_text: List[str] = []
        self.profile_tab_text: List[str] = []
        self.animation_tab_text: List[str] = []

        self.profile_tab_parameters: List[str] = []
        self.profile_tab_parameters_equations: List[str] = []
        self.profile_tab_circles: List[str] = []

        self.animation_tab_graphical_additions: List[str] = []
        self.animation_tab_parameters: List[str] = []

    # ---------------------------------------------------------------
    @property
    def lang_tuple(self) -> tuple[str, str]:
        return LANGUAGE_MAP[self.language_choice]

    def load(self, toothing_is_involute: bool = True) -> None:
        """Load every text file for the currently selected language."""
        folder, prefix = self.lang_tuple
        self.outer_text = _read_lines(text_path(folder, f"{prefix}_outer.txt"))
        self.home_tab_text = _read_lines(text_path(folder, f"{prefix}_home_tab.txt"))
        self.profile_tab_text = _read_lines(text_path(folder, f"{prefix}_profile_tab.txt"))

        if toothing_is_involute:
            anim_file = f"{prefix}_animation_tab_involute.txt"
            eq_file = "Profile_tab_parameters_equations_involute.txt"
        else:
            anim_file = f"{prefix}_animation_tab_cycloid.txt"
            eq_file = "Profile_tab_parameters_equations_cycloid.txt"
        self.animation_tab_text = _read_lines(text_path(folder, anim_file))
        self.profile_tab_parameters_equations = _read_lines(text_path(eq_file))

        self.profile_tab_parameters = _read_lines(text_path(folder, f"{prefix}_profile_tab_parameters.txt"))
        self.profile_tab_circles = _read_lines(text_path(folder, f"{prefix}_profile_tab_circles.txt"))
        self.animation_tab_graphical_additions = _read_lines(
            text_path(folder, f"{prefix}_animation_tab_graphical_additions.txt")
        )
        self.animation_tab_parameters = _read_lines(
            text_path(folder, f"{prefix}_animation_tab_parameters.txt")
        )


class LineCursor:
    """Helper that mirrors the MATLAB ``seq()`` sequential counter.

    Each call to :meth:`next` returns the next line of the stored text
    list and auto-rewinds at the end, exactly like the original pattern
    ``if seq >= numel(text_file); seq = 0; end``.
    """

    def __init__(self, lines: List[str]) -> None:
        self._lines = lines
        self._index = 0

    def next(self, default: str = "") -> str:
        if not self._lines:
            return default
        if self._index >= len(self._lines):
            self._index = 0
        value = self._lines[self._index]
        self._index += 1
        return value

    def reset(self) -> None:
        self._index = 0
