"""Load standard module series tables (ports CSN 01 4608 data files)."""
from __future__ import annotations

from typing import List

from gear_model.resources.paths import module_series_path


def load_module_series(series: int) -> List[float]:
    """Return series 1 or series 2 as a list of float moduli."""
    if series not in (1, 2):
        raise ValueError("series must be 1 or 2")
    path = module_series_path(f"Module_series_{series}.txt")
    if not path.exists():
        return []
    values: List[float] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            values.append(float(line))
        except ValueError:
            continue
    return values
