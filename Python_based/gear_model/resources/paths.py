"""Centralised asset-path resolution for the Gear Model application."""
from __future__ import annotations

from pathlib import Path

# Root package directory (gear_model/)
PACKAGE_ROOT: Path = Path(__file__).resolve().parent.parent

# Directory holding the packaged resources (text files, data tables, ...).
RESOURCES_ROOT: Path = PACKAGE_ROOT / "resources"

# Directory containing bundled language text files (mirrors MATLAB Text/).
TEXT_ROOT: Path = RESOURCES_ROOT / "text"

# Directory containing the standard module-series tables.
MODULE_SERIES_ROOT: Path = RESOURCES_ROOT / "standard_module_series"

# Directory where optional image assets live (copied verbatim by the
# build script; may or may not exist at runtime).
IMAGES_ROOT: Path = PACKAGE_ROOT / "Images"


def image_path(filename: str) -> Path:
    """Return the absolute path to a packaged image asset.

    The returned path is not guaranteed to exist - callers should check.
    """
    return IMAGES_ROOT / filename


def text_path(*parts: str) -> Path:
    """Return the absolute path to a packaged text resource."""
    return TEXT_ROOT.joinpath(*parts)


def module_series_path(filename: str) -> Path:
    """Return the absolute path to a standard-module-series data file."""
    return MODULE_SERIES_ROOT / filename
