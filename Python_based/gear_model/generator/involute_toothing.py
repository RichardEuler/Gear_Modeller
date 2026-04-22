"""Port of +Generator/involuteToothing.m."""
from __future__ import annotations

import math
import warnings
from typing import Optional

import numpy as np
from scipy.optimize import brentq, minimize_scalar

from gear_model.generator.tool_root_rounding import tool_root_rounding


class InvoluteToothing:
    """Involute tooth profile generator."""

    Cs = 0.5

    def __init__(
        self,
        modul: float = 1.0,
        profile_angle: float = 20.0,
        num_teeth: int = 30,
        unit_shift: float = 0.0,
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
        self.alpha = math.radians(profile_angle)
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
        self.R_b = self.R * math.cos(self.alpha)
        self.R_a = self.R + self.h_a
        self.R_f = self.R - self.h_f

        self.p = self.m_n * math.pi
        self.p_b = (2 * math.pi / self.z) * self.R_b
        self.p_f = (2 * math.pi / self.z) * self.R_f
        self.p_a = (2 * math.pi / self.z) * self.R_a

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

        self.initial_guess = 3.0

        # Build curve functions (stored as closures)
        self._build_curves()
        self._lower_limit_profile_shift()
        self._upper_limit_profile_shift()

        self.tooth: Optional[np.ndarray] = None
        self.profile: Optional[np.ndarray] = None
        try:
            self._tooth_profile()
        except Exception as exc:  # noqa: BLE001
            warnings.warn(f"Failed to build involute profile: {exc}")

    # ----------------------------------------------------------------
    def _build_curves(self) -> None:
        self.Oa_X = (
            self.Cs * self.m_n * math.pi / 2
            - self.h_a0 * math.tan(self.alpha)
            - self.r_a0 * math.tan(math.pi / 4 - self.alpha / 2)
        )

        def Oa_Y(par: float) -> float:
            return -self.h_a0 + self.r_a0 + self.m_n * par

        def psi(par: float) -> float:
            return (
                math.tan(self.alpha) - self.alpha
                - (self.Cs * self.m_n * math.pi - 2 * self.m_n * par * math.tan(self.alpha))
                / (2 * self.R)
            )

        def _cos(x):
            return np.cos(x) if isinstance(x, np.ndarray) else math.cos(x)

        def _sin(x):
            return np.sin(x) if isinstance(x, np.ndarray) else math.sin(x)

        def Inv_X(par1, par2):
            p = psi(par2)
            return self.R_b * par1 * _cos(p + par1) - self.R_b * _sin(p + par1)

        def Inv_Y(par1, par2):
            p = psi(par2)
            return self.R_b * par1 * _sin(p + par1) + self.R_b * _cos(p + par1)

        def Tr1_X(par1, par2):
            return self.R * par1 * _cos(par1 - self.Oa_X / self.R) - (Oa_Y(par2) + self.R) * _sin(par1 - self.Oa_X / self.R)

        def Tr1_Y(par1, par2):
            return self.R * par1 * _sin(par1 - self.Oa_X / self.R) + (Oa_Y(par2) + self.R) * _cos(par1 - self.Oa_X / self.R)

        def Tr1_dX(par1, par2):
            return -Oa_Y(par2) * _cos(par1 - self.Oa_X / self.R) - self.R * par1 * _sin(par1 - self.Oa_X / self.R)

        def Tr1_dY(par1, par2):
            return -Oa_Y(par2) * _sin(par1 - self.Oa_X / self.R) + self.R * par1 * _cos(par1 - self.Oa_X / self.R)

        if self.x >= 1 + self.c_koef - self.rf_koef:
            def Tr2_X(par1, par2):
                dx = Tr1_dX(-par1, par2)
                dy = Tr1_dY(-par1, par2)
                ang = np.arctan2(-dx, dy) + math.pi
                return Tr1_X(-par1, par2) + self.r_a0 * np.cos(ang)

            def Tr2_Y(par1, par2):
                dx = Tr1_dX(-par1, par2)
                dy = Tr1_dY(-par1, par2)
                ang = np.arctan2(-dx, dy) + math.pi
                return Tr1_Y(-par1, par2) + self.r_a0 * np.sin(ang)
        else:
            def Tr2_X(par1, par2):
                dx = Tr1_dX(par1, par2)
                dy = Tr1_dY(par1, par2)
                ang = np.arctan2(-dx, dy)
                return Tr1_X(par1, par2) + self.r_a0 * np.cos(ang)

            def Tr2_Y(par1, par2):
                dx = Tr1_dX(par1, par2)
                dy = Tr1_dY(par1, par2)
                ang = np.arctan2(-dx, dy)
                return Tr1_Y(par1, par2) + self.r_a0 * np.sin(ang)

        def Inv_R(par):
            return self.R_b * np.sqrt(1 + par**2)

        def Tr2_R(par1, par2):
            return np.sqrt(Tr2_X(par1, par2) ** 2 + Tr2_Y(par1, par2) ** 2)

        def Inv_t(rho):
            return -np.sqrt(rho**2 - self.R_b**2) / self.R_b

        self.psi = psi
        self.Inv_X = Inv_X
        self.Inv_Y = Inv_Y
        self.Inv_R = Inv_R
        self.Inv_t = Inv_t
        self.Tr1_X = Tr1_X
        self.Tr1_Y = Tr1_Y
        self.Tr1_dX = Tr1_dX
        self.Tr1_dY = Tr1_dY
        self.Tr2_X = Tr2_X
        self.Tr2_Y = Tr2_Y
        self.Tr2_R = Tr2_R

    # ----------------------------------------------------------------
    def _lower_limit_profile_shift(self) -> None:
        def fun_Tr2_X(par1, par2):
            dx = self.Tr1_dX(par1, par2)
            dy = self.Tr1_dY(par1, par2)
            return self.Tr1_X(par1, par2) + self.r_a0 * math.cos(math.atan2(-dx, dy))

        def fun_Tr2_Y(par1, par2):
            dx = self.Tr1_dX(par1, par2)
            dy = self.Tr1_dY(par1, par2)
            return self.Tr1_Y(par1, par2) + self.r_a0 * math.sin(math.atan2(-dx, dy))

        def fun_Tr2_R(par1, par2):
            return math.sqrt(fun_Tr2_X(par1, par2) ** 2 + fun_Tr2_Y(par1, par2) ** 2)

        def distance(x_lim: float) -> float:
            try:
                t_inv_lim = float(self.Inv_t(self.R + (1 + x_lim) * self.m_n))
                def eq(par): return float(self.Inv_R(t_inv_lim)) - fun_Tr2_R(par, x_lim)
                t_tr_lim = brentq(eq, 0.0, self.initial_guess)
                dx = fun_Tr2_X(t_tr_lim, x_lim) - float(self.Inv_X(t_inv_lim, x_lim))
                dy = fun_Tr2_Y(t_tr_lim, x_lim) - float(self.Inv_Y(t_inv_lim, x_lim))
                return math.sqrt(dx * dx + dy * dy)
            except Exception:
                return 1e6

        x_start = self.z / 2.0 * (math.cos(self.alpha) - 1) - 1
        try:
            res = minimize_scalar(distance, bounds=(x_start, 0.0), method="bounded")
            x_lower = float(res.x)
        except Exception:
            x_lower = 0.0
        self.x_lower = math.ceil(x_lower * 1e4) * 1e-4

    def _upper_limit_profile_shift(self) -> None:
        def pointed_tip(x_lim: float) -> float:
            try:
                t_int = float(self.Inv_t(self.R + (1 + x_lim) * self.m_n))
                angle_inv = math.atan(float(self.Inv_X(t_int, x_lim)) / float(self.Inv_Y(t_int, x_lim)))
                return abs(angle_inv - math.pi / self.z)
            except Exception:
                return 1e6

        try:
            res = minimize_scalar(
                pointed_tip, bounds=(self.x_lower, 1 + self.c_koef), method="bounded"
            )
            x_upper = float(res.x)
        except Exception:
            x_upper = 1 + self.c_koef
        self.x_upper = math.floor(x_upper * 1e4) * 1e-4

    # ----------------------------------------------------------------
    def _tooth_profile(self) -> None:
        t_tr_start = 0.0

        def Tr2R_scalar(p):
            return float(self.Tr2_R(p, self.x))

        def Tr2X_scalar(p):
            return float(self.Tr2_X(p, self.x))

        def Tr2Y_scalar(p):
            return float(self.Tr2_Y(p, self.x))

        def InvR_scalar(p):
            return float(self.Inv_R(p))

        def InvX_scalar(p):
            return float(self.Inv_X(p, self.x))

        def InvY_scalar(p):
            return float(self.Inv_Y(p, self.x))

        def InvT_scalar(rho):
            return float(self.Inv_t(rho))

        involute = None
        head = None
        profile_pointed = False

        if self.x > self.x_lower:
            t_tr_end = brentq(lambda p: self.R_a - Tr2R_scalar(p), t_tr_start, self.initial_guess)

            t_inv_tip = InvT_scalar(self.R_a)
            angle_tip = math.atan(InvX_scalar(t_inv_tip) / InvY_scalar(t_inv_tip))
            if angle_tip > math.pi / self.z:
                t_inv_tip = brentq(
                    lambda p: math.atan(InvX_scalar(p) / InvY_scalar(p)) - math.pi / self.z,
                    t_inv_tip,
                    0.0,
                )
                self.PointedTips = True
                profile_pointed = True

            def intersection_distance(t_inv):
                common_radius = InvR_scalar(t_inv)
                try:
                    t_tr = brentq(lambda p: common_radius - Tr2R_scalar(p), t_tr_start, t_tr_end)
                except ValueError:
                    if common_radius < Tr2R_scalar(t_tr_start):
                        t_tr = t_tr_start
                    else:
                        t_tr = t_tr_end
                return math.sqrt(
                    (Tr2X_scalar(t_tr) - InvX_scalar(t_inv)) ** 2
                    + (Tr2Y_scalar(t_tr) - InvY_scalar(t_inv)) ** 2
                )

            lo, hi = sorted((t_inv_tip, 0.0))
            res = minimize_scalar(intersection_distance, bounds=(lo, hi), method="bounded")
            t_inv_intersection = float(res.x)
            t_tr_intersection = brentq(
                lambda p: InvR_scalar(t_inv_intersection) - Tr2R_scalar(p),
                t_tr_start,
                t_tr_end,
            )

            t_involute = np.linspace(t_inv_intersection, t_inv_tip, self.quality)
            involute = np.vstack([self.Inv_X(t_involute, self.x), self.Inv_Y(t_involute, self.x)])

            if not profile_pointed:
                t_a_start = math.atan(involute[0, -1] / involute[1, -1])
                t_head = np.linspace(t_a_start, math.pi / self.z, max(1, self.quality // 4))
                head = np.vstack([self.R_a * np.sin(t_head), self.R_a * np.cos(t_head)])
        else:
            t_tr_intersection = brentq(
                lambda p: self.R_a - Tr2R_scalar(p), t_tr_start, self.initial_guess
            )
            t_a_start = math.atan(Tr2X_scalar(t_tr_intersection) / Tr2Y_scalar(t_tr_intersection))
            t_head = np.linspace(t_a_start, math.pi / self.z, max(1, self.quality // 4))
            head = np.vstack([self.R_a * np.sin(t_head), self.R_a * np.cos(t_head)])

        t_trochoid = np.linspace(t_tr_start, t_tr_intersection, self.quality)
        trochoid = np.vstack([self.Tr2_X(t_trochoid, self.x), self.Tr2_Y(t_trochoid, self.x)])

        # Remove parts beyond pi/z
        angle_trochoid = np.arctan(trochoid[0, :] / trochoid[1, :])
        over = np.where(angle_trochoid > math.pi / self.z)[0]
        if over.size > 0:
            idx = over[0]
            try:
                t_no_head = brentq(
                    lambda p: math.atan(Tr2X_scalar(p) / Tr2Y_scalar(p)) - math.pi / self.z,
                    0.0,
                    t_trochoid[idx],
                )
                t_trochoid = np.linspace(t_tr_start, t_no_head, self.quality)
                trochoid = np.vstack([self.Tr2_X(t_trochoid, self.x), self.Tr2_Y(t_trochoid, self.x)])
            except ValueError:
                pass

        t_f_end = math.atan(trochoid[0, 0] / trochoid[1, 0])
        t_foot = np.linspace(0.0, t_f_end, max(1, self.quality // 4))
        foot = np.vstack([self.R_f * np.sin(t_foot), self.R_f * np.cos(t_foot)])

        # Strip trochoid if it crosses y-axis
        negative_idx = np.where(trochoid[0, :] < 0)[0]
        if negative_idx.size > 0:
            last_neg = negative_idx[-1]
            trochoid = trochoid[:, last_neg + 1 :]
            foot = None

        segments = []
        if foot is not None:
            segments.append(foot[:, :-1] if foot.shape[1] > 1 else foot)
        if trochoid.shape[1] >= 1:
            if involute is not None:
                segments.append(trochoid[:, :-1] if trochoid.shape[1] > 1 else trochoid)
            else:
                segments.append(trochoid)
        if involute is not None:
            segments.append(involute)
        if head is not None and not profile_pointed:
            segments.append(head[:, 1:] if head.shape[1] > 1 else head)

        profile = np.hstack([s for s in segments if s is not None and s.size > 0])
        # Remove NaN columns
        mask = ~np.any(np.isnan(profile), axis=0)
        profile = profile[:, mask]

        # Mirror to full symmetric tooth
        ang = math.pi / self.z
        T = np.array([[math.cos(ang), -math.sin(ang)], [math.sin(ang), math.cos(ang)]])
        left_profile = T @ profile
        right_profile = np.vstack([-left_profile[0, :], left_profile[1, :]])

        self.profile = profile
        self.tooth = np.hstack(
            [
                np.vstack(
                    [left_profile[0, :-1] if left_profile.shape[1] > 1 else left_profile[0, :],
                     left_profile[1, :-1] if left_profile.shape[1] > 1 else left_profile[1, :]]
                ),
                right_profile[:, ::-1],
            ]
        )
