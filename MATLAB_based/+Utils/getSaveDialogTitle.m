function title = getSaveDialogTitle(lang)
    % getSaveDialogTitle — Return the localised save-file dialog title.
    switch lang
        case "SK", title = "Uloženie názvu súboru";
        case "CZ", title = "Uložení názvu souboru";
        case "EN", title = "Save file name";
    end
end
