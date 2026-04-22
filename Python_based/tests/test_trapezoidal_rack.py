import math

import numpy as np
import pytest

from gear_model.generator import TrapezoidalRack


def test_trapezoidal_rack_basic_dims():
    rack = TrapezoidalRack(modul=1.0, profile_angle=20.0, unit_shift=0.0, quality=25)

    assert rack.m_n == pytest.approx(1.0)
    assert rack.alpha == pytest.approx(math.radians(20.0))
    assert rack.c_koef == pytest.approx(0.25)
    assert rack.h_a0 == pytest.approx(1.25)
    # c_0 = ceil(4*sqrt(1))/10 = 0.4
    assert rack.c_0 == pytest.approx(0.4)
    assert rack.h_f0 == pytest.approx(1.4)


def test_trapezoidal_rack_symmetry():
    rack = TrapezoidalRack(modul=2.0, profile_angle=20.0, unit_shift=0.0, quality=25)
    tooth = rack.tooth
    assert tooth is not None
    # Symmetric about x = 0: the set of x-coords should include both +v and -v
    xs = tooth[0, :]
    for x in xs:
        assert np.any(np.isclose(xs, -x, atol=1e-9))


def test_trapezoidal_rack_pitch():
    # Rightmost profile point lies at m * pi / 2
    rack = TrapezoidalRack(modul=1.0, profile_angle=20.0, unit_shift=0.0, quality=25)
    assert rack.tooth[0, -1] == pytest.approx(math.pi / 2, rel=1e-12)
