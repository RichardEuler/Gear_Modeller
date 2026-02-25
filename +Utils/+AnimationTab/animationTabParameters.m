% Copyright (c) 2026 Richard Timko
classdef animationTabParameters < handle

    properties
        F matlab.ui.Figure
        UpperComponents
        LowerComponents
        SymbolTextFile
    end

    methods
        function obj = animationTabParameters
            obj.UpperComponents = gobjects(4,2);
            obj.LowerComponents = gobjects(5,3);
        end

        function create(obj,ut,app)
            obj.SymbolTextFile = readlines(fullfile("Text","Animation_tab_parameters_equations_2.txt"));

            % Counter function for captions
            function current_number = seq1
                persistent c; % Declare 'counter' as persistent
                if isempty(c)
                    c = 0; % Initialize counter if it's the first call
                end
                c = c + 1; % Increment the counter
                current_number = c; %  Output the current number
                if c >= numel(app.LanguageUtils.TextFileAnimationTabParameters)
                    c = 0; % Reset the counter when the maximum number of lines has been reached
                end
            end

            % Create a separate window from the main app.
            pointer_coordinates = get(0,'PointerLocation'); pointer_coordinates(2) = pointer_coordinates(2) - 260/2;
            obj.F = uifigure("OuterPosition",[pointer_coordinates 520 260],"Theme","light");
            obj.F.Icon = fullfile(app.appFolder,"Images","Gear_icon.png");
            obj.F.Name = app.LanguageUtils.TextFileAnimationTabParameters{seq1};

            % We specify the outer grid (2x1), whose parent is the new figure created
            OuterGrid = uigridlayout(obj.F);
            OuterGrid.RowHeight = {"fit","fit"}; OuterGrid.ColumnWidth = "1x"; OuterGrid.Padding = [10 10 10 10]; OuterGrid.ColumnSpacing = 10; OuterGrid.RowSpacing = 10;

            % We specify inner 2 grids (6x3 and 6x5), whose parent is the outer grid
            UpperGrid = uigridlayout(OuterGrid);
            UpperGrid.RowHeight = repmat({20}, 1, 4); UpperGrid.ColumnWidth = {250,"fit"}; UpperGrid.Padding = [0 0 0 0]; UpperGrid.ColumnSpacing = 0; UpperGrid.RowSpacing = 0;
            UpperGrid.Layout.Row = 1; UpperGrid.Layout.Column = 1;

            LowerGrid = uigridlayout(OuterGrid);
            LowerGrid.RowHeight = repmat({20}, 1, 6); LowerGrid.ColumnWidth = {250,"fit",20,"fit"}; LowerGrid.Padding = [0 0 0 0]; LowerGrid.ColumnSpacing = 0;  LowerGrid.RowSpacing = 0;
            LowerGrid.Layout.Row = 2; LowerGrid.Layout.Column = 1;

            % Components of UpperGrid
            for j = 1:2 % Columns
                for i = 1:size(obj.UpperComponents,1) % Rows
                    obj.UpperComponents(i,j) = uilabel(UpperGrid);
                    obj.UpperComponents(i,j).Layout.Row = i; obj.UpperComponents(i,j).Layout.Column = j; % Odd numbers [1 3]
                end
            end

            % Pinion and wheel labels
            PinionLabel = uilabel(LowerGrid);
            PinionLabel.Layout.Row = 1; PinionLabel.Layout.Column = 2; PinionLabel.HorizontalAlignment = "center"; PinionLabel.FontAngle = "italic";

            WheelLabel = uilabel(LowerGrid);
            WheelLabel.Layout.Row = 1; WheelLabel.Layout.Column = 4; WheelLabel.HorizontalAlignment = "center"; WheelLabel.FontAngle = "italic";

            % Components of LowerGrid
            id = [1 2 4];
            for j = 1:3 % Columns
                for i = 1:size(obj.LowerComponents,1) % Rows
                    obj.LowerComponents(i,j) = uilabel(LowerGrid);
                    obj.LowerComponents(i,j).Layout.Row = i+1; obj.LowerComponents(i,j).Layout.Column = id(j); % Odd numbers [1 3 5]
                end
            end

            % Text assignment
            for i = 1:size(obj.UpperComponents,1) % Rows
                obj.UpperComponents(i,1).Text = app.LanguageUtils.TextFileAnimationTabParameters{seq1};
            end

            PinionLabel.Text = app.LanguageUtils.TextFileAnimationTabParameters{seq1};
            WheelLabel.Text = app.LanguageUtils.TextFileAnimationTabParameters{seq1};

            for i = 1:size(obj.LowerComponents,1) % Rows
                obj.LowerComponents(i,1).Text = app.LanguageUtils.TextFileAnimationTabParameters{seq1};
            end

            set(obj.UpperComponents(:,2),"Interpreter","Latex")
            set(obj.LowerComponents(:,[2 3]),"Interpreter","Latex")

            if all(ut.x == 0)
                obj.UpperComponents(end,2).Text =  "N";
            elseif sum(ut.x) == 0
                obj.UpperComponents(end,2).Text =  "VN";
            else
                obj.UpperComponents(end,2).Text =  "V";
            end

            textValueAssignment(obj,ut);
        end

        function textValueAssignment(obj,ut)
            % Counter function for latex formatted text
            function current_number = seq2
                persistent c; % Declare 'counter' as persistent
                if isempty(c)
                    c = 0; % Initialize counter if it's the first call
                end
                c = c + 1; % Increment the counter
                current_number = c; %  Output the current number
                if c >= numel(obj.SymbolTextFile)
                    c = 0; % Reset the counter when the maximum number of lines has been reached
                end
            end

            if ~ut.AxisAnimation.Visible
                values_text_file = replace(obj.SymbolTextFile, "?", "...");
            else
                values_text_file = obj.SymbolTextFile;
                ordered_values = [ut.u ut.length_action_line ut.eps_a ut.d_w' ut.d' 2*ut.gear.p.R_b 2*ut.gear.w.R_b 2*ut.gear.p.R_a 2*ut.gear.w.R_a 2*ut.gear.p.R_f 2*ut.gear.w.R_f];
                for i = 1:length(ordered_values)
                    % 1. Determine the format based on the index
                    if i <= 5
                        fmt = "%.3f";
                    else
                        fmt = "%.2f";
                    end

                    % 2. Create the formatted number string
                    formattedVal = sprintf(fmt, ordered_values(i));

                    % 3. Replace only the FIRST '?' found in the current string
                    values_text_file{i} = regexprep(values_text_file{i}, '\?', formattedVal);
                end

            end

            values_text_file = replace(values_text_file, "NaN", "...");

            for i = 1:size(obj.UpperComponents,1)-1 % Rows
                obj.UpperComponents(i,2).Text = values_text_file{seq2};
            end

            for i = 1:size(obj.LowerComponents,1) % Rows
                obj.LowerComponents(i,2).Text = values_text_file{seq2};
                obj.LowerComponents(i,3).Text = values_text_file{seq2};
            end
        end
    end
end