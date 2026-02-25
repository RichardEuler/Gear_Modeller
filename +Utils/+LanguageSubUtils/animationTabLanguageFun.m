% Copyright (c) 2026 Richard Timko
function animationTabLanguageFun(app, text_file)
    % Function language manager for animation tab

    % Counter function
    function current_number = seq
        persistent c; % Declare 'counter' as persistent
        if isempty(c)
            c = 0; % Initialize counter if it's the first call
        end
        c = c + 1; % Increment the counter
        current_number = c; %  Output the current number
        if c >= numel(text_file)
            c = 0; % Reset the counter when the maximum number of lines has been reached
        end
    end

    app.AnimationTab.Title  = text_file{seq};

    % Empty space area in the upper space of the tab
    app.AnimationTabUtils.TabLabel.Text = text_file{seq};
    app.AnimationTabUtils.ModeLabel.Text = text_file{seq};
    itemsCellArray = split(text_file{seq}, ',');
    itemsCellArray = strtrim(itemsCellArray);
    app.AnimationTabUtils.Mode.Items = itemsCellArray;


    % Panel 1
    app.AnimationSettingPanel.Title = text_file{seq};
    for j = 1:7
        app.AnimationTabUtils.AnimationLabels(j).Text = text_file{seq};
        if j == 5
            for k = 1:9
                app.AnimationTabUtils.Menus(k).Text = text_file{seq};
            end
        end
        if j == 6
            itemsCellArray = split(text_file{seq}, ',');
            itemsCellArray = strtrim(itemsCellArray);
            app.AnimationTabUtils.StyleLine.Items = itemsCellArray;
        end
    end
    
    for j = 1:2
        app.AnimationTabUtils.Checkers(j).Text = text_file{seq};
    end

    app.AnimationTabUtils.CurveDisplay.Text = text_file{seq};


    % Panel 2
    app.ToothingSettingPanel.Title = text_file{seq};
    app.AnimationTabUtils.ToothingChoiceLabel.Text = text_file{seq};
    app.AnimationTabUtils.ToothingChoices(1).Text = text_file{seq};
    app.AnimationTabUtils.ToothingChoices(2).Text = text_file{seq};
    app.AnimationTabUtils.FurtherParametersButton.Text = text_file{seq};

    for j = 1:length(app.AnimationTabUtils.ToothingLabels1)
        app.AnimationTabUtils.ToothingLabels1(j).Text = text_file{seq};
        if j == 3
            app.AnimationTabUtils.ToothingLabels1(j).Tooltip = text_file{seq};
        end
    end

    if app.AnimationTabUtils.ToothingChoices(1).Value == 1
        app.AnimationTabUtils.ToothingLabels1(7).Tooltip = "";
    else
        app.AnimationTabUtils.ToothingLabels1(7).Tooltip = text_file{seq};
        app.AnimationTabUtils.ToothingSymbolLabels1(5).Tooltip = text_file{seq};
        app.AnimationTabUtils.ToothingSymbolLabels1(6).Tooltip = text_file{seq};
    end

    for j = 1:length(app.AnimationTabUtils.ToothingLabels2)
        app.AnimationTabUtils.ToothingLabels2(j).Text = text_file{seq};
    end


    % Panel 3
    app.ExportSettingPanel.Title = text_file{seq};

    app.AnimationExport.ExportLabels(1).Text = text_file{seq};
    app.AnimationExport.ExportRadioButton(3).Text = text_file{seq};
    app.AnimationExport.ExportLabels(2).Text = text_file{seq};

    itemsCellArray = split(text_file{seq}, ',');
    itemsCellArray = strtrim(itemsCellArray);
    app.AnimationExport.ExportDropdown(1).Items = itemsCellArray;
    app.AnimationExport.ExportDropdown(1).ValueIndex = 1;

    app.AnimationExport.ExportDropdown(2).Tooltip = text_file{seq};
    app.AnimationExport.ExportRadioButton(2).Text = text_file{seq};
    app.AnimationExport.InfoImage.Tooltip = sprintf(text_file{seq});
    app.AnimationExport.ExportLabels(3).Text = text_file{seq};
    app.AnimationExport.ExportDropdown(3).Tooltip = app.AnimationExport.ExportDropdown(2).Tooltip;

    app.AnimationExport.ExportRadioButton(1).Text = text_file{seq};
    app.AnimationExport.ExportLabels(4).Text = text_file{seq};
    app.AnimationExport.ExportDropdown(4).Tooltip = app.AnimationExport.ExportDropdown(3).Tooltip;

    app.AnimationExport.PathEditFieldLabel.Text = text_file{seq};
    app.AnimationExport.PathEditField.Placeholder = text_file{seq};
    app.AnimationExport.ExportButton.Text = text_file{seq};


    % Animation control buttons
    app.DisplayButton.Text = text_file{seq};
    itemsCellArray = split(text_file{seq}, ',');
    itemsCellArray = strtrim(itemsCellArray);
    if app.AnimationControl.start_state == 0
        app.StartPauseButton.Text = itemsCellArray{1};
    else
        app.StartPauseButton.Text = itemsCellArray{2};
    end
    app.CancelButton.Text = text_file{seq};
end