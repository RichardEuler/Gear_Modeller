"""Port of +Generator/cycloidRack.m."""
from __future__ import annotations

import math
import warnings

import numpy as np
from scipy.optimize import brentq

from gear_model.generator.tool_root_rounding import tool_root_rounding


class CycloidRack:
    """Basic cycloidal tooth profile of a rack (addendum + dedendum cycloids)."""

    Cs = 0.5

    def __init__(
        self,
        modul: float,
        rho_a: float,
        rho_f: float,
        unit_shift: float = 0.0,
        quality: int = 50,
    ) -> None:
        quality = int(quality)
        if quality % 2 == 1:
            quality += 1
            warnings.warn(f"Quality increased to {quality} to be even.")
        self.quality = quality

        self.m_n = float(modul)
        self.rho_a0 = float(rho_a)
        self.rho_f0 = float(rho_f)
        self.x = float(unit_shift)
        self.X_d = self.m_n * self.x

        self.c_koef = 0.25
        self.rf_koef = 0.38

        self.r_f0 = tool_root_rounding(self.m_n)
        self.r_a0 = self.rf_koef * self.m_n
        self.c_0 = math.ceil(4 * math.sqrt(self.m_n)) / 10.0
        self.h_a0 = self.m_n * (1 + self.c_koef)
        self.h_f0 = self.m_n + self.c_0

        self.p = self.m_n * math.pi

        self.rho_a0_lim = [self.h_a0 / 2, self.h_a0 / 2]
        self.rho_f0_lim = [self.h_f0 / 2, self.h_f0 / 2]

        # Horizontal profile shift
        if self.X_d > 0:
            par = math.acos(1 - self.X_d / self.rho_f0)
            self.profile_shift = -self.rho_f0 * (par - math.sin(par))
        elif self.X_d < 0:
            par = math.acos(1 + self.X_d / self.rho_a0)
            self.profile_shift = self.rho_a0 * (par - math.sin(par))
        else:
            self.profile_shift = 0.0

        self._lim_fun()

        self.tooth: np.ndarray | None = None

        if self.rho_a0 <= max(self.rho_a0_lim):
            warnings.warn(
                "Addendum cycloid creation not possible; "
                f"rho_a must exceed {max(self.rho_a0_lim):.3f} mm."
            )
            return
        if self.rho_f0 <= max(self.rho_f0_lim):
            warnings.warn(
                "Dedendum cycloid creation not possible; "
                f"rho_f must exceed {max(self.rho_f0_lim):.3f} mm."
            )
            return

        self._profile_function()

    # ----------------------------------------------------------------
    # Limit helper
    # ----------------------------------------------------------------
    def _lim_fun(self) -> None:
        if self.X_d < self.h_f0 - self.r_f0:
            A = self.h_f0 - self.r_f0 + self.X_d
            B = self.profile_shift - self.m_n * math.pi / 2 * (1 - self.Cs)

            def fun_f(t: float) -> float:
                s = math.sqrt(2 * (1 - math.cos(t)))
                return (
                    s * ((t - math.sin(t)) * A + (1 - math.cos(t)) * B)
                    + t * self.r_f0 * (1 - math.cos(t))
                )

            try:
                t_f_lim = brentq(fun_f, 1e-6, math.pi)
                self.rho_f0_lim[1] = (
                    1 / (1 - math.cos(t_f_lim))
                    * (A + self.r_f0 * (1 - math.cos(t_f_lim)) / math.sqrt(2 * (1 - math.cos(t_f_lim))))
                )
            except ValueError:
                pass

        if self.X_d > -self.h_a0 + self.r_a0:
            A = self.h_a0 - self.r_a0 - self.X_d
            B = self.profile_shift + self.Cs * self.m_n * math.pi / 2

            def fun_a(t: float) -> float:
                s = math.sqrt(2 * (1 - math.cos(t)))
                return (
                    s * ((1 - math.cos(t)) * B - (t - math.sin(t)) * A)
                    - t * self.r_a0 * (1 - math.cos(t))
                )

            try:
                t_a_lim = brentq(fun_a, 1e-6, math.pi)
                self.rho_a0_lim[1] = (
                    1 / (1 - math.cos(t_a_lim))
                    * (A + self.r_a0 * (1 - math.cos(t_a_lim)) / math.sqrt(2 * (1 - math.cos(t_a_lim))))
                )
            except ValueError:
                pass

    # ----------------------------------------------------------------
    # Profile branches
    # ----------------------------------------------------------------
    def _profile_function(self) -> None:
        if self.X_d < self.h_a0 - self.r_a0 and self.X_d > -self.h_f0 + self.r_f0:
            self._both_cycloid_profile()
        elif self.X_d <= -self.h_f0 + self.r_f0:
            self._head_cycloid_profile()
        elif self.X_d >= self.h_a0 - self.r_a0:
            self._foot_cycloid_profile()
        else:
            raise RuntimeError("Unexpected condition in cycloid rack profile.")

        # Apply radial shift to y-coordinate
        self.tooth[1, :] += self.X_d

    def _both_cycloid_profile(self) -> None:
        def foot_eq(par: float) -> float:
            s = math.sqrt(2 * (1 - math.cos(par)))
            return (
                self.rho_f0 * (1 - math.cos(par))
                - self.r_f0 * (1 - math.cos(par)) / s
                - self.h_f0 + self.r_f0 - self.X_d
            )

        def tip_eq(par: float) -> float:
            s = math.sqrt(2 * (1 - math.cos(par)))
            return (
                -self.rho_a0 * (1 - math.cos(par))
                + self.r_a0 * (1 - math.cos(par)) / s
                + self.h_a0 - self.r_a0 - self.X_d
            )

        tau_f_lo = math.acos((self.r_f0 - self.h_f0 - self.X_d) / self.rho_f0 + 1)
        tau_f_hi = math.acos((-self.h_f0 - self.X_d) / self.rho_f0 + 1)
        tau_a_lo = math.acos((self.r_a0 - self.h_a0 + self.X_d) / self.rho_a0 + 1)
        tau_a_hi = math.acos((-self.h_a0 + self.X_d) / self.rho_a0 + 1)

        tau_f = brentq(foot_eq, tau_f_lo, tau_f_hi)
        tau_a = brentq(tip_eq, tau_a_lo, tau_a_hi)

        t_f = np.linspace(0.0, tau_f, self.quality)
        t_a = np.linspace(0.0, tau_a, self.quality)

        cyc_f_x = self.rho_f0 * (t_f - np.sin(t_f)) + self.Cs * self.m_n * math.pi / 2 + self.profile_shift
        cyc_f_y = self.rho_f0 * (1 - np.cos(t_f)) - self.X_d
        cyc_a_x = -self.rho_a0 * (t_a - np.sin(t_a)) + self.Cs * self.m_n * math.pi / 2 + self.profile_shift
        cyc_a_y = -self.rho_a0 * (1 - np.cos(t_a)) - self.X_d

        s_f = math.sqrt(2 * (1 - math.cos(tau_f)))
        s_a = math.sqrt(2 * (1 - math.cos(tau_a)))

        O_f_x = (
            self.rho_f0 * (tau_f - math.sin(tau_f))
            + self.r_f0 * math.sin(tau_f) / s_f
            + self.Cs * self.m_n * math.pi / 2
            + self.profile_shift
        )
        O_f_y = (
            self.rho_f0 * (1 - math.cos(tau_f))
            + self.r_f0 * (math.cos(tau_f) - 1) / s_f
            - self.X_d
        )
        O_a_x = (
            -self.rho_a0 * (tau_a - math.sin(tau_a))
            - self.r_a0 * math.sin(tau_a) / s_a
            + self.Cs * self.m_n * math.pi / 2
            + self.profile_shift
        )
        O_a_y = (
            -self.rho_a0 * (1 - math.cos(tau_a))
            - self.r_a0 * (math.cos(tau_a) - 1) / s_a
            - self.X_d
        )

        tau_Cf = math.acos((cyc_f_y[-1] + self.r_f0 - self.h_f0) / self.r_f0)
        t_Cf = np.linspace(0.0, tau_Cf, self.quality // 2)
        circle_f_x = O_f_x - self.r_f0 * np.sin(t_Cf)
        circle_f_y = O_f_y + self.r_f0 * np.cos(t_Cf)

        tau_Ca = math.acos((self.r_a0 - self.h_a0 - cyc_a_y[-1]) / self.r_a0)
        t_Ca = np.linspace(0.0, tau_Ca, self.quality // 2)
        circle_a_x = O_a_x + self.r_a0 * np.sin(t_Ca)
        circle_a_y = O_a_y - self.r_a0 * np.cos(t_Ca)

        profile_x = np.concatenate(
            [[0.0], circle_a_x, cyc_a_x[1:-1][::-1], cyc_f_x[:-1], circle_f_x[::-1], [self.m_n * math.pi / 2]]
        )
        profile_y = np.concatenate(
            [[-self.h_a0], circle_a_y, cyc_a_y[1:-1][::-1], cyc_f_y[:-1], circle_f_y[::-1], [self.h_f0]]
        )
        profile = np.vstack([profile_x, profile_y])

        half = profile[:, 1:]
        mirror = np.vstack([-half[0, :], half[1, :]])[:, ::-1]
        self.tooth = np.hstack([mirror, half])

    def _head_cycloid_profile(self) -> None:
        # Addendum cycloid only branch
        if self.X_d == -self.h_f0 + self.r_f0:
            tau_f = 0.0
        else:
            def foot_eq(par: float) -> float:
                s = math.sqrt(2 * (1 - math.cos(par)))
                return (
                    -self.rho_a0 * (1 - math.cos(par))
                    - self.r_f0 * (1 - math.cos(par)) / s
                    - self.h_f0 + self.r_f0 - self.X_d
                )

            if self.X_d > -self.h_f0:
                lo = 1e-6
            else:
                lo = math.acos((self.h_f0 + self.X_d) / self.rho_a0 + 1)
            hi = math.acos((self.h_f0 - self.r_f0 + self.X_d) / self.rho_a0 + 1)
            tau_f = brentq(foot_eq, lo, hi)

        def tip_eq(par: float) -> float:
            s = math.sqrt(2 * (1 - math.cos(par)))
            return (
                -self.rho_a0 * (1 - math.cos(par))
                + self.r_a0 * (1 - math.cos(par)) / s
                + self.h_a0 - self.r_a0 - self.X_d
            )

        tau_a_lo = math.acos((self.r_a0 - self.h_a0 + self.X_d) / self.rho_a0 + 1)
        tau_a_hi = math.acos((-self.h_a0 + self.X_d) / self.rho_a0 + 1)
        tau_a = brentq(tip_eq, tau_a_lo, tau_a_hi)

        t_a = np.linspace(tau_f, tau_a, 100)
        cyc_a_x = -self.rho_a0 * (t_a - np.sin(t_a)) + self.Cs * self.m_n * math.pi / 2 + self.profile_shift
        cyc_a_y = -self.rho_a0 * (1 - np.cos(t_a)) - self.X_d

        if self.X_d == -self.h_f0 + self.r_f0:
            tau_Cf = math.pi / 2
            O_f_x = -self.rho_a0 * (tau_f - math.sin(tau_f)) + self.r_f0 + self.Cs * self.m_n * math.pi / 2 + self.profile_shift
            O_f_y = self.h_f0 - self.r_f0
        else:
            tau_Cf = math.acos((cyc_a_y[0] + self.r_f0 - self.h_f0) / self.r_f0)
            s_f = math.sqrt(2 * (1 - math.cos(tau_f)))
            O_f_x = (
                -self.rho_a0 * (tau_f - math.sin(tau_f))
                + self.r_f0 * math.sin(tau_f) / s_f
                + self.Cs * self.m_n * math.pi / 2
                + self.profile_shift
            )
            O_f_y = (
                -self.rho_a0 * (1 - math.cos(tau_f))
                + self.r_f0 * (math.cos(tau_f) - 1) / s_f
                - self.X_d
            )

        s_a = math.sqrt(2 * (1 - math.cos(tau_a)))
        O_a_x = (
            -self.rho_a0 * (tau_a - math.sin(tau_a))
            - self.r_a0 * math.sin(tau_a) / s_a
            + self.Cs * self.m_n * math.pi / 2
            + self.profile_shift
        )
        O_a_y = (
            -self.rho_a0 * (1 - math.cos(tau_a))
            - self.r_a0 * (math.cos(tau_a) - 1) / s_a
            - self.X_d
        )

        t_Cf = np.linspace(0.0, tau_Cf, 100)
        circle_f_x = O_f_x - self.r_f0 * np.sin(t_Cf)
        circle_f_y = O_f_y + self.r_f0 * np.cos(t_Cf)

        tau_Ca = math.acos((self.r_a0 - self.h_a0 - cyc_a_y[-1]) / self.r_a0)
        t_Ca = np.linspace(0.0, tau_Ca, 100)
        circle_a_x = O_a_x + self.r_a0 * np.sin(t_Ca)
        circle_a_y = O_a_y - self.r_a0 * np.cos(t_Ca)

        profile_x = np.concatenate(
            [[0.0], circle_a_x, cyc_a_x[1:-1][::-1], circle_f_x[::-1], [self.m_n * math.pi / 2]]
        )
        profile_y = np.concatenate(
            [[-self.h_a0], circle_a_y, cyc_a_y[1:-1][::-1], circle_f_y[::-1], [self.h_f0]]
        )
        profile = np.vstack([profile_x, profile_y])
        half = profile[:, 1:]
        mirror = np.vstack([-half[0, :], half[1, :]])[:, ::-1]
        self.tooth = np.hstack([mirror, half])

    def _foot_cycloid_profile(self) -> None:
        if self.X_d == self.h_a0 - self.r_a0:
            tau_a = 0.0
        else:
            def tip_eq(par: float) -> float:
                s = math.sqrt(2 * (1 - math.cos(par)))
                return (
                    self.rho_f0 * (1 - math.cos(par))
                    + self.r_a0 * (1 - math.cos(par)) / s
                    + self.h_a0 - self.r_a0 - self.X_d
                )

            if self.X_d < self.h_a0:
                lo = 1e-6
            else:
                lo = math.acos((self.h_a0 - self.X_d) / self.rho_f0 + 1)
            hi = math.acos((self.h_a0 - self.r_a0 - self.X_d) / self.rho_f0 + 1)
            tau_a = brentq(tip_eq, lo, hi)

        def foot_eq(par: float) -> float:
            s = math.sqrt(2 * (1 - math.cos(par)))
            return (
                self.rho_f0 * (1 - math.cos(par))
                - self.r_f0 * (1 - math.cos(par)) / s
                - self.h_f0 + self.r_f0 - self.X_d
            )

        tau_f_lo = math.acos((self.r_f0 - self.h_f0 - self.X_d) / self.rho_f0 + 1)
        tau_f_hi = math.acos((-self.h_f0 - self.X_d) / self.rho_f0 + 1)
        tau_f = brentq(foot_eq, tau_f_lo, tau_f_hi)

        t_f = np.linspace(tau_a, tau_f, 100)
        cyc_f_x = self.rho_f0 * (t_f - np.sin(t_f)) + self.Cs * self.m_n * math.pi / 2 + self.profile_shift
        cyc_f_y = self.rho_f0 * (1 - np.cos(t_f)) - self.X_d

        if self.X_d == self.h_a0 - self.r_a0:
            tau_Ca = math.pi / 2
            O_a_x = (
                self.rho_f0 * (tau_a - math.sin(tau_a))
                - self.r_a0 + self.Cs * self.m_n * math.pi / 2 + self.profile_shift
            )
            O_a_y = -self.h_a0 + self.r_a0
        else:
            tau_Ca = math.acos((self.r_a0 - self.h_a0 - cyc_f_y[0]) / self.r_a0)
            s_a = math.sqrt(2 * (1 - math.cos(tau_a)))
            O_a_x = (
                self.rho_f0 * (tau_a - math.sin(tau_a))
                - self.r_a0 * math.sin(tau_a) / s_a
                + self.Cs * self.m_n * math.pi / 2
                + self.profile_shift
            )
            O_a_y = (
                self.rho_f0 * (1 - math.cos(tau_a))
                - self.r_a0 * (math.cos(tau_a) - 1) / s_a
                - self.X_d
            )

        s_f = math.sqrt(2 * (1 - math.cos(tau_f)))
        O_f_x = (
            self.rho_f0 * (tau_f - math.sin(tau_f))
            + self.r_f0 * math.sin(tau_f) / s_f
            + self.Cs * self.m_n * math.pi / 2
            + self.profile_shift
        )
        O_f_y = (
            self.rho_f0 * (1 - math.cos(tau_f))
            + self.r_f0 * (math.cos(tau_f) - 1) / s_f
            - self.X_d
        )

        tau_Cf = math.acos((cyc_f_y[0] + self.r_f0 - self.h_f0) / self.r_f0)
        t_Cf = np.linspace(0.0, tau_Cf, 100)
        circle_f_x = O_f_x - self.r_f0 * np.sin(t_Cf)
        circle_f_y = O_f_y + self.r_f0 * np.cos(t_Cf)

        t_Ca = np.linspace(0.0, tau_Ca, 100)
        circle_a_x = O_a_x + self.r_a0 * np.sin(t_Ca)
        circle_a_y = O_a_y - self.r_a0 * np.cos(t_Ca)

        profile_x = np.concatenate(
            [[0.0], circle_a_x, cyc_f_x[1:-1], circle_f_x[::-1], [self.m_n * math.pi / 2]]
        )
        profile_y = np.concatenate(
            [[-self.h_a0], circle_a_y, cyc_f_y[1:-1], circle_f_y[::-1], [self.h_f0]]
        )
        profile = np.vstack([profile_x, profile_y])
        half = profile[:, 1:]
        mirror = np.vstack([-half[0, :], half[1, :]])[:, ::-1]
        self.tooth = np.hstack([mirror, half])
