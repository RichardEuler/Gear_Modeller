"""Port of +Utils/+ProfileTab/profileLineStyleFunction.m."""
from __future__ import annotations

_STYLES = ["-", "--", ":", "-."]


def profile_line_style(index_1based: int) -> str:
    """Convert a 1-based dropdown index to a Matplotlib line style string."""
    i = index_1based - 1
    if 0 <= i < len(_STYLES):
        return _STYLES[i]
    return "-"
