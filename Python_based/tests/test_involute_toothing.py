import math

import numpy as np
import pytest

from gear_model.generator import InvoluteToothing


def test_involute_basic_dimensions():
    gear = InvoluteToothing(modul=1.0, profile_angle=20.0, num_teeth=30, unit_shift=0.0)
    assert gear.z == 30
    assert gear.R == pytest.approx(15.0)
    # Base circle: d*cos(alpha)
    assert gear.R_b == pytest.approx(15.0 * math.cos(math.radians(20.0)), rel=1e-12)
    assert gear.R_a == pytest.approx(16.0, rel=1e-12)
    assert gear.R_f == pytest.approx(15.0 - 1.25, rel=1e-12)


def test_involute_profile_built():
    gear = InvoluteToothing(modul=1.0, profile_angle=20.0, num_teeth=30, unit_shift=0.0)
    assert gear.tooth is not None
    assert gear.tooth.shape[0] == 2
    assert gear.tooth.shape[1] > 10


def test_involute_symmetric_tooth():
    gear = InvoluteToothing(modul=2.0, profile_angle=20.0, num_teeth=20, unit_shift=0.0)
    assert gear.tooth is not None
    # Tooth is symmetric about the central pi/z axis after the rotation;
    # simplest check: x extremes are balanced
    xs = gear.tooth[0, :]
    assert abs(xs.min() + xs.max()) < 1e-6
