% Copyright (c) 2026 Richard Timko
function animationTabLanguageFun(app, text_file)
    % animationTabLanguageFun — Assign text from the animation-tab language
    % file to every label, spinner, dropdown, checkbox, and button on that tab.

    % Sequential counter returning the next line index on each call
    c = 0;
    function current_number = seq
        c = c + 1;
        current_number = c;
    end

    % Preserve dropdown selections across language changes
    prevModeIdx = app.AnimationTabUtils.Mode.ValueIndex;
    prevStyleLineIdx = app.AnimationTabUtils.StyleLine.ValueIndex;
    prevExportDd1Idx = app.AnimationExport.ExportDropdown(1).ValueIndex;

    % Animation tab title
    app.AnimationTab.Title = text_file{seq};

    % Descriptive text and mode selector
    app.AnimationTabUtils.TabLabel.Text  = text_file{seq};
    app.AnimationTabUtils.ModeLabel.Text = text_file{seq};
    itemsCellArray = strtrim(split(text_file{seq}, ','));
    app.AnimationTabUtils.Mode.Items = itemsCellArray;
    if prevModeIdx >= 1 && prevModeIdx <= numel(itemsCellArray)
        app.AnimationTabUtils.Mode.ValueIndex = prevModeIdx;
    end

    % ---- Animation Settings Panel ----
    app.AnimationSettingPanel.Title = text_file{seq};
    for j = 1:7
        app.AnimationTabUtils.AnimationLabels(j).Text = text_file{seq};
        if j == 5
            % Context menu entries for the colour picker
            for k = 1:9
                app.AnimationTabUtils.Menus(k).Text = text_file{seq};
            end
        end
        if j == 6
            % Line-style dropdown items
            itemsCellArray = strtrim(split(text_file{seq}, ','));
            app.AnimationTabUtils.StyleLine.Items = itemsCellArray;
            if prevStyleLineIdx >= 1 && prevStyleLineIdx <= numel(itemsCellArray)
                app.AnimationTabUtils.StyleLine.ValueIndex = prevStyleLineIdx;
            end
        end
    end

    for j = 1:2
        app.AnimationTabUtils.Checkers(j).Text = text_file{seq};
    end
    app.AnimationTabUtils.CurveDisplay.Text = text_file{seq};

    % ---- Toothing Settings Panel ----
    app.ToothingSettingPanel.Title = text_file{seq};
    app.AnimationTabUtils.ToothingChoiceLabel.Text   = text_file{seq};
    app.AnimationTabUtils.ToothingChoices(1).Text    = text_file{seq};
    app.AnimationTabUtils.ToothingChoices(2).Text    = text_file{seq};
    app.AnimationTabUtils.FurtherParametersButton.Text = text_file{seq};

    for j = 1:numel(app.AnimationTabUtils.ToothingLabels1)
        app.AnimationTabUtils.ToothingLabels1(j).Text = text_file{seq};
        if j == 3
            app.AnimationTabUtils.ToothingLabels1(j).Tooltip = text_file{seq};
        end
    end

    % Tooltip for cycloidal-only parameters
    if app.AnimationTabUtils.ToothingChoices(1).Value == 1
        app.AnimationTabUtils.ToothingLabels1(7).Tooltip = '';
    else
        app.AnimationTabUtils.ToothingLabels1(7).Tooltip = text_file{seq};
        app.AnimationTabUtils.ToothingSymbolLabels1(5).Tooltip = text_file{seq};
        app.AnimationTabUtils.ToothingSymbolLabels1(6).Tooltip = text_file{seq};
    end

    for j = 1:numel(app.AnimationTabUtils.ToothingLabels2)
        app.AnimationTabUtils.ToothingLabels2(j).Text = text_file{seq};
    end

    % ---- Export Settings Panel ----
    app.ExportSettingPanel.Title = text_file{seq};

    app.AnimationExport.ExportLabels(1).Text       = text_file{seq};
    app.AnimationExport.ExportRadioButton(3).Text  = text_file{seq};
    app.AnimationExport.ExportLabels(2).Text       = text_file{seq};

    itemsCellArray = strtrim(split(text_file{seq}, ','));
    app.AnimationExport.ExportDropdown(1).Items      = itemsCellArray;
    if prevExportDd1Idx >= 1 && prevExportDd1Idx <= numel(itemsCellArray)
        app.AnimationExport.ExportDropdown(1).ValueIndex = prevExportDd1Idx;
    else
        app.AnimationExport.ExportDropdown(1).ValueIndex = 1;
    end

    formatTooltip = text_file{seq};
    app.AnimationExport.ExportDropdown(2).Tooltip    = formatTooltip;
    app.AnimationExport.ExportRadioButton(2).Text    = text_file{seq};
    app.AnimationExport.InfoImage.Tooltip             = sprintf(text_file{seq});
    app.AnimationExport.ExportLabels(3).Text          = text_file{seq};
    app.AnimationExport.ExportDropdown(3).Tooltip     = formatTooltip;

    app.AnimationExport.ExportRadioButton(1).Text    = text_file{seq};
    app.AnimationExport.ExportLabels(4).Text         = text_file{seq};
    app.AnimationExport.ExportDropdown(4).Tooltip    = formatTooltip;

    app.AnimationExport.PathEditFieldLabel.Text      = text_file{seq};
    app.AnimationExport.PathEditField.Placeholder    = text_file{seq};
    app.AnimationExport.ExportButton.Text            = text_file{seq};

    % ---- Animation control buttons ----
    app.DisplayButton.Text = text_file{seq};

    % Play/Pause labels are comma-separated on one line
    playPauseLine = text_file{seq};
    itemsCellArray = strtrim(split(playPauseLine, ','));
    if app.AnimationControl.start_state == 0
        app.StartPauseButton.Text = itemsCellArray{1};
    else
        app.StartPauseButton.Text = itemsCellArray{2};
    end

    app.CancelButton.Text = text_file{seq};
end
