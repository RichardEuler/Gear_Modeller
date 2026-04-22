"""Animation tab - simplified port (static preview of a gear mesh)."""
from __future__ import annotations

import math
from typing import List, Optional

import numpy as np
from PySide6.QtCore import QTimer
from PySide6.QtWidgets import (
    QButtonGroup, QCheckBox, QComboBox, QDoubleSpinBox, QGridLayout,
    QGroupBox, QHBoxLayout, QLabel, QPushButton, QRadioButton, QSpinBox,
    QVBoxLayout, QWidget, QMessageBox,
)

from gear_model.generator import (
    CycloidRack, CycloidToothing, InvoluteToothing, TrapezoidalRack,
)
from gear_model.utils.language_utils import LineCursor


def _rot(angle: float) -> np.ndarray:
    c, s = math.cos(angle), math.sin(angle)
    return np.array([[c, -s], [s, c]])


def _build_wheel(tooth: np.ndarray, z: int) -> np.ndarray:
    num = tooth.shape[1]
    out = np.zeros((2, num * z))
    for j in range(z):
        T = _rot(j * 2 * math.pi / z)
        out[:, num * j:num * (j + 1)] = T @ tooth
    return out


class AnimationTab(QWidget):
    """Simplified port of the MATLAB Animation tab."""

    def __init__(self, parent_window, output_window) -> None:
        super().__init__()
        self.window_ref = parent_window
        self.output_window = output_window

        self._pinion_line = None
        self._wheel_line = None
        self._timer = QTimer(self)
        self._timer.timeout.connect(self._tick)
        self._frame = 0
        self._pinion_data: Optional[np.ndarray] = None
        self._wheel_data: Optional[np.ndarray] = None
        self._aw: float = 0.0
        self._phi_p: float = 0.0
        self._phi_w: float = 0.0
        self._frames_per_pitch: int = 60

        self._build_ui()

    # ----------------------------------------------------------------
    def _build_ui(self) -> None:
        outer = QVBoxLayout(self)

        self.desc_label = QLabel("")
        self.desc_label.setWordWrap(True)
        outer.addWidget(self.desc_label)

        # Mode row
        mode_row = QHBoxLayout()
        self.mode_label = QLabel("Mode:")
        self.mode_combo = QComboBox()
        self.mode_combo.addItems(["Gear meshing", "Gear generation"])
        mode_row.addWidget(self.mode_label)
        mode_row.addWidget(self.mode_combo)
        mode_row.addStretch(1)
        outer.addLayout(mode_row)

        # Animation settings
        self.anim_group = QGroupBox()
        ag = QHBoxLayout(self.anim_group)

        self.speed_label = QLabel("Pinion speed:")
        self.speed_spin = QSpinBox(); self.speed_spin.setRange(1, 10000); self.speed_spin.setValue(20)
        self.fps_label = QLabel("FPS:")
        self.fps_spin = QSpinBox(); self.fps_spin.setRange(1, 120); self.fps_spin.setValue(20)

        ag.addWidget(self.speed_label); ag.addWidget(self.speed_spin)
        ag.addWidget(self.fps_label); ag.addWidget(self.fps_spin)
        ag.addStretch(1)
        outer.addWidget(self.anim_group)

        # Toothing settings
        self.tooth_group = QGroupBox()
        tg = QGridLayout(self.tooth_group)
        self.tt_label = QLabel("Gear type:")
        self.involute_rb = QRadioButton("Involute"); self.involute_rb.setChecked(True)
        self.cycloidal_rb = QRadioButton("Cycloidal")
        self.tt_group = QButtonGroup(self)
        self.tt_group.addButton(self.involute_rb)
        self.tt_group.addButton(self.cycloidal_rb)
        tg.addWidget(self.tt_label, 0, 0); tg.addWidget(self.involute_rb, 0, 1); tg.addWidget(self.cycloidal_rb, 0, 2)

        # Parameters
        self.m_label = QLabel("Module:"); self.m_spin = QDoubleSpinBox(); self.m_spin.setValue(1.0); self.m_spin.setRange(0.01, 1e4)
        self.z1_label = QLabel("z_pinion:"); self.z1_spin = QSpinBox(); self.z1_spin.setRange(2, 10000); self.z1_spin.setValue(20)
        self.z2_label = QLabel("z_wheel:"); self.z2_spin = QSpinBox(); self.z2_spin.setRange(2, 10000); self.z2_spin.setValue(30)
        self.x1_label = QLabel("x1:"); self.x1_spin = QDoubleSpinBox(); self.x1_spin.setRange(-10.0, 10.0); self.x1_spin.setValue(0.0)
        self.x2_label = QLabel("x2:"); self.x2_spin = QDoubleSpinBox(); self.x2_spin.setRange(-10.0, 10.0); self.x2_spin.setValue(0.0)
        self.alpha_label = QLabel("alpha:"); self.alpha_spin = QDoubleSpinBox(); self.alpha_spin.setRange(0.01, 90.0); self.alpha_spin.setValue(20.0)
        self.rho_label = QLabel("rho_a:"); self.rho_spin = QDoubleSpinBox(); self.rho_spin.setRange(0.01, 10000.0); self.rho_spin.setValue(5.0)

        row = 1
        for a, b in ((self.m_label, self.m_spin), (self.z1_label, self.z1_spin), (self.z2_label, self.z2_spin),
                     (self.x1_label, self.x1_spin), (self.x2_label, self.x2_spin),
                     (self.alpha_label, self.alpha_spin), (self.rho_label, self.rho_spin)):
            tg.addWidget(a, row, 0); tg.addWidget(b, row, 1, 1, 2)
            row += 1

        self.tt_group.buttonToggled.connect(self._on_type_changed)
        outer.addWidget(self.tooth_group)

        # Action buttons
        actions = QHBoxLayout()
        self.display_btn = QPushButton("DISPLAY"); self.display_btn.clicked.connect(self._display)
        self.play_btn = QPushButton("PLAY"); self.play_btn.setEnabled(False); self.play_btn.clicked.connect(self._toggle_play)
        self.cancel_btn = QPushButton("DELETE"); self.cancel_btn.clicked.connect(self._cancel)
        actions.addWidget(self.display_btn); actions.addWidget(self.play_btn); actions.addWidget(self.cancel_btn)
        outer.addLayout(actions)

        outer.addStretch(1)
        self._on_type_changed()

    # ----------------------------------------------------------------
    def _on_type_changed(self) -> None:
        is_inv = self.involute_rb.isChecked()
        self.alpha_label.setVisible(is_inv)
        self.alpha_spin.setVisible(is_inv)
        self.rho_label.setVisible(not is_inv)
        self.rho_spin.setVisible(not is_inv)

    # ----------------------------------------------------------------
    def apply_translations(self, anim_text: List[str]) -> None:
        c = LineCursor(anim_text)
        _tab = c.next("Animation")  # tab title
        self.desc_label.setText(c.next(""))
        self.mode_label.setText(c.next("Mode:"))
        mode_items_line = c.next("Gear meshing, Gear generation")
        items = [s.strip() for s in mode_items_line.split(",")]
        prev = self.mode_combo.currentIndex()
        self.mode_combo.clear(); self.mode_combo.addItems(items)
        if 0 <= prev < len(items):
            self.mode_combo.setCurrentIndex(prev)

        self.anim_group.setTitle(c.next("Animation settings"))
        self.speed_label.setText(c.next("Pinion speed:"))
        self.fps_label.setText(c.next("Frame rate:"))

    # ----------------------------------------------------------------
    def _display(self) -> None:
        try:
            m = self.m_spin.value()
            z = (self.z1_spin.value(), self.z2_spin.value())
            x = (self.x1_spin.value(), self.x2_spin.value())

            if self.involute_rb.isChecked():
                gear_p = InvoluteToothing(m, self.alpha_spin.value(), z[0], x[0])
                gear_w = InvoluteToothing(m, self.alpha_spin.value(), z[1], x[1])
            else:
                rho = self.rho_spin.value()
                gear_p = CycloidToothing(m, rho, rho, z[0], x[0])
                gear_w = CycloidToothing(m, rho, rho, z[1], x[1])

            if gear_p.tooth is None or gear_w.tooth is None:
                QMessageBox.warning(self, "Warning", "Failed to build gear profiles."); return

            pinion = _build_wheel(gear_p.tooth[:, :-1], z[0])
            wheel = _build_wheel(gear_w.tooth[:, :-1], z[1])

            aw = m * (z[0] + z[1]) / 2.0
            wheel_shifted = np.vstack([wheel[0, :], wheel[1, :] + aw])

            self._pinion_data = pinion
            self._wheel_data = wheel_shifted
            self._aw = aw

            ax = self.output_window.canvas.ax
            ax.clear(); ax.set_visible(True); ax.set_aspect("equal")
            self.output_window.hide_standby()
            self._pinion_line, = ax.plot(pinion[0, :], pinion[1, :], color="black")
            self._wheel_line, = ax.plot(wheel_shifted[0, :], wheel_shifted[1, :], color="black")
            ax.relim(); ax.autoscale_view()
            ax.grid(True)
            self.output_window.canvas.draw_idle()

            # Set up animation parameters
            fps = self.fps_spin.value()
            n_rph = self.speed_spin.value() / 3600.0  # rev/s
            self._phi_p = -2 * math.pi * n_rph / fps
            u = z[1] / z[0]
            self._phi_w = -self._phi_p / u * -1  # wheel rotates opposite direction
            self._frame = 0
            self.play_btn.setEnabled(True)
            self.play_btn.setText("PLAY")
        except Exception as exc:  # noqa: BLE001
            QMessageBox.warning(self, "Error", f"Could not build animation:\n{exc}")

    def _toggle_play(self) -> None:
        if self._timer.isActive():
            self._timer.stop()
            self.play_btn.setText("PLAY")
        else:
            fps = self.fps_spin.value()
            self._timer.start(int(1000 / max(fps, 1)))
            self.play_btn.setText("PAUSE")

    def _tick(self) -> None:
        if self._pinion_data is None or self._wheel_data is None:
            return
        Tp = _rot(self._phi_p)
        Tw = _rot(self._phi_w)
        self._pinion_data = Tp @ self._pinion_data
        # Wheel rotates about its own centre (at y=aw)
        centred = self._wheel_data - np.array([[0.0], [self._aw]])
        centred = Tw @ centred
        self._wheel_data = centred + np.array([[0.0], [self._aw]])
        self._pinion_line.set_data(self._pinion_data[0, :], self._pinion_data[1, :])
        self._wheel_line.set_data(self._wheel_data[0, :], self._wheel_data[1, :])
        self.output_window.canvas.draw_idle()

    def _cancel(self) -> None:
        if self._timer.isActive():
            self._timer.stop()
        ax = self.output_window.canvas.ax
        ax.clear(); ax.set_visible(False)
        self._pinion_line = None; self._wheel_line = None
        self._pinion_data = None; self._wheel_data = None
        self.output_window.show_standby(True)
        self.output_window.canvas.draw_idle()
        self.play_btn.setEnabled(False)
        self.play_btn.setText("PLAY")
