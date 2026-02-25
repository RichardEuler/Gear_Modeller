% Copyright (c) 2026 Richard Timko
function profileTabLanguageFun(app, text_file)
    % Function language manager for home tab

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

    app.ProfileText.Text = text_file{seq};

    % Panel 1
    app.NastaveniezobrazeniaPanel.Title = text_file{seq};

    app.MonostigenerovaniaLabel.Text = text_file{seq};
    app.JednotlivprofilButton.Text = text_file{seq};
    app.ParametricksekvenciaprofilovButton.Text = text_file{seq};
    app.NumberOfProfilesSpinnerLabel.Text = text_file{seq};

    app.UzamknutiezobrazeniadopoiatkuLabel.Text = text_file{seq};

    app.iaryLabel.Text = text_file{seq};
    app.HrbkaSpinnerLabel.Text = text_file{seq};
    app.FarbaColorPickerLabel.Text = text_file{seq};
    app.ContextMenuPlotColourUtils.Menu1.Text = text_file{seq}; % 11
    app.ContextMenuPlotColourUtils.Menu2.Text = text_file{seq}; % 12
    app.tlDropDownLabel.Text = text_file{seq};

    itemsCellArray = split(text_file{seq}, ',');
    itemsCellArray = strtrim(itemsCellArray);
    app.tlDropDown.Items = itemsCellArray;
    app.tlDropDown.ValueIndex = 1;

    app.GrafLabel.Text = text_file{seq};
    app.MriekaCheckBox.Text = text_file{seq};
    app.OsiCheckBox.Text = text_file{seq};
    app.VznamnkruniceButton.Text = text_file{seq};

    % Panel 2
    app.NastavenieozubeniaPanel.Title = text_file{seq};

    app.TypozubeniaLabel.Text = text_file{seq};
    app.EvolventnButton.Text = text_file{seq};
    app.CykloidnButton.Text = text_file{seq};
    app.DodatoneParametreButton.Text = text_file{seq};

    app.ContextMenuModuleUtils1.SeriesMenu1.Text = text_file{seq};
    app.ContextMenuModuleUtils2.SeriesMenu1.Text = app.ContextMenuModuleUtils1.SeriesMenu1.Text;
    app.ContextMenuModuleUtils1.SeriesMenu2.Text = text_file{seq};
    app.ContextMenuModuleUtils2.SeriesMenu2.Text = app.ContextMenuModuleUtils1.SeriesMenu2.Text;

    app.ModuleLabel.Text = text_file{seq};
    app.NumberOfTeethLabel.Text = text_file{seq};
    app.ProfileShiftCoefficientLabel.Text = text_file{seq};
    app.Option2Label.Text = text_file{seq};

    if app.EvolventnButton.Value == 1
        str_language = ["Uhol profilu"; "Úhel profilu"; "Profile angle"];

        switch app.LanguageUtils.LanguageChoice
            case "SK"
                app.Option1Label.Text = str_language(1);
            case "CZ"
                app.Option1Label.Text = str_language(2);
            case "EN"
                app.Option1Label.Text = str_language(3);
        end

        app.Option1SymbolicLabel.Text = "$\alpha \: \mathrm{[^\circ]}$";

    elseif app.CykloidnButton.Value == 1

        str_language = ["Polomer tvoriacej kružnice epicykloidy"; ...
            "Poloměr tvořící kružnice epicykloidy"; ...
            "Radius of epicycloid generating circle"];

        switch app.LanguageUtils.LanguageChoice
            case "SK"
                app.Option1Label.Text = str_language(1);
            case "CZ"
                app.Option1Label.Text = str_language(2);
            case "EN"
                app.Option1Label.Text = str_language(3);
        end
    end

    % Panel 3
    app.ExportPanel.Title = text_file{seq};

    app.ExportUtils.ExportLabels(1).Text = text_file{seq};
    app.ExportUtils.ExportRadioButton(2).Text = text_file{seq};
    app.ExportUtils.ExportLabels(2).Text = text_file{seq};

    itemsCellArray = split(text_file{seq}, ',');
    itemsCellArray = strtrim(itemsCellArray);
    app.ExportUtils.ExportDropdown(1).Items = itemsCellArray;
    app.ExportUtils.ExportDropdown(1).ValueIndex = 1;

    app.ExportUtils.ExportDropdown(2).Tooltip = text_file{seq};
    app.ExportUtils.ExportRadioButton(1).Text = text_file{seq};
    app.ExportUtils.ExportLabels(3).Text = text_file{seq};
    app.ExportUtils.ExportDropdown(3).Tooltip = app.ExportUtils.ExportDropdown(2).Tooltip;

    app.ExportUtils.PathEditFieldLabel.Text = text_file{seq};
    app.ExportUtils.PathEditField.Placeholder = text_file{seq};
    app.ExportUtils.ExportButton.Text = text_file{seq};

    % Tlačidlá
    app.DrawProfileButton.Text = text_file{seq};
    app.CancelProfileButton.Text = text_file{seq};
    app.CancelAllProfilesButton.Text = text_file{seq};
end