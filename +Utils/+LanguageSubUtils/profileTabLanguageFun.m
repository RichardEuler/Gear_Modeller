% Copyright (c) 2026 Richard Timko
function profileTabLanguageFun(app, text_file)
    % profileTabLanguageFun — Assign text from the profile-tab language file
    % to every label, button, checkbox, dropdown, and export control on that tab.

    % Sequential counter returning the next line index on each call
    c = 0;
    function current_number = seq
        c = c + 1;
        current_number = c;
    end

    % Preserve the user's current dropdown selection across language changes
    prevLineStyleIdx = app.LineStyleDropDown.ValueIndex;
    prevExportDropdown1Idx = app.ExportUtils.ExportDropdown(1).ValueIndex;

    % Descriptive text at the top of the profile tab
    app.ProfileText.Text = text_file{seq};

    % ---- Display Settings Panel ----
    app.DisplaySettingsPanel.Title = text_file{seq};

    app.GenerationOptionsLabel.Text          = text_file{seq};
    app.SingleProfileButton.Text             = text_file{seq};
    app.ParametricProfileSequenceButton.Text = text_file{seq};
    app.NumberOfProfilesSpinnerLabel.Text    = text_file{seq};

    app.LockToOriginLabel.Text = text_file{seq};

    app.LinesLabel.Text             = text_file{seq};
    app.ThicknessSpinnerLabel.Text  = text_file{seq};
    app.ColorPickerLabel.Text       = text_file{seq};
    app.ContextMenuPlotColourUtils.Menu1.Text = text_file{seq};  % Random colour
    app.ContextMenuPlotColourUtils.Menu2.Text = text_file{seq};  % User colour
    app.LineStyleDropDownLabel.Text = text_file{seq};

    % Line-style dropdown items (comma-separated in one line)
    itemsCellArray = strtrim(split(text_file{seq}, ','));
    app.LineStyleDropDown.Items      = itemsCellArray;
    if prevLineStyleIdx >= 1 && prevLineStyleIdx <= numel(itemsCellArray)
        app.LineStyleDropDown.ValueIndex = prevLineStyleIdx;
    else
        app.LineStyleDropDown.ValueIndex = 1;
    end

    app.GraphLabel.Text              = text_file{seq};
    app.GridCheckBox.Text            = text_file{seq};
    app.AxesCheckBox.Text            = text_file{seq};
    app.RelevantCirclesButton.Text   = text_file{seq};

    % ---- Gear Settings Panel ----
    app.GearSettingsPanel.Title  = text_file{seq};

    app.ToothingTypeLabel.Text               = text_file{seq};
    app.InvoluteButton.Text                  = text_file{seq};
    app.CycloidalButton.Text                 = text_file{seq};
    app.AdditionalParametersButton.Text      = text_file{seq};

    % Module context menu series labels
    seriesText1 = text_file{seq};
    app.ContextMenuModuleUtils.First.SeriesMenu1.Text  = seriesText1;
    app.ContextMenuModuleUtils.Second.SeriesMenu1.Text = seriesText1;
    seriesText2 = text_file{seq};
    app.ContextMenuModuleUtils.First.SeriesMenu2.Text  = seriesText2;
    app.ContextMenuModuleUtils.Second.SeriesMenu2.Text = seriesText2;

    app.ModuleLabel.Text                       = text_file{seq};
    app.NumberOfTeethLabel.Text                = text_file{seq};
    app.ProfileShiftCoefficientLabel.Text      = text_file{seq};
    app.HypocycloidRadiusLabel.Text            = text_file{seq};

    % Profile angle label changes depending on the toothing type.
    % We still consume this line from the text file to keep `seq` aligned
    % with the file, but ignore its value: the involute caption lives here
    % while the cycloidal caption comes from the hardcoded helper below.
    profileAngleTextInvolute = text_file{seq};
    if app.CycloidalButton.Value == 1
        app.ProfileAngleLabel.Text = getProfileAngleLabelTextLocal(app.LanguageUtils.LanguageChoice, false);
        app.ProfileAngleSymbolicLabel.Text = '$\rho_e  \: \mathrm{[mm]}$';
    else
        app.ProfileAngleLabel.Text = profileAngleTextInvolute;
        app.ProfileAngleSymbolicLabel.Text = '$\alpha \: \mathrm{[^\circ]}$';
    end

    % ---- Export Panel ----
    app.ExportPanel.Title = text_file{seq};

    app.ExportUtils.ExportLabels(1).Text       = text_file{seq};
    app.ExportUtils.ExportRadioButton(2).Text  = text_file{seq};
    app.ExportUtils.ExportLabels(2).Text       = text_file{seq};

    itemsCellArray = strtrim(split(text_file{seq}, ','));
    app.ExportUtils.ExportDropdown(1).Items      = itemsCellArray;
    if prevExportDropdown1Idx >= 1 && prevExportDropdown1Idx <= numel(itemsCellArray)
        app.ExportUtils.ExportDropdown(1).ValueIndex = prevExportDropdown1Idx;
    else
        app.ExportUtils.ExportDropdown(1).ValueIndex = 1;
    end

    formatTooltip = text_file{seq};
    app.ExportUtils.ExportDropdown(2).Tooltip    = formatTooltip;
    app.ExportUtils.ExportRadioButton(1).Text    = text_file{seq};
    app.ExportUtils.ExportLabels(3).Text         = text_file{seq};
    app.ExportUtils.ExportDropdown(3).Tooltip    = formatTooltip;

    app.ExportUtils.PathEditFieldLabel.Text      = text_file{seq};
    app.ExportUtils.PathEditField.Placeholder    = text_file{seq};
    app.ExportUtils.ExportButton.Text            = text_file{seq};

    % ---- Action Buttons ----
    app.DrawProfileButton.Text       = text_file{seq};
    app.CancelProfileButton.Text     = text_file{seq};
    app.CancelAllProfilesButton.Text = text_file{seq};
end

function txt = getProfileAngleLabelTextLocal(lang, isInvolute)
    % Local mirror of the helper in profileTabManagerUtils so that this
    % file does not have to reach into the other class's file-local scope.
    if isInvolute
        switch lang
            case "SK", txt = "Uhol profilu";
            case "CZ", txt = "Úhel profilu";
            case "EN", txt = "Profile angle";
        end
    else
        switch lang
            case "SK", txt = "Polomer tvoriacej kružnice epicykloidy";
            case "CZ", txt = "Poloměr tvořící kružnice epicykloidy";
            case "EN", txt = "Radius of epicycloid generating circle";
        end
    end
end
