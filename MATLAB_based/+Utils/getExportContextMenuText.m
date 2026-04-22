function txt = getExportContextMenuText(lang)
    % getExportContextMenuText — Return localised text for export context menus.
    % This centralises the hardcoded SK/CZ/EN strings that were duplicated
    % in both exportUtils and animationExport.

    switch lang
        case "SK"
            txt.resolution  = "Rozlíšenie";
            txt.background  = "Farba pozadia";
            txt.colorSpace  = "Typ farebného priestoru";
            txt.bgCurrent   = "Aktuálna";
            txt.bgNone      = "Žiadna";
            txt.csColor     = "Farebný";
            txt.csBW        = "Čiernobiely";
        case "CZ"
            txt.resolution  = "Rozlišení";
            txt.background  = "Barva pozadí";
            txt.colorSpace  = "Typ barevného prostoru";
            txt.bgCurrent   = "Aktuální";
            txt.bgNone      = "Žádná";
            txt.csColor     = "Barevný";
            txt.csBW        = "Černobílý";
        case "EN"
            txt.resolution  = "Resolution";
            txt.background  = "Background color";
            txt.colorSpace  = "Color space type";
            txt.bgCurrent   = "Current";
            txt.bgNone      = "None";
            txt.csColor     = "Colorful";
            txt.csBW        = "Black-and-white";
    end
end
