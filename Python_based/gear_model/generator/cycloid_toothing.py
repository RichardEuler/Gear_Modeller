"""Port of +Generator/cycloidToothing.m."""
from __future__ import annotations

import math
import warnings
from typing import Optional

import numpy as np
from scipy.optimize import brentq, minimize_scalar

from gear_model.generator.tool_root_rounding import tool_root_rounding


class CycloidToothing:
    """Cycloidal tooth profile generator."""

    Cs = 0.5

    def __init__(
        self,
        modul: float,
        rho_epi: float,
        rho_hypo: float,
        num_teeth: int,
        unit_shift: float,
        quality: int = 200,
    ) -> None:
        quality = int(quality)
        rem4 = quality % 4
        if rem4 != 0:
            quality += 4 - rem4
        self.quality = quality

        self.PointedTips = False

        self.m_n = float(modul)
        self.z = int(num_teeth)
        self.a_e = float(rho_epi)
        self.a_h = float(rho_hypo)
        self.x = float(unit_shift)
        self.X_d = self.m_n * self.x

        self.c_koef = 0.25
        self.rf_koef = 0.38

        self.r_f0 = tool_root_rounding(self.m_n)
        self.r_a0 = self.rf_koef * self.m_n
        self.c_0 = math.ceil(4 * math.sqrt(self.m_n)) / 10.0
        self.h_a0 = self.m_n * (1 + self.c_koef)
        self.h_f0 = self.m_n + self.c_0

        self.r_f = self.r_a0
        self.h_a = self.m_n + self.X_d
        self.h_f = self.m_n * (1 + self.c_koef) - self.X_d
        self.R = self.m_n * self.z / 2.0
        # Base circle: not defined for cycloidal gearing -> NaN
        self.R_b = float("nan")
        self.R_a = self.R + self.h_a
        self.R_f = self.R - self.h_f

        self.p = self.m_n * math.pi

        self.initial_guess = 3.0
        self.profile: Optional[np.ndarray] = None
        self.tooth: Optional[np.ndarray] = None

        self._build_curves()

        # Validity
        if self.m_n * self.z == 2 * self.a_h:
            warnings.warn("Hypocycloid creation not possible: degenerate point.")
            return
        if self.a_h > self.R - self.h_f / 2 or self.a_h < self.h_f / 2:
            warnings.warn("Hypocycloid creation not possible: no intersection.")
            return

        try:
            self._tooth_profile()
        except Exception as exc:  # noqa: BLE001
            warnings.warn(f"Failed to build cycloidal profile: {exc}")

    # ----------------------------------------------------------------
    def _tip_center_function(self) -> None:
        self.Oa_Y = -self.h_a0 + self.r_a0 + self.X_d

        if self.X_d > 0:
            par = math.acos(1 - self.X_d / self.a_e)
            self.X_shift = -self.a_e * (par - math.sin(par))
        elif self.X_d < 0:
            par = math.acos(1 + self.X_d / self.a_h)
            self.X_shift = self.a_h * (par - math.sin(par))
        else:
            self.X_shift = 0.0

        if self.X_d < self.h_a0 - self.r_a0 and self.X_d > -self.h_f0 + self.r_f0:
            def tip_eq(par: float) -> float:
                s = math.sqrt(2 * (1 - math.cos(par)))
                return (
                    -self.a_h * (1 - math.cos(par))
                    - self.r_a0 * (math.cos(par) - 1) / s
                    + self.h_a0 - self.r_a0 - self.X_d
                )

            lo = math.acos((self.r_a0 - self.h_a0 + self.X_d) / self.a_h + 1)
            hi = math.acos((-self.h_a0 + self.X_d) / self.a_h + 1)
            tau = brentq(tip_eq, lo, hi)
            s = math.sqrt(2 * (1 - math.cos(tau)))
            self.Oa_X = (
                -self.a_h * (tau - math.sin(tau))
                - self.r_a0 * math.sin(tau) / s
                + (1 - self.Cs) * self.m_n * math.pi / 2 + self.X_shift
            )
        elif self.X_d <= -self.h_f0 + self.r_f0:
            def tip_eq(par: float) -> float:
                s = math.sqrt(2 * (1 - math.cos(par)))
                return (
                    -self.a_h * (1 - math.cos(par))
                    - self.r_a0 * (math.cos(par) - 1) / s
                    + self.h_a0 - self.r_a0 - self.X_d
                )

            lo = math.acos((self.r_a0 - self.h_a0 + self.X_d) / self.a_h + 1)
            hi = math.acos((-self.h_a0 + self.X_d) / self.a_h + 1)
            tau = brentq(tip_eq, lo, hi)
            s = math.sqrt(2 * (1 - math.cos(tau)))
            self.Oa_X = (
                -self.a_h * (tau - math.sin(tau))
                - self.r_a0 * math.sin(tau) / s
                + (1 - self.Cs) * self.m_n * math.pi / 2 + self.X_shift
            )
        else:  # X_d >= h_a0 - r_a0
            if self.X_d == self.h_a0 - self.r_a0:
                tau = 0.0
                self.Oa_X = (
                    self.a_e * (tau - math.sin(tau)) - self.r_a0
                    + (1 - self.Cs) * self.m_n * math.pi / 2
                )
            else:
                def tip_eq(par: float) -> float:
                    s = math.sqrt(2 * (1 - math.cos(par)))
                    return (
                        self.a_e * (1 - math.cos(par))
                        - self.r_a0 * (math.cos(par) - 1) / s
                        + self.h_a0 - self.r_a0 - self.X_d
                    )

                if self.X_d < self.h_a0:
                    lo = 1e-6
                else:
                    lo = math.acos((self.h_a0 - self.X_d) / self.a_e + 1)
                hi = math.acos((self.h_a0 - self.r_a0 - self.X_d) / self.a_e + 1)
                tau = brentq(tip_eq, lo, hi)
                s = math.sqrt(2 * (1 - math.cos(tau)))
                self.Oa_X = (
                    self.a_e * (tau - math.sin(tau))
                    - self.r_a0 * math.sin(tau) / s
                    + (1 - self.Cs) * self.m_n * math.pi / 2 + self.X_shift
                )

    def _build_curves(self) -> None:
        self._tip_center_function()
        self.psi = math.asin((self.Cs * self.m_n * math.pi / 2 + self.X_shift) / self.R)

        R = self.R
        a_e = self.a_e
        a_h = self.a_h
        psi = self.psi

        def Hypo_X(par):
            return a_h * np.sin((R - a_h) / a_h * par + psi) - (R - a_h) * np.sin(par - psi)

        def Hypo_Y(par):
            return a_h * np.cos((R - a_h) / a_h * par + psi) + (R - a_h) * np.cos(par - psi)

        def Epi_X(par):
            return (R + a_e) * np.sin(par + psi) - a_e * np.sin((R + a_e) / a_e * par + psi)

        def Epi_Y(par):
            return (R + a_e) * np.cos(par + psi) - a_e * np.cos((R + a_e) / a_e * par + psi)

        def Tr1_X(par):
            return R * par * np.cos(par - self.Oa_X / R) - (self.Oa_Y + R) * np.sin(par - self.Oa_X / R)

        def Tr1_Y(par):
            return R * par * np.sin(par - self.Oa_X / R) + (self.Oa_Y + R) * np.cos(par - self.Oa_X / R)

        def Tr1_dX(par):
            return -self.Oa_Y * np.cos(par - self.Oa_X / R) - R * par * np.sin(par - self.Oa_X / R)

        def Tr1_dY(par):
            return -self.Oa_Y * np.sin(par - self.Oa_X / R) + R * par * np.cos(par - self.Oa_X / R)

        if self.x >= 1 + self.c_koef - self.rf_koef:
            def Tr2_X(par):
                dx = Tr1_dX(-par); dy = Tr1_dY(-par)
                ang = np.arctan2(-dx, dy) + math.pi
                return Tr1_X(-par) + self.r_a0 * np.cos(ang)

            def Tr2_Y(par):
                dx = Tr1_dX(-par); dy = Tr1_dY(-par)
                ang = np.arctan2(-dx, dy) + math.pi
                return Tr1_Y(-par) + self.r_a0 * np.sin(ang)
        else:
            def Tr2_X(par):
                dx = Tr1_dX(par); dy = Tr1_dY(par)
                ang = np.arctan2(-dx, dy)
                return Tr1_X(par) + self.r_a0 * np.cos(ang)

            def Tr2_Y(par):
                dx = Tr1_dX(par); dy = Tr1_dY(par)
                ang = np.arctan2(-dx, dy)
                return Tr1_Y(par) + self.r_a0 * np.sin(ang)

        def Hypo_R(par):
            return np.sqrt(
                (R - a_h) ** 2 + a_h ** 2 + 2 * a_h * (R - a_h) * np.cos(par * R / a_h)
            )

        def Epi_R(par):
            return np.sqrt(
                (R + a_e) ** 2 + a_e ** 2 - 2 * a_e * (R + a_e) * np.cos(par * R / a_e)
            )

        def Tr2_R(par):
            return np.sqrt(Tr2_X(par) ** 2 + Tr2_Y(par) ** 2)

        def Hypo_t(rho):
            return a_h / R * np.arccos((rho ** 2 - (R - a_h) ** 2 - a_h ** 2) / (2 * a_h * (R - a_h)))

        def Epi_t(rho):
            return a_e / R * np.arccos((-rho ** 2 + (R + a_e) ** 2 + a_e ** 2) / (2 * a_e * (R + a_e)))

        self.Hypo_X = Hypo_X; self.Hypo_Y = Hypo_Y
        self.Epi_X = Epi_X; self.Epi_Y = Epi_Y
        self.Tr2_X = Tr2_X; self.Tr2_Y = Tr2_Y
        self.Hypo_R = Hypo_R; self.Epi_R = Epi_R; self.Tr2_R = Tr2_R
        self.Hypo_t = Hypo_t; self.Epi_t = Epi_t

    # ----------------------------------------------------------------
    def _tooth_profile(self) -> None:
        def Tr2X(p): return float(self.Tr2_X(p))
        def Tr2Y(p): return float(self.Tr2_Y(p))
        def Tr2R(p): return float(self.Tr2_R(p))
        def HypoX(p): return float(self.Hypo_X(p))
        def HypoY(p): return float(self.Hypo_Y(p))
        def HypoR(p): return float(self.Hypo_R(p))
        def EpiX(p): return float(self.Epi_X(p))
        def EpiY(p): return float(self.Epi_Y(p))
        def EpiR(p): return float(self.Epi_R(p))

        # Parameter on trochoid at addendum radius (fzero with squared form in MATLAB)
        t_tr_Ra_sq = brentq(lambda p: self.R_a - Tr2R(p * p), 0.0, math.sqrt(self.initial_guess * 2 + 1))
        t_tr_Ra = t_tr_Ra_sq ** 2

        angle_epi_tip = float("nan")

        # Orientation check at R_a
        if self.x < -1:
            t_hypo_Ra = float(self.Hypo_t(self.R_a))
            vector_Ra = [HypoX(t_hypo_Ra) - Tr2X(t_tr_Ra), HypoY(t_hypo_Ra) - Tr2Y(t_tr_Ra)]
        else:
            t_epi_Ra = float(self.Epi_t(self.R_a))
            vector_Ra = [EpiX(t_epi_Ra) - Tr2X(t_tr_Ra), EpiY(t_epi_Ra) - Tr2Y(t_tr_Ra)]

        normal_ra = [Tr2Y(t_tr_Ra), -Tr2X(t_tr_Ra)]
        dp = normal_ra[0] * vector_Ra[0] + normal_ra[1] * vector_Ra[1]
        orientation_Ra = 0 if dp == 0 else (1 if dp > 0 else -1)

        hypocycloid = np.array([[float("nan")], [float("nan")]])
        epicycloid = np.array([[float("nan")], [float("nan")]])
        trochoid = None

        if orientation_Ra == 1:
            if self.x > -1 and self.x < 1 + self.c_koef:
                t_tr_R = brentq(lambda p: self.R - Tr2R(p), 0.0, t_tr_Ra)

                vector_R = [HypoX(0) - Tr2X(t_tr_R), HypoY(0) - Tr2Y(t_tr_R)]
                normal_r = [Tr2Y(t_tr_R), -Tr2X(t_tr_R)]
                dp_r = normal_r[0] * vector_R[0] + normal_r[1] * vector_R[1]
                orientation_R = 0 if dp_r == 0 else (1 if dp_r > 0 else -1)

                if orientation_R == 1:
                    def chord_hypo(t_curve):
                        common_radius = HypoR(t_curve)
                        try:
                            t_tr = brentq(lambda p: common_radius - Tr2R(p), 0.0, t_tr_R)
                        except ValueError:
                            t_tr = t_tr_R
                        return math.sqrt((Tr2X(t_tr) - HypoX(t_curve)) ** 2 + (Tr2Y(t_tr) - HypoY(t_curve)) ** 2)

                    hi = float(self.Hypo_t(self.R_f))
                    res = minimize_scalar(chord_hypo, bounds=(0.0, hi), method="bounded")
                    t_hypo_int = float(res.x)
                    t_tr_intersection = brentq(
                        lambda p: HypoR(t_hypo_int) - Tr2R(p), 0.0, t_tr_R
                    )

                    t_hypo = np.linspace(0.0, t_hypo_int, self.quality)
                    hypocycloid = np.vstack([self.Hypo_X(t_hypo), self.Hypo_Y(t_hypo)])

                    t_epi_tip = float(self.Epi_t(self.R_a))
                    angle_epi_tip = math.atan(EpiX(t_epi_tip) / EpiY(t_epi_tip))
                    t_epi = np.linspace(0.0, t_epi_tip, self.quality)
                    epicycloid = np.vstack([self.Epi_X(t_epi), self.Epi_Y(t_epi)])
                elif orientation_R == -1:
                    def chord_epi(t_curve):
                        common_radius = EpiR(t_curve)
                        try:
                            t_tr = brentq(lambda p: common_radius - Tr2R(p), t_tr_R, t_tr_Ra)
                        except ValueError:
                            t_tr = t_tr_R
                        return math.sqrt((Tr2X(t_tr) - EpiX(t_curve)) ** 2 + (Tr2Y(t_tr) - EpiY(t_curve)) ** 2)

                    hi = float(self.Epi_t(self.R_a))
                    res = minimize_scalar(chord_epi, bounds=(0.0, hi), method="bounded")
                    t_epi_int = float(res.x)
                    t_tr_intersection = brentq(
                        lambda p: EpiR(t_epi_int) - Tr2R(p), t_tr_R, t_tr_Ra
                    )

                    t_epi_tip = float(self.Epi_t(self.R_a))
                    angle_epi_tip = math.atan(EpiX(t_epi_tip) / EpiY(t_epi_tip))
                    t_epi = np.linspace(t_epi_int, t_epi_tip, self.quality)
                    epicycloid = np.vstack([self.Epi_X(t_epi), self.Epi_Y(t_epi)])
                else:
                    t_tr_intersection = t_tr_R
                    t_epi_tip = float(self.Epi_t(self.R_a))
                    angle_epi_tip = math.atan(EpiX(t_epi_tip) / EpiY(t_epi_tip))
                    t_epi = np.linspace(0.0, t_epi_tip, self.quality)
                    epicycloid = np.vstack([self.Epi_X(t_epi), self.Epi_Y(t_epi)])

            elif self.x <= -1:
                def chord_hypo(t_curve):
                    common_radius = HypoR(t_curve)
                    try:
                        t_tr = brentq(lambda p: common_radius - Tr2R(p), 0.0, t_tr_Ra)
                    except ValueError:
                        t_tr = t_tr_Ra
                    return math.sqrt((Tr2X(t_tr) - HypoX(t_curve)) ** 2 + (Tr2Y(t_tr) - HypoY(t_curve)) ** 2)

                lo = float(self.Hypo_t(self.R_a))
                hi = float(self.Hypo_t(self.R_f))
                res = minimize_scalar(chord_hypo, bounds=(lo, hi), method="bounded")
                t_hypo_int = float(res.x)
                t_tr_intersection = brentq(lambda p: HypoR(t_hypo_int) - Tr2R(p), 0.0, t_tr_Ra)
                t_hypo = np.linspace(lo, t_hypo_int, self.quality)
                hypocycloid = np.vstack([self.Hypo_X(t_hypo), self.Hypo_Y(t_hypo)])

            elif self.x >= 1 + self.c_koef:
                def chord_epi(t_curve):
                    common_radius = EpiR(t_curve)
                    try:
                        t_tr = brentq(lambda p: common_radius - Tr2R(p), 0.0, t_tr_Ra)
                    except ValueError:
                        t_tr = t_tr_Ra
                    return math.sqrt((Tr2X(t_tr) - EpiX(t_curve)) ** 2 + (Tr2Y(t_tr) - EpiY(t_curve)) ** 2)

                lo = float(self.Epi_t(self.R_f))
                hi = float(self.Epi_t(self.R_a))
                res = minimize_scalar(chord_epi, bounds=(lo, hi), method="bounded")
                t_epi_int = float(res.x)
                t_tr_intersection = brentq(lambda p: EpiR(t_epi_int) - Tr2R(p), 0.0, t_tr_Ra)

                t_epi_tip = float(self.Epi_t(self.R_a))
                angle_epi_tip = math.atan(EpiX(t_epi_tip) / EpiY(t_epi_tip))
                t_epi = np.linspace(t_epi_int, t_epi_tip, self.quality)
                epicycloid = np.vstack([self.Epi_X(t_epi), self.Epi_Y(t_epi)])
            else:
                raise RuntimeError("Unexpected condition in cycloid profile.")

            t_tr = np.linspace(0.0, t_tr_intersection, self.quality)
            trochoid = np.vstack([self.Tr2_X(t_tr), self.Tr2_Y(t_tr)])
        else:
            t_tr = np.linspace(0.0, t_tr_Ra, self.quality)
            trochoid = np.vstack([self.Tr2_X(t_tr), self.Tr2_Y(t_tr)])

        # Addendum arc (or pointed tip)
        if math.isnan(angle_epi_tip) or angle_epi_tip < math.pi / self.z:
            if not np.all(np.isnan(epicycloid)):
                tau_start = math.atan(epicycloid[0, -1] / epicycloid[1, -1])
            elif not np.all(np.isnan(hypocycloid)):
                tau_start = math.atan(hypocycloid[0, 0] / hypocycloid[1, 0])
            else:
                tau_start = math.atan(trochoid[0, -1] / trochoid[1, -1])
            t_a = np.linspace(tau_start, math.pi / self.z, max(1, self.quality // 4))
            head = np.vstack([self.R_a * np.sin(t_a), self.R_a * np.cos(t_a)])
        else:
            self.PointedTips = True
            head = np.array([[float("nan")], [float("nan")]])

        # Dedendum arc
        tau_f = math.atan(trochoid[0, 0] / trochoid[1, 0])
        t_foot = np.linspace(0.0, tau_f, max(1, self.quality // 4))
        foot = np.vstack([self.R_f * np.sin(t_foot), self.R_f * np.cos(t_foot)])

        # Assemble half-profile; hypocycloid is stored reversed
        segs = [foot, trochoid]
        if not np.all(np.isnan(hypocycloid)):
            segs.append(hypocycloid[:, ::-1])
        if not np.all(np.isnan(epicycloid)):
            segs.append(epicycloid)
        if not np.all(np.isnan(head)):
            segs.append(head)

        profile = np.hstack(segs)
        mask = ~np.any(np.isnan(profile), axis=0)
        profile = profile[:, mask]
        self.profile = profile

        ang = math.pi / self.z
        T = np.array([[math.cos(ang), -math.sin(ang)], [math.sin(ang), math.cos(ang)]])
        left = T @ profile
        right = np.vstack([-left[0, :], left[1, :]])
        self.tooth = np.hstack([left[:, :-1], right[:, ::-1]])
