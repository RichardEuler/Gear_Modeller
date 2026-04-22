"""Port of +Generator/toolRootRounding.m.

Hob tool root rounding radius per CSN 01 4608.
"""
from __future__ import annotations


def tool_root_rounding(m_n: float) -> float:
    """Return the hob tool root rounding radius for a given normal module.

    Mirrors the MATLAB lookup table exactly.
    """
    if m_n < 1:
        return 0.1
    if m_n < 2:
        return 0.2
    if m_n < 4.5:
        return 0.5
    if m_n < 7:
        return 1.0
    if m_n < 10:
        return 1.5
    if m_n < 18:
        return 2.0
    return 2.5
