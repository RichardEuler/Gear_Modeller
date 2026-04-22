"""Port of +Generator/trapezoidalRack.m."""
from __future__ import annotations

import math
import warnings

import numpy as np
from scipy.optimize import brentq

from gear_model.generator.tool_root_rounding import tool_root_rounding


class TrapezoidalRack:
    """Trapezoidal basic tooth profile for involute gearing."""

    Cs = 0.5  # Tooth thickness coefficient

    def __init__(
        self,
        modul: float = 1.0,
        profile_angle: float = 20.0,
        unit_shift: float = 0.0,
        quality: int = 25,
    ) -> None:
        self.m_n = float(modul)
        self.alpha = math.radians(profile_angle)
        self.x = float(unit_shift)
        self.X_d = self.m_n * self.x

        self.c_koef = 0.25
        self.rf_koef = 0.38

        # Tool rounding radii (CSN 01 4608)
        self.r_f0 = tool_root_rounding(self.m_n)
        self.r_a0 = self.rf_koef * self.m_n

        self.c_0 = math.ceil(4 * math.sqrt(self.m_n)) / 10.0
        self.h_a0 = self.m_n * (1 + self.c_koef)
        self.h_f0 = self.m_n + self.c_0

        self.p = self.m_n * math.pi
        self.quality = int(quality)

        # Maximum profile angle
        def alpha_eq(par: float) -> float:
            return (
                self.Cs * self.m_n * math.pi / 2
                - self.h_a0 * math.tan(par)
                - self.r_a0 * math.tan(math.pi / 4 - par / 2)
            )

        try:
            amax = brentq(alpha_eq, 1e-6, math.pi / 2 - 1e-6)
        except ValueError:
            amax = math.radians(20)
        self.alpha_max = math.floor(math.degrees(amax) * 1e4) * 1e-4

        if profile_angle > self.alpha_max:
            warnings.warn(
                f"Profile angle exceeds maximum ({self.alpha_max:.4f} deg)."
            )

        self.Cs_lower = (
            self.h_a0 * math.tan(self.alpha)
            + self.r_a0 * math.tan(math.pi / 4 - self.alpha / 2)
        ) / (self.m_n * math.pi)
        self.Cs_upper = 1 - 2 / (self.m_n * math.pi) * (
            self.h_f0 * math.tan(self.alpha)
            + self.r_f0 * math.tan(math.pi / 4 - self.alpha / 2)
        )

        self._build_profile()

    def _build_profile(self) -> None:
        # Significant profile points (2x4)
        points = np.zeros((2, 4))
        points[0, 3] = self.Cs * self.m_n * math.pi / 2
        points[0, 0] = (
            points[0, 3]
            - self.h_a0 * math.tan(self.alpha)
            - self.r_a0 * math.tan(math.pi / 4 - self.alpha / 2)
        )
        points[0, 1] = points[0, 0]
        points[0, 2] = points[0, 0] + self.r_a0 * math.cos(self.alpha)

        points[1, 0] = -self.h_a0 + self.r_a0
        points[1, 1] = -self.h_a0
        points[1, 2] = points[1, 0] - self.r_a0 * math.sin(self.alpha)
        points[1, 3] = 0.0

        # Root fillet centre
        O_f = (
            points[0, 3]
            + self.h_f0 * math.tan(self.alpha)
            + self.r_f0 * math.tan(math.pi / 4 - self.alpha / 2),
            self.h_f0 - self.r_f0,
        )

        # linspace includes endpoints (MATLAB and numpy behave identically)
        t = np.linspace(0.0, math.pi / 2 - self.alpha, int(self.quality))

        head_x = self.r_a0 * np.sin(t) + points[0, 0]
        head_y = -self.r_a0 * np.cos(t) + points[1, 0]
        root_x = -self.r_f0 * np.cos(t + self.alpha) + O_f[0]
        root_y = self.r_f0 * np.sin(t + self.alpha) + O_f[1]

        profile_x = np.concatenate(
            ([0.0], head_x, root_x, [self.m_n * math.pi / 2])
        )
        profile_y = np.concatenate(
            ([-self.h_a0], head_y, root_y, [self.h_f0])
        )
        profile = np.vstack([profile_x, profile_y])

        # Apply profile shift
        points[1, :] += self.X_d
        profile[1, :] += self.X_d

        # Mirror to full tooth
        mirror = np.vstack([-profile[0, 1:], profile[1, 1:]])[:, ::-1]
        self.tooth = np.hstack([mirror, profile[:, 1:]])

        mirror_pts = np.vstack([-points[0, :], points[1, :]])[:, ::-1]
        self.points = np.hstack([mirror_pts, points])
        self.profile = profile
