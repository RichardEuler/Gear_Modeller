% Copyright (c) 2026 Richard Timko
classdef profileTabManagerUtils < handle
    % profileTabManagerUtils — Manages the Profile tab state: which
    % parameters are visible, drawing profiles, updating read-out values,
    % and handling the toothing-type switch.

    properties
        LockChecker    (1,1) logical = false   % true when the view is locked to the origin
        ProfileCounter uint16 {mustBeScalarOrEmpty} = 0  % Number of profiles drawn
        ProfilePlot                                      % Array of line handles

        ReadOutLabels                                    % Label handles for the parameters dialog
        ReadOutValues  string                            % Formatted parameter values
    end

    methods
        function obj = profileTabManagerUtils(app)
            obj.ReadOutLabels = gobjects(numel(app.LanguageUtils.TextFileProfileTabParametersEquations), 2);
            obj.ProfilePlot = gobjects(1);

            app.InvoluteButton.Position  = [1 1 85 20];
            app.CycloidalButton.Position = [86 1 85 20];

            app.ToothingTypeButtonGroup.SelectionChangedFcn = @(~,~) gearProfileSwitch(obj, app);

            % Set default hypocycloid radius and its limits
            app.HypocycloidRadiusEditField.From.Value = app.NumberOfTeethEditField.From.Value / 4;
            x0 = app.ProfileShiftCoefficientEditField.From.Value;
            m0 = app.ModuleEditField.From.Value;
            z0 = app.NumberOfTeethEditField.From.Value;
            app.HypocycloidRadiusEditField.From.Limits(1) = (1.25 - x0) * m0 / 2;
            app.HypocycloidRadiusEditField.From.Limits(2) = (m0*z0 - (1.25 - x0)*m0) / 2;
            app.HypocycloidRadiusEditField.To.Limits(2)   = app.HypocycloidRadiusEditField.From.Limits(2);
        end

        function profileSettingFunction(obj, app)
            % Show/hide UI elements depending on the generation mode.
            if app.SingleProfileButton.Value == 1
                app.NumberOfProfilesSpinner.Enable = 0;
                set([app.ModuleButton, app.NumberOfTeethButton, app.ProfileAngleButton, ...
                     app.ProfileShiftCoefficientButton, ...
                     app.ModuleEditField.To, app.ProfileAngleEditField.To, ...
                     app.NumberOfTeethEditField.To, app.ProfileShiftCoefficientEditField.To], ...
                    'Enable', 0, 'Visible', 0);
            else
                app.NumberOfProfilesSpinner.Enable = 1;
                set([app.ModuleButton, app.NumberOfTeethButton, app.ProfileAngleButton, ...
                     app.ProfileShiftCoefficientButton], ...
                    'Enable', 1, 'Visible', 1);
                obj.profileSettingParameterFunction(app);
            end

            if app.CycloidalButton.Value == 1
                if app.SingleProfileButton.Value == 1
                    set([app.HypocycloidRadiusButton, app.HypocycloidRadiusEditField.To], 'Enable', 0, 'Visible', 0);
                else
                    set(app.HypocycloidRadiusButton, 'Enable', 1, 'Visible', 1);
                end
            end
        end

        function profileSettingParameterFunction(obj, app) %#ok<INUSL>
            % Show only the To-field for the currently selected varied parameter.
            allTo = [app.ModuleEditField.To, app.ProfileAngleEditField.To, ...
                     app.NumberOfTeethEditField.To, app.ProfileShiftCoefficientEditField.To, ...
                     app.HypocycloidRadiusEditField.To];
            set(allTo, 'Enable', 0, 'Visible', 0);

            if     app.ModuleButton.Value == 1,                  set(app.ModuleEditField.To, 'Enable', 1, 'Visible', 1);
            elseif app.ProfileAngleButton.Value == 1,            set(app.ProfileAngleEditField.To, 'Enable', 1, 'Visible', 1);
            elseif app.NumberOfTeethButton.Value == 1,           set(app.NumberOfTeethEditField.To, 'Enable', 1, 'Visible', 1);
            elseif app.ProfileShiftCoefficientButton.Value == 1, set(app.ProfileShiftCoefficientEditField.To, 'Enable', 1, 'Visible', 1);
            elseif app.HypocycloidRadiusButton.Value == 1,       set(app.HypocycloidRadiusEditField.To, 'Enable', 1, 'Visible', 1);
            end
        end

        function profileDrawerFunction(obj, app, module, teeth)
            % Draw a single profile on the output axes.

            isFirstProfile = (isempty(obj.ProfileCounter) || obj.ProfileCounter == 0);
            if isFirstProfile
                obj.ProfileCounter = 1;
                app.HomeUtils.FigureText.Visible = 'off';

                if app.AxesCheckBox.Value, axis(app.AxisOutput, 'on'); else, axis(app.AxisOutput, 'off'); end
                if app.GridCheckBox.Value, grid(app.AxisOutput, 'on'); else, grid(app.AxisOutput, 'off'); end

                hold(app.AxisOutput, 'on');
                axis(app.AxisOutput, 'equal');
            else
                obj.ProfileCounter = obj.ProfileCounter + 1;
            end

            obj.ProfilePlot(obj.ProfileCounter) = plot(app.AxisOutput, app.Gen.tooth(1,:), app.Gen.tooth(2,:));
            circlePlot(obj, app);

            % Lock-to-origin shift
            if obj.LockChecker
                yShift = -module * teeth / 2;
                set(obj.ProfilePlot(obj.ProfileCounter), 'YData', ...
                    get(obj.ProfilePlot(obj.ProfileCounter), 'YData') + yShift);
                if any(app.CirclesUtils.Checkers)
                    for j = 1:4
                        if app.CirclesUtils.Checkers(j+1) && ...
                                size(app.CirclesUtils.CirclePlot, 2) >= obj.ProfileCounter && ...
                                isgraphics(app.CirclesUtils.CirclePlot(j, obj.ProfileCounter)) && ...
                                isvalid(app.CirclesUtils.CirclePlot(j, obj.ProfileCounter))
                            set(app.CirclesUtils.CirclePlot(j, obj.ProfileCounter), 'YData', ...
                                get(app.CirclesUtils.CirclePlot(j, obj.ProfileCounter), 'YData') + yShift);
                        end
                    end
                end
            end

            % Apply user-chosen colour, width, and style
            if strcmp(app.ColorPicker.Enable, 'on')
                set(obj.ProfilePlot(obj.ProfileCounter), 'Color', app.ColorPicker.Value);
            end
            set(obj.ProfilePlot(obj.ProfileCounter), ...
                'LineWidth', app.ThicknessSpinner.Value, ...
                'LineStyle', Utils.ProfileTab.profileLineStyleFunction(app.LineStyleDropDown.ValueIndex));

            % Update export spinner
            if obj.ProfileCounter > 0
                app.ExportUtils.ExportButton.Enable  = 1;
                app.ExportUtils.ExportSpinner.Limits  = [1 double(obj.ProfileCounter)];
                app.ExportUtils.ExportSpinner.Value   = double(obj.ProfileCounter);
            end
        end

        function updateReadOutValues(obj, app)
            % Refresh the numeric values shown in the additional-parameters dialog.
            nEq = numel(app.LanguageUtils.TextFileProfileTabParametersEquations);
            obj.ReadOutValues = strings(1, nEq);

            isInvolute = (app.InvoluteButton.Value == 1);
            hasProfile = (obj.ProfileCounter > 0);

            if hasProfile && ~isempty(app.Gen) && ((isInvolute && ~isnan(app.Gen.R_b)) || (~isInvolute && isnan(app.Gen.R_b)))
                obj.ReadOutValues(3) = num2str(app.Gen.h_f, '%.2f');
                obj.ReadOutValues(4) = num2str(app.Gen.h_a, '%.2f');
                obj.ReadOutValues(6) = num2str(2*app.Gen.R, '%.2f');
                if isInvolute
                    obj.ReadOutValues(7) = num2str(2*app.Gen.R_b, '%.2f');
                    obj.ReadOutValues(8) = num2str(2*app.Gen.R_f, '%.2f');
                    obj.ReadOutValues(9) = num2str(2*app.Gen.R_a, '%.2f');
                else
                    obj.ReadOutValues(7) = num2str(2*app.Gen.R_f, '%.2f');
                    obj.ReadOutValues(8) = num2str(2*app.Gen.R_a, '%.2f');
                end
            else
                for k = [3 4 6:nEq]
                    obj.ReadOutValues(k) = '...';
                end
            end

            for i = 1:nEq
                if i <= size(obj.ReadOutLabels, 1) && isvalid(obj.ReadOutLabels(i, 2))
                    str = strrep(app.LanguageUtils.TextFileProfileTabParametersEquations{i}, '???', obj.ReadOutValues(i));
                    obj.ReadOutLabels(i, 2).Text = string(str);
                end
            end
        end

        function circlePlot(obj, app)
            % Draw significant circles for the current profile.
            if any(app.CirclesUtils.Checkers)
                t = linspace(-pi/app.Gen.z, pi/app.Gen.z);
                R = [app.Gen.R  app.Gen.R_b  app.Gen.R_a  app.Gen.R_f];
                for i = 1:4
                    if app.CirclesUtils.Checkers(i+1) == 1 && ~isnan(R(i))
                        ls = Utils.ProfileTab.profileLineStyleFunction(app.CirclesUtils.Style(i));
                        app.CirclesUtils.CirclePlot(i, obj.ProfileCounter) = plot(app.AxisOutput, R(i)*sin(t), R(i)*cos(t));

                        % Determine whether the colour picker is enabled
                        if ~isempty(app.CirclesUtils.F) && isvalid(app.CirclesUtils.F)
                            colourEnabled = app.CirclesUtils.Components(i,2).Enable;
                        else
                            colourEnabled = app.CirclesUtils.ActiveColour(i);
                        end
                        if colourEnabled
                            set(app.CirclesUtils.CirclePlot(i, obj.ProfileCounter), 'Color', app.CirclesUtils.Colours(i,:));
                        end
                        set(app.CirclesUtils.CirclePlot(i, obj.ProfileCounter), 'LineWidth', app.CirclesUtils.Width(i), 'LineStyle', ls);
                    end
                end
            else
                app.CirclesUtils.CirclePlot(:, obj.ProfileCounter) = gobjects(4, 1);
            end
        end

        function gearProfileSwitch(obj, app)
            % Handle toothing-type radio-button changes on the Profile tab.
            if app.InvoluteButton.Value == 1
                if app.HypocycloidRadiusButton.Value == 1 && app.ParametricProfileSequenceButton.Value == 1
                    app.ModuleButton.Value = 1;
                    set(app.ModuleEditField.To, 'Enable', 1, 'Visible', 1);
                end
                set([app.HypocycloidRadiusLabel, app.HypocycloidRadiusSymbolicLabel, ...
                     app.HypocycloidRadiusButton, app.HypocycloidRadiusEditField.From, ...
                     app.HypocycloidRadiusEditField.To], 'Enable', 0, 'Visible', 0);
                app.ProfileAngleLabel.Text = getProfileAngleLabelText(app.LanguageUtils.LanguageChoice, true);
                app.ProfileAngleSymbolicLabel.Text = '$\alpha \: \mathrm{[^\circ]}$';
            else
                set([app.HypocycloidRadiusLabel, app.HypocycloidRadiusSymbolicLabel, ...
                     app.HypocycloidRadiusEditField.From], 'Enable', 1, 'Visible', 1);
                if app.ParametricProfileSequenceButton.Value == 1
                    set(app.HypocycloidRadiusButton, 'Enable', 1, 'Visible', 1);
                end
                app.ProfileAngleLabel.Text = getProfileAngleLabelText(app.LanguageUtils.LanguageChoice, false);
                app.ProfileAngleSymbolicLabel.Text = '$\rho_e  \: \mathrm{[mm]}$';
                app.CirclesUtils.Checkers(3) = 0;
            end

            % Refresh the additional-parameters dialog if open
            if ~isempty(app.FurtherParametersUtils.F) && isgraphics(app.FurtherParametersUtils.F)
                nEq = numel(app.LanguageUtils.TextFileProfileTabParametersEquations);
                for k = [3 4 6:nEq], obj.ReadOutValues(k) = '...'; end
                app.FurtherParametersUtils = updateLabels(app.FurtherParametersUtils, app);
                for i = 1:nEq
                    str = strrep(app.LanguageUtils.TextFileProfileTabParametersEquations{i}, '???', obj.ReadOutValues(i));
                    obj.ReadOutLabels(i, 2).Text = string(str);
                end
                if app.InvoluteButton.Value == 1
                    set(obj.ReadOutLabels(end,:), 'Visible', 1);
                else
                    set(obj.ReadOutLabels(end,:), 'Visible', 0);
                end
            end

            % Enable/disable base-circle row in the circles dialog
            if ~isempty(app.CirclesUtils.F) && isgraphics(app.CirclesUtils.F)
                if app.InvoluteButton.Value == 1
                    set(app.CirclesUtils.Components(2,:), 'Enable', 1);
                else
                    set(app.CirclesUtils.Components(2,1), 'Value', 0);
                    set(app.CirclesUtils.Components(2,:), 'Enable', 0);
                end
            end
        end
    end
end

function txt = getProfileAngleLabelText(lang, isInvolute)
    % Return the correct label for the profile-angle / epicycloid-radius row.
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
            case "EN", txt = "Radius of Epicycloid Generating Circle";
        end
    end
end
