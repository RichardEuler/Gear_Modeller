import pytest

from gear_model.generator import tool_root_rounding


@pytest.mark.parametrize("m,expected", [
    (0.5, 0.1),
    (1.0, 0.2),
    (1.9, 0.2),
    (2.0, 0.5),
    (4.4, 0.5),
    (4.5, 1.0),
    (6.9, 1.0),
    (7.0, 1.5),
    (9.5, 1.5),
    (10.0, 2.0),
    (17.9, 2.0),
    (18.0, 2.5),
    (25.0, 2.5),
])
def test_tool_root_rounding(m: float, expected: float) -> None:
    assert tool_root_rounding(m) == pytest.approx(expected)
