% Copyright (c) 2026 Richard Timko
classdef animationGraphicalAdditions < handle
    % animationGraphicalAdditions — Dialog for toggling graphical overlays
    % (action line, pitch/base/addendum/dedendum circles) on the animation plot.

    properties
        F  matlab.ui.Figure       % Dialog figure
        PlotAdditions             % Graphics handles for the overlays
        AllAdditions matlab.ui.control.CheckBox
        Components                % Nx4 array of [checkbox, colorpicker, spinner, dropdown]
        ContextMenuColourPicker

        Checkers  logical         % [allFlag, actionLine, pitch, base, addendum, dedendum]
        Colours                   % Nx3 RGB matrix
        Width                     % Line widths
        Style                     % Line style indices
        ActiveColour              % Colour-picker enable flags
    end

    methods
        function obj = animationGraphicalAdditions(app)
            obj.PlotAdditions = gobjects(5,1);
            obj.Checkers = [0 0 0 0 0 0];

            obj.Colours = zeros(5,3);
            if strcmp(app.OutputFigure.Theme.BaseColorStyle, 'light')
                obj.Colours(:,:) = 0;
            else
                obj.Colours(:,:) = 1;
            end
            obj.Colours(1,:) = [1 0 0];  % Action line defaults to red

            obj.Width  = [2 0.5 0.5 0.5 0.5];
            obj.Style  = [1 2 1 2 2];
            obj.ActiveColour = [1 1 1 1 1];
        end

        function obj = create(obj, app)
            % Open the graphical-additions dialog.
            pointer = get(0,'PointerLocation');
            pointer(2) = pointer(2) - 225;
            obj.F = uifigure('OuterPosition', [pointer 530 225], 'Theme', 'light');
            obj.F.Icon = fullfile(app.appFolder, 'Images', 'Gear_icon.png');
            obj.F.Name = app.LanguageUtils.TextFileAnimationTabGraphicalAdditions{1};
            obj.F.CloseRequestFcn = @(~,~) closeWindow();

            OuterGrid = uigridlayout(obj.F);
            OuterGrid.ColumnSpacing = 0; OuterGrid.ColumnWidth = {'1x'}; OuterGrid.RowHeight = {'fit','fit'};

            InnerGrid1 = uigridlayout(OuterGrid);
            InnerGrid1.Layout.Row = 1; InnerGrid1.Layout.Column = 1;
            InnerGrid1.ColumnWidth = {'fit','1x'}; InnerGrid1.RowHeight = {20}; InnerGrid1.Padding = [0 0 0 0];

            InnerGrid2 = uigridlayout(OuterGrid);
            InnerGrid2.Layout.Row = 2; InnerGrid2.Layout.Column = 1;
            InnerGrid2.ColumnWidth = {'fit','1x','1x','1x'}; InnerGrid2.RowHeight = {20,20,20,20,20};
            InnerGrid2.Padding = [0 0 0 0];

            set([OuterGrid InnerGrid1 InnerGrid2], 'BackgroundColor', [0.94 0.94 0.94]);

            obj.AllAdditions = uicheckbox(InnerGrid1);
            obj.AllAdditions.Text = app.LanguageUtils.TextFileAnimationTabGraphicalAdditions{2};
            obj.AllAdditions.Value = obj.Checkers(1);
            obj.AllAdditions.Layout.Row = 1; obj.AllAdditions.Layout.Column = 1;

            nAdditions = numel(app.LanguageUtils.TextFileAnimationTabGraphicalAdditions) - 2;
            obj.Components = gobjects(nAdditions, 4);

            for i = 1:size(obj.PlotAdditions,1)
                obj.Components(i,1) = uicheckbox(InnerGrid2);
                obj.Components(i,1).Text  = app.LanguageUtils.TextFileAnimationTabGraphicalAdditions{i+2};
                obj.Components(i,1).Value = obj.Checkers(i+1);
                obj.Components(i,1).Layout.Row = i; obj.Components(i,1).Layout.Column = 1;
                obj.Components(i,1).ValueChangedFcn = @(src,~) updateCheck(src, i+1);

                obj.Components(i,2) = uicolorpicker(InnerGrid2);
                obj.Components(i,2).Value  = obj.Colours(i,:);
                obj.Components(i,2).Enable = obj.ActiveColour(i);
                obj.Components(i,2).Layout.Row = i; obj.Components(i,2).Layout.Column = 2;
                obj.ContextMenuColourPicker = Utils.ProfileTab.contextMenuPlotColourUtils(obj.F, app.LanguageUtils.LanguageChoice, obj.Components(i,2));
                obj.Components(i,2).ValueChangedFcn = @(src,~) updateColour(src, i);

                obj.Components(i,3) = uispinner(InnerGrid2);
                obj.Components(i,3).Step = 0.1; obj.Components(i,3).Value = obj.Width(i);
                obj.Components(i,3).Limits(1) = 0;
                obj.Components(i,3).Layout.Row = i; obj.Components(i,3).Layout.Column = 3;
                obj.Components(i,3).ValueChangedFcn = @(src,~) updateWidth(src, i);

                obj.Components(i,4) = uidropdown(InnerGrid2);
                obj.Components(i,4).Items = app.LineStyleDropDown.Items;
                obj.Components(i,4).Layout.Row = i; obj.Components(i,4).Layout.Column = 4;
                obj.Components(i,4).ValueIndex = obj.Style(i);
                obj.Components(i,4).ValueChangedFcn = @(src,~) updateStyle(src, i);
            end

            obj.AllAdditions.ValueChangedFcn = @(src,~) toggleAll(src);

            function updateCheck(src, j),  obj.Checkers(j) = src.Value;     end
            function updateColour(src, j), obj.Colours(j,:) = src.Value;    end
            function updateWidth(src, j),  obj.Width(j) = src.Value;        end
            function updateStyle(src, j),  obj.Style(j) = src.ValueIndex;   end

            function toggleAll(src)
                if app.InvoluteButton.Value == 1
                    set(obj.Components(:,1), 'Value', src.Value);
                else
                    set(obj.Components([1,3:end],1), 'Value', src.Value);
                end
                obj.Checkers(:) = src.Value;
                deactivateUnavailable();
            end

            function deactivateUnavailable()
                % Disable the base-circle row for cycloidal gearing
                if app.AnimationTabUtils.ToothingChoices(1).Value == 1
                    set(obj.Components(3,:), 'Enable', 1);
                else
                    obj.Checkers(4) = 0; obj.Components(3,1).Value = 0;
                    set(obj.Components(3,:), 'Enable', 0);
                end
                % Disable the action-line row in hobbing mode
                if app.AnimationTabUtils.Mode.ValueIndex == 1
                    set(obj.Components(1,:), 'Enable', 1);
                else
                    obj.Checkers(2) = 0; obj.Components(1,1).Value = 0;
                    set(obj.Components(1,:), 'Enable', 0);
                end
            end

            function closeWindow()
                for j = 1:min(4, size(obj.Components,1))
                    obj.ActiveColour(j) = obj.Components(j,2).Enable;
                end
                delete(obj.F);
            end

            deactivateUnavailable();
        end
    end
end
