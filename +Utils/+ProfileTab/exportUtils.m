% Copyright (c) 2026 Richard Timko
classdef exportUtils < handle
    % exportUtils — Manages the export controls on the Profile tab
    % (image and coordinate export).

    properties
        OpenFolderButton;  ExportButton
        ExportLabels;  ExportRadioButton;  ExportDropdown;  ExportSpinner
        PathEditField;  PathEditFieldLabel
        ExportMenu;  ExportFileName string = "";  ExportLocation string = ""
        ResolutionMenu;  BackgroundMenu;  ColorSpaceMenu
        ExportResolution uint16 = 300
        ExportBackground string = "current"
        ExportColorSpace string = "RGB"
    end

    methods
        function obj = exportUtils(app)
            % Build export-panel UI inside the Profile tab.

            UpperGrid = uigridlayout(app.ExportGridLayout); LowerGrid = uigridlayout(app.ExportGridLayout);
            UpperGrid.BackgroundColor = [0.94 0.94 0.94]; LowerGrid.BackgroundColor = UpperGrid.BackgroundColor;
            UpperGrid.Layout.Row = 1; UpperGrid.Layout.Column = 1;
            UpperGrid.ColumnWidth = {'fit',90,'1x','fit',100,'1x',70}; UpperGrid.RowHeight = [20,20]; UpperGrid.Padding = [0 0 0 0];
            set(UpperGrid,'RowSpacing',4,'ColumnSpacing',5);
            LowerGrid.Layout.Row = 2; LowerGrid.Layout.Column = 1;
            LowerGrid.ColumnWidth = {'1x',30,120}; LowerGrid.RowHeight = {'1x'}; LowerGrid.Padding = [0 0 0 0];

            obj.ExportLabels = gobjects(3,1);
            for i = 1:3, obj.ExportLabels(i) = uilabel(UpperGrid); end
            obj.ExportLabels(1).Layout.Row = 1; obj.ExportLabels(1).Layout.Column = 1;
            obj.ExportLabels(2).Layout.Row = 1; obj.ExportLabels(2).Layout.Column = 4;
            obj.ExportLabels(3).Layout.Row = 2; obj.ExportLabels(3).Layout.Column = 4;

            ExportButtonGroup = uibuttongroup(UpperGrid);
            ExportButtonGroup.Layout.Row = [1 2]; ExportButtonGroup.Layout.Column = 2;
            ExportButtonGroup.BorderType = 'none'; ExportButtonGroup.BackgroundColor = UpperGrid.BackgroundColor;
            obj.ExportRadioButton = gobjects(2,1);
            for i = 1:2
                obj.ExportRadioButton(i) = uiradiobutton(ExportButtonGroup);
                obj.ExportRadioButton(i).Position([1,2,4]) = [3 (20+UpperGrid.RowSpacing)*(i-1)+2 20];
                obj.ExportRadioButton(i).Position(3) = UpperGrid.ColumnWidth{2} - 3;
            end
            obj.ExportRadioButton(2).Value = 1;

            obj.ExportDropdown = gobjects(3,1);
            for i = 1:2
                obj.ExportDropdown(i) = uidropdown(UpperGrid);
                obj.ExportDropdown(i).Layout.Row = 1; obj.ExportDropdown(i).Layout.Column = 5+2*(i-1);
                obj.ExportDropdown(i).BackgroundColor = [1 1 1];
            end
            obj.ExportDropdown(3) = uidropdown(UpperGrid);
            obj.ExportDropdown(3).Layout.Row = 2; obj.ExportDropdown(3).Layout.Column = 7;
            obj.ExportDropdown(3).BackgroundColor = [1 1 1];
            obj.ExportDropdown(2).Items = {'PNG','JPEG','TIFF'};
            obj.ExportDropdown(3).Items = {'TXT','CSV','XLSX (Excel)','PTS (Creo)'};
            obj.ExportDropdown(1).ValueChangedFcn = @(src,~) exportGraphicSwitch(src);

            function exportGraphicSwitch(src)
                if src.ValueIndex == 1
                    obj.ExportDropdown(2).Items = {'PNG','JPEG','TIFF'};
                else
                    obj.ExportDropdown(2).Items = {'PDF','SVG'};
                end
                obj.ExportDropdown(2).ValueIndex = 1;
            end

            obj.ExportSpinner = uispinner(UpperGrid);
            obj.ExportSpinner.Layout.Row = 2; obj.ExportSpinner.Layout.Column = 5;
            obj.ExportSpinner.BackgroundColor = [1 1 1]; obj.ExportSpinner.Step = 1;
            obj.ExportSpinner.RoundFractionalValues = 'on';
            obj.ExportSpinner.Limits = [0 0];
            set(obj.ExportSpinner,'UpperLimitInclusive',1,'LowerLimitInclusive',1);

            GridEditfield = uigridlayout(LowerGrid);
            GridEditfield.Layout.Row = 1; GridEditfield.Layout.Column = 1;
            GridEditfield.ColumnWidth = {'fit','1x'}; GridEditfield.RowHeight = {'1x'}; GridEditfield.Padding = [0 0 0 0];
            obj.PathEditFieldLabel = uilabel(GridEditfield); obj.PathEditFieldLabel.Layout.Row = 1; obj.PathEditFieldLabel.Layout.Column = 1;
            obj.PathEditField = uieditfield(GridEditfield); obj.PathEditField.Layout.Row = 1; obj.PathEditField.Layout.Column = 2;

            obj.OpenFolderButton = uibutton(LowerGrid);
            obj.OpenFolderButton.Layout.Row = 1; obj.OpenFolderButton.Layout.Column = 2;
            obj.OpenFolderButton.Icon = fullfile(app.appFolder,'Images','Folder_icon.png'); obj.OpenFolderButton.Text = '';
            obj.OpenFolderButton.IconAlignment = 'center'; obj.OpenFolderButton.BackgroundColor = [1 1 1];
            obj.OpenFolderButton.ButtonPushedFcn = @(~,~) exportPath(obj,app);

            obj.ExportButton = uibutton(LowerGrid);
            obj.ExportButton.Layout.Row = 1; obj.ExportButton.Layout.Column = 3;
            obj.ExportButton.FontWeight = 'bold'; obj.ExportButton.BackgroundColor = [1 1 1]; obj.ExportButton.Enable = 0;
            obj.ExportButton.ButtonPushedFcn = @(~,~) exportButtonPushed(obj,app);

            % Context menu for image export settings
            ExportContextMenu = uicontextmenu(app.MainUIFigure);
            obj.ExportRadioButton(2).ContextMenu = ExportContextMenu;
            obj.ExportMenu = gobjects(3,1);
            for i = 1:3, obj.ExportMenu(i) = uimenu(ExportContextMenu); end

            resOpts = [50 100 150 200 250 300 350 400 450 500 550 600];
            obj.ResolutionMenu = gobjects(numel(resOpts),1);
            for j = 1:numel(resOpts)
                obj.ResolutionMenu(j) = uimenu(obj.ExportMenu(1),'Text',num2str(resOpts(j))+" DPI",...
                    'MenuSelectedFcn',@(src,~) resFun(src,obj,j));
            end
            obj.ResolutionMenu(6).Checked = 1;

            obj.BackgroundMenu = gobjects(2,1);
            for j = 1:2
                obj.BackgroundMenu(j) = uimenu(obj.ExportMenu(2),'MenuSelectedFcn',@(src,~) bgFun(src,obj,j));
            end
            obj.BackgroundMenu(1).Checked = 1;

            obj.ColorSpaceMenu = gobjects(2,1);
            for j = 1:2
                obj.ColorSpaceMenu(j) = uimenu(obj.ExportMenu(3),'MenuSelectedFcn',@(src,~) csFun(src,obj,j));
            end
            obj.ColorSpaceMenu(1).Checked = 1;

            obj = exportContextMenu(obj,app);

            function resFun(src,o,j)
                src.Checked = 1; idx = 1:numel(resOpts); idx(j) = [];
                set(o.ResolutionMenu(idx),'Checked',0); o.ExportResolution = resOpts(j);
            end
            function bgFun(src,o,j)
                src.Checked = 1; o.BackgroundMenu(3-j).Checked = 0;
                if j==1, o.ExportBackground="current"; else, o.ExportBackground="none"; end
            end
            function csFun(src,o,j)
                src.Checked = 1; o.ColorSpaceMenu(3-j).Checked = 0;
                if j==1, o.ExportColorSpace="RGB"; else, o.ExportColorSpace="Gray"; end
            end
        end

        function obj = exportContextMenu(obj, app)
            % Set localised text on the export context-menu entries.
            txt = Utils.getExportContextMenuText(app.LanguageUtils.LanguageChoice);
            obj.ExportMenu(1).Text = txt.resolution;
            obj.ExportMenu(2).Text = txt.background;
            obj.ExportMenu(3).Text = txt.colorSpace;
            obj.BackgroundMenu(1).Text = txt.bgCurrent;
            obj.BackgroundMenu(2).Text = txt.bgNone;
            obj.ColorSpaceMenu(1).Text = txt.csColor;
            obj.ColorSpaceMenu(2).Text = txt.csBW;
        end

        function exportPath(obj, app)
            title = Utils.getSaveDialogTitle(app.LanguageUtils.LanguageChoice);
            extension = getExportExtension(obj);
            [file_name, file_location] = uiputfile(extension, title, obj.PathEditField.Value);
            if file_name ~= 0
                obj.ExportFileName = file_name; obj.PathEditField.Value = file_name; obj.ExportLocation = file_location;
            end
        end

        function exportButtonPushed(obj, app)
            if obj.ExportLocation == ""
                txt = Utils.getNoPathWarning(app.LanguageUtils.LanguageChoice);
                warndlg(txt.msg, txt.title); return
            end
            str_path = fullfile(obj.ExportLocation, obj.ExportFileName);
            if obj.ExportRadioButton(2).Value == 1
                if obj.ExportDropdown(1).ValueIndex == 1
                    exportgraphics(app.AxisOutput, str_path, 'ContentType','image',...
                        'Resolution',obj.ExportResolution,'BackgroundColor',obj.ExportBackground,'Colorspace',obj.ExportColorSpace);
                else
                    exportgraphics(app.AxisOutput, str_path, 'ContentType','vector','BackgroundColor',obj.ExportBackground);
                end
            else
                if obj.ExportDropdown(3).ValueIndex ~= 4
                    matrix = ["XData","YData"; ...
                        string(app.ProfileTabManagerUtils.ProfilePlot(obj.ExportSpinner.Value).XData'), ...
                        string(app.ProfileTabManagerUtils.ProfilePlot(obj.ExportSpinner.Value).YData')];
                    writematrix(matrix, str_path);
                else
                    matrix = [app.ProfileTabManagerUtils.ProfilePlot(obj.ExportSpinner.Value).XData', ...
                              app.ProfileTabManagerUtils.ProfilePlot(obj.ExportSpinner.Value).YData', ...
                              zeros(numel(app.ProfileTabManagerUtils.ProfilePlot(obj.ExportSpinner.Value).XData),1)];
                    fid = fopen(str_path, 'w');
                    if fid == -1
                        warning('Could not open file for writing: %s', str_path);
                        return;
                    end
                    fprintf(fid, '%.8f %.8f %.0f\n', matrix');
                    fclose(fid);
                end
            end
        end
    end

    methods (Access = private)
        function extension = getExportExtension(obj)
            if obj.ExportRadioButton(2).Value == 1
                if obj.ExportDropdown(1).ValueIndex == 1
                    exts = {{'*.png','PNG'},{'*.jpg','JPEG'},{'*.tif','TIFF'}};
                    extension = exts{obj.ExportDropdown(2).ValueIndex};
                else
                    exts = {{'*.pdf','PDF'},{'*.svg','SVG'}};
                    extension = exts{obj.ExportDropdown(2).ValueIndex};
                end
            else
                exts = {{'*.txt','Text file'},{'*.csv','CSV'},{'*.xlsx','Excel'},{'*.pts','Creo PTS'}};
                extension = exts{obj.ExportDropdown(3).ValueIndex};
            end
        end
    end
end
