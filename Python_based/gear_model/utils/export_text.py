"""Localised strings for the export-related context menus / dialogs.

Ports +Utils/getExportContextMenuText.m, getNoPathWarning.m,
getSaveDialogTitle.m.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass
class ExportContextMenuText:
    resolution: str
    background: str
    color_space: str
    bg_current: str
    bg_none: str
    cs_color: str
    cs_bw: str


def get_export_context_menu_text(lang: str) -> ExportContextMenuText:
    if lang == "SK":
        return ExportContextMenuText(
            "Rozlíšenie", "Farba pozadia", "Typ farebného priestoru",
            "Aktuálna", "Žiadna", "Farebný", "Čiernobiely",
        )
    if lang == "CZ":
        return ExportContextMenuText(
            "Rozlišení", "Barva pozadí", "Typ barevného prostoru",
            "Aktuální", "Žádná", "Barevný", "Černobílý",
        )
    return ExportContextMenuText(
        "Resolution", "Background color", "Color space type",
        "Current", "None", "Colorful", "Black-and-white",
    )


def get_no_path_warning(lang: str) -> tuple[str, str]:
    if lang == "SK":
        return ("Nebola zadaná cesta súboru.", "Varovanie")
    if lang == "CZ":
        return ("Nebyla zadaná cesta souboru.", "Varování")
    return ("No file path was specified.", "Warning")


def get_save_dialog_title(lang: str) -> str:
    return {
        "SK": "Uloženie názvu súboru",
        "CZ": "Uložení názvu souboru",
        "EN": "Save file name",
    }.get(lang, "Save file name")
