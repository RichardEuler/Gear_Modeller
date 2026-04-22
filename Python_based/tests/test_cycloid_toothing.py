import math

import pytest

from gear_model.generator import CycloidToothing


def test_cycloid_basic_dimensions():
    gear = CycloidToothing(modul=1.0, rho_epi=2.0, rho_hypo=5.0,
                            num_teeth=20, unit_shift=0.0)
    assert gear.z == 20
    assert gear.R == pytest.approx(10.0)
    # Cycloidal gears have NaN base-circle radius
    import math as _m
    assert _m.isnan(gear.R_b)
    assert gear.R_a == pytest.approx(11.0)
    assert gear.R_f == pytest.approx(10.0 - 1.25)


def test_cycloid_profile_built():
    gear = CycloidToothing(modul=1.0, rho_epi=2.0, rho_hypo=5.0,
                            num_teeth=20, unit_shift=0.0)
    assert gear.tooth is not None
    assert gear.tooth.shape[0] == 2
    assert gear.tooth.shape[1] > 10
