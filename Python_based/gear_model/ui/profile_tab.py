"""Profile tab UI (ports of the MATLAB Profile tab and its helpers)."""
from __future__ import annotations

import math
import random
from typing import List, Optional

import numpy as np
from PySide6.QtCore import Qt
from PySide6.QtGui import QColor
from PySide6.QtWidgets import (
    QButtonGroup, QCheckBox, QColorDialog, QComboBox, QDoubleSpinBox,
    QFormLayout, QGroupBox, QHBoxLayout, QLabel, QLineEdit, QMessageBox,
    QPushButton, QRadioButton, QSpinBox, QVBoxLayout, QWidget, QFileDialog,
    QScrollArea, QDialog, QDialogButtonBox, QGridLayout, QSizePolicy,
)

from gear_model.generator import CycloidToothing, InvoluteToothing
from gear_model.utils.language_utils import LineCursor
from gear_model.utils.line_style import profile_line_style


class CirclesDialog(QDialog):
    """Dialog for toggling significant circles on the output plot."""

    def __init__(self, parent, texts: List[str], is_involute: bool) -> None:
        super().__init__(parent)
        self.setWindowTitle(texts[0] if texts else "Relevant circles")
        self.setMinimumWidth(500)

        self.checks: List[QCheckBox] = []
        self.colors: List[QColor] = [QColor("black")] * 4
        self.widths: List[QDoubleSpinBox] = []
        self.styles: List[QComboBox] = []
        self._color_buttons: List[QPushButton] = []

        outer = QVBoxLayout(self)
        all_cb = QCheckBox(texts[1] if len(texts) > 1 else "Activate all")
        outer.addWidget(all_cb)

        grid = QGridLayout()
        outer.addLayout(grid)

        for i in range(4):
            label = texts[i + 2] if len(texts) > i + 2 else f"Circle {i+1}"
            cb = QCheckBox(label)
            self.checks.append(cb)
            grid.addWidget(cb, i, 0)

            col_btn = QPushButton()
            col_btn.setFixedWidth(60)
            col_btn.setStyleSheet("background-color: black")
            col_btn.clicked.connect(lambda _=False, idx=i: self._pick_color(idx))
            self._color_buttons.append(col_btn)
            grid.addWidget(col_btn, i, 1)

            w_spin = QDoubleSpinBox()
            w_spin.setRange(0.0, 10.0)
            w_spin.setSingleStep(0.1)
            w_spin.setValue(1.0)
            self.widths.append(w_spin)
            grid.addWidget(w_spin, i, 2)

            style = QComboBox()
            style.addItems(["solid", "dashed", "dotted", "dashdot"])
            style.setCurrentIndex(1 if i == 0 else 0)
            self.styles.append(style)
            grid.addWidget(style, i, 3)

        all_cb.toggled.connect(self._toggle_all)

        if not is_involute:
            # Base circle row disabled for cycloidal gearing
            self.checks[1].setChecked(False)
            for w in (self.checks[1], self._color_buttons[1], self.widths[1], self.styles[1]):
                w.setEnabled(False)

        btns = QDialogButtonBox(QDialogButtonBox.Close)
        btns.rejected.connect(self.reject)
        btns.accepted.connect(self.accept)
        outer.addWidget(btns)

    def _toggle_all(self, state: bool) -> None:
        for i, cb in enumerate(self.checks):
            if cb.isEnabled():
                cb.setChecked(state)

    def _pick_color(self, idx: int) -> None:
        c = QColorDialog.getColor(self.colors[idx], self, "Select color")
        if c.isValid():
            self.colors[idx] = c
            self._color_buttons[idx].setStyleSheet(f"background-color: {c.name()}")

    def checkers(self) -> List[bool]:
        return [cb.isChecked() for cb in self.checks]

    def color_tuples(self) -> List[tuple]:
        return [(c.redF(), c.greenF(), c.blueF()) for c in self.colors]

    def width_values(self) -> List[float]:
        return [w.value() for w in self.widths]

    def style_indices(self) -> List[int]:
        return [s.currentIndex() + 1 for s in self.styles]


class ProfileTab(QWidget):
    """Port of the MATLAB Profile tab."""

    def __init__(self, parent_window, output_window) -> None:
        super().__init__()
        self.window_ref = parent_window
        self.output_window = output_window

        # State (mirrors profileTabManagerUtils)
        self.profile_plots: List = []
        self.circle_plots: List = []
        self.lock_checker = False
        self.current_generator = None

        # Circles dialog state
        self.circles_checkers: List[bool] = [False, False, False, False, False]
        self.circles_colors: List[tuple] = [(0, 0, 0)] * 4
        self.circles_widths: List[float] = [1.0, 1.0, 1.0, 1.0]
        self.circles_styles: List[int] = [2, 1, 2, 2]

        self.plot_color: Optional[QColor] = None  # None -> random

        self._build_ui()

    # ----------------------------------------------------------------
    def _build_ui(self) -> None:
        scroll = QScrollArea(self)
        scroll.setWidgetResizable(True)
        inner = QWidget()
        scroll.setWidget(inner)
        outer = QVBoxLayout(self)
        outer.addWidget(scroll)
        layout = QVBoxLayout(inner)

        # Description text
        self.desc_label = QLabel("")
        self.desc_label.setWordWrap(True)
        layout.addWidget(self.desc_label)

        # --- Display Settings Panel ---
        self.display_group = QGroupBox()
        d_layout = QVBoxLayout(self.display_group)

        # Generation mode
        mode_row = QHBoxLayout()
        self.gen_mode_label = QLabel()
        self.single_rb = QRadioButton()
        self.single_rb.setChecked(True)
        self.param_rb = QRadioButton()
        self.count_label = QLabel()
        self.count_spin = QSpinBox(); self.count_spin.setRange(2, 1000); self.count_spin.setValue(10); self.count_spin.setEnabled(False)

        self.mode_group = QButtonGroup(self)
        self.mode_group.addButton(self.single_rb)
        self.mode_group.addButton(self.param_rb)
        self.mode_group.buttonToggled.connect(self._on_mode_changed)

        mode_row.addWidget(self.gen_mode_label)
        mode_row.addWidget(self.single_rb)
        mode_row.addWidget(self.param_rb)
        mode_row.addStretch(1)
        mode_row.addWidget(self.count_label)
        mode_row.addWidget(self.count_spin)
        d_layout.addLayout(mode_row)

        # Lock to origin
        lock_row = QHBoxLayout()
        self.lock_label = QLabel()
        self.lock_btn = QPushButton("\U0001F513")  # open lock unicode
        self.lock_btn.setFixedWidth(40)
        self.lock_btn.clicked.connect(self._toggle_lock)
        lock_row.addWidget(self.lock_label)
        lock_row.addWidget(self.lock_btn)
        lock_row.addStretch(1)
        d_layout.addLayout(lock_row)

        # Plot style
        style_row = QHBoxLayout()
        self.lines_label = QLabel("Lines:")
        self.thick_label = QLabel("Thickness:")
        self.thick_spin = QDoubleSpinBox(); self.thick_spin.setRange(0.05, 20.0); self.thick_spin.setSingleStep(0.05); self.thick_spin.setValue(1.0)
        self.color_label = QLabel("Color:")
        self.color_btn = QPushButton("Random")
        self.color_btn.clicked.connect(self._pick_color)
        self.style_label = QLabel("Style:")
        self.style_combo = QComboBox(); self.style_combo.addItems(["solid", "dashed", "dotted", "dashdot"])

        style_row.addWidget(self.lines_label)
        style_row.addWidget(self.thick_label); style_row.addWidget(self.thick_spin)
        style_row.addWidget(self.color_label); style_row.addWidget(self.color_btn)
        style_row.addWidget(self.style_label); style_row.addWidget(self.style_combo)
        d_layout.addLayout(style_row)

        # Graph controls
        graph_row = QHBoxLayout()
        self.graph_label = QLabel("Graph:")
        self.grid_cb = QCheckBox(); self.grid_cb.setChecked(True); self.grid_cb.toggled.connect(self._on_grid)
        self.axes_cb = QCheckBox(); self.axes_cb.setChecked(True); self.axes_cb.toggled.connect(self._on_axes)
        self.circles_btn = QPushButton()
        self.circles_btn.clicked.connect(self._open_circles_dialog)
        graph_row.addWidget(self.graph_label)
        graph_row.addWidget(self.grid_cb)
        graph_row.addWidget(self.axes_cb)
        graph_row.addWidget(self.circles_btn)
        graph_row.addStretch(1)
        d_layout.addLayout(graph_row)

        layout.addWidget(self.display_group)

        # --- Gear Settings Panel ---
        self.gear_group = QGroupBox()
        g_layout = QVBoxLayout(self.gear_group)

        # Toothing type row
        tt_row = QHBoxLayout()
        self.tt_label = QLabel()
        self.involute_rb = QRadioButton(); self.involute_rb.setChecked(True)
        self.cycloidal_rb = QRadioButton()
        self.tt_group = QButtonGroup(self)
        self.tt_group.addButton(self.involute_rb); self.tt_group.addButton(self.cycloidal_rb)
        self.tt_group.buttonToggled.connect(self._on_toothing_type_changed)
        tt_row.addWidget(self.tt_label)
        tt_row.addWidget(self.involute_rb); tt_row.addWidget(self.cycloidal_rb)
        tt_row.addStretch(1)
        g_layout.addLayout(tt_row)

        # Parameter table
        grid = QGridLayout()
        g_layout.addLayout(grid)

        # Labels
        self.module_label = QLabel()
        self.teeth_label = QLabel()
        self.shift_label = QLabel()
        self.angle_label = QLabel()  # also epicycloid radius for cycloidal
        self.hypo_label = QLabel()

        # Parameter choice radio buttons
        self.module_rb = QRadioButton(); self.module_rb.setChecked(True)
        self.teeth_rb = QRadioButton()
        self.shift_rb = QRadioButton()
        self.angle_rb = QRadioButton()
        self.hypo_rb = QRadioButton()

        self.param_group = QButtonGroup(self)
        for rb in (self.module_rb, self.teeth_rb, self.shift_rb, self.angle_rb, self.hypo_rb):
            self.param_group.addButton(rb)

        # Edit fields - From / To
        self.module_from = QDoubleSpinBox(); self.module_from.setRange(0.01, 1e6); self.module_from.setValue(1.0); self.module_from.setDecimals(4)
        self.module_to = QDoubleSpinBox(); self.module_to.setRange(0.01, 1e6); self.module_to.setValue(0.0); self.module_to.setDecimals(4); self.module_to.setEnabled(False)

        self.teeth_from = QSpinBox(); self.teeth_from.setRange(1, 100000); self.teeth_from.setValue(20)
        self.teeth_to = QSpinBox(); self.teeth_to.setRange(1, 100000); self.teeth_to.setValue(0); self.teeth_to.setEnabled(False)

        self.shift_from = QDoubleSpinBox(); self.shift_from.setRange(-1000.0, 1000.0); self.shift_from.setValue(0.0); self.shift_from.setDecimals(4)
        self.shift_to = QDoubleSpinBox(); self.shift_to.setRange(-1000.0, 1000.0); self.shift_to.setValue(0.0); self.shift_to.setDecimals(4); self.shift_to.setEnabled(False)

        self.angle_from = QDoubleSpinBox(); self.angle_from.setRange(0.01, 1e6); self.angle_from.setValue(20.0); self.angle_from.setDecimals(4)
        self.angle_to = QDoubleSpinBox(); self.angle_to.setRange(0.01, 1e6); self.angle_to.setValue(0.0); self.angle_to.setDecimals(4); self.angle_to.setEnabled(False)

        self.hypo_from = QDoubleSpinBox(); self.hypo_from.setRange(0.01, 1e6); self.hypo_from.setValue(10.0); self.hypo_from.setDecimals(4)
        self.hypo_to = QDoubleSpinBox(); self.hypo_to.setRange(0.01, 1e6); self.hypo_to.setValue(0.0); self.hypo_to.setDecimals(4); self.hypo_to.setEnabled(False)

        rows = [
            (self.module_label, self.module_rb, self.module_from, self.module_to),
            (self.teeth_label, self.teeth_rb, self.teeth_from, self.teeth_to),
            (self.shift_label, self.shift_rb, self.shift_from, self.shift_to),
            (self.angle_label, self.angle_rb, self.angle_from, self.angle_to),
            (self.hypo_label, self.hypo_rb, self.hypo_from, self.hypo_to),
        ]
        for i, (lbl, rb, fr, to) in enumerate(rows):
            grid.addWidget(lbl, i, 0)
            grid.addWidget(rb, i, 1)
            grid.addWidget(fr, i, 2)
            grid.addWidget(to, i, 3)

        layout.addWidget(self.gear_group)

        # --- Export panel ---
        self.export_group = QGroupBox()
        e_layout = QVBoxLayout(self.export_group)

        e_row1 = QHBoxLayout()
        self.export_image_rb = QRadioButton(); self.export_image_rb.setChecked(True)
        self.export_coord_rb = QRadioButton()
        self.export_btn_group = QButtonGroup(self)
        self.export_btn_group.addButton(self.export_image_rb)
        self.export_btn_group.addButton(self.export_coord_rb)

        self.graph_type_combo = QComboBox(); self.graph_type_combo.addItems(["Raster", "Vector"])
        self.graph_type_combo.currentIndexChanged.connect(self._on_graph_type_changed)
        self.format_combo = QComboBox(); self.format_combo.addItems(["PNG", "JPEG", "TIFF"])
        self.coord_combo = QComboBox(); self.coord_combo.addItems(["TXT", "CSV", "XLSX (Excel)", "PTS (Creo)"])
        self.order_label = QLabel("Profile:")
        self.order_spin = QSpinBox(); self.order_spin.setRange(0, 0)

        e_row1.addWidget(self.export_image_rb)
        e_row1.addWidget(self.graph_type_combo)
        e_row1.addWidget(self.format_combo)
        e_row1.addWidget(self.export_coord_rb)
        e_row1.addWidget(self.coord_combo)
        e_row1.addWidget(self.order_label)
        e_row1.addWidget(self.order_spin)
        e_layout.addLayout(e_row1)

        e_row2 = QHBoxLayout()
        self.path_edit = QLineEdit()
        self.path_btn = QPushButton("...")
        self.path_btn.setFixedWidth(40)
        self.path_btn.clicked.connect(self._choose_export_path)
        self.export_btn = QPushButton()
        self.export_btn.setEnabled(False)
        self.export_btn.clicked.connect(self._do_export)
        e_row2.addWidget(self.path_edit)
        e_row2.addWidget(self.path_btn)
        e_row2.addWidget(self.export_btn)
        e_layout.addLayout(e_row2)

        layout.addWidget(self.export_group)

        # --- Action buttons ---
        actions = QHBoxLayout()
        self.draw_btn = QPushButton()
        self.draw_btn.clicked.connect(self._draw)
        self.cancel_btn = QPushButton()
        self.cancel_btn.clicked.connect(self._cancel_last)
        self.cancel_all_btn = QPushButton()
        self.cancel_all_btn.clicked.connect(self.cancel_all)
        actions.addWidget(self.draw_btn)
        actions.addWidget(self.cancel_btn)
        actions.addWidget(self.cancel_all_btn)
        layout.addLayout(actions)
        layout.addStretch(1)

        self._apply_initial_visibility()

    # ----------------------------------------------------------------
    def _apply_initial_visibility(self) -> None:
        # Cycloid-only parameters disabled initially
        for w in (self.hypo_label, self.hypo_rb, self.hypo_from, self.hypo_to):
            w.setVisible(False)
        # Only module / angle / shift / teeth visible in single-profile mode
        for w in (self.module_rb, self.teeth_rb, self.shift_rb, self.angle_rb):
            w.setVisible(False)
        for w in (self.module_to, self.teeth_to, self.shift_to, self.angle_to):
            w.setVisible(False)

    # ----------------------------------------------------------------
    # Localisation
    def apply_translations(self, cursor: LineCursor, profile_text: List[str],
                            is_involute: bool, profile_angle_cycloidal: str = "") -> None:
        """Apply the text file to every UI component (mirrors
        profileTabLanguageFun.m)."""
        c = LineCursor(profile_text)
        self.desc_label.setText(c.next("Profile"))

        self.display_group.setTitle(c.next("Display Settings"))
        self.gen_mode_label.setText(c.next("Generation Options:"))
        self.single_rb.setText(c.next("Individual Profile"))
        self.param_rb.setText(c.next("Parametric Sequence"))
        self.count_label.setText(c.next("Count"))
        self.lock_label.setText(c.next("Lock Display to Origin:"))
        self.lines_label.setText(c.next("Lines:"))
        self.thick_label.setText(c.next("Thickness:"))
        self.color_label.setText(c.next("Color:"))
        _ = c.next("")  # random colour context menu item
        _ = c.next("")  # user colour context menu item
        self.style_label.setText(c.next("Style:"))
        style_items_line = c.next("solid,dashed,dotted,dashdot")
        items = [s.strip() for s in style_items_line.split(",")]
        prev_idx = self.style_combo.currentIndex()
        self.style_combo.clear()
        if items:
            self.style_combo.addItems(items)
            if 0 <= prev_idx < len(items):
                self.style_combo.setCurrentIndex(prev_idx)

        self.graph_label.setText(c.next("Graph:"))
        self.grid_cb.setText(c.next("Grid"))
        self.axes_cb.setText(c.next("Axes"))
        self.circles_btn.setText(c.next("Relevant Circles"))

        self.gear_group.setTitle(c.next("Gear Settings"))
        self.tt_label.setText(c.next("Gearing Type:"))
        self.involute_rb.setText(c.next("Involute"))
        self.cycloidal_rb.setText(c.next("Cycloidal"))
        _ = c.next("")  # additional parameters button (not implemented)

        _series1 = c.next("Series 1")
        _series2 = c.next("Series 2")

        self.module_label.setText(c.next("Gear Module"))
        self.teeth_label.setText(c.next("Number of Teeth"))
        self.shift_label.setText(c.next("Unit Shift"))
        self.hypo_label.setText(c.next("Hypocycloid Radius"))

        angle_text_involute = c.next("Profile Angle")
        if is_involute:
            self.angle_label.setText(angle_text_involute)
        else:
            self.angle_label.setText(profile_angle_cycloidal or "Epicycloid radius")

        self.export_group.setTitle(c.next("Exporting"))
        _ = c.next("")  # Options:
        self.export_image_rb.setText(c.next("Image"))
        _ = c.next("")  # Type of graphics label
        graphic_types = c.next("Raster, Vector")
        g_items = [s.strip() for s in graphic_types.split(",")]
        if g_items:
            prev = self.graph_type_combo.currentIndex()
            self.graph_type_combo.clear(); self.graph_type_combo.addItems(g_items)
            if 0 <= prev < len(g_items):
                self.graph_type_combo.setCurrentIndex(prev)
        _ = c.next("")  # Format tooltip
        self.export_coord_rb.setText(c.next("Coordinates"))
        self.order_label.setText(c.next("Profile Order:"))
        _ = c.next("")  # Coord tooltip / placeholder

        _ = c.next("")  # Path label
        self.path_edit.setPlaceholderText(c.next("Enter file name"))
        self.export_btn.setText(c.next("EXPORT"))

        self.draw_btn.setText(c.next("DISPLAY"))
        self.cancel_btn.setText(c.next("DELETE LAST"))
        self.cancel_all_btn.setText(c.next("DELETE ALL"))

    # ----------------------------------------------------------------
    # Callbacks
    def _on_mode_changed(self) -> None:
        if self.single_rb.isChecked():
            self.count_spin.setEnabled(False)
            for w in (self.module_rb, self.teeth_rb, self.shift_rb, self.angle_rb, self.hypo_rb):
                w.setVisible(False)
            for w in (self.module_to, self.teeth_to, self.shift_to, self.angle_to, self.hypo_to):
                w.setVisible(False)
        else:
            self.count_spin.setEnabled(True)
            for w in (self.module_rb, self.teeth_rb, self.shift_rb, self.angle_rb):
                w.setVisible(True)
            if self.cycloidal_rb.isChecked():
                self.hypo_rb.setVisible(True)
            self._update_to_fields()

    def _update_to_fields(self) -> None:
        pairs = [
            (self.module_rb, self.module_to),
            (self.teeth_rb, self.teeth_to),
            (self.shift_rb, self.shift_to),
            (self.angle_rb, self.angle_to),
            (self.hypo_rb, self.hypo_to),
        ]
        for rb, to in pairs:
            rb_checked = rb.isChecked() and self.param_rb.isChecked() and rb.isVisible()
            to.setVisible(rb_checked)
            to.setEnabled(rb_checked)

    def _on_toothing_type_changed(self) -> None:
        is_cyc = self.cycloidal_rb.isChecked()
        for w in (self.hypo_label, self.hypo_from):
            w.setVisible(is_cyc)
        if is_cyc and self.param_rb.isChecked():
            self.hypo_rb.setVisible(True)
        else:
            self.hypo_rb.setVisible(False)
            if self.hypo_rb.isChecked():
                self.module_rb.setChecked(True)

        # Update angle label for cycloidal mode
        if is_cyc:
            self.angle_label.setText(self._profile_angle_label_cyc())
        else:
            self.angle_label.setText(self._profile_angle_label_inv())
        self._update_to_fields()

    def _profile_angle_label_inv(self) -> str:
        choice = self.window_ref.language_utils.language_choice
        return {"SK": "Uhol profilu", "CZ": "Úhel profilu", "EN": "Profile angle"}.get(choice, "Profile angle")

    def _profile_angle_label_cyc(self) -> str:
        choice = self.window_ref.language_utils.language_choice
        return {
            "SK": "Polomer tvoriacej kružnice epicykloidy",
            "CZ": "Poloměr tvořící kružnice epicykloidy",
            "EN": "Radius of epicycloid generating circle",
        }.get(choice, "Epicycloid radius")

    def _on_grid(self, state: bool) -> None:
        ax = self.output_window.canvas.ax
        if ax.get_visible():
            ax.grid(state)
            self.output_window.canvas.draw_idle()

    def _on_axes(self, state: bool) -> None:
        ax = self.output_window.canvas.ax
        if ax.get_visible():
            ax.axis("on" if state else "off")
            self.output_window.canvas.draw_idle()

    def _toggle_lock(self) -> None:
        self.lock_checker = not self.lock_checker
        self.lock_btn.setText("\U0001F512" if self.lock_checker else "\U0001F513")

    def _pick_color(self) -> None:
        current = self.plot_color or QColor("black")
        c = QColorDialog.getColor(current, self, "Select color")
        if c.isValid():
            self.plot_color = c
            self.color_btn.setText(c.name())
            self.color_btn.setStyleSheet(f"background-color: {c.name()}")

    def _on_graph_type_changed(self, idx: int) -> None:
        self.format_combo.clear()
        if idx == 0:
            self.format_combo.addItems(["PNG", "JPEG", "TIFF"])
        else:
            self.format_combo.addItems(["PDF", "SVG"])

    def _open_circles_dialog(self) -> None:
        texts = self.window_ref.language_utils.profile_tab_circles
        dlg = CirclesDialog(self, texts, self.involute_rb.isChecked())
        # Restore previous state
        for i, cb in enumerate(dlg.checks):
            cb.setChecked(self.circles_checkers[i + 1] if i + 1 < len(self.circles_checkers) else False)
        if dlg.exec() == QDialog.Accepted:
            self.circles_checkers = [any(dlg.checkers())] + dlg.checkers()
            self.circles_colors = dlg.color_tuples()
            self.circles_widths = dlg.width_values()
            self.circles_styles = dlg.style_indices()
            # Redraw existing profiles' circles
            self._redraw_circles()

    def _redraw_circles(self) -> None:
        for plot in self.circle_plots:
            for line in plot:
                try:
                    line.remove()
                except Exception:
                    pass
        self.circle_plots = []
        ax = self.output_window.canvas.ax
        for gen in self._stored_generators:
            self._draw_circles_for(gen, ax)
        self.output_window.canvas.draw_idle()

    @property
    def _stored_generators(self) -> List:
        return [pm["generator"] for pm in self.profile_plots]

    # ----------------------------------------------------------------
    def _current_params(self) -> dict:
        return dict(
            m=self.module_from.value(),
            z=self.teeth_from.value(),
            x=self.shift_from.value(),
            alpha=self.angle_from.value(),
            rho_h=self.hypo_from.value(),
        )

    def _make_generator(self, m: float, z: int, x: float, alpha_or_epi: float, rho_h: float):
        if self.involute_rb.isChecked():
            return InvoluteToothing(m, alpha_or_epi, z, x)
        return CycloidToothing(m, alpha_or_epi, rho_h, z, x)

    def _draw(self) -> None:
        params = self._current_params()
        try:
            if self.single_rb.isChecked():
                gen = self._make_generator(params["m"], params["z"], params["x"], params["alpha"], params["rho_h"])
                self._plot_generator(gen, params["m"], params["z"])
            else:
                n = self.count_spin.value()
                if self.module_rb.isChecked():
                    vals = np.linspace(params["m"], self.module_to.value(), n)
                    for v in vals:
                        gen = self._make_generator(v, params["z"], params["x"], params["alpha"], params["rho_h"])
                        self._plot_generator(gen, v, params["z"])
                elif self.teeth_rb.isChecked():
                    vals = np.round(np.linspace(params["z"], self.teeth_to.value(), n)).astype(int)
                    for v in vals:
                        gen = self._make_generator(params["m"], int(v), params["x"], params["alpha"], params["rho_h"])
                        self._plot_generator(gen, params["m"], int(v))
                elif self.shift_rb.isChecked():
                    vals = np.linspace(params["x"], self.shift_to.value(), n)
                    for v in vals:
                        gen = self._make_generator(params["m"], params["z"], float(v), params["alpha"], params["rho_h"])
                        self._plot_generator(gen, params["m"], params["z"])
                elif self.angle_rb.isChecked():
                    vals = np.linspace(params["alpha"], self.angle_to.value(), n)
                    for v in vals:
                        gen = self._make_generator(params["m"], params["z"], params["x"], float(v), params["rho_h"])
                        self._plot_generator(gen, params["m"], params["z"])
                elif self.hypo_rb.isChecked() and self.cycloidal_rb.isChecked():
                    vals = np.linspace(params["rho_h"], self.hypo_to.value(), n)
                    for v in vals:
                        gen = CycloidToothing(params["m"], params["alpha"], float(v), params["z"], params["x"])
                        self._plot_generator(gen, params["m"], params["z"])
        except Exception as exc:  # noqa: BLE001
            QMessageBox.warning(self, "Error", f"Could not generate profile:\n{exc}")

    def _plot_generator(self, gen, m: float, z: int) -> None:
        if gen.tooth is None:
            QMessageBox.warning(self, "Warning", "Profile could not be built with current parameters.")
            return

        ax = self.output_window.canvas.ax
        first = len(self.profile_plots) == 0
        if first:
            ax.clear()
            ax.set_aspect("equal")
            ax.set_visible(True)
            self.output_window.hide_standby()
            ax.grid(self.grid_cb.isChecked())
            ax.axis("on" if self.axes_cb.isChecked() else "off")

        self.current_generator = gen

        x_data = np.array(gen.tooth[0, :], dtype=float)
        y_data = np.array(gen.tooth[1, :], dtype=float)
        if self.lock_checker:
            y_data = y_data - m * z / 2.0

        if self.plot_color is not None:
            color = self.plot_color.name()
        else:
            color = (random.random(), random.random(), random.random())

        line, = ax.plot(
            x_data, y_data,
            color=color,
            linewidth=self.thick_spin.value(),
            linestyle=profile_line_style(self.style_combo.currentIndex() + 1),
        )

        circles = self._draw_circles_for(gen, ax, y_offset=-m * z / 2.0 if self.lock_checker else 0.0)

        self.profile_plots.append({"generator": gen, "line": line, "m": m, "z": z})
        self.circle_plots.append(circles)

        self.order_spin.setRange(1, len(self.profile_plots))
        self.order_spin.setValue(len(self.profile_plots))
        self.export_btn.setEnabled(True)

        ax.relim(); ax.autoscale_view()
        self.output_window.canvas.draw_idle()

    def _draw_circles_for(self, gen, ax, y_offset: float = 0.0) -> List:
        out = []
        if not any(self.circles_checkers[1:]):
            return out
        t = np.linspace(-math.pi / gen.z, math.pi / gen.z, 200)
        radii = [gen.R, gen.R_b, gen.R_a, gen.R_f]
        for i, R in enumerate(radii):
            if not self.circles_checkers[i + 1]:
                out.append(None); continue
            if R is None or (isinstance(R, float) and math.isnan(R)):
                out.append(None); continue
            color = self.circles_colors[i]
            width = self.circles_widths[i]
            style = profile_line_style(self.circles_styles[i])
            xs = R * np.sin(t)
            ys = R * np.cos(t) + y_offset
            line, = ax.plot(xs, ys, color=color, linewidth=width, linestyle=style)
            out.append(line)
        return out

    def _cancel_last(self) -> None:
        if not self.profile_plots:
            return
        info = self.profile_plots.pop()
        try:
            info["line"].remove()
        except Exception:
            pass
        if self.circle_plots:
            circles = self.circle_plots.pop()
            for line in circles:
                if line is not None:
                    try:
                        line.remove()
                    except Exception:
                        pass
        if not self.profile_plots:
            ax = self.output_window.canvas.ax
            ax.set_visible(False)
            ax.clear()
            self.output_window.show_standby(True)
            self.export_btn.setEnabled(False)
            self.order_spin.setRange(0, 0)
        else:
            self.order_spin.setRange(1, len(self.profile_plots))
            self.order_spin.setValue(len(self.profile_plots))
        self.output_window.canvas.draw_idle()

    def cancel_all(self) -> None:
        ax = self.output_window.canvas.ax
        ax.clear()
        ax.set_visible(False)
        self.profile_plots.clear()
        self.circle_plots.clear()
        self.export_btn.setEnabled(False)
        self.order_spin.setRange(0, 0)
        self.output_window.show_standby(True)
        self.output_window.canvas.draw_idle()

    # ----------------------------------------------------------------
    def _choose_export_path(self) -> None:
        if self.export_image_rb.isChecked():
            idx = self.format_combo.currentIndex()
            raster = self.graph_type_combo.currentIndex() == 0
            if raster:
                exts = ["*.png", "*.jpg", "*.tif"]
            else:
                exts = ["*.pdf", "*.svg"]
            ext = exts[idx] if idx < len(exts) else "*.png"
        else:
            exts = ["*.txt", "*.csv", "*.xlsx", "*.pts"]
            ext = exts[self.coord_combo.currentIndex()]
        fname, _ = QFileDialog.getSaveFileName(self, "Save", self.path_edit.text(), f"File ({ext})")
        if fname:
            self.path_edit.setText(fname)

    def _do_export(self) -> None:
        path = self.path_edit.text().strip()
        if not path:
            QMessageBox.warning(self, "Warning", "No file path was specified.")
            return
        if self.export_image_rb.isChecked():
            try:
                self.output_window.canvas.figure.savefig(path, dpi=300)
            except Exception as exc:  # noqa: BLE001
                QMessageBox.warning(self, "Error", str(exc))
        else:
            idx = self.order_spin.value() - 1
            if idx < 0 or idx >= len(self.profile_plots):
                QMessageBox.warning(self, "Warning", "No profile selected."); return
            line = self.profile_plots[idx]["line"]
            xs = line.get_xdata(); ys = line.get_ydata()
            fmt = self.coord_combo.currentIndex()
            try:
                if fmt == 3:  # PTS
                    with open(path, "w", encoding="utf-8") as fh:
                        for x, y in zip(xs, ys):
                            fh.write(f"{x:.8f} {y:.8f} 0\n")
                elif fmt == 2:  # XLSX
                    try:
                        import openpyxl  # type: ignore
                        wb = openpyxl.Workbook()
                        ws = wb.active
                        ws.append(["XData", "YData"])
                        for x, y in zip(xs, ys):
                            ws.append([float(x), float(y)])
                        wb.save(path)
                    except ImportError:
                        np.savetxt(path, np.column_stack([xs, ys]), delimiter=",", header="XData,YData", comments="")
                else:
                    sep = "," if fmt == 1 else "\t"
                    np.savetxt(path, np.column_stack([xs, ys]), delimiter=sep, header=f"XData{sep}YData", comments="")
            except Exception as exc:  # noqa: BLE001
                QMessageBox.warning(self, "Error", str(exc))
