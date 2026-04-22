function txt = getNoPathWarning(lang)
    % getNoPathWarning — Return the localised "no file path" warning text.
    switch lang
        case "SK"
            txt.msg   = "Nebola zadaná cesta súboru.";
            txt.title = "Varovanie";
        case "CZ"
            txt.msg   = "Nebyla zadaná cesta souboru.";
            txt.title = "Varování";
        case "EN"
            txt.msg   = "No file path was specified.";
            txt.title = "Warning";
    end
end
