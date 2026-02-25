% Copyright (c) 2026 Richard Timko
classdef circlesUtils < handle
    properties
        F matlab.ui.Figure % Dialog figure for cirle activations
        CirclePlot % Graphics handles

        AllCircle matlab.ui.control.CheckBox % Check box component
        Components
        ContextMenuColourPicker

        Checkers logical
        Colours
        Width
        Style
        ActiveColour
    end

    methods
        function obj = circlesUtils(app)
            obj.CirclePlot = gobjects(4,1); % Four circles
            obj.Checkers = [0 0 0 0 0];

            obj.Colours = nan(4,3);
            if app.OutputFigure.Theme.BaseColorStyle == "light"
                obj.Colours(:,:) = 0;
            else
                obj.Colours(:,:) = 1;
            end

            obj.Width = [1 1 1 1];
            obj.Style = [2 1 2 2];

            obj.ActiveColour = [1 1 1 1];
        end

        function obj = create(obj,app)
            % Create a separate window from the main app. We get a handle 'ProfileCirclesFigure' to refer to this new window.
            pointer_coordinates = get(0,'PointerLocation'); pointer_coordinates(2) = pointer_coordinates(2) - 200;
            obj.F = uifigure("OuterPosition",[pointer_coordinates 530 200],"Theme","light");
            obj.F.Icon = fullfile(app.appFolder,"Images","Gear_icon.png");
            obj.F.Name = app.LanguageUtils.TextFileProfileTabCircle{1};
            obj.F.CloseRequestFcn = @(src,event) closeWindow;

            % We specify a 4x2 grid (4 rows, 2 columns), whose parent is the new figure created.
            OuterGrid = uigridlayout(obj.F,"RowHeight",20);
            OuterGrid.ColumnSpacing = 0; OuterGrid.ColumnWidth = "1x"; OuterGrid.RowHeight = {"fit","fit"};

            InnerGrid1 = uigridlayout(OuterGrid);
            InnerGrid1.Layout.Row = 1; InnerGrid1.Layout.Column = 1;
            InnerGrid1.ColumnWidth = {"fit","1x"}; InnerGrid1.RowHeight = {20};
            InnerGrid1.Padding = [0 0 0 0];

            InnerGrid2 = uigridlayout(OuterGrid);
            InnerGrid2.Layout.Row = 2; InnerGrid2.Layout.Column = 1;
            InnerGrid2.ColumnWidth = {"fit", "1x", "1x", "1x"}; InnerGrid2.RowHeight = {20,20,20,20};
            InnerGrid2.Padding = [0 0 0 0];

            set([OuterGrid InnerGrid1 InnerGrid2],"BackgroundColor",[0.94 0.94 0.94]);

            obj.AllCircle = uicheckbox(InnerGrid1);
            obj.AllCircle.Text = app.LanguageUtils.TextFileProfileTabCircle{2};
            obj.AllCircle.Value = obj.Checkers(1); % Default unchecked state
            obj.AllCircle.Layout.Row = 1; obj.AllCircle.Layout.Column = 1; % Position in the grid

            obj.Components = gobjects(numel(app.LanguageUtils.TextFileProfileTabCircle)-2,4);
            for i = 1:size(obj.CirclePlot,1)
                % Checkboxes
                obj.Components(i,1) = uicheckbox(InnerGrid2);
                obj.Components(i,1).Text = app.LanguageUtils.TextFileProfileTabCircle{i+2};
                obj.Components(i,1).Value = obj.Checkers(i+1); % Default unchecked state
                obj.Components(i,1).Layout.Row = i; obj.Components(i,1).Layout.Column = 1; % Position in the inner grid
                obj.Components(i,1).ValueChangedFcn = @(src, event) updateCallback1(src, i+1);

                % ColourPicker
                obj.Components(i,2) = uicolorpicker(InnerGrid2);
                obj.Components(i,2).Value = obj.Colours(i,:);
                obj.Components(i,2).Enable = obj.ActiveColour(i);
                obj.Components(i,2).Layout.Row = i; obj.Components(i,2).Layout.Column = 2; % Position in the inner grid
                obj.ContextMenuColourPicker = Utils.ProfileTab.contextMenuPlotColourUtils(obj.F,app.LanguageUtils.LanguageChoice,obj.Components(i,2));
                obj.Components(i,2).ValueChangedFcn = @(src, event) updateCallback2(src, i);

                % Line width
                obj.Components(i,3) = uispinner(InnerGrid2);
                obj.Components(i,3).Step = 0.1; % Quantity by which the Value property increments or decrements
                obj.Components(i,3).Value = obj.Width(i); % Default line width value
                obj.Components(i,3).Limits(1) = 0; % Set low limit
                obj.Components(i,3).Layout.Row = i; obj.Components(i,3).Layout.Column = 3; % Position in the inner grid
                obj.Components(i,3).ValueChangedFcn = @(src, event) updateCallback3(src, i);

                % Line Style
                obj.Components(i,4) = uidropdown(InnerGrid2);
                obj.Components(i,4).Items = app.tlDropDown.Items; % Line style options
                obj.Components(i,4).Layout.Row = i; obj.Components(i,4).Layout.Column = 4; % Position in the inner grid
                obj.Components(i,4).ValueIndex = obj.Style(i);
                obj.Components(i,4).ValueChangedFcn = @(src, event) updateCallback4(src, i);
            end

            % Callback function
            obj.AllCircle.ValueChangedFcn = @(src, event) updateValueAllCirclesCallback(src);

            function updateCallback1(src, j)
                obj.Checkers(j) = src.Value;
            end

            function updateCallback2(src, j)
                obj.Colours(j,:) = src.Value;
            end

            function updateCallback3(src, j)
                obj.Width(j) = src.Value;
            end

            function updateCallback4(src, j)
                obj.Style(j) = src.ValueIndex;
            end

            function updateValueAllCirclesCallback(src)
                if app.EvolventnButton.Value == 1
                    set(obj.Components(:,1),'Value',src.Value);
                else
                    set(obj.Components([1,3:end],1),'Value',src.Value);
                end
                
                if src.Value == 1
                    obj.Checkers(:) = 1;
                else
                    obj.Checkers(:) = 0;
                end
            end

            function closeWindow
                for j = 1:4
                    obj.ActiveColour(j) = obj.Components(j,2).Enable;
                end
                delete(obj.F);
            end

            if app.EvolventnButton.Value == 0
                obj.Checkers(3) = 0;
                set(obj.Components(2,:),"Enable",0);
            end
        end
    end
end
