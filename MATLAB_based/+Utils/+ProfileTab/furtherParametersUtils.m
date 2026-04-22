% Copyright (c) 2026 Richard Timko
classdef furtherParametersUtils
    % furtherParametersUtils — Dialog showing calculated gear parameters
    % (addendum/dedendum heights, circle diameters, etc.) for the Profile tab.

    properties
        F  matlab.ui.Figure  % The dialog figure handle
    end

    methods
        function obj = create(obj, app)
            % Open the additional-parameters dialog.

            pointer = get(0, 'PointerLocation');
            pointer(2) = pointer(2) - 200;
            obj.F = uifigure('OuterPosition', [pointer 530 300], 'Theme', 'light');
            obj.F.Icon = fullfile(app.appFolder, 'Images', 'Gear_icon.png');
            obj.F.Name = app.LanguageUtils.TextFileProfileTabParameters{1};

            G = uigridlayout(obj.F, 'BackgroundColor', [0.94 0.94 0.94], 'Scrollable', 'on');
            G.ColumnWidth = {'fit', '1x'};
            G.RowHeight = {20, 20, 20, 20, 20, 20, 20, 20, 20};

            app.LanguageUtils = switchProfile(app.LanguageUtils, app);

            for i = 1:numel(app.LanguageUtils.TextFileProfileTabParametersEquations)
                app.ProfileTabManagerUtils.ReadOutLabels(i, 1) = uilabel(G);
                app.ProfileTabManagerUtils.ReadOutLabels(i, 2) = uilabel(G);
            end

            obj = updateLabels(obj, app);
            updateReadOutValues(app.ProfileTabManagerUtils, app);
        end

        function obj = updateLabels(obj, app)
            % Refresh the label text from the current language files.
            app.LanguageUtils = switchProfile(app.LanguageUtils, app);

            for i = 1:numel(app.LanguageUtils.TextFileProfileTabParametersEquations)
                app.ProfileTabManagerUtils.ReadOutLabels(i, 1).Text = app.LanguageUtils.TextFileProfileTabParameters{i+1};
                app.ProfileTabManagerUtils.ReadOutLabels(i, 1).Layout.Row = i;
                app.ProfileTabManagerUtils.ReadOutLabels(i, 1).Layout.Column = 1;
                app.ProfileTabManagerUtils.ReadOutLabels(i, 1).FontSize = 12;

                app.ProfileTabManagerUtils.ReadOutLabels(i, 2).Layout.Row = i;
                app.ProfileTabManagerUtils.ReadOutLabels(i, 2).Layout.Column = 2;
                app.ProfileTabManagerUtils.ReadOutLabels(i, 2).Interpreter = 'latex';
                app.ProfileTabManagerUtils.ReadOutLabels(i, 2).FontSize = 12;
            end
        end
    end
end
