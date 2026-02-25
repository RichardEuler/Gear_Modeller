% Copyright (c) 2026 Richard Timko
classdef furtherParametersUtils
    properties
        F matlab.ui.Figure % Dialog figure for further parameters
    end

    methods
        function obj = create(obj,app)
        % Create a separate window from the main app. We get a handle 'ProfileTabParametersFigure' to refer to this new window.
        
        pointer_coordinates = get(0,'PointerLocation'); pointer_coordinates(2) = pointer_coordinates(2) - 200;
        obj.F = uifigure("OuterPosition",[pointer_coordinates 530 300],"Theme","light");
        obj.F.Icon = fullfile(app.appFolder,"Images","Gear_icon.png");
        obj.F.Name = app.LanguageUtils.TextFileProfileTabParameters{1};

        % We specify a 4x2 grid (4 rows, 2 columns), whose parent is the new figure created.
        G = uigridlayout(obj.F,"BackgroundColor",[0.94 0.94 0.94],"Scrollable","on");

        % The first column will be just wide enough for the labels, and the second will fill the rest.
        G.ColumnWidth = {"fit", "1x"};
        % All rows have equal height.
        G.RowHeight = {20,20,20,20,20,20,20,20,20};

        app.LanguageUtils = switchProfile(app.LanguageUtils,app);
        for i = 1:numel(app.LanguageUtils.TextFileProfileTabParametersEquations)
                app.ProfileTabManagerUtils.ReadOutLabels(i,1) = uilabel(G);
                app.ProfileTabManagerUtils.ReadOutLabels(i,2) = uilabel(G);
        end

        obj = updateLabels(obj,app);
        updateReadOutValues(app.ProfileTabManagerUtils,app);
        end

        function obj = updateLabels(obj,app)
            app.LanguageUtils = switchProfile(app.LanguageUtils,app);
            % ReadOutPanel labels
            for i = 1:numel(app.LanguageUtils.TextFileProfileTabParametersEquations)
                app.ProfileTabManagerUtils.ReadOutLabels(i,1).Text = app.LanguageUtils.TextFileProfileTabParameters{i+1};
                app.ProfileTabManagerUtils.ReadOutLabels(i,1).Layout.Row = i; app.ProfileTabManagerUtils.ReadOutLabels(i,1).Layout.Column = 1;
                app.ProfileTabManagerUtils.ReadOutLabels(i,1).FontSize = 12;

                app.ProfileTabManagerUtils.ReadOutLabels(i,2).Layout.Row = i; app.ProfileTabManagerUtils.ReadOutLabels(i,2).Layout.Column = 2;
                app.ProfileTabManagerUtils.ReadOutLabels(i,2).Interpreter = "latex";
                app.ProfileTabManagerUtils.ReadOutLabels(i,2).FontSize = 12;
            end
        end
    end
end