# Gear Model (Python Port)

A standalone Python port of the MATLAB "Gear Modeller" application, which
generates involute and cycloidal gear tooth profiles based on the
rack-cutter hobbing and MAAG shaping manufacturing processes.

This port removes the MATLAB licence dependency entirely.

## Installation

```bash
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m pip install -e .
```

## Running

Any of the following works:

```bash
python -m gear_model
gear-model
python gear_model/main.py
```

## Platform notes

- **Windows / macOS / Linux**: Python 3.10+ with PySide6 is required.
- On Linux, a Qt platform plugin (X11 or Wayland) must be available.

## Features

- Involute and cycloidal tooth profile generation.
- Single profile and parametric sequence modes.
- Relevant circles overlay (pitch, base, addendum, dedendum).
- Multi-language UI (EN / CZ / SK) loaded from text files at runtime.
- Export profiles as PNG / JPEG / PDF / SVG / TXT / CSV / XLSX / PTS.
- Animation tab with gear-meshing and hobbing simulation.

## Tests

```bash
pytest -q
```

## Project layout

```
gear_model/
    main.py                 # Entry point
    __main__.py             # python -m gear_model
    generator/              # Tooth-profile generators
    utils/                  # UI + language helpers
    resources/
        standard_module_series/
        text/
```

MIT License — see `LICENSE`.
