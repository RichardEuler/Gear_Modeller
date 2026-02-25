% Copyright (c) 2026 Richard Timko
classdef animationTabUtils < handle
    % This class creates some graphical elements inside the animation tab
    % Moreover it includes methods for managing these elements

    properties
        % Text file for symbols of parameters
        SymbolTextFile

        % Properties of the empty space area
        TabLabel
        ModeLabel
        Mode

        % Properties of Animation setting
        AnimationLabels
        AnimationSpinners
        ColorChoice
        Menus
        StyleLine
        Checkers
        CurveDisplay

        % Properties of Gear setting
        Grid3
        ToothingChoiceLabel
        ToothingChoices
        FurtherParametersButton

        ToothingLabels1
        ToothingSymbolLabels1
        ValueEdit1

        ToothingLabels2
        ToothingSymbolLabels2
        MeshingChoices
        ValueEdit2

        % Transparency value
        Transparency
    end

    methods
        function obj = animationTabUtils(app)
            % Class Constructor: creates all necessary graphical elements
            obj.SymbolTextFile = readlines(fullfile("Text","Animation_tab_parameters_equations_1.txt"));
            
            BC = [0.94 0.94 0.94]; % Basic background color

            % Empty space area in the upper space of the tab
            Grid1 = gobjects(2,1);

            Grid1(1) = uigridlayout(app.AnimationGridLayout,"BackgroundColor",BC);
            Grid1(1).Layout.Row = 1; Grid1(1).Layout.Column = 1;
            Grid1(1).ColumnWidth = {'1x'}; Grid1(1).RowHeight = {'1x',20}; Grid1(1).Padding = [0 0 0 0];
            set(Grid1(1),"RowSpacing",10,"ColumnSpacing",10);
            
            obj.TabLabel = uilabel(Grid1(1));
            obj.TabLabel.WordWrap = 1;
            obj.TabLabel.Layout.Row = 1; obj.TabLabel.Layout.Column = 1;
            obj.TabLabel.VerticalAlignment = "top";

            Grid1(2) = uigridlayout(Grid1(1));
            Grid1(2).Layout.Row = 2; Grid1(2).Layout.Column = 1;
            Grid1(2).ColumnWidth = {'fit','fit','1x'}; Grid1(2).RowHeight = {'1x'}; Grid1(2).Padding = [0 0 0 0];
            set(Grid1(2),"RowSpacing",10,"ColumnSpacing",2)
            Grid1(2).BackgroundColor = BC;

            obj.ModeLabel = uilabel(Grid1(2));
            obj.ModeLabel.Layout.Row = 1; obj.ModeLabel.Layout.Column = 1;

            obj.Mode = uidropdown(Grid1(2));
            obj.Mode.ValueChangedFcn = @(src,event) modeSwitcher(obj,app);
            obj.Mode.Layout.Row = 1; obj.Mode.Layout.Column = 2;
            obj.Mode.BackgroundColor = [1 1 1]; obj.Mode.ValueIndex = 1;

            %% Graphical elements for Animation setting panel
            Grid2 = gobjects(5,1);

            for j = 1:2
                Grid2(j) = uigridlayout(app.UpperAnimationSettingGridLayout,"BackgroundColor",BC);
                Grid2(j).ColumnWidth = {'fit','1x',20}; Grid2(j).RowHeight = {'1x'}; Grid2(j).Padding = [0 0 0 0];
                set(Grid2(j),"RowSpacing",0,"ColumnSpacing",5);
                Grid2(j).Layout.Row = 1; Grid2(j).Layout.Column = j;
            end

            for j = 3:5
                Grid2(j) = uigridlayout(app.LowerAnimationSettingGridLayout,"BackgroundColor",BC);
                Grid2(j).RowHeight = {'1x'}; Grid2(j).Padding = [0 0 0 0];
                set(Grid2(j),"RowSpacing",0,"ColumnSpacing",2);
            end
            
            Grid2(3).ColumnWidth = {'fit',60}; Grid2(3).Layout.Row = 1; Grid2(3).Layout.Column = 3;
            Grid2(4).ColumnWidth = {'fit',40}; Grid2(4).Layout.Row = 1; Grid2(4).Layout.Column = 5;
            Grid2(5).ColumnWidth = {'fit',130}; Grid2(5).Layout.Row = 1; Grid2(5).Layout.Column = 7;

            obj.AnimationLabels = gobjects(9,1);
            for j = 1:2
                obj.AnimationLabels(j) = uilabel(Grid2(j)); obj.AnimationLabels(j).Layout.Row = 1; obj.AnimationLabels(j).Layout.Column = 1;
            end
            obj.AnimationLabels(3) = uilabel(app.LowerAnimationSettingGridLayout); obj.AnimationLabels(3).Layout.Row = 1; obj.AnimationLabels(3).Layout.Column = 1;
            for j = 4:6
                obj.AnimationLabels(j) = uilabel(Grid2(j-1)); obj.AnimationLabels(j).Layout.Row = 1; obj.AnimationLabels(j).Layout.Column = 1;
            end
            obj.AnimationLabels(7) = uilabel(app.LowerAnimationSettingGridLayout); obj.AnimationLabels(7).Layout.Row = 2; obj.AnimationLabels(7).Layout.Column = 1;

            obj.AnimationSpinners = gobjects(3,1);
            obj.AnimationSpinners(1) = uispinner(Grid2(1),"Value",20,"LowerLimitInclusive",0,'ValueDisplayFormat','%.0f/hod'); 
            obj.AnimationSpinners(2) = uispinner(Grid2(2),"Value",20,"LowerLimitInclusive",0,'ValueDisplayFormat','%.0f Hz');
            obj.AnimationSpinners(3) = uispinner(Grid2(3),"Value",1,"Step",0.1,"LowerLimitInclusive",0);
            set(obj.AnimationSpinners(1:2),"ValueChangedFcn",@(src, event) updateAnimationSetting(app.AnimationControl,app.AnimationTabUtils))

            for j = [1 3]
                obj.AnimationSpinners(j).Layout.Row = 1; obj.AnimationSpinners(j).Layout.Column = 2; obj.AnimationSpinners(j).Limits = [0 Inf];
            end
            obj.AnimationSpinners(2).Layout.Row = 1; obj.AnimationSpinners(2).Layout.Column = 2; obj.AnimationSpinners(2).Limits = [30*2/60 Inf];

            obj.ColorChoice = gobjects(2,1);
            obj.ColorChoice(1) = uicolorpicker(Grid2(4)); obj.ColorChoice(2) = uicolorpicker(Grid2(4));

            if strcmp(app.OutputFigure.Theme.BaseColorStyle,"light")
                set(obj.ColorChoice,"BackgroundColor",[0.94 0.94 0.94]);
                set(obj.ColorChoice(1),"Value",[0 0 0],"Icon","line")
                set(obj.ColorChoice(2),"Value",[0.85 0.85 0.85],"Icon","fill")
            else
                set(obj.ColorChoice,"BackgroundColor",[0.85 0.85 0.85]);
                set(obj.ColorChoice(1),"Value",[1 1 1],"Icon","line")
                set(obj.ColorChoice(2),"Value",[0.35 0.35 0.35],"Icon","fill")
            end
            obj.ColorChoice(1).Layout.Row = 1; obj.ColorChoice(1).Layout.Column = 2;
            obj.ColorChoice(2).Layout.Row = 1; obj.ColorChoice(2).Layout.Column = 2;

            set(obj.ColorChoice(2),"Enable",0,"Visible",0);

            obj.Menus = gobjects(2,1);
            CM = uicontextmenu(app.MainUIFigure);
            obj.Menus(1) = uimenu(CM,"MenuSelectedFcn",@(src,event) f1(obj));
            
            obj.Menus(2) = uimenu(CM);
            obj.Menus(3) = uimenu(obj.Menus(2),"MenuSelectedFcn",@(src,event) f2(obj),"Checked","on");
            obj.Menus(4) = uimenu(obj.Menus(2),"MenuSelectedFcn",@(src,event) f3(obj));

            % Transparency
            obj.Menus(5) = uimenu(obj.Menus(4),"MenuSelectedFcn",@(src,event) f4(src,obj,1),"Checked","on");
            obj.Menus(6) = uimenu(obj.Menus(4),"MenuSelectedFcn",@(src,event) f4(src,obj,0.75),"Checked","off");
            obj.Menus(7) = uimenu(obj.Menus(4),"MenuSelectedFcn",@(src,event) f4(src,obj,0.5),"Checked","off");
            obj.Menus(8) = uimenu(obj.Menus(4),"MenuSelectedFcn",@(src,event) f4(src,obj,0.25),"Checked","off");
            obj.Menus(9) = uimenu(obj.Menus(4),"MenuSelectedFcn",@(src,event) f4(src,obj,0),"Checked","off");


            function f1(obj)
                set(obj.ColorChoice(1),"Enable",1,"Visible",1);
                set(obj.ColorChoice(2),"Enable",0,"Visible",0);
            end

            function f2(obj)
                set(obj.ColorChoice(1),"Enable",1,"Visible",1);
                set(obj.ColorChoice(2),"Enable",0,"Visible",0);
                set(obj.Menus(3),"Checked","on");
            end

            function f3(obj)
                set(obj.ColorChoice(1),"Enable",0,"Visible",0);
                set(obj.ColorChoice(2),"Enable",1,"Visible",1);
                set(obj.Menus(3),"Checked","off");
            end

            function f4(src,obj,k)
                set(obj.Menus(5:9),"Checked","off"); set(src,"Checked","on");
                obj.Transparency = k;
            end

            obj.AnimationLabels(5).ContextMenu = CM; obj.ColorChoice(1).ContextMenu = CM; obj.ColorChoice(2).ContextMenu = CM;

            obj.StyleLine = uidropdown(Grid2(5),"BackgroundColor",[1 1 1]);
            obj.StyleLine.Layout.Row = 1; obj.StyleLine.Layout.Column = 2; obj.StyleLine.ValueIndex = 1;

            obj.Checkers = gobjects(2,1);
            for j = 1:2
                obj.Checkers(j) = uicheckbox(app.LowerAnimationSettingGridLayout,"Value",1);
                obj.Checkers(j).Layout.Row = 2; obj.Checkers(j).Layout.Column = 2*j+1;
            end

            obj.Checkers(1).ValueChangedFcn = @(src, event) f_grid(src,app);
            obj.Checkers(2).ValueChangedFcn = @(src, event) f_axis(src,app);

            function f_grid(src,app)
                if isgraphics(app.AnimationControl.AxisAnimation)
                    if src.Value
                        grid(app.AnimationControl.AxisAnimation,"on")
                    else
                        grid(app.AnimationControl.AxisAnimation,"off")
                    end
                end
            end

            function f_axis(src,app)
                if isgraphics(app.AnimationControl.AxisAnimation)
                    if src.Value
                        axis(app.AnimationControl.AxisAnimation,"on")
                    else
                        axis(app.AnimationControl.AxisAnimation,"off")
                    end
                end
            end

            obj.CurveDisplay = uibutton(app.LowerAnimationSettingGridLayout,"BackgroundColor",[1 1 1]);
            obj.CurveDisplay.Layout.Row = 2; obj.CurveDisplay.Layout.Column = 7;

            obj.CurveDisplay.ButtonPushedFcn = @(src, event) CurveDisplayFun(app.GraphicalAdditions,app);

            function CurveDisplayFun(ut,app)
                if isgraphics(ut.F)
                    close(ut.F)
                else
                    create(ut,app);
                end
            end

            %% Graphical elements for Gear setting panel
            obj.Grid3 = gobjects(4,1);

            obj.Grid3(1) = uigridlayout(app.ToothingSettingPanel,"BackgroundColor",BC,"Scrollable",1);
            obj.Grid3(1).ColumnWidth = {'1x'}; obj.Grid3(1).RowHeight = {20,'fit','fit'}; obj.Grid3(1).Padding = [10 10 10 10];
            set(obj.Grid3(1),"RowSpacing",15,"ColumnSpacing",10);

            obj.Grid3(2) = uigridlayout(obj.Grid3(1),"BackgroundColor",BC);
            obj.Grid3(2).Layout.Row = 1; obj.Grid3(2).Layout.Column = 1;
            obj.Grid3(2).ColumnWidth = {'fit',170,'1x',155}; obj.Grid3(2).RowHeight = {'1x'}; obj.Grid3(2).Padding = [0 0 0 0];
            set(obj.Grid3(2),"RowSpacing",0,"ColumnSpacing",5);

            obj.ToothingChoiceLabel = uilabel(obj.Grid3(2));
            obj.ToothingChoiceLabel.Layout.Row = 1; obj.ToothingChoiceLabel.Layout.Column = 1;

            ToothingGroup = uibuttongroup(obj.Grid3(2),"BorderType","none","BackgroundColor",BC);
            ToothingGroup.SelectionChangedFcn = @(src,event) switchProfile(obj,app);
            ToothingGroup.Layout.Row = 1; ToothingGroup.Layout.Column = 2;

            obj.ToothingChoices = gobjects(1,2);
            obj.ToothingChoices(1) = uiradiobutton(ToothingGroup,"Position",[1,0,84,20]);
            obj.ToothingChoices(2) = uiradiobutton(ToothingGroup,"Position",[86,0,84,20]);

            obj.FurtherParametersButton = uibutton(obj.Grid3(2),"BackgroundColor",[1 1 1]);
            obj.FurtherParametersButton.Layout.Row = 1; obj.FurtherParametersButton.Layout.Column = 4;
            obj.FurtherParametersButton.ButtonPushedFcn = @(src,event) parametersButtonFun(app);

            function parametersButtonFun(app)
                if isgraphics(app.AnimationParameters.F)
                    delete(app.AnimationParameters.F)
                else
                    create(app.AnimationParameters,app.AnimationControl,app)
                end
            end

            % Parameters of spur gears
            obj.Grid3(3) = uigridlayout(obj.Grid3(1),"BackgroundColor",BC);
            obj.Grid3(3).Layout.Row = 2; obj.Grid3(3).Layout.Column = 1;
            obj.Grid3(3).ColumnWidth = {200,60,'1x',50,50}; obj.Grid3(3).RowHeight = [20 20 20 20 20]; obj.Grid3(3).Padding = [0 0 0 0];
            set(obj.Grid3(3),"RowSpacing",5,"ColumnSpacing",5);
            
            obj.ToothingLabels1 = gobjects(7,1);

            for j = 1:length(obj.ToothingLabels1)
                obj.ToothingLabels1(j) = uilabel(obj.Grid3(3));
                if j >= 4
                    obj.ToothingLabels1(j).Layout.Row = j-2; obj.ToothingLabels1(j).Layout.Column = 1;
                end
            end
            set(obj.ToothingLabels1(1:3),"FontAngle","italic","VerticalAlignment","bottom");
            set(obj.ToothingLabels1(2:3),"HorizontalAlignment","center")
            
            obj.ToothingLabels1(1).Layout.Row = 1; obj.ToothingLabels1(1).Layout.Column = 1;
            obj.ToothingLabels1(2).Layout.Row = 1; obj.ToothingLabels1(2).Layout.Column = 4;
            obj.ToothingLabels1(3).Layout.Row = 1; obj.ToothingLabels1(3).Layout.Column = 5;

            obj.ToothingSymbolLabels1 = gobjects(6,1);
            for j = 1:length(obj.ToothingSymbolLabels1)
                if j <= 4
                    obj.ToothingSymbolLabels1(j) = uilabel(obj.Grid3(3),"Interpreter","latex","HorizontalAlignment","center");
                    obj.ToothingSymbolLabels1(j).Layout.Row = j+1; obj.ToothingSymbolLabels1(j).Layout.Column = 2;
                    obj.ToothingSymbolLabels1(j).Text = obj.SymbolTextFile{j};
                else
                    obj.ToothingSymbolLabels1(j) = uilabel(obj.Grid3(3),"Interpreter","latex","HorizontalAlignment","center","Enable",0,"Visible",0);
                    obj.ToothingSymbolLabels1(j).Layout.Row = 4; obj.ToothingSymbolLabels1(j).Layout.Column = j-1;
                    obj.ToothingSymbolLabels1(j).Text = obj.SymbolTextFile{j};
                end
            end

            obj.ValueEdit1 = gobjects(7,1);
            for j = 1:length(obj.ValueEdit1)
                if j ~= 7
                    obj.ValueEdit1(j) = uieditfield(obj.Grid3(3),"numeric");
                else
                    obj.ValueEdit1(j) = uieditfield(obj.Grid3(3),"numeric","Enable",0,"Visible",0);
                end
            end
            set(obj.ValueEdit1,"BackgroundColor",[1 1 1],"AllowEmpty","off","HorizontalAlignment","center")
            rows = [2 3 3 4 4 5];
            for j = 1:length(obj.ValueEdit1)-1
                obj.ValueEdit1(j).Layout.Row = rows(j);
            end
            obj.ValueEdit1(1).Layout.Column = [4 5]; obj.ValueEdit1(6).Layout.Column = [4 5];
            obj.ValueEdit1(2).Layout.Column = 4; obj.ValueEdit1(4).Layout.Column = 4;
            obj.ValueEdit1(3).Layout.Column = 5; obj.ValueEdit1(5).Layout.Column = 5;
            obj.ValueEdit1(7).Layout.Row = 5; obj.ValueEdit1(7).Layout.Column = 5; obj.ValueEdit1(7).Value = 10;

            for j = 1:length(obj.ValueEdit1)-1
                if ismember(j,[2 3])
                    obj.ValueEdit1(j).ValueChangedFcn = @(src, event) calculationFun(app.AnimationControl,app.AnimationTabUtils,1,j);
                elseif j == 4
                    obj.ValueEdit1(j).ValueChangedFcn = @(src, event) calculationFun(app.AnimationControl,app.AnimationTabUtils,1,0,2);
                elseif j == 5
                    obj.ValueEdit1(j).ValueChangedFcn = @(src, event) calculationFun(app.AnimationControl,app.AnimationTabUtils,1,0,3);
                else
                    obj.ValueEdit1(j).ValueChangedFcn = @(src, event) calculationFun(app.AnimationControl,app.AnimationTabUtils,1);
                end
            end

            % Limits
            set(obj.ValueEdit1([2 3 6 7]),"Limits",[0 Inf],"LowerLimitInclusive",0)
            set(obj.ValueEdit1([4 5]),"LowerLimitInclusive",0,"UpperLimitInclusive",0)
            set(obj.ValueEdit1(6:7),"UpperLimitInclusive",0);

            CM = Utils.ProfileTab.contextMenuModuleUtils(app,obj.ValueEdit1(1));
            obj.ValueEdit1(1).ContextMenu = CM.ContextMenu;

            % Parameters of gear meshing
            obj.Grid3(4) = uigridlayout(obj.Grid3(1),"BackgroundColor",BC);
            obj.Grid3(4).Layout.Row = 3; obj.Grid3(4).Layout.Column = 1;
            obj.Grid3(4).ColumnWidth = {200,60,'1x',16,50}; obj.Grid3(4).RowHeight = [20 20 20 20 20]; obj.Grid3(4).Padding = [0 0 0 0];
            set(obj.Grid3(4),"RowSpacing",5,"ColumnSpacing",5);

            obj.ToothingLabels2 = gobjects(5,1);

            for j = 1:length(obj.ToothingLabels2)
                obj.ToothingLabels2(j) = uilabel(obj.Grid3(4));
                obj.ToothingLabels2(j).Layout.Row = j; obj.ToothingLabels2(j).Layout.Column = 1;
            end
            set(obj.ToothingLabels2(1),"FontAngle","italic","VerticalAlignment","bottom");

            obj.ToothingSymbolLabels2 = gobjects(4,1);
            for j = 1:length(obj.ToothingSymbolLabels2)
                obj.ToothingSymbolLabels2(j) = uilabel(obj.Grid3(4),"Interpreter","latex","HorizontalAlignment","center");
                obj.ToothingSymbolLabels2(j).Layout.Row = j+1; obj.ToothingSymbolLabels2(j).Layout.Column = 2;
                obj.ToothingSymbolLabels2(j).Text = obj.SymbolTextFile{j+6};
            end

            MeshingGroup = uibuttongroup(obj.Grid3(4),"BorderType","none","BackgroundColor",BC);
            MeshingGroup.SelectionChangedFcn = @(src,event) switchGroundVariable(obj);
            MeshingGroup.Layout.Row = [2 5]; MeshingGroup.Layout.Column = 4;

            obj.MeshingChoices = gobjects(4,1);
            for j = 1:length(obj.MeshingChoices)
                obj.MeshingChoices(j) = uiradiobutton(MeshingGroup,"Text","","Position",[1 76-(j-1)*25 15 20]);
            end

            obj.ValueEdit2 = gobjects(4,1);
            values = [0 20 25 0];
            for j = 1:length(obj.ValueEdit2)
                obj.ValueEdit2(j) = uieditfield(obj.Grid3(4),"numeric","Value",values(j));
                obj.ValueEdit2(j).Layout.Row = j+1; obj.ValueEdit2(j).Layout.Column = 5;
                obj.ValueEdit2(j).ValueChangedFcn = @(src, event) calculationFun(app.AnimationControl,app.AnimationTabUtils);
            end

            set(obj.ValueEdit2(1:3),"Limits",[0 Inf])
            set(obj.ValueEdit2(2:4),"Enable",0);
        end
        
        function modeSwitcher(obj,app)
            updateAnimationSetting(app.AnimationControl,app.AnimationTabUtils);
            if obj.Mode.ValueIndex == 1
                gearMeshing(obj,app);
            else
                hobbingProcess(obj,app);
            end
        end

        function gearMeshing(obj,app)
            line = 33;
            obj.ValueEdit1(2).Layout.Column = 4; obj.ValueEdit1(4).Layout.Column = 4;
            obj.ValueEdit1(1).Layout.Row = 2; obj.ValueEdit1(2).Layout.Row = 3; obj.ValueEdit1(4).Layout.Row = 4;

            for j = 1:4
                obj.ToothingLabels1(j+3).Layout.Row = j+1;
                obj.ToothingSymbolLabels1(j).Layout.Row = j+1;
            end
            obj.ValueEdit1(6).Layout.Row = 5;

            if obj.ToothingChoices(1).Value == 1 % Involute gear active
                calculationFun(app.AnimationControl,app.AnimationTabUtils);
                obj.Grid3(4).HandleVisibility = 'on';
                obj.Grid3(1).RowHeight = {20,'fit','fit'};
                obj.Grid3(1).Scrollable = 1;
                obj.ToothingSymbolLabels1(4).Text = "$\alpha \: \mathrm{[^\circ]}$";
                obj.ToothingLabels1(7).Tooltip = "";
            else % Cycloid gear active
                calculationFun(app.AnimationControl,app.AnimationTabUtils);
                obj.Grid3(4).HandleVisibility = 'off';
                obj.Grid3(1).RowHeight = {20,'fit'};
                obj.Grid3(1).Scrollable = 0;
                obj.ToothingSymbolLabels1(4).Text = "$\rho_a \: \mathrm{[mm]}$";
                obj.ToothingLabels1(7).Tooltip = app.LanguageUtils.AnimationTabTextFile{line+1};
            end

            set(obj.ToothingLabels1(1:3),"Enable",1,"Visible",1)
            set(obj.ValueEdit1([3 5]),"Enable",1,"Visible",1);
            set(obj.ToothingSymbolLabels1(5:6),"Enable",0,"Visible",0)

            if isvalid(app.GraphicalAdditions.F)
                set(app.GraphicalAdditions.Components(1,:),"Enable",1)
            end

            app.AnimationExport.ExportRadioButton(2).Enable = 1;
            app.AnimationExport.ExportSpinner.Enable = 1;
        end

        function hobbingProcess(obj,app)
            obj.Grid3(4).HandleVisibility = 'off';
            obj.Grid3(1).RowHeight = {20,'fit'};
            obj.Grid3(1).Scrollable = 0;

            set(obj.ToothingLabels1(1:3),"Enable",0,"Visible",0)
            set(obj.ValueEdit1([3 5]),"Enable",0,"Visible",0);

            obj.ValueEdit1(2).Layout.Column = [4 5]; obj.ValueEdit1(4).Layout.Column = [4 5];
            obj.ValueEdit1(1).Layout.Row = 1; obj.ValueEdit1(2).Layout.Row = 2; obj.ValueEdit1(4).Layout.Row = 3;

            if obj.ToothingChoices(1).Value == 1 % Involute gear active
                set(obj.ToothingSymbolLabels1(5:6),"Enable",0,"Visible",0);
                set(obj.ValueEdit1(7),"Enable",0,"Visible",0)
                for j = 1:4
                    obj.ToothingLabels1(j+3).Layout.Row = j;
                    obj.ToothingSymbolLabels1(j).Layout.Row = j;
                end
                obj.ToothingSymbolLabels1(4).Text = "$\alpha \: \mathrm{[^\circ]}$";
                obj.ValueEdit1(6).Layout.Row = 4;
            else % Cycloid gear active
                set(obj.ToothingSymbolLabels1(5:6),"Enable",1,"Visible",1);
                for j = 1:3
                    obj.ToothingLabels1(j+3).Layout.Row = j;
                    obj.ToothingSymbolLabels1(j).Layout.Row = j;
                end
                set(obj.ValueEdit1(7),"Enable",1,"Visible",1)
                obj.ToothingSymbolLabels1(4).Text = "$\rho \: \mathrm{[mm]}$";
                obj.ToothingLabels1(7).Tooltip = "";
                obj.ValueEdit1(6).Layout.Row = 5;
            end

            if isvalid(app.GraphicalAdditions.F)
                app.GraphicalAdditions.Checkers(2) = 0;
                app.GraphicalAdditions.Components(1,1).Value = 0;
                set(app.GraphicalAdditions.Components(1,:),"Enable",0)
            end

            app.AnimationExport.ExportRadioButton(3).Value = 1;
            app.AnimationExport.ExportRadioButton(2).Enable = 0;

            app.AnimationExport.ExportSpinner.Enable = 0;
        end

        function switchProfile(obj,app)
            % Callback function when switching tooth profile
            app.LanguageUtils = profileSwitcher(app.LanguageUtils,app,app.LanguageUtils.lang_storage);
            ct = app.AnimationControl; % Access to animation control
            line = 38;
            obj.ToothingLabels1(7).Text = app.LanguageUtils.AnimationTabTextFile{line};
            if obj.Mode.ValueIndex == 1 % Gear Meshing active
                if obj.ToothingChoices(1).Value == 1 % Involute gear active
                    obj.Grid3(4).HandleVisibility = 'on';
                    obj.Grid3(1).RowHeight = {20,'fit','fit'};
                    obj.Grid3(1).Scrollable = 1;

                    obj.ToothingSymbolLabels1(4).Text = "$\alpha \: \mathrm{[^\circ]}$";
                    obj.ToothingLabels1(7).Tooltip = "";

                    obj.ValueEdit1(6).Layout.Column = [4 5];
                    set(obj.ValueEdit1(7),"Enable",0,"Visible",0)

                    obj.ValueEdit1(6).Limits = [0 Inf];
                    obj.ValueEdit1(6).Value = rad2deg(ct.alpha);

                    obj.ValueEdit1(4).Limits = [-Inf Inf];
                    obj.ValueEdit1(5).Limits = [-Inf Inf];

                    if isvalid(app.GraphicalAdditions.F)
                        set(app.GraphicalAdditions.Components(3,:),"Enable",1)
                    end
                    calculationFun(app.AnimationControl,app.AnimationTabUtils,0,0,0,true)

                else % Cycloid gear active
                    obj.Grid3(4).HandleVisibility = 'off';
                    obj.Grid3(1).RowHeight = {20,'fit'};
                    obj.Grid3(1).Scrollable = 0;

                    obj.ToothingSymbolLabels1(5).Tooltip = app.LanguageUtils.AnimationTabTextFile{line+2};
                    obj.ToothingSymbolLabels1(6).Tooltip = app.LanguageUtils.AnimationTabTextFile{line+3};
                    obj.ToothingSymbolLabels1(4).Text = "$\rho_a \: \mathrm{[mm]}$";
                    obj.ToothingLabels1(7).Tooltip = app.LanguageUtils.AnimationTabTextFile{line+1};

                    set(obj.ValueEdit1(7),"Enable",1,"Visible",1)
                    obj.ValueEdit1(6).Layout.Column = 4;

                    obj.ValueEdit1(6).Limits(1) = ( 1.25-ct.x(2) ) * ct.m/2;
                    obj.ValueEdit1(6).Limits(2) = ( ct.z(2)-1.25-ct.x(2) ) * ct.m/2;

                    obj.ValueEdit1(7).Limits(1) = ( 1.25-ct.x(1) ) * ct.m/2;
                    obj.ValueEdit1(7).Limits(2) = ( ct.z(1)-1.25-ct.x(1) ) * ct.m/2;

                    obj.ValueEdit1(4).Value = 0;
                    obj.ValueEdit1(5).Value = 0;
 
                    obj.ValueEdit1(4).Limits = [-1 1];
                    obj.ValueEdit1(5).Limits = [-1 1];

                    try
                        obj.ValueEdit1(6).Value = ct.rho_a(1);
                        obj.ValueEdit1(7).Value = ct.rho_a(2);
                    catch ME
                        if strcmp(ME.identifier, 'MATLAB:ui:NumericEditField:invalidValue')
                            obj.ValueEdit1(6).Value = round( sum(obj.ValueEdit1(6).Limits)/2, 3 );
                            obj.ValueEdit1(7).Value = round( sum(obj.ValueEdit1(7).Limits)/2, 3 );
                            calculationFun(ct,app.AnimationTabUtils,1);
                        else
                            rethrow(ME)
                        end
                    end

                    if isvalid(app.GraphicalAdditions.F)
                        app.GraphicalAdditions.Checkers(4) = 0;
                        app.GraphicalAdditions.Components(3,1).Value = 0;
                        set(app.GraphicalAdditions.Components(3,:),"Enable",0)
                    end
                    calculationFun(app.AnimationControl,app.AnimationTabUtils,0,0,0,true)
                end

            else % Hobbing process active
                obj.ToothingLabels1(7).Tooltip = "";
                if obj.ToothingChoices(1).Value == 1 % Involute gear active
                    set(obj.ToothingSymbolLabels1(5:6),"Enable",0,"Visible",0)
                    set(obj.ValueEdit1(7),"Enable",0,"Visible",0)
                    obj.ToothingLabels1(7).Layout.Row = 4;
                    obj.ToothingSymbolLabels1(4).Layout.Row = 4;
                    obj.ValueEdit1(6).Layout.Row = 4; obj.ValueEdit1(6).Layout.Column = [4 5];
                    obj.ToothingSymbolLabels1(4).Text = "$\alpha \: \mathrm{[^\circ]}$";
                    obj.ValueEdit1(6).Value = rad2deg(ct.alpha);

                    if isvalid(app.GraphicalAdditions.F)
                        set(app.GraphicalAdditions.Components(3,:),"Enable",1)
                    end

                else % Cycloid gear active
                    obj.ToothingSymbolLabels1(5).Tooltip = app.LanguageUtils.AnimationTabTextFile{line+2};
                    obj.ToothingSymbolLabels1(6).Tooltip = app.LanguageUtils.AnimationTabTextFile{line+3};
                    obj.ToothingLabels1(7).Text = app.LanguageUtils.AnimationTabTextFile{line};
                    set(obj.ToothingSymbolLabels1(5:6),"Enable",1,"Visible",1);
                    obj.ToothingLabels1(7).Layout.Row = 5;
                    obj.ToothingSymbolLabels1(4).Layout.Row = 5;
                    obj.ValueEdit1(6).Layout.Row = 5; obj.ValueEdit1(6).Layout.Column = 4;
                    set(obj.ValueEdit1(7),"Enable",1,"Visible",1)
                    obj.ToothingSymbolLabels1(4).Text = "$\rho \: \mathrm{[mm]}$";
                    obj.ValueEdit1(6).Value = ct.rho_a(1);
                    obj.ValueEdit1(7).Value = ct.rho_a(2);

                    if isvalid(app.GraphicalAdditions.F)
                        app.GraphicalAdditions.Checkers(4) = 0;
                        app.GraphicalAdditions.Components(3,1).Value = 0;
                        set(app.GraphicalAdditions.Components(3,:),"Enable",0)
                    end
                end
            end
        end

        function switchGroundVariable(obj)
            % Callback function when switching ground variable for gear meshing determination
            numbers = 1:4;
            if obj.MeshingChoices(1).Value == 1
                obj.ValueEdit2(1).Enable = 1;
                excluded_num = numbers; excluded_num(1) = [];
                set(obj.ValueEdit2(excluded_num),"Enable",0);
            elseif obj.MeshingChoices(2).Value == 1
                obj.ValueEdit2(2).Enable = 1;
                excluded_num = numbers; excluded_num(2) = [];
                set(obj.ValueEdit2(excluded_num),"Enable",0);
            elseif obj.MeshingChoices(3).Value == 1
                obj.ValueEdit2(3).Enable = 1;
                excluded_num = numbers; excluded_num(3) = [];
                set(obj.ValueEdit2(excluded_num),"Enable",0);
            else
                obj.ValueEdit2(4).Enable = 1;
                excluded_num = numbers; excluded_num(4) = [];
                set(obj.ValueEdit2(excluded_num),"Enable",0);
            end
        end
    end
end