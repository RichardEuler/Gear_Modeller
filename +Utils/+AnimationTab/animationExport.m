% Copyright (c) 2026 Richard Timko
classdef animationExport < handle
    % animationExport — Manages export controls on the Animation tab
    % (image, coordinate, and video export).

    properties
        OpenFolderButton;  ExportButton
        ExportLabels;  ExportRadioButton;  ExportDropdown;  ExportSpinner
        InfoImage
        PathEditField;  PathEditFieldLabel
        ExportMenu;  ExportFileName string = "";  ExportLocation string = ""
        ResolutionMenu;  BackgroundMenu;  ColorSpaceMenu
        ExportResolution uint16 = 300
        ExportBackground string = "current"
        ExportColorSpace string = "RGB"
        video_export_state = 0
    end

    methods
        function obj = animationExport(app)
            % Build the export panel UI inside the Animation tab.

            ExportGrid = uigridlayout(app.ExportSettingPanel);
            ExportGrid.BackgroundColor = [0.94 0.94 0.94];
            ExportGrid.ColumnWidth = {'1x'}; ExportGrid.RowHeight = {'1x',20}; ExportGrid.Padding = [10 10 10 10];
            set(ExportGrid,'RowSpacing',10,'ColumnSpacing',10);

            UpperGrid = uigridlayout(ExportGrid); LowerGrid = uigridlayout(ExportGrid);
            UpperGrid.BackgroundColor = [0.94 0.94 0.94]; LowerGrid.BackgroundColor = UpperGrid.BackgroundColor;
            UpperGrid.Layout.Row = 1; UpperGrid.Layout.Column = 1;
            UpperGrid.ColumnWidth = {'fit',90,'1x','fit',100,'1x',70}; UpperGrid.RowHeight = [20,20,20]; UpperGrid.Padding = [0 0 0 0];
            set(UpperGrid,'RowSpacing',4,'ColumnSpacing',5);
            LowerGrid.Layout.Row = 2; LowerGrid.Layout.Column = 1;
            LowerGrid.ColumnWidth = {'1x',30,120}; LowerGrid.RowHeight = {'1x'}; LowerGrid.Padding = [0 0 0 0];

            obj.ExportLabels = gobjects(4,1);
            for i = [1 2 4]
                obj.ExportLabels(i) = uilabel(UpperGrid);
            end
            obj.ExportLabels(1).Layout.Row = 1; obj.ExportLabels(1).Layout.Column = 1;
            obj.ExportLabels(2).Layout.Row = 1; obj.ExportLabels(2).Layout.Column = 4;
            obj.ExportLabels(4).Layout.Row = 3; obj.ExportLabels(4).Layout.Column = 4;

            InfoGridLayout = uigridlayout(UpperGrid,'BackgroundColor',[0.94 0.94 0.94]);
            InfoGridLayout.ColumnWidth = {'fit','1x'}; InfoGridLayout.RowHeight = 20; InfoGridLayout.Padding = [0 0 0 0];
            set(InfoGridLayout,'RowSpacing',0,'ColumnSpacing',5);
            InfoGridLayout.Layout.Row = 2; InfoGridLayout.Layout.Column = [4 5];
            obj.ExportLabels(3) = uilabel(InfoGridLayout);
            obj.ExportLabels(3).Layout.Row = 1; obj.ExportLabels(3).Layout.Column = 2;

            obj.InfoImage = uiimage(InfoGridLayout);
            obj.InfoImage.ImageSource = fullfile(app.appFolder, 'Images', 'Info_icon.png');
            obj.InfoImage.Layout.Row = 1; obj.InfoImage.Layout.Column = 1;
            set(obj.InfoImage,'HorizontalAlignment','center','VerticalAlignment','center');
            obj.InfoImage.ScaleMethod = 'fit';

            ExportButtonGroup = uibuttongroup(UpperGrid);
            ExportButtonGroup.Layout.Row = [1 3]; ExportButtonGroup.Layout.Column = 2;
            ExportButtonGroup.BorderType = 'none'; ExportButtonGroup.BackgroundColor = UpperGrid.BackgroundColor;

            obj.ExportRadioButton = gobjects(3,1);
            for i = 1:3
                obj.ExportRadioButton(i) = uiradiobutton(ExportButtonGroup);
                obj.ExportRadioButton(i).Position([1,2,4]) = [3 (20+UpperGrid.RowSpacing)*(i-1)+2 20];
                obj.ExportRadioButton(i).Position(3) = UpperGrid.ColumnWidth{2} - obj.ExportRadioButton(i).Position(1);
            end
            obj.ExportRadioButton(3).Value = 1;

            obj.ExportDropdown = gobjects(4,1);
            obj.ExportDropdown(1) = uidropdown(UpperGrid); obj.ExportDropdown(1).Layout.Row = 1; obj.ExportDropdown(1).Layout.Column = 5;
            for i = 1:3
                obj.ExportDropdown(i+1) = uidropdown(UpperGrid);
                obj.ExportDropdown(i+1).Layout.Row = i; obj.ExportDropdown(i+1).Layout.Column = 7;
            end
            set(obj.ExportDropdown,'BackgroundColor',[1 1 1]);
            obj.ExportDropdown(2).Items = {'PNG','JPEG','TIFF'};
            obj.ExportDropdown(3).Items = {'TXT','CSV','XLSX (Excel)','PTS (Creo)'};
            obj.ExportDropdown(4).Items = {'GIF','AVI','MP4'};
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
            obj.ExportSpinner.Layout.Row = 3; obj.ExportSpinner.Layout.Column = 5;
            obj.ExportSpinner.BackgroundColor = [1 1 1]; obj.ExportSpinner.Step = 1;
            obj.ExportSpinner.RoundFractionalValues = 'on';
            obj.ExportSpinner.Limits(1) = 1;

            % Lower grid
            GridEditfield = uigridlayout(LowerGrid);
            GridEditfield.Layout.Row = 1; GridEditfield.Layout.Column = 1;
            GridEditfield.ColumnWidth = {'fit','1x'}; GridEditfield.RowHeight = {'1x'}; GridEditfield.Padding = [0 0 0 0];
            obj.PathEditFieldLabel = uilabel(GridEditfield); obj.PathEditFieldLabel.Layout.Row = 1; obj.PathEditFieldLabel.Layout.Column = 1;
            obj.PathEditField = uieditfield(GridEditfield); obj.PathEditField.Layout.Row = 1; obj.PathEditField.Layout.Column = 2;

            obj.OpenFolderButton = uibutton(LowerGrid);
            obj.OpenFolderButton.Layout.Row = 1; obj.OpenFolderButton.Layout.Column = 2;
            obj.OpenFolderButton.Icon = fullfile(app.appFolder, 'Images', 'Folder_icon.png'); obj.OpenFolderButton.Text = '';
            obj.OpenFolderButton.IconAlignment = 'center'; obj.OpenFolderButton.BackgroundColor = [1 1 1];
            obj.OpenFolderButton.ButtonPushedFcn = @(~,~) exportPath(obj,app);

            obj.ExportButton = uibutton(LowerGrid);
            obj.ExportButton.Layout.Row = 1; obj.ExportButton.Layout.Column = 3;
            obj.ExportButton.FontWeight = 'bold'; obj.ExportButton.BackgroundColor = [1 1 1]; obj.ExportButton.Enable = 0;
            obj.ExportButton.ButtonPushedFcn = @(~,~) exportButtonPushed(obj,app);

            % Context menu for image export settings
            ExportContextMenu = uicontextmenu(app.MainUIFigure);
            obj.ExportRadioButton(3).ContextMenu = ExportContextMenu;
            obj.ExportMenu = gobjects(3,1);
            for i = 1:3, obj.ExportMenu(i) = uimenu(ExportContextMenu); end

            resolution_options = [50 100 150 200 250 300 350 400 450 500 550 600];
            obj.ResolutionMenu = gobjects(numel(resolution_options),1);
            for j = 1:numel(resolution_options)
                obj.ResolutionMenu(j) = uimenu(obj.ExportMenu(1),'Text',num2str(resolution_options(j))+" DPI",...
                    'MenuSelectedFcn',@(src,~) resolutionFun(src,obj,j));
            end
            obj.ResolutionMenu(6).Checked = 1;

            obj.BackgroundMenu = gobjects(2,1);
            for j = 1:2
                obj.BackgroundMenu(j) = uimenu(obj.ExportMenu(2),'MenuSelectedFcn',@(src,~) backgroundFun(src,obj,j));
            end
            obj.BackgroundMenu(1).Checked = 1;

            obj.ColorSpaceMenu = gobjects(2,1);
            for j = 1:2
                obj.ColorSpaceMenu(j) = uimenu(obj.ExportMenu(3),'MenuSelectedFcn',@(src,~) colorSpaceFun(src,obj,j));
            end
            obj.ColorSpaceMenu(1).Checked = 1;

            obj = exportContextMenu(obj,app);

            function resolutionFun(src,o,j)
                src.Checked = 1; idx = 1:numel(resolution_options); idx(j) = [];
                set(o.ResolutionMenu(idx),'Checked',0); o.ExportResolution = resolution_options(j);
            end
            function backgroundFun(src,o,j)
                src.Checked = 1; o.BackgroundMenu(3-j).Checked = 0;
                if j==1, o.ExportBackground="current"; else, o.ExportBackground="none"; end
            end
            function colorSpaceFun(src,o,j)
                src.Checked = 1; o.ColorSpaceMenu(3-j).Checked = 0;
                if j==1, o.ExportColorSpace="RGB"; else, o.ExportColorSpace="Gray"; end
            end
        end

        function obj = exportContextMenu(obj,app)
            % Set localised text for the export context-menu entries.
            txt = Utils.getExportContextMenuText(app.LanguageUtils.LanguageChoice);
            obj.ExportMenu(1).Text = txt.resolution;
            obj.ExportMenu(2).Text = txt.background;
            obj.ExportMenu(3).Text = txt.colorSpace;
            obj.BackgroundMenu(1).Text = txt.bgCurrent;
            obj.BackgroundMenu(2).Text = txt.bgNone;
            obj.ColorSpaceMenu(1).Text = txt.csColor;
            obj.ColorSpaceMenu(2).Text = txt.csBW;
        end

        function exportPath(obj,app)
            % Open a save-file dialog for the chosen export type.
            title = Utils.getSaveDialogTitle(app.LanguageUtils.LanguageChoice);
            extension = getExportExtension(obj);
            [file_name, file_location] = uiputfile(extension, title, obj.PathEditField.Value);
            if file_name ~= 0
                obj.ExportFileName = file_name;
                obj.PathEditField.Value = file_name;
                obj.ExportLocation = file_location;
            end
        end

        function exportButtonPushed(obj,app)
            % Execute the export operation.
            if obj.ExportLocation == ""
                txt = Utils.getNoPathWarning(app.LanguageUtils.LanguageChoice);
                warndlg(txt.msg, txt.title);
                return
            end

            str_path = fullfile(obj.ExportLocation, obj.ExportFileName);

            if obj.ExportRadioButton(3).Value == 1
                % Image export
                if obj.ExportDropdown(1).ValueIndex == 1
                    exportgraphics(app.AnimationControl.AxisAnimation, str_path, 'ContentType','image',...
                        'Resolution',obj.ExportResolution,'BackgroundColor',obj.ExportBackground,'Colorspace',obj.ExportColorSpace);
                else
                    exportgraphics(app.AnimationControl.AxisAnimation, str_path, 'ContentType','vector','BackgroundColor',obj.ExportBackground);
                end

            elseif obj.ExportRadioButton(2).Value == 1
                % Coordinate export
                [folder,name,ext] = fileparts(str_path);
                if obj.ExportDropdown(3).ValueIndex ~= 4
                    for pw = ["_pinion","_wheel"]
                        if pw == "_pinion"
                            data = app.AnimationControl.tooth.p;
                        else
                            data = app.AnimationControl.tooth.w;
                            data(2,:) = data(2,:) + app.AnimationControl.a_w;
                        end
                        matrix = ["XData","YData"; string(data(1,:)'), string(data(2,:)')];
                        writematrix(matrix, fullfile(folder, name+pw+ext));
                    end
                else
                    for pw = ["_pinion","_wheel"]
                        if pw == "_pinion"
                            data = app.AnimationControl.tooth.p;
                        else
                            data = app.AnimationControl.tooth.w;
                            data(2,:) = data(2,:) + app.AnimationControl.a_w;
                        end
                        matrix = [data(1,:)', data(2,:)', zeros(size(data,2),1)];
                        fid = fopen(fullfile(folder, name+pw+ext), 'w');
                        if fid == -1
                            warning('Could not open file for writing: %s', fullfile(folder, name+pw+ext));
                            continue;
                        end
                        fprintf(fid, '%.8f %.8f %.0f\n', matrix');
                        fclose(fid);
                    end
                end

            else
                % Video export
                app.StartPauseButton.Enable = 'off'; obj.ExportButton.Enable = 0;
                app.AnimationControl.start_state = 0; obj.video_export_state = 1;

                switch obj.ExportDropdown(4).ValueIndex
                    case 1, startAnimation(app.AnimationControl, app, str_path);
                    case 2, startAnimation(app.AnimationControl, app, str_path, 'Motion JPEG AVI');
                    case 3, startAnimation(app.AnimationControl, app, str_path, 'MPEG-4');
                end

                obj.video_export_state = 0; obj.ExportButton.Enable = 1;
            end
        end
    end

    methods (Access = private)
        function extension = getExportExtension(obj)
            % Return the file-extension filter for the current export selection.
            if obj.ExportRadioButton(3).Value == 1
                if obj.ExportDropdown(1).ValueIndex == 1
                    exts = {{'*.png','Portable Network Graphics'},{'*.jpg','JPEG'},{'*.tif','TIFF'}};
                    extension = exts{obj.ExportDropdown(2).ValueIndex};
                else
                    exts = {{'*.pdf','PDF'},{'*.svg','SVG'}};
                    extension = exts{obj.ExportDropdown(2).ValueIndex};
                end
            elseif obj.ExportRadioButton(2).Value == 1
                exts = {{'*.txt','Text file'},{'*.csv','CSV'},{'*.xlsx','Excel'},{'*.pts','Creo PTS'}};
                extension = exts{obj.ExportDropdown(3).ValueIndex};
            else
                exts = {{'*.gif','GIF'},{'*.avi','AVI'},{'*.mp4','MP4'}};
                extension = exts{obj.ExportDropdown(4).ValueIndex};
            end
        end
    end
end
