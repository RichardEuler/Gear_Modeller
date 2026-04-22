% Copyright (c) 2026 Richard Timko
classdef circlesUtils < handle
    % circlesUtils — Dialog for toggling significant circles (pitch, base,
    % addendum, dedendum) overlaid on the profile plot.

    properties
        F  matlab.ui.Figure
        CirclePlot
        AllCircle matlab.ui.control.CheckBox
        Components;  ContextMenuColourPicker
        Checkers logical;  Colours;  Width;  Style;  ActiveColour
    end

    methods
        function obj = circlesUtils(app)
            obj.CirclePlot = gobjects(4,1);
            obj.Checkers = [0 0 0 0 0];
            obj.Colours = zeros(4,3);
            if strcmp(app.OutputFigure.Theme.BaseColorStyle, 'light')
                obj.Colours(:,:) = 0;
            else
                obj.Colours(:,:) = 1;
            end
            obj.Width  = [1 1 1 1];
            obj.Style  = [2 1 2 2];
            obj.ActiveColour = [1 1 1 1];
        end

        function obj = create(obj, app)
            % Open the circles dialog.
            pointer = get(0,'PointerLocation'); pointer(2) = pointer(2) - 200;
            obj.F = uifigure('OuterPosition', [pointer 530 200], 'Theme', 'light');
            obj.F.Icon = fullfile(app.appFolder, 'Images', 'Gear_icon.png');
            obj.F.Name = app.LanguageUtils.TextFileProfileTabCircle{1};
            obj.F.CloseRequestFcn = @(~,~) closeWindow();

            OuterGrid = uigridlayout(obj.F);
            OuterGrid.ColumnSpacing = 0; OuterGrid.ColumnWidth = {'1x'}; OuterGrid.RowHeight = {'fit','fit'};
            InnerGrid1 = uigridlayout(OuterGrid); InnerGrid1.Layout.Row = 1; InnerGrid1.Layout.Column = 1;
            InnerGrid1.ColumnWidth = {'fit','1x'}; InnerGrid1.RowHeight = {20}; InnerGrid1.Padding = [0 0 0 0];
            InnerGrid2 = uigridlayout(OuterGrid); InnerGrid2.Layout.Row = 2; InnerGrid2.Layout.Column = 1;
            InnerGrid2.ColumnWidth = {'fit','1x','1x','1x'}; InnerGrid2.RowHeight = {20,20,20,20}; InnerGrid2.Padding = [0 0 0 0];
            set([OuterGrid InnerGrid1 InnerGrid2], 'BackgroundColor', [0.94 0.94 0.94]);

            obj.AllCircle = uicheckbox(InnerGrid1);
            obj.AllCircle.Text = app.LanguageUtils.TextFileProfileTabCircle{2};
            obj.AllCircle.Value = obj.Checkers(1);
            obj.AllCircle.Layout.Row = 1; obj.AllCircle.Layout.Column = 1;

            nCircles = numel(app.LanguageUtils.TextFileProfileTabCircle) - 2;
            obj.Components = gobjects(nCircles, 4);

            for i = 1:size(obj.CirclePlot, 1)
                obj.Components(i,1) = uicheckbox(InnerGrid2);
                obj.Components(i,1).Text  = app.LanguageUtils.TextFileProfileTabCircle{i+2};
                obj.Components(i,1).Value = obj.Checkers(i+1);
                obj.Components(i,1).Layout.Row = i; obj.Components(i,1).Layout.Column = 1;
                obj.Components(i,1).ValueChangedFcn = @(src,~) setCheck(src, i+1);

                obj.Components(i,2) = uicolorpicker(InnerGrid2);
                obj.Components(i,2).Value = obj.Colours(i,:); obj.Components(i,2).Enable = obj.ActiveColour(i);
                obj.Components(i,2).Layout.Row = i; obj.Components(i,2).Layout.Column = 2;
                obj.ContextMenuColourPicker = Utils.ProfileTab.contextMenuPlotColourUtils(obj.F, app.LanguageUtils.LanguageChoice, obj.Components(i,2));
                obj.Components(i,2).ValueChangedFcn = @(src,~) setColour(src, i);

                obj.Components(i,3) = uispinner(InnerGrid2);
                obj.Components(i,3).Step = 0.1; obj.Components(i,3).Value = obj.Width(i); obj.Components(i,3).Limits(1) = 0;
                obj.Components(i,3).Layout.Row = i; obj.Components(i,3).Layout.Column = 3;
                obj.Components(i,3).ValueChangedFcn = @(src,~) setWidth(src, i);

                obj.Components(i,4) = uidropdown(InnerGrid2);
                obj.Components(i,4).Items = app.LineStyleDropDown.Items; obj.Components(i,4).ValueIndex = obj.Style(i);
                obj.Components(i,4).Layout.Row = i; obj.Components(i,4).Layout.Column = 4;
                obj.Components(i,4).ValueChangedFcn = @(src,~) setStyle(src, i);
            end

            obj.AllCircle.ValueChangedFcn = @(src,~) toggleAll(src);

            function setCheck(src, j),  obj.Checkers(j) = src.Value;     end
            function setColour(src, j), obj.Colours(j,:) = src.Value;    end
            function setWidth(src, j),  obj.Width(j) = src.Value;        end
            function setStyle(src, j),  obj.Style(j) = src.ValueIndex;   end

            function toggleAll(src)
                if app.InvoluteButton.Value == 1
                    set(obj.Components(:,1), 'Value', src.Value);
                else
                    set(obj.Components([1,3:end],1), 'Value', src.Value);
                end
                obj.Checkers(:) = src.Value;
            end

            function closeWindow()
                for j = 1:4
                    obj.ActiveColour(j) = obj.Components(j,2).Enable;
                end
                delete(obj.F);
            end

            % Disable base-circle row for cycloidal gearing
            if app.InvoluteButton.Value == 0
                obj.Checkers(3) = 0;
                set(obj.Components(2,:), 'Enable', 0);
            end
        end
    end
end
