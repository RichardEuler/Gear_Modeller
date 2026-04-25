classdef Gear_Model < handle
    % ------------------------------------------------------------------------
    % Gear_model — Main application class for the Gear Model tool.
    %
    % This class creates the main UI figure, all tabs (Home, Profile,
    % Animation), wires callbacks, and orchestrates the auxiliary utility
    % objects that manage language, profile generation, animation, and export.
    %
    % Author: Richard Timko
    % Copyright (c) 2026 Richard Timko
    %
    % This file is part of Gear Model and is released under the MIT License.
    % See the LICENSE file in the project root directory for full details.
    % ------------------------------------------------------------------------

    % UI component properties — main window and top-level layout
    properties (Access = public)
        MainUIFigure      matlab.ui.Figure
        MainGridLayout    matlab.ui.container.GridLayout
        MainTabGroup      matlab.ui.container.TabGroup

        % Home tab
        HomeTab           matlab.ui.container.Tab

        % Profile tab — root container and descriptive label
        ProfileTab        matlab.ui.container.Tab
        ProfileGridLayout matlab.ui.container.GridLayout
        ProfileText       matlab.ui.control.Label

        % ---- Gear Settings Panel ----
        GearSettingsPanel  matlab.ui.container.Panel
        GearSettingsGrid   matlab.ui.container.GridLayout

        % Row 1 — Toothing type selection
        ToothingTypeGrid          matlab.ui.container.GridLayout
        ToothingTypeLabel         matlab.ui.control.Label
        ToothingTypeButtonGroup   matlab.ui.container.ButtonGroup
        InvoluteButton            matlab.ui.control.RadioButton
        CycloidalButton           matlab.ui.control.RadioButton
        AdditionalParametersButton matlab.ui.control.Button

        % Row 2 — Gear parameter edit fields (struct with .From and .To)
        GearParametersGrid                   matlab.ui.container.GridLayout
        ModuleEditField                      struct
        NumberOfTeethEditField               struct
        ProfileShiftCoefficientEditField     struct
        ProfileAngleEditField                struct
        HypocycloidRadiusEditField           struct

        % Radio buttons for choosing the varied parameter in parametric mode
        ParameterChoiceButtonGroup      matlab.ui.container.ButtonGroup
        ModuleButton                    matlab.ui.control.RadioButton
        NumberOfTeethButton             matlab.ui.control.RadioButton
        ProfileShiftCoefficientButton   matlab.ui.control.RadioButton
        ProfileAngleButton              matlab.ui.control.RadioButton
        HypocycloidRadiusButton         matlab.ui.control.RadioButton

        % Row labels and LaTeX symbolic labels
        ModuleLabel                          matlab.ui.control.Label
        ModuleSymbolicLabel                  matlab.ui.control.Label
        NumberOfTeethLabel                   matlab.ui.control.Label
        NumberOfTeethSymbolicLabel           matlab.ui.control.Label
        ProfileShiftCoefficientLabel         matlab.ui.control.Label
        ProfileShiftCoefficientSymbolicLabel matlab.ui.control.Label
        ProfileAngleLabel                    matlab.ui.control.Label
        ProfileAngleSymbolicLabel            matlab.ui.control.Label
        HypocycloidRadiusLabel               matlab.ui.control.Label
        HypocycloidRadiusSymbolicLabel       matlab.ui.control.Label

        % ---- Display Settings Panel ----
        DisplaySettingsPanel  matlab.ui.container.Panel
        DisplaySettingsGrid   matlab.ui.container.GridLayout

        % Generation mode (single vs. parametric)
        GenerationModeGrid              matlab.ui.container.GridLayout
        GenerationOptionsLabel          matlab.ui.control.Label
        GenerationModeButtonGroup       matlab.ui.container.ButtonGroup
        SingleProfileButton             matlab.ui.control.RadioButton
        ParametricProfileSequenceButton matlab.ui.control.RadioButton
        ProfileCountGrid                matlab.ui.container.GridLayout
        NumberOfProfilesSpinner         matlab.ui.control.Spinner
        NumberOfProfilesSpinnerLabel    matlab.ui.control.Label

        % Lock display to origin
        ViewLockGrid       matlab.ui.container.GridLayout
        LockToOriginLabel  matlab.ui.control.Label
        LockButton         matlab.ui.control.Button

        % Plot style controls
        PlotStyleGrid          matlab.ui.container.GridLayout
        LinesLabel             matlab.ui.control.Label
        GraphLabel             matlab.ui.control.Label
        ThicknessGrid          matlab.ui.container.GridLayout
        ThicknessSpinnerLabel  matlab.ui.control.Label
        ThicknessSpinner       matlab.ui.control.Spinner
        ColorGrid              matlab.ui.container.GridLayout
        ColorPickerLabel       matlab.ui.control.Label
        ColorPicker            matlab.ui.control.ColorPicker
        LineStyleGrid          matlab.ui.container.GridLayout
        LineStyleDropDownLabel matlab.ui.control.Label
        LineStyleDropDown      matlab.ui.control.DropDown
        GridCheckBox           matlab.ui.control.CheckBox
        AxesCheckBox           matlab.ui.control.CheckBox
        RelevantCirclesButton  matlab.ui.control.Button

        % ---- Export Panel (Profile tab) ----
        ExportPanel      matlab.ui.container.Panel
        ExportGridLayout matlab.ui.container.GridLayout

        % ---- Profile Action Buttons ----
        ProfileActionButtonsGrid  matlab.ui.container.GridLayout
        DrawProfileButton         matlab.ui.control.Button
        CancelProfileButton       matlab.ui.control.Button
        CancelAllProfilesButton   matlab.ui.control.Button

        % ---- Animation Tab ----
        AnimationTab        matlab.ui.container.Tab
        AnimationGridLayout matlab.ui.container.GridLayout

        % Animation tab panels
        AnimationSettingPanel           matlab.ui.container.Panel
        AnimationSettingGridLayout      matlab.ui.container.GridLayout
        UpperAnimationSettingGridLayout matlab.ui.container.GridLayout
        LowerAnimationSettingGridLayout matlab.ui.container.GridLayout
        ToothingSettingPanel            matlab.ui.container.Panel
        ExportSettingPanel              matlab.ui.container.Panel

        % Animation tab action buttons
        DisplayButtonsGridLayout matlab.ui.container.GridLayout
        DisplayButton            matlab.ui.control.Button
        StartPauseButton         matlab.ui.control.Button
        CancelButton             matlab.ui.control.Button
    end

    properties
        OutputFigure         matlab.ui.Figure        % Main graphical output figure
        ProfileCirclesFigure matlab.ui.Figure        % Dialog for activating circles in plot
        AxisOutput           matlab.graphics.axis.Axes % Axes inside OutputFigure
        appFolder            % Root folder of the application (used for images, text files, etc.)
    end

    % Auxiliary utility objects used by the application
    properties
        Gen                          % Tooth profile generator instance

        LanguageUtils                % Language management (populates all UI text)
        HomeUtils                    % Home tab helper

        ProfileTabManagerUtils       % Profile tab logic manager
        AnimationTabUtils            % Animation tab creation and logic
        FurtherParametersUtils       % Additional parameters dialog
        CirclesUtils                 % Relevant circles dialog
        GraphicalAdditions           % Graphical additions dialog (Animation tab)
        ExportUtils                  % Export controls (Profile tab)
        AnimationControl             % Animation playback controller
        AnimationExport              % Animation export controls
        AnimationParameters          % Animation parameters dialog

        % Context menus for standard module selection (.First → From, .Second → To)
        ContextMenuModuleUtils       struct
        ContextMenuPlotColourUtils   % Context menu for colour picker enable/disable
    end

    % ====================================================================
    % Public helper methods
    % ====================================================================
    methods

        function CancelAllFun(app)
            % Remove every drawn profile, reset export controls, and hide axes.

            % Delete all profile line objects and their associated circle plots
            while app.ProfileTabManagerUtils.ProfileCounter > 0
                if isvalid(app.ProfileTabManagerUtils.ProfilePlot(app.ProfileTabManagerUtils.ProfileCounter))
                    delete(app.ProfileTabManagerUtils.ProfilePlot(app.ProfileTabManagerUtils.ProfileCounter));
                end
                if size(app.CirclesUtils.CirclePlot, 2) >= app.ProfileTabManagerUtils.ProfileCounter
                    for ci = 1:size(app.CirclesUtils.CirclePlot, 1)
                        if isvalid(app.CirclesUtils.CirclePlot(ci, app.ProfileTabManagerUtils.ProfileCounter))
                            delete(app.CirclesUtils.CirclePlot(ci, app.ProfileTabManagerUtils.ProfileCounter));
                        end
                    end
                end
                app.ProfileTabManagerUtils.ProfileCounter = app.ProfileTabManagerUtils.ProfileCounter - 1;
            end

            % Reset profile-tab export controls
            app.ExportUtils.ExportSpinner.Limits = [0 0];
            app.ExportUtils.ExportSpinner.Value  = 0;
            app.ExportUtils.ExportButton.Enable  = 0;

            % Remove any residual line objects from the output axes
            if ~isempty(app.AxisOutput) && isvalid(app.AxisOutput)
                delete(findobj(app.AxisOutput, 'Type', 'Line'));

                % Hide the output axes and show the standby placeholder text
                set(app.AxisOutput, 'Visible', 'off', 'HandleVisibility', 'off');
            end
            app.HomeUtils.FigureText.Visible = 'on';

            % Reset animation state so that a fresh display can be triggered
            app.AnimationControl.start_state = 0;
            app.AnimationExport.video_export_state = 0;
            if ~isempty(app.AnimationControl.AxisAnimation) && isvalid(app.AnimationControl.AxisAnimation)
                app.AnimationControl.AxisAnimation.Visible = 'off';
                delete(findobj(app.AnimationControl.AxisAnimation, 'Type', 'line'));
                delete(findobj(app.AnimationControl.AxisAnimation, 'Type', 'patch'));
            end

            % Gear-mesh content is gone — disable the ANSYS launch button.
            app.AnimationTabUtils.AnsysLauchState = 0;
            syncAnsysLaunchButton(app);
        end
    end

    % ====================================================================
    % Private callbacks
    % ====================================================================
    methods (Access = private)

        % ----------------------------------------------------------------
        % Startup — executed once after all components are created
        % ----------------------------------------------------------------
        function startupFcn(app)
            app.appFolder = fileparts(mfilename('fullpath'));

            % Construct auxiliary utility objects
            app.LanguageUtils      = Utils.languageUtils;
            app.HomeUtils          = Utils.homeUtils(app);

            app.GraphicalAdditions  = Utils.AnimationTab.animationGraphicalAdditions(app);
            app.AnimationTabUtils   = Utils.AnimationTab.animationTabUtils(app);
            app.AnimationControl    = Utils.AnimationTab.animationControl(app.AnimationTabUtils, app.OutputFigure);
            app.AnimationExport     = Utils.AnimationTab.animationExport(app);
            app.AnimationParameters = Utils.AnimationTab.animationTabParameters;

            app.ExportUtils            = Utils.ProfileTab.exportUtils(app);
            app.ProfileTabManagerUtils = Utils.ProfileTab.profileTabManagerUtils(app);
            app.FurtherParametersUtils = Utils.ProfileTab.furtherParametersUtils;
            app.CirclesUtils           = Utils.ProfileTab.circlesUtils(app);

            % Attach context menus to module edit fields for standard series.
            % IMPORTANT: These must be created BEFORE languageSetUp is called
            % so that profileTabLanguageFun can assign localised text to the
            % actual uimenu objects. Otherwise on first startup the menus
            % retain their default English "Series 1" / "Series 2" text.
            app.ContextMenuModuleUtils.First  = Utils.ProfileTab.contextMenuModuleUtils(app, app.ModuleEditField.From);
            app.ModuleEditField.From.ContextMenu = app.ContextMenuModuleUtils.First.ContextMenu;

            app.ContextMenuModuleUtils.Second = Utils.ProfileTab.contextMenuModuleUtils(app, app.ModuleEditField.To);
            app.ModuleEditField.To.ContextMenu = app.ContextMenuModuleUtils.Second.ContextMenu;

            % Context menu for the colour picker (random vs. user selection).
            % Also must be created before languageSetUp so profileTabLanguageFun
            % can assign localised text to the actual menu objects.
            app.ContextMenuPlotColourUtils = Utils.ProfileTab.contextMenuPlotColourUtils( ...
                app.MainUIFigure, app.LanguageUtils.LanguageChoice, ...
                app.ColorPicker, app.ColorPickerLabel);

            % Populate every UI text according to the current language
            app.LanguageUtils = languageSetUp(app.LanguageUtils, app);

            % Configure profile-tab parameter visibility
            profileSettingFunction(app.ProfileTabManagerUtils, app);
        end

        % ----------------------------------------------------------------
        % Window close — clean up all secondary figures before deleting app
        % ----------------------------------------------------------------
        function MainUIFigureCloseRequest(app, ~)
            secondaryFigs = {app.OutputFigure, app.FurtherParametersUtils.F, ...
                             app.CirclesUtils.F, app.GraphicalAdditions.F, ...
                             app.AnimationParameters.F};

            for i = 1:numel(secondaryFigs)
                if ~isempty(secondaryFigs{i}) && isvalid(secondaryFigs{i})
                    delete(secondaryFigs{i});
                end
            end

            if ~isdeployed
                % Clear persistent variables from project .m files
                fileList = dir(fullfile(app.appFolder, '**', '*.m'));
                [~, names] = cellfun(@fileparts, {fileList.name}, 'UniformOutput', false);
                for k = 1:numel(names)
                    try
                        clear(names{k});
                    catch
                        % Ignore clear failures for built-in names
                    end
                end
            end

            delete(app);
        end

        % ----------------------------------------------------------------
        % Generation mode changed (single profile vs. parametric sequence)
        % ----------------------------------------------------------------
        function GenerationModeButtonGroupSelectionChanged(app, ~)
            app.ProfileTabManagerUtils.profileSettingFunction(app);

            if app.SingleProfileButton.Value == 1
                % Single-profile mode: From fields have no upper limit
                app.ModuleEditField.From.Limits(2)                  = Inf;
                app.NumberOfTeethEditField.From.Limits(2)           = Inf;
                app.ProfileShiftCoefficientEditField.From.Limits(2) = Inf;
                app.ProfileAngleEditField.From.Limits(2)            = Inf;

            elseif app.ParametricProfileSequenceButton.Value == 1
                % Parametric mode: cross-link From/To limits
                app.ModuleEditField.To.Limits(1)                  = app.ModuleEditField.From.Value;
                app.NumberOfTeethEditField.To.Limits(1)           = app.NumberOfTeethEditField.From.Value;
                app.ProfileShiftCoefficientEditField.To.Limits(1) = app.ProfileShiftCoefficientEditField.From.Value;
                app.ProfileAngleEditField.To.Limits(1)            = app.ProfileAngleEditField.From.Value;
                app.HypocycloidRadiusEditField.To.Limits(1)       = app.HypocycloidRadiusEditField.From.Value;

                % Set upper bound of From to the current To value (if set)
                if ~isempty(app.ModuleEditField.To.Value)
                    app.ModuleEditField.From.Limits(2) = app.ModuleEditField.To.Value;
                end
                if ~isempty(app.NumberOfTeethEditField.To.Value)
                    app.NumberOfTeethEditField.From.Limits(2) = app.NumberOfTeethEditField.To.Value;
                end
                if ~isempty(app.ProfileShiftCoefficientEditField.To.Value)
                    app.ProfileShiftCoefficientEditField.From.Limits(2) = app.ProfileShiftCoefficientEditField.To.Value;
                end
                if ~isempty(app.ProfileAngleEditField.To.Value)
                    app.ProfileAngleEditField.From.Limits(2) = app.ProfileAngleEditField.To.Value;
                end
                if ~isempty(app.HypocycloidRadiusEditField.To.Value)
                    app.HypocycloidRadiusEditField.From.Limits(2) = app.HypocycloidRadiusEditField.To.Value;
                end

            end
        end

        % ----------------------------------------------------------------
        % Parameter choice changed (which parameter is varied)
        % ----------------------------------------------------------------
        function ParameterChoiceButtonGroupSelectionChanged(app, ~)
            profileSettingParameterFunction(app.ProfileTabManagerUtils, app);
        end

        % ----------------------------------------------------------------
        % Module edit field callbacks
        % ----------------------------------------------------------------
        function ModuleEditFieldToValueChanged(app, ~)
            app.ModuleEditField.From.Limits(2) = app.ModuleEditField.To.Value;
            app.ModuleEditField.To.AllowEmpty   = 'off';
        end

        function ModuleEditFieldFromValueChanged(app, ~)
            app.ModuleEditField.To.Limits(1) = app.ModuleEditField.From.Value;
            % Recalculate hypocycloid radius limits based on current module
            x = app.ProfileShiftCoefficientEditField.From.Value;
            m = app.ModuleEditField.From.Value;
            z = app.NumberOfTeethEditField.From.Value;
            app.HypocycloidRadiusEditField.From.Limits(1) = (1.25 - x) * m / 2;
            app.HypocycloidRadiusEditField.From.Limits(2) = (m * z - (1.25 - x) * m) / 2;
            app.HypocycloidRadiusEditField.To.Limits(2)   = app.HypocycloidRadiusEditField.From.Limits(2);
        end

        % ----------------------------------------------------------------
        % Number of teeth edit field callbacks
        % ----------------------------------------------------------------
        function NumberOfTeethEditFieldToValueChanged(app, ~)
            app.NumberOfTeethEditField.From.Limits(2) = app.NumberOfTeethEditField.To.Value;
            app.NumberOfTeethEditField.To.AllowEmpty   = 'off';
        end

        function NumberOfTeethEditFieldFromValueChanged(app, ~)
            app.NumberOfTeethEditField.To.Limits(1) = app.NumberOfTeethEditField.From.Value;
        end

        % ----------------------------------------------------------------
        % Profile shift coefficient edit field callbacks
        % ----------------------------------------------------------------
        function ProfileShiftCoefficientEditFieldToValueChanged(app, ~)
            app.ProfileShiftCoefficientEditField.From.Limits(2) = app.ProfileShiftCoefficientEditField.To.Value;
            app.ProfileShiftCoefficientEditField.To.AllowEmpty   = 'off';
        end

        function ProfileShiftCoefficientEditFieldFromValueChanged(app, ~)
            % Recalculate hypocycloid radius limits when profile shift changes
            x = app.ProfileShiftCoefficientEditField.From.Value;
            m = app.ModuleEditField.From.Value;
            z = app.NumberOfTeethEditField.From.Value;
            app.HypocycloidRadiusEditField.From.Limits(1) = (1.25 - x) * m / 2;
            app.HypocycloidRadiusEditField.From.Limits(2) = (m * z - (1.25 - x) * m) / 2;
            app.HypocycloidRadiusEditField.To.Limits(2)   = app.HypocycloidRadiusEditField.From.Limits(2);
        end

        % ----------------------------------------------------------------
        % Profile angle edit field callbacks
        % ----------------------------------------------------------------
        function ProfileAngleEditFieldToValueChanged(app, ~)
            app.ProfileAngleEditField.From.Limits(2) = app.ProfileAngleEditField.To.Value;
            app.ProfileAngleEditField.To.AllowEmpty   = 'off';
        end

        function ProfileAngleEditFieldFromValueChanged(app, ~)
            app.ProfileAngleEditField.To.Limits(1) = app.ProfileAngleEditField.From.Value;
        end

        % ----------------------------------------------------------------
        % Draw / Cancel profile buttons
        % ----------------------------------------------------------------
        function DrawProfileButtonPushed(app, ~)
            % Generate and draw the tooth profile with current settings
            Utils.ProfileTab.drawFunction(app);
            % Profile-Tab content is now in the Output Figure — disable ANSYS.
            app.AnimationTabUtils.AnsysLauchState = 0;
            syncAnsysLaunchButton(app);
        end

        function CancelProfileButtonPushed(app, ~)
            % Remove the most recently drawn profile.

            if app.ProfileTabManagerUtils.ProfileCounter > 0
                if isvalid(app.ProfileTabManagerUtils.ProfilePlot(app.ProfileTabManagerUtils.ProfileCounter))
                    delete(app.ProfileTabManagerUtils.ProfilePlot(app.ProfileTabManagerUtils.ProfileCounter));
                end
                if size(app.CirclesUtils.CirclePlot, 2) >= app.ProfileTabManagerUtils.ProfileCounter
                    for ci = 1:size(app.CirclesUtils.CirclePlot, 1)
                        if isvalid(app.CirclesUtils.CirclePlot(ci, app.ProfileTabManagerUtils.ProfileCounter))
                            delete(app.CirclesUtils.CirclePlot(ci, app.ProfileTabManagerUtils.ProfileCounter));
                        end
                    end
                end
                app.ProfileTabManagerUtils.ProfileCounter = app.ProfileTabManagerUtils.ProfileCounter - 1;

                if app.ProfileTabManagerUtils.ProfileCounter == 0
                    app.ExportUtils.ExportSpinner.Limits = [0 0];
                else
                    app.ExportUtils.ExportSpinner.Limits = [1 double(app.ProfileTabManagerUtils.ProfileCounter)];
                end
                app.ExportUtils.ExportSpinner.Value = double(app.ProfileTabManagerUtils.ProfileCounter);
            end

            % When all profiles are gone, fully clear the Output Figure.
            % Mirrors CancelAllFun exactly so both cancel buttons leave the
            % app in the same state regardless of what was on screen
            % (profile plot, gear mesh, or gear generator output).
            if app.ProfileTabManagerUtils.ProfileCounter == 0
                set(app.AxisOutput, 'Visible', 'off', 'HandleVisibility', 'off');
                app.HomeUtils.FigureText.Visible = 'on';
                app.ExportUtils.ExportSpinner.Limits = [0 0];
                app.ExportUtils.ExportSpinner.Value  = 0;
                app.ExportUtils.ExportButton.Enable  = 0;

                % Clear the animation axes too — this was the missing piece
                % that caused gear-mesh content to survive a single-cancel.
                app.AnimationControl.start_state = 0;
                app.AnimationExport.video_export_state = 0;
                if ~isempty(app.AnimationControl.AxisAnimation) && ...
                        isvalid(app.AnimationControl.AxisAnimation)
                    app.AnimationControl.AxisAnimation.Visible = 'off';
                    delete(findobj(app.AnimationControl.AxisAnimation, 'Type', 'line'));
                    delete(findobj(app.AnimationControl.AxisAnimation, 'Type', 'patch'));
                end
            end

            % Sync the ANSYS launch button regardless of how many profiles remain.
            app.AnimationTabUtils.AnsysLauchState = 0;
            syncAnsysLaunchButton(app);
        end

        function CancelAllProfilesButtonPushed(app, ~)
            % Remove all drawn profiles and reset the UI
            CancelAllFun(app);
        end

        % ----------------------------------------------------------------
        % Lock button — toggle view locked to origin
        % ----------------------------------------------------------------
        function LockButtonPushed(app, ~)
            if app.ProfileTabManagerUtils.LockChecker == false
                app.ProfileTabManagerUtils.LockChecker = true;
                app.LockButton.Icon = fullfile(app.appFolder, 'Images', 'Lock_closed.png');
            else
                app.ProfileTabManagerUtils.LockChecker = false;
                app.LockButton.Icon = fullfile(app.appFolder, 'Images', 'Lock_open.png');
            end
        end

        % ----------------------------------------------------------------
        % Additional parameters dialog toggle
        % ----------------------------------------------------------------
        function AdditionalParametersButtonPushed(app, ~)
            if ~isempty(app.FurtherParametersUtils.F) && isgraphics(app.FurtherParametersUtils.F)
                close(app.FurtherParametersUtils.F);
            else
                app.FurtherParametersUtils = create(app.FurtherParametersUtils, app);
            end
        end

        % ----------------------------------------------------------------
        % Plot display controls
        % ----------------------------------------------------------------
        function AxesCheckBoxValueChanged(app, ~)
            % Show or hide axes ticks/labels on the output plot
            if app.ProfileTabManagerUtils.ProfileCounter >= 1
                if app.AxesCheckBox.Value
                    axis(app.AxisOutput, 'on');
                else
                    axis(app.AxisOutput, 'off');
                end
            end
        end

        function GridCheckBoxValueChanged(app, ~)
            % Show or hide the grid on the output plot
            if app.ProfileTabManagerUtils.ProfileCounter >= 1
                if app.GridCheckBox.Value
                    grid(app.AxisOutput, 'on');
                else
                    grid(app.AxisOutput, 'off');
                end
            end
        end

        function ColorPickerValueChanged(app, ~)
            % Apply the chosen colour to the most recent profile line
            if app.ProfileTabManagerUtils.ProfileCounter >= 1 && strcmp(app.ColorPicker.Enable, 'on')
                if isvalid(app.ProfileTabManagerUtils.ProfilePlot(app.ProfileTabManagerUtils.ProfileCounter))
                    set(app.ProfileTabManagerUtils.ProfilePlot(app.ProfileTabManagerUtils.ProfileCounter), ...
                        'Color', app.ColorPicker.Value);
                end
            end
        end

        function ThicknessSpinnerValueChanged(app, ~)
            % Apply the chosen line width to the most recent profile line
            if app.ProfileTabManagerUtils.ProfileCounter >= 1
                if isvalid(app.ProfileTabManagerUtils.ProfilePlot(app.ProfileTabManagerUtils.ProfileCounter))
                    set(app.ProfileTabManagerUtils.ProfilePlot(app.ProfileTabManagerUtils.ProfileCounter), ...
                        'LineWidth', app.ThicknessSpinner.Value);
                end
            end
        end

        function LineStyleDropDownValueChanged(app, ~)
            % Apply the chosen line style to the most recent profile line
            if app.ProfileTabManagerUtils.ProfileCounter >= 1
                if isvalid(app.ProfileTabManagerUtils.ProfilePlot(app.ProfileTabManagerUtils.ProfileCounter))
                    set(app.ProfileTabManagerUtils.ProfilePlot(app.ProfileTabManagerUtils.ProfileCounter), ...
                        'LineStyle', Utils.ProfileTab.profileLineStyleFunction(app.LineStyleDropDown.ValueIndex));
                end
            end
        end

        % ----------------------------------------------------------------
        % Relevant circles dialog toggle
        % ----------------------------------------------------------------
        function RelevantCirclesButtonPushed(app, ~)
            if ~isempty(app.CirclesUtils.F) && isgraphics(app.CirclesUtils.F)
                close(app.CirclesUtils.F);
            else
                app.CirclesUtils = create(app.CirclesUtils, app);
            end
        end

        % ----------------------------------------------------------------
        % Animation tab buttons
        % ----------------------------------------------------------------
        function DisplayButtonPushed(app, ~)
            % Show animation axes and display the gear animation
            if ~isempty(app.AnimationControl.AxisAnimation) && isvalid(app.AnimationControl.AxisAnimation)
                app.AnimationControl.AxisAnimation.Visible = 'on';
            end
            displayFun(app.AnimationControl, app);
            % Gear mesh is now on screen — enable ANSYS only in meshing mode.
            if app.AnimationTabUtils.Mode.ValueIndex == 1
                app.AnimationTabUtils.AnsysLauchState = 1;
            else
                app.AnimationTabUtils.AnsysLauchState = 0;
            end
            syncAnsysLaunchButton(app);
        end

        function StartPauseButtonPushed(app, ~)
            % Start or pause the running animation.
            % Directly disable the ANSYS launch button before entering the
            % blocking animation loop, then sync when the loop returns
            % (i.e. when the animation is paused or finished).
            dlg = app.AnimationTabUtils.AnsysDialog;
            if ~isempty(dlg) && isvalid(dlg) && isgraphics(dlg.F) && isvalid(dlg.F)
                dlg.LaunchButton.Enable = 'off';
            end
            startAnimation(app.AnimationControl, app);
            % Loop has exited — re-evaluate based on AnsysLaunchState.
            syncAnsysLaunchButton(app);
        end

        function syncAnsysLaunchButton(app)
            % Forward the sync call to the ANSYS dialog if it is open.
            % Called from every action that changes the output-figure content
            % or the animation running-state.  All enable/disable logic lives
            % in ansysIntegrationUtils.syncLaunchButton() — this is just the
            % routing shim that keeps Gear_Model ignorant of dialog internals.
            dlg = app.AnimationTabUtils.AnsysDialog;
            if ~isempty(dlg) && isvalid(dlg) && ...
               isgraphics(dlg.F) && isvalid(dlg.F)
                dlg.syncLaunchButton();
            end
        end
    end

    % ====================================================================
    % Component initialization
    % ====================================================================
    methods (Access = private)

        function createComponents(app)
            % Build every UI component and wire up all callbacks.
            % Text content is deliberately omitted — LanguageUtils populates
            % it during startupFcn.

            pathToApp = fileparts(mfilename('fullpath'));

            % ---- Main figure ----
            app.MainUIFigure = uifigure('Visible', 'off');
            app.MainUIFigure.Position        = [0 80 600 800];
            app.MainUIFigure.Icon            = fullfile(pathToApp, 'Images', 'VUT_logo.png');
            app.MainUIFigure.Theme           = 'light';
            app.MainUIFigure.CloseRequestFcn = @(src,evt) MainUIFigureCloseRequest(app, evt);

            app.MainGridLayout = uigridlayout(app.MainUIFigure);
            app.MainGridLayout.ColumnWidth = {'1x'};
            app.MainGridLayout.RowHeight   = {'1x'};

            app.MainTabGroup = uitabgroup(app.MainGridLayout);
            app.MainTabGroup.Layout.Row    = 1;
            app.MainTabGroup.Layout.Column = 1;

            % Initialise struct-based edit field properties
            app.ModuleEditField                  = struct('From', [], 'To', []);
            app.NumberOfTeethEditField           = struct('From', [], 'To', []);
            app.ProfileShiftCoefficientEditField = struct('From', [], 'To', []);
            app.ProfileAngleEditField            = struct('From', [], 'To', []);
            app.HypocycloidRadiusEditField       = struct('From', [], 'To', []);
            app.ContextMenuModuleUtils           = struct('First', [], 'Second', []);

            % Background colour constant used for all panels/grids
            bgColor = [0.9412 0.9412 0.9412];

            % ---- HOME TAB ----
            app.HomeTab = uitab(app.MainTabGroup);
            app.HomeTab.BackgroundColor = bgColor;

            % ---- PROFILE TAB ----
            app.ProfileTab = uitab(app.MainTabGroup);
            app.ProfileTab.BackgroundColor = bgColor;

            app.ProfileGridLayout = uigridlayout(app.ProfileTab);
            app.ProfileGridLayout.ColumnWidth = {'1x'};
            app.ProfileGridLayout.RowHeight   = {50, 192, 'fit', '1x', 35};
            app.ProfileGridLayout.RowSpacing  = 20;
            app.ProfileGridLayout.Padding     = [20 20 20 20];
            app.ProfileGridLayout.Scrollable  = 'on';

            % Top descriptive label
            app.ProfileText = uilabel(app.ProfileGridLayout);
            app.ProfileText.VerticalAlignment = 'top';
            app.ProfileText.WordWrap          = 'on';
            app.ProfileText.Layout.Row        = 1;
            app.ProfileText.Layout.Column     = 1;

            % ---- GEAR SETTINGS PANEL ----
            app.GearSettingsPanel = uipanel(app.ProfileGridLayout);
            app.GearSettingsPanel.BackgroundColor = bgColor;
            app.GearSettingsPanel.Layout.Row      = 3;
            app.GearSettingsPanel.Layout.Column   = 1;
            app.GearSettingsPanel.FontWeight      = 'bold';

            app.GearSettingsGrid = uigridlayout(app.GearSettingsPanel);
            app.GearSettingsGrid.ColumnWidth     = {'1x'};
            app.GearSettingsGrid.RowHeight       = {20, 'fit'};
            app.GearSettingsGrid.RowSpacing      = 20;
            app.GearSettingsGrid.BackgroundColor = bgColor;

            % --- Row 1: Toothing type ---
            app.ToothingTypeGrid = uigridlayout(app.GearSettingsGrid);
            app.ToothingTypeGrid.ColumnWidth     = {80, 180, '1x', 150};
            app.ToothingTypeGrid.RowHeight       = {20};
            app.ToothingTypeGrid.ColumnSpacing   = 5;
            app.ToothingTypeGrid.RowSpacing      = 0;
            app.ToothingTypeGrid.Padding         = [0 0 0 0];
            app.ToothingTypeGrid.Layout.Row      = 1;
            app.ToothingTypeGrid.Layout.Column   = 1;
            app.ToothingTypeGrid.BackgroundColor = bgColor;

            app.ToothingTypeLabel = uilabel(app.ToothingTypeGrid);
            app.ToothingTypeLabel.Layout.Row    = 1;
            app.ToothingTypeLabel.Layout.Column = 1;

            app.ToothingTypeButtonGroup = uibuttongroup(app.ToothingTypeGrid);
            app.ToothingTypeButtonGroup.BorderType      = 'none';
            app.ToothingTypeButtonGroup.BorderWidth     = 0;
            app.ToothingTypeButtonGroup.BackgroundColor = bgColor;
            app.ToothingTypeButtonGroup.Layout.Row      = 1;
            app.ToothingTypeButtonGroup.Layout.Column   = 2;

            app.CycloidalButton = uiradiobutton(app.ToothingTypeButtonGroup);
            app.CycloidalButton.Position = [86 1 85 20];

            app.InvoluteButton = uiradiobutton(app.ToothingTypeButtonGroup);
            app.InvoluteButton.Position = [1 1 85 20];
            app.InvoluteButton.Value    = true;

            app.AdditionalParametersButton = uibutton(app.ToothingTypeGrid, 'push');
            app.AdditionalParametersButton.ButtonPushedFcn = @(src,evt) AdditionalParametersButtonPushed(app, evt);
            app.AdditionalParametersButton.BackgroundColor  = [1 1 1];
            app.AdditionalParametersButton.Layout.Row       = 1;
            app.AdditionalParametersButton.Layout.Column    = 4;

            % --- Row 2: Gear parameter edit fields ---
            app.GearParametersGrid = uigridlayout(app.GearSettingsGrid);
            app.GearParametersGrid.ColumnWidth     = {'1x', 'fit', 15, 50, 50};
            app.GearParametersGrid.RowHeight       = {20, 20, 20, 20, 20};
            app.GearParametersGrid.Padding         = [0 0 0 0];
            app.GearParametersGrid.Layout.Row      = 2;
            app.GearParametersGrid.Layout.Column   = 1;
            app.GearParametersGrid.BackgroundColor = bgColor;

            % Row 5 — HypocycloidRadius (cycloidal only)
            app.HypocycloidRadiusSymbolicLabel = uilabel(app.GearParametersGrid);
            app.HypocycloidRadiusSymbolicLabel.HorizontalAlignment = 'center';
            app.HypocycloidRadiusSymbolicLabel.Enable      = 'off';
            app.HypocycloidRadiusSymbolicLabel.Visible     = 'off';
            app.HypocycloidRadiusSymbolicLabel.Layout.Row  = 5;
            app.HypocycloidRadiusSymbolicLabel.Layout.Column = 2;
            app.HypocycloidRadiusSymbolicLabel.Interpreter = 'latex';
            app.HypocycloidRadiusSymbolicLabel.Text        = '$\rho_h  \: \mathrm{[mm]}$';

            app.HypocycloidRadiusLabel = uilabel(app.GearParametersGrid);
            app.HypocycloidRadiusLabel.Enable          = 'off';
            app.HypocycloidRadiusLabel.Visible         = 'off';
            app.HypocycloidRadiusLabel.Layout.Row      = 5;
            app.HypocycloidRadiusLabel.Layout.Column   = 1;

            % Row 4 — ProfileAngle
            app.ProfileAngleSymbolicLabel = uilabel(app.GearParametersGrid);
            app.ProfileAngleSymbolicLabel.HorizontalAlignment = 'center';
            app.ProfileAngleSymbolicLabel.FontAngle    = 'italic';
            app.ProfileAngleSymbolicLabel.Layout.Row   = 4;
            app.ProfileAngleSymbolicLabel.Layout.Column = 2;
            app.ProfileAngleSymbolicLabel.Interpreter  = 'latex';
            app.ProfileAngleSymbolicLabel.Text         = '$\alpha \: \mathrm{[^\circ]}$';

            app.ProfileAngleLabel = uilabel(app.GearParametersGrid);
            app.ProfileAngleLabel.Layout.Row    = 4;
            app.ProfileAngleLabel.Layout.Column = 1;

            % Row 3 — ProfileShiftCoefficient
            app.ProfileShiftCoefficientSymbolicLabel = uilabel(app.GearParametersGrid);
            app.ProfileShiftCoefficientSymbolicLabel.HorizontalAlignment = 'center';
            app.ProfileShiftCoefficientSymbolicLabel.Layout.Row    = 3;
            app.ProfileShiftCoefficientSymbolicLabel.Layout.Column = 2;
            app.ProfileShiftCoefficientSymbolicLabel.Interpreter   = 'latex';
            app.ProfileShiftCoefficientSymbolicLabel.Text          = '$x \: \mathrm{[-]}$';

            app.ProfileShiftCoefficientLabel = uilabel(app.GearParametersGrid);
            app.ProfileShiftCoefficientLabel.Layout.Row    = 3;
            app.ProfileShiftCoefficientLabel.Layout.Column = 1;

            % Row 2 — NumberOfTeeth
            app.NumberOfTeethSymbolicLabel = uilabel(app.GearParametersGrid);
            app.NumberOfTeethSymbolicLabel.HorizontalAlignment = 'center';
            app.NumberOfTeethSymbolicLabel.Layout.Row    = 2;
            app.NumberOfTeethSymbolicLabel.Layout.Column = 2;
            app.NumberOfTeethSymbolicLabel.Interpreter   = 'latex';
            app.NumberOfTeethSymbolicLabel.Text          = '$z \: \mathrm{[-]}$';

            app.NumberOfTeethLabel = uilabel(app.GearParametersGrid);
            app.NumberOfTeethLabel.Layout.Row    = 2;
            app.NumberOfTeethLabel.Layout.Column = 1;

            % Row 1 — Module
            app.ModuleSymbolicLabel = uilabel(app.GearParametersGrid);
            app.ModuleSymbolicLabel.HorizontalAlignment = 'center';
            app.ModuleSymbolicLabel.Layout.Row    = 1;
            app.ModuleSymbolicLabel.Layout.Column = 2;
            app.ModuleSymbolicLabel.Interpreter   = 'latex';
            app.ModuleSymbolicLabel.Text          = '$m \: \mathrm{[mm]}$';

            app.ModuleLabel = uilabel(app.GearParametersGrid);
            app.ModuleLabel.Layout.Row    = 1;
            app.ModuleLabel.Layout.Column = 1;

            % Parameter choice radio buttons (column 3, spanning rows 1–5)
            app.ParameterChoiceButtonGroup = uibuttongroup(app.GearParametersGrid);
            app.ParameterChoiceButtonGroup.SelectionChangedFcn = @(src,evt) ParameterChoiceButtonGroupSelectionChanged(app, evt);
            app.ParameterChoiceButtonGroup.BorderType      = 'none';
            app.ParameterChoiceButtonGroup.BorderWidth     = 0;
            app.ParameterChoiceButtonGroup.BackgroundColor = bgColor;
            app.ParameterChoiceButtonGroup.Layout.Row      = [1 5];
            app.ParameterChoiceButtonGroup.Layout.Column   = 3;

            app.HypocycloidRadiusButton = uiradiobutton(app.ParameterChoiceButtonGroup);
            app.HypocycloidRadiusButton.Enable  = 'off';
            app.HypocycloidRadiusButton.Visible = 'off';
            app.HypocycloidRadiusButton.Text     = '';
            app.HypocycloidRadiusButton.Position = [1 1 15 20];

            app.ProfileAngleButton = uiradiobutton(app.ParameterChoiceButtonGroup);
            app.ProfileAngleButton.Text     = '';
            app.ProfileAngleButton.Position = [1 31 15 20];

            app.ProfileShiftCoefficientButton = uiradiobutton(app.ParameterChoiceButtonGroup);
            app.ProfileShiftCoefficientButton.Text     = '';
            app.ProfileShiftCoefficientButton.Position = [1 61 15 20];

            app.NumberOfTeethButton = uiradiobutton(app.ParameterChoiceButtonGroup);
            app.NumberOfTeethButton.Text     = '';
            app.NumberOfTeethButton.Position = [1 91 15 20];

            app.ModuleButton = uiradiobutton(app.ParameterChoiceButtonGroup);
            app.ModuleButton.Text     = '';
            app.ModuleButton.Position = [1 121 15 20];
            app.ModuleButton.Value    = true;

            % ---- Edit fields — columns 4 (From) and 5 (To) ----

            % HypocycloidRadius (row 5)
            app.HypocycloidRadiusEditField.To = uieditfield(app.GearParametersGrid, 'numeric');
            app.HypocycloidRadiusEditField.To.LowerLimitInclusive = 'off';
            app.HypocycloidRadiusEditField.To.UpperLimitInclusive = 'off';
            app.HypocycloidRadiusEditField.To.Limits       = [0 Inf];
            app.HypocycloidRadiusEditField.To.AllowEmpty    = 'on';
            app.HypocycloidRadiusEditField.To.HorizontalAlignment = 'center';
            app.HypocycloidRadiusEditField.To.Enable       = 'off';
            app.HypocycloidRadiusEditField.To.Visible      = 'off';
            app.HypocycloidRadiusEditField.To.Layout.Row   = 5;
            app.HypocycloidRadiusEditField.To.Layout.Column = 5;
            app.HypocycloidRadiusEditField.To.Value        = [];

            app.HypocycloidRadiusEditField.From = uieditfield(app.GearParametersGrid, 'numeric');
            app.HypocycloidRadiusEditField.From.LowerLimitInclusive = 'off';
            app.HypocycloidRadiusEditField.From.UpperLimitInclusive = 'off';
            app.HypocycloidRadiusEditField.From.AllowEmpty           = 'on';
            app.HypocycloidRadiusEditField.From.HorizontalAlignment  = 'center';
            app.HypocycloidRadiusEditField.From.Enable  = 'off';
            app.HypocycloidRadiusEditField.From.Visible = 'off';
            app.HypocycloidRadiusEditField.From.Layout.Row    = 5;
            app.HypocycloidRadiusEditField.From.Layout.Column = 4;
            app.HypocycloidRadiusEditField.From.Value   = 10;

            % ProfileAngle (row 4)
            app.ProfileAngleEditField.To = uieditfield(app.GearParametersGrid, 'numeric');
            app.ProfileAngleEditField.To.LowerLimitInclusive = 'off';
            app.ProfileAngleEditField.To.AllowEmpty    = 'on';
            app.ProfileAngleEditField.To.ValueChangedFcn = @(src,evt) ProfileAngleEditFieldToValueChanged(app, evt);
            app.ProfileAngleEditField.To.HorizontalAlignment = 'center';
            app.ProfileAngleEditField.To.Layout.Row    = 4;
            app.ProfileAngleEditField.To.Layout.Column = 5;
            app.ProfileAngleEditField.To.Value         = [];

            app.ProfileAngleEditField.From = uieditfield(app.GearParametersGrid, 'numeric');
            app.ProfileAngleEditField.From.LowerLimitInclusive = 'off';
            app.ProfileAngleEditField.From.UpperLimitInclusive = 'off';
            app.ProfileAngleEditField.From.Limits = [0 Inf];
            app.ProfileAngleEditField.From.ValueChangedFcn = @(src,evt) ProfileAngleEditFieldFromValueChanged(app, evt);
            app.ProfileAngleEditField.From.HorizontalAlignment = 'center';
            app.ProfileAngleEditField.From.Layout.Row    = 4;
            app.ProfileAngleEditField.From.Layout.Column = 4;
            app.ProfileAngleEditField.From.Value   = 20;

            % ProfileShiftCoefficient (row 3)
            app.ProfileShiftCoefficientEditField.To = uieditfield(app.GearParametersGrid, 'numeric');
            app.ProfileShiftCoefficientEditField.To.LowerLimitInclusive = 'off';
            app.ProfileShiftCoefficientEditField.To.AllowEmpty    = 'on';
            app.ProfileShiftCoefficientEditField.To.ValueChangedFcn = @(src,evt) ProfileShiftCoefficientEditFieldToValueChanged(app, evt);
            app.ProfileShiftCoefficientEditField.To.HorizontalAlignment = 'center';
            app.ProfileShiftCoefficientEditField.To.Layout.Row    = 3;
            app.ProfileShiftCoefficientEditField.To.Layout.Column = 5;
            app.ProfileShiftCoefficientEditField.To.Value         = [];

            app.ProfileShiftCoefficientEditField.From = uieditfield(app.GearParametersGrid, 'numeric');
            app.ProfileShiftCoefficientEditField.From.LowerLimitInclusive = 'off';
            app.ProfileShiftCoefficientEditField.From.UpperLimitInclusive = 'off';
            app.ProfileShiftCoefficientEditField.From.ValueChangedFcn = @(src,evt) ProfileShiftCoefficientEditFieldFromValueChanged(app, evt);
            app.ProfileShiftCoefficientEditField.From.HorizontalAlignment = 'center';
            app.ProfileShiftCoefficientEditField.From.Layout.Row    = 3;
            app.ProfileShiftCoefficientEditField.From.Layout.Column = 4;

            % NumberOfTeeth (row 2)
            app.NumberOfTeethEditField.To = uieditfield(app.GearParametersGrid, 'numeric');
            app.NumberOfTeethEditField.To.LowerLimitInclusive = 'off';
            app.NumberOfTeethEditField.To.AllowEmpty    = 'on';
            app.NumberOfTeethEditField.To.ValueChangedFcn = @(src,evt) NumberOfTeethEditFieldToValueChanged(app, evt);
            app.NumberOfTeethEditField.To.HorizontalAlignment = 'center';
            app.NumberOfTeethEditField.To.Layout.Row    = 2;
            app.NumberOfTeethEditField.To.Layout.Column = 5;
            app.NumberOfTeethEditField.To.Value         = [];
            app.NumberOfTeethEditField.To.RoundFractionalValues = 'on';

            app.NumberOfTeethEditField.From = uieditfield(app.GearParametersGrid, 'numeric');
            app.NumberOfTeethEditField.From.LowerLimitInclusive = 'off';
            app.NumberOfTeethEditField.From.UpperLimitInclusive = 'off';
            app.NumberOfTeethEditField.From.Limits = [0 Inf];
            app.NumberOfTeethEditField.From.ValueChangedFcn = @(src,evt) NumberOfTeethEditFieldFromValueChanged(app, evt);
            app.NumberOfTeethEditField.From.HorizontalAlignment = 'center';
            app.NumberOfTeethEditField.From.Layout.Row    = 2;
            app.NumberOfTeethEditField.From.Layout.Column = 4;
            app.NumberOfTeethEditField.From.Value   = 20;
            app.NumberOfTeethEditField.From.RoundFractionalValues = 'on';

            % Module (row 1)
            app.ModuleEditField.To = uieditfield(app.GearParametersGrid, 'numeric');
            app.ModuleEditField.To.LowerLimitInclusive = 'off';
            app.ModuleEditField.To.AllowEmpty    = 'on';
            app.ModuleEditField.To.ValueChangedFcn = @(src,evt) ModuleEditFieldToValueChanged(app, evt);
            app.ModuleEditField.To.HorizontalAlignment = 'center';
            app.ModuleEditField.To.Layout.Row    = 1;
            app.ModuleEditField.To.Layout.Column = 5;
            app.ModuleEditField.To.Value         = [];

            app.ModuleEditField.From = uieditfield(app.GearParametersGrid, 'numeric');
            app.ModuleEditField.From.LowerLimitInclusive = 'off';
            app.ModuleEditField.From.UpperLimitInclusive = 'off';
            app.ModuleEditField.From.Limits = [0 Inf];
            app.ModuleEditField.From.ValueChangedFcn = @(src,evt) ModuleEditFieldFromValueChanged(app, evt);
            app.ModuleEditField.From.HorizontalAlignment = 'center';
            app.ModuleEditField.From.Layout.Row    = 1;
            app.ModuleEditField.From.Layout.Column = 4;
            app.ModuleEditField.From.Value   = 1;

            % ---- DISPLAY SETTINGS PANEL ----
            app.DisplaySettingsPanel = uipanel(app.ProfileGridLayout);
            app.DisplaySettingsPanel.BackgroundColor = bgColor;
            app.DisplaySettingsPanel.Layout.Row      = 2;
            app.DisplaySettingsPanel.Layout.Column   = 1;
            app.DisplaySettingsPanel.FontWeight      = 'bold';

            app.DisplaySettingsGrid = uigridlayout(app.DisplaySettingsPanel);
            app.DisplaySettingsGrid.ColumnWidth     = {'1x'};
            app.DisplaySettingsGrid.RowHeight       = {45, 20, 50};
            app.DisplaySettingsGrid.RowSpacing      = 20;
            app.DisplaySettingsGrid.BackgroundColor = bgColor;

            % --- Row 1: Generation mode ---
            app.GenerationModeGrid = uigridlayout(app.DisplaySettingsGrid);
            app.GenerationModeGrid.ColumnWidth     = {122, '1x', 'fit'};
            app.GenerationModeGrid.RowHeight       = {20, 20};
            app.GenerationModeGrid.ColumnSpacing   = 5;
            app.GenerationModeGrid.RowSpacing      = 5;
            app.GenerationModeGrid.Padding         = [0 0 0 0];
            app.GenerationModeGrid.Layout.Row      = 1;
            app.GenerationModeGrid.Layout.Column   = 1;
            app.GenerationModeGrid.BackgroundColor = bgColor;

            app.GenerationOptionsLabel = uilabel(app.GenerationModeGrid);
            app.GenerationOptionsLabel.Layout.Row    = 1;
            app.GenerationOptionsLabel.Layout.Column = 1;

            % Profile count sub-grid
            app.ProfileCountGrid = uigridlayout(app.GenerationModeGrid);
            app.ProfileCountGrid.RowHeight       = {'1x'};
            app.ProfileCountGrid.ColumnWidth     = {'fit', 60};
            app.ProfileCountGrid.ColumnSpacing   = 5;
            app.ProfileCountGrid.RowSpacing      = 0;
            app.ProfileCountGrid.Padding         = [0 0 0 0];
            app.ProfileCountGrid.Layout.Row      = 2;
            app.ProfileCountGrid.Layout.Column   = 3;
            app.ProfileCountGrid.BackgroundColor = bgColor;

            app.NumberOfProfilesSpinnerLabel = uilabel(app.ProfileCountGrid);
            app.NumberOfProfilesSpinnerLabel.HorizontalAlignment = 'right';
            app.NumberOfProfilesSpinnerLabel.Layout.Row    = 1;
            app.NumberOfProfilesSpinnerLabel.Layout.Column = 1;

            app.NumberOfProfilesSpinner = uispinner(app.ProfileCountGrid);
            app.NumberOfProfilesSpinner.Limits        = [2 Inf];
            app.NumberOfProfilesSpinner.RoundFractionalValues = 'on';
            app.NumberOfProfilesSpinner.Layout.Row    = 1;
            app.NumberOfProfilesSpinner.Layout.Column = 2;
            app.NumberOfProfilesSpinner.Value         = 10;

            % Generation mode button group
            app.GenerationModeButtonGroup = uibuttongroup(app.GenerationModeGrid);
            app.GenerationModeButtonGroup.SelectionChangedFcn = @(src,evt) GenerationModeButtonGroupSelectionChanged(app, evt);
            app.GenerationModeButtonGroup.BorderColor     = [0.9608 0.9608 0.9608];
            app.GenerationModeButtonGroup.HighlightColor  = [0.9608 0.9608 0.9608];
            app.GenerationModeButtonGroup.BorderType      = 'none';
            app.GenerationModeButtonGroup.BorderWidth     = 0;
            app.GenerationModeButtonGroup.BackgroundColor = bgColor;
            app.GenerationModeButtonGroup.Layout.Row      = [1 2];
            app.GenerationModeButtonGroup.Layout.Column   = 2;

            app.ParametricProfileSequenceButton = uiradiobutton(app.GenerationModeButtonGroup);
            app.ParametricProfileSequenceButton.Position = [2 2 190 17];

            app.SingleProfileButton = uiradiobutton(app.GenerationModeButtonGroup);
            app.SingleProfileButton.Position = [2 22 190 17];
            app.SingleProfileButton.Value    = true;

            % --- Row 2: Lock display to origin ---
            app.ViewLockGrid = uigridlayout(app.DisplaySettingsGrid);
            app.ViewLockGrid.ColumnWidth     = {'fit', 40};
            app.ViewLockGrid.RowHeight       = {20};
            app.ViewLockGrid.ColumnSpacing   = 5;
            app.ViewLockGrid.Padding         = [0 0 0 0];
            app.ViewLockGrid.Layout.Row      = 2;
            app.ViewLockGrid.Layout.Column   = 1;
            app.ViewLockGrid.BackgroundColor = bgColor;

            app.LockToOriginLabel = uilabel(app.ViewLockGrid);
            app.LockToOriginLabel.Layout.Row    = 1;
            app.LockToOriginLabel.Layout.Column = 1;

            app.LockButton = uibutton(app.ViewLockGrid, 'push');
            app.LockButton.ButtonPushedFcn = @(src,evt) LockButtonPushed(app, evt);
            app.LockButton.Icon            = fullfile(pathToApp, 'Images', 'Lock_open.png');
            app.LockButton.IconAlignment   = 'center';
            app.LockButton.BackgroundColor = [1 1 1];
            app.LockButton.FontWeight      = 'bold';
            app.LockButton.FontColor       = bgColor;
            app.LockButton.Layout.Row      = 1;
            app.LockButton.Layout.Column   = 2;
            app.LockButton.Text            = '';

            % --- Row 3: Plot style controls ---
            app.PlotStyleGrid = uigridlayout(app.DisplaySettingsGrid);
            app.PlotStyleGrid.ColumnWidth     = {'fit','1x','fit','1x','fit','1x','fit'};
            app.PlotStyleGrid.Padding         = [0 0 0 0];
            app.PlotStyleGrid.Layout.Row      = 3;
            app.PlotStyleGrid.Layout.Column   = 1;
            app.PlotStyleGrid.BackgroundColor = bgColor;

            app.GraphLabel = uilabel(app.PlotStyleGrid);
            app.GraphLabel.Layout.Row    = 2;
            app.GraphLabel.Layout.Column = 1;

            app.LinesLabel = uilabel(app.PlotStyleGrid);
            app.LinesLabel.Layout.Row    = 1;
            app.LinesLabel.Layout.Column = 1;

            % Line style dropdown (column 7, row 1)
            app.LineStyleGrid = uigridlayout(app.PlotStyleGrid);
            app.LineStyleGrid.ColumnWidth     = {'fit', '1x'};
            app.LineStyleGrid.RowHeight       = {'1x'};
            app.LineStyleGrid.ColumnSpacing   = 5;
            app.LineStyleGrid.Padding         = [0 0 0 0];
            app.LineStyleGrid.Layout.Row      = 1;
            app.LineStyleGrid.Layout.Column   = 7;
            app.LineStyleGrid.BackgroundColor = bgColor;

            app.LineStyleDropDownLabel = uilabel(app.LineStyleGrid);
            app.LineStyleDropDownLabel.Layout.Row    = 1;
            app.LineStyleDropDownLabel.Layout.Column = 1;

            app.LineStyleDropDown = uidropdown(app.LineStyleGrid);
            app.LineStyleDropDown.ValueChangedFcn = @(src,evt) LineStyleDropDownValueChanged(app, evt);
            app.LineStyleDropDown.BackgroundColor  = [1 1 1];
            app.LineStyleDropDown.Layout.Row       = 1;
            app.LineStyleDropDown.Layout.Column    = 2;

            % Colour picker (column 5, row 1)
            app.ColorGrid = uigridlayout(app.PlotStyleGrid);
            app.ColorGrid.ColumnWidth     = {35, '1x'};
            app.ColorGrid.RowHeight       = {'1x'};
            app.ColorGrid.ColumnSpacing   = 5;
            app.ColorGrid.Padding         = [0 0 0 0];
            app.ColorGrid.Layout.Row      = 1;
            app.ColorGrid.Layout.Column   = 5;
            app.ColorGrid.BackgroundColor = bgColor;

            app.ColorPickerLabel = uilabel(app.ColorGrid);
            app.ColorPickerLabel.BackgroundColor = bgColor;
            app.ColorPickerLabel.Enable          = 'off';
            app.ColorPickerLabel.Layout.Row      = 1;
            app.ColorPickerLabel.Layout.Column   = 1;

            app.ColorPicker = uicolorpicker(app.ColorGrid);
            app.ColorPicker.Value            = [0 0 0];
            app.ColorPicker.Icon             = 'line';
            app.ColorPicker.ValueChangedFcn  = @(src,evt) ColorPickerValueChanged(app, evt);
            app.ColorPicker.Enable           = 'off';
            app.ColorPicker.Layout.Row       = 1;
            app.ColorPicker.Layout.Column    = 2;
            app.ColorPicker.BackgroundColor  = [1 1 1];

            % Thickness spinner (column 3, row 1)
            app.ThicknessGrid = uigridlayout(app.PlotStyleGrid);
            app.ThicknessGrid.ColumnWidth     = {'fit', 55};
            app.ThicknessGrid.RowHeight       = {'1x'};
            app.ThicknessGrid.ColumnSpacing   = 5;
            app.ThicknessGrid.Padding         = [0 0 0 0];
            app.ThicknessGrid.Layout.Row      = 1;
            app.ThicknessGrid.Layout.Column   = 3;
            app.ThicknessGrid.BackgroundColor = bgColor;

            app.ThicknessSpinnerLabel = uilabel(app.ThicknessGrid);
            app.ThicknessSpinnerLabel.BackgroundColor = bgColor;
            app.ThicknessSpinnerLabel.Layout.Row      = 1;
            app.ThicknessSpinnerLabel.Layout.Column   = 1;

            app.ThicknessSpinner = uispinner(app.ThicknessGrid);
            app.ThicknessSpinner.Step                = 0.05;
            app.ThicknessSpinner.LowerLimitInclusive = 'off';
            app.ThicknessSpinner.Limits              = [0 Inf];
            app.ThicknessSpinner.ValueChangedFcn     = @(src,evt) ThicknessSpinnerValueChanged(app, evt);
            app.ThicknessSpinner.Layout.Row          = 1;
            app.ThicknessSpinner.Layout.Column       = 2;
            app.ThicknessSpinner.Value               = 1;

            % Grid checkbox (row 2, column 3)
            app.GridCheckBox = uicheckbox(app.PlotStyleGrid);
            app.GridCheckBox.ValueChangedFcn = @(src,evt) GridCheckBoxValueChanged(app, evt);
            app.GridCheckBox.Layout.Row      = 2;
            app.GridCheckBox.Layout.Column   = 3;
            app.GridCheckBox.Value           = true;

            % Axes checkbox (row 2, column 5)
            app.AxesCheckBox = uicheckbox(app.PlotStyleGrid);
            app.AxesCheckBox.ValueChangedFcn = @(src,evt) AxesCheckBoxValueChanged(app, evt);
            app.AxesCheckBox.Layout.Row      = 2;
            app.AxesCheckBox.Layout.Column   = 5;
            app.AxesCheckBox.Value           = true;

            % Relevant circles button (row 2, column 7)
            app.RelevantCirclesButton = uibutton(app.PlotStyleGrid, 'push');
            app.RelevantCirclesButton.ButtonPushedFcn = @(src,evt) RelevantCirclesButtonPushed(app, evt);
            app.RelevantCirclesButton.BackgroundColor  = [1 1 1];
            app.RelevantCirclesButton.Layout.Row       = 2;
            app.RelevantCirclesButton.Layout.Column    = 7;

            % ---- EXPORT PANEL ----
            app.ExportPanel = uipanel(app.ProfileGridLayout);
            app.ExportPanel.BackgroundColor = bgColor;
            app.ExportPanel.Layout.Row      = 4;
            app.ExportPanel.Layout.Column   = 1;
            app.ExportPanel.FontWeight      = 'bold';

            app.ExportGridLayout = uigridlayout(app.ExportPanel);
            app.ExportGridLayout.ColumnWidth     = {'1x'};
            app.ExportGridLayout.RowHeight       = {'1x', 20};
            app.ExportGridLayout.BackgroundColor = bgColor;

            % ---- PROFILE ACTION BUTTONS ----
            app.ProfileActionButtonsGrid = uigridlayout(app.ProfileGridLayout);
            app.ProfileActionButtonsGrid.ColumnWidth     = {'1x', '1x', '1x'};
            app.ProfileActionButtonsGrid.RowHeight       = {'1x'};
            app.ProfileActionButtonsGrid.Padding         = [0 0 0 0];
            app.ProfileActionButtonsGrid.Layout.Row      = 5;
            app.ProfileActionButtonsGrid.Layout.Column   = 1;

            app.DrawProfileButton = uibutton(app.ProfileActionButtonsGrid, 'push');
            app.DrawProfileButton.ButtonPushedFcn = @(src,evt) DrawProfileButtonPushed(app, evt);
            app.DrawProfileButton.BackgroundColor  = [1 1 1];
            app.DrawProfileButton.FontWeight       = 'bold';
            app.DrawProfileButton.Layout.Row       = 1;
            app.DrawProfileButton.Layout.Column    = 1;

            app.CancelProfileButton = uibutton(app.ProfileActionButtonsGrid, 'push');
            app.CancelProfileButton.ButtonPushedFcn = @(src,evt) CancelProfileButtonPushed(app, evt);
            app.CancelProfileButton.BackgroundColor  = [1 1 1];
            app.CancelProfileButton.FontWeight       = 'bold';
            app.CancelProfileButton.Layout.Row       = 1;
            app.CancelProfileButton.Layout.Column    = 2;

            app.CancelAllProfilesButton = uibutton(app.ProfileActionButtonsGrid, 'push');
            app.CancelAllProfilesButton.ButtonPushedFcn = @(src,evt) CancelAllProfilesButtonPushed(app, evt);
            app.CancelAllProfilesButton.BackgroundColor  = [1 1 1];
            app.CancelAllProfilesButton.FontWeight       = 'bold';
            app.CancelAllProfilesButton.Layout.Row       = 1;
            app.CancelAllProfilesButton.Layout.Column    = 3;

            % ---- ANIMATION TAB ----
            app.AnimationTab = uitab(app.MainTabGroup);
            app.AnimationTab.BackgroundColor = bgColor;

            app.AnimationGridLayout = uigridlayout(app.AnimationTab);
            app.AnimationGridLayout.ColumnWidth     = {'1x'};
            app.AnimationGridLayout.RowHeight       = {'1x', 120, 195, 140, 35};
            app.AnimationGridLayout.RowSpacing      = 20;
            app.AnimationGridLayout.Padding         = [20 20 20 20];
            app.AnimationGridLayout.BackgroundColor = bgColor;

            % Export setting panel (row 4)
            app.ExportSettingPanel = uipanel(app.AnimationGridLayout);
            app.ExportSettingPanel.BackgroundColor = bgColor;
            app.ExportSettingPanel.Layout.Row      = 4;
            app.ExportSettingPanel.Layout.Column   = 1;
            app.ExportSettingPanel.FontWeight      = 'bold';

            % Toothing setting panel (row 3)
            app.ToothingSettingPanel = uipanel(app.AnimationGridLayout);
            app.ToothingSettingPanel.BackgroundColor = bgColor;
            app.ToothingSettingPanel.Layout.Row      = 3;
            app.ToothingSettingPanel.Layout.Column   = 1;
            app.ToothingSettingPanel.FontWeight      = 'bold';

            % Animation setting panel (row 2)
            app.AnimationSettingPanel = uipanel(app.AnimationGridLayout);
            app.AnimationSettingPanel.BackgroundColor = bgColor;
            app.AnimationSettingPanel.Layout.Row      = 2;
            app.AnimationSettingPanel.Layout.Column   = 1;
            app.AnimationSettingPanel.FontWeight      = 'bold';

            app.AnimationSettingGridLayout = uigridlayout(app.AnimationSettingPanel);
            app.AnimationSettingGridLayout.ColumnWidth     = {'1x'};
            app.AnimationSettingGridLayout.RowHeight       = {20, 50};
            app.AnimationSettingGridLayout.BackgroundColor = bgColor;

            app.UpperAnimationSettingGridLayout = uigridlayout(app.AnimationSettingGridLayout);
            app.UpperAnimationSettingGridLayout.RowHeight       = {20};
            app.UpperAnimationSettingGridLayout.ColumnSpacing   = 5;
            app.UpperAnimationSettingGridLayout.Padding         = [0 0 0 0];
            app.UpperAnimationSettingGridLayout.Layout.Row      = 1;
            app.UpperAnimationSettingGridLayout.Layout.Column   = 1;
            app.UpperAnimationSettingGridLayout.BackgroundColor = bgColor;

            app.LowerAnimationSettingGridLayout = uigridlayout(app.AnimationSettingGridLayout);
            app.LowerAnimationSettingGridLayout.ColumnWidth     = {'fit','1x','fit','1x','fit','1x','fit'};
            app.LowerAnimationSettingGridLayout.RowHeight       = {20, 20};
            app.LowerAnimationSettingGridLayout.ColumnSpacing   = 0;
            app.LowerAnimationSettingGridLayout.Padding         = [0 0 0 0];
            app.LowerAnimationSettingGridLayout.Layout.Row      = 2;
            app.LowerAnimationSettingGridLayout.Layout.Column   = 1;
            app.LowerAnimationSettingGridLayout.BackgroundColor = bgColor;

            % Animation buttons (row 5)
            app.DisplayButtonsGridLayout = uigridlayout(app.AnimationGridLayout);
            app.DisplayButtonsGridLayout.ColumnWidth     = {'1x', '1x', '1x'};
            app.DisplayButtonsGridLayout.RowHeight       = {'1x'};
            app.DisplayButtonsGridLayout.Padding         = [0 0 0 0];
            app.DisplayButtonsGridLayout.Layout.Row      = 5;
            app.DisplayButtonsGridLayout.Layout.Column   = 1;
            app.DisplayButtonsGridLayout.BackgroundColor = bgColor;

            app.CancelButton = uibutton(app.DisplayButtonsGridLayout, 'push');
            app.CancelButton.ButtonPushedFcn = @(src,evt) CancelAllProfilesButtonPushed(app, evt);
            app.CancelButton.BackgroundColor  = [1 1 1];
            app.CancelButton.FontWeight       = 'bold';
            app.CancelButton.Layout.Row       = 1;
            app.CancelButton.Layout.Column    = 3;

            app.DisplayButton = uibutton(app.DisplayButtonsGridLayout, 'push');
            app.DisplayButton.ButtonPushedFcn = @(src,evt) DisplayButtonPushed(app, evt);
            app.DisplayButton.BackgroundColor  = [1 1 1];
            app.DisplayButton.FontWeight       = 'bold';
            app.DisplayButton.Layout.Row       = 1;
            app.DisplayButton.Layout.Column    = 1;

            app.StartPauseButton = uibutton(app.DisplayButtonsGridLayout, 'push');
            app.StartPauseButton.ButtonPushedFcn = @(src,evt) StartPauseButtonPushed(app, evt);
            app.StartPauseButton.BackgroundColor  = [1 1 1];
            app.StartPauseButton.FontWeight       = 'bold';
            app.StartPauseButton.Enable           = 'off';
            app.StartPauseButton.Layout.Row       = 1;
            app.StartPauseButton.Layout.Column    = 2;

            % Make the figure visible after all components are built
            app.MainUIFigure.Visible = 'on';
        end
    end

    % ====================================================================
    % App creation and deletion
    % ====================================================================
    methods (Access = public)

        function app = Gear_Model()
            % Constructor: build components then run startup logic.
            createComponents(app);
            startupFcn(app);
            if nargout == 0
                clear app;
            end
        end

        function delete(app)
            % Destructor: safely delete the main figure.
            if isvalid(app.MainUIFigure)
                delete(app.MainUIFigure);
            end
        end
    end
end