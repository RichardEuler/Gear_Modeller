% Copyright (c) 2026 Richard Timko
classdef animationTabParameters < handle
    % animationTabParameters — Dialog showing calculated gear parameters
    % (gear ratio, contact ratio, circle diameters, etc.).

    properties
        F  matlab.ui.Figure
        UpperComponents            % Labels for scalar parameters
        LowerComponents            % Labels for per-gear parameters
        SymbolTextFile             % LaTeX equation text file
    end

    methods
        function obj = animationTabParameters
            obj.UpperComponents = gobjects(4, 2);
            obj.LowerComponents = gobjects(5, 3);
        end

        function create(obj, ut, app)
            % Open the parameters dialog and populate it.

            obj.SymbolTextFile = readlines(fullfile(app.appFolder, 'Text', 'Animation_tab_parameters_equations_2.txt'));

            % Sequential counter for caption lines
            lineIdx = 0;
            function current_number = seq1
                lineIdx = lineIdx + 1;
                current_number = lineIdx;
                if lineIdx >= numel(app.LanguageUtils.TextFileAnimationTabParameters)
                    lineIdx = 0;
                end
            end

            pointer = get(0, 'PointerLocation');
            pointer(2) = pointer(2) - 130;
            obj.F = uifigure('OuterPosition', [pointer 520 260], 'Theme', 'light');
            obj.F.Icon = fullfile(app.appFolder, 'Images', 'Gear_icon.png');
            obj.F.Name = app.LanguageUtils.TextFileAnimationTabParameters{seq1};

            OuterGrid = uigridlayout(obj.F);
            OuterGrid.RowHeight = {'fit','fit'}; OuterGrid.ColumnWidth = {'1x'};
            OuterGrid.Padding = [10 10 10 10]; OuterGrid.ColumnSpacing = 10; OuterGrid.RowSpacing = 10;

            UpperGrid = uigridlayout(OuterGrid);
            UpperGrid.RowHeight = repmat({20},1,4); UpperGrid.ColumnWidth = {250,'fit'};
            UpperGrid.Padding = [0 0 0 0]; UpperGrid.ColumnSpacing = 0; UpperGrid.RowSpacing = 0;
            UpperGrid.Layout.Row = 1; UpperGrid.Layout.Column = 1;

            LowerGrid = uigridlayout(OuterGrid);
            LowerGrid.RowHeight = repmat({20},1,6); LowerGrid.ColumnWidth = {250,'fit',20,'fit'};
            LowerGrid.Padding = [0 0 0 0]; LowerGrid.ColumnSpacing = 0; LowerGrid.RowSpacing = 0;
            LowerGrid.Layout.Row = 2; LowerGrid.Layout.Column = 1;

            for j = 1:2
                for i = 1:size(obj.UpperComponents,1)
                    obj.UpperComponents(i,j) = uilabel(UpperGrid);
                    obj.UpperComponents(i,j).Layout.Row = i;
                    obj.UpperComponents(i,j).Layout.Column = j;
                end
            end

            PinionLabel = uilabel(LowerGrid);
            PinionLabel.Layout.Row = 1; PinionLabel.Layout.Column = 2;
            PinionLabel.HorizontalAlignment = 'center'; PinionLabel.FontAngle = 'italic';

            WheelLabel = uilabel(LowerGrid);
            WheelLabel.Layout.Row = 1; WheelLabel.Layout.Column = 4;
            WheelLabel.HorizontalAlignment = 'center'; WheelLabel.FontAngle = 'italic';

            colId = [1 2 4];
            for j = 1:3
                for i = 1:size(obj.LowerComponents,1)
                    obj.LowerComponents(i,j) = uilabel(LowerGrid);
                    obj.LowerComponents(i,j).Layout.Row = i+1;
                    obj.LowerComponents(i,j).Layout.Column = colId(j);
                end
            end

            % Assign text from the language file
            for i = 1:size(obj.UpperComponents,1)
                obj.UpperComponents(i,1).Text = app.LanguageUtils.TextFileAnimationTabParameters{seq1};
            end
            PinionLabel.Text = app.LanguageUtils.TextFileAnimationTabParameters{seq1};
            WheelLabel.Text  = app.LanguageUtils.TextFileAnimationTabParameters{seq1};
            for i = 1:size(obj.LowerComponents,1)
                obj.LowerComponents(i,1).Text = app.LanguageUtils.TextFileAnimationTabParameters{seq1};
            end

            set(obj.UpperComponents(:,2), 'Interpreter', 'Latex');
            set(obj.LowerComponents(:,[2 3]), 'Interpreter', 'Latex');

            % Correction type indicator
            if all(ut.x == 0)
                obj.UpperComponents(end,2).Text = 'N';
            elseif sum(ut.x) == 0
                obj.UpperComponents(end,2).Text = 'VN';
            else
                obj.UpperComponents(end,2).Text = 'V';
            end

            textValueAssignment(obj, ut);
        end

        function textValueAssignment(obj, ut)
            % Update the numeric values displayed in the dialog.

            symIdx = 0;
            function current_number = seq2
                symIdx = symIdx + 1;
                current_number = symIdx;
                if symIdx >= numel(obj.SymbolTextFile), symIdx = 0; end
            end

            if isempty(ut.AxisAnimation) || ~ut.AxisAnimation.Visible
                values_text = replace(obj.SymbolTextFile, '?', '...');
            else
                values_text = obj.SymbolTextFile;
                ordered = [ut.u  ut.length_action_line  ut.eps_a  ut.d_w'  ut.d'  ...
                           2*ut.gear.p.R_b  2*ut.gear.w.R_b  2*ut.gear.p.R_a  2*ut.gear.w.R_a  ...
                           2*ut.gear.p.R_f  2*ut.gear.w.R_f];
                for i = 1:numel(ordered)
                    if i <= 5, fmt = '%.3f'; else, fmt = '%.2f'; end
                    values_text{i} = regexprep(values_text{i}, '\?', sprintf(fmt, ordered(i)));
                end
            end
            values_text = replace(values_text, 'NaN', '...');

            for i = 1:size(obj.UpperComponents,1)-1
                obj.UpperComponents(i,2).Text = values_text{seq2};
            end
            for i = 1:size(obj.LowerComponents,1)
                obj.LowerComponents(i,2).Text = values_text{seq2};
                obj.LowerComponents(i,3).Text = values_text{seq2};
            end
        end
    end
end
