% Copyright (c) 2026 Richard Timko
classdef animationExport < handle
    properties
        OpenFolderButton
        ExportButton

        ExportLabels
        ExportRadioButton
        ExportDropdown
        ExportSpinner
        InfoImage

        PathEditField
        PathEditFieldLabel

        ExportMenu
        ExportFileName string = ""
        ExportLocation string = ""

        ResolutionMenu
        BackgroundMenu
        ColorSpaceMenu
        
        ExportResolution uint16 = 300
        ExportBackground string = "current"
        ExportColorSpace string = "RGB"
        video_export_state = 0
    end

    methods
        function obj = animationExport(app)
            ExportGrid = uigridlayout(app.ExportSettingPanel);
            ExportGrid.BackgroundColor = [0.94 0.94 0.94];
            ExportGrid.ColumnWidth = {'1x'}; ExportGrid.RowHeight = {'1x',20}; ExportGrid.Padding = [10 10 10 10];
            set(ExportGrid,"RowSpacing",10,"ColumnSpacing",10);

            UpperGrid = uigridlayout(ExportGrid);
            LowerGrid = uigridlayout(ExportGrid);

            UpperGrid.BackgroundColor = [0.94 0.94 0.94];
            LowerGrid.BackgroundColor = UpperGrid.BackgroundColor;

            UpperGrid.Layout.Row = 1; UpperGrid.Layout.Column = 1;
            UpperGrid.ColumnWidth = {'fit', 90, '1x', 'fit', 100, '1x', 70}; UpperGrid.RowHeight = [20,20,20]; UpperGrid.Padding = [0 0 0 0];
            set(UpperGrid,"RowSpacing",4,"ColumnSpacing",5);

            LowerGrid.Layout.Row = 2; LowerGrid.Layout.Column = 1;
            LowerGrid.ColumnWidth = {'1x', 30, 120}; LowerGrid.RowHeight = {'1x'}; LowerGrid.Padding = [0 0 0 0];

            obj.ExportLabels = gobjects(4,1);

            % Upper grid components
            for i = [1 2 4]
                obj.ExportLabels(i) = uilabel(UpperGrid);
            end

            obj.ExportLabels(1).Layout.Row = 1; obj.ExportLabels(1).Layout.Column = 1;
            obj.ExportLabels(2).Layout.Row = 1; obj.ExportLabels(2).Layout.Column = 4;
            obj.ExportLabels(4).Layout.Row = 3; obj.ExportLabels(4).Layout.Column = 4;

            InfoGridLayout = uigridlayout(UpperGrid);
            InfoGridLayout.BackgroundColor = [0.94 0.94 0.94];
            InfoGridLayout.ColumnWidth = {'fit','1x'}; InfoGridLayout.RowHeight = 20; InfoGridLayout.Padding = [0 0 0 0];
            set(InfoGridLayout,"RowSpacing",0,"ColumnSpacing",5);
            InfoGridLayout.Layout.Row = 2; InfoGridLayout.Layout.Column = [4 5];

            obj.ExportLabels(3) = uilabel(InfoGridLayout);
            obj.ExportLabels(3).Layout.Row = 1; obj.ExportLabels(3).Layout.Column = 2;
            
            obj.InfoImage = uiimage(InfoGridLayout);
            obj.InfoImage.ImageSource = fullfile("Images","Info_icon.png");
            obj.InfoImage.Layout.Row = 1; obj.InfoImage.Layout.Column = 1;
            set(obj.InfoImage,'HorizontalAlignment','center','VerticalAlignment','center')
            obj.InfoImage.ScaleMethod = 'fit';

            ExportButtonGroup = uibuttongroup(UpperGrid);
            ExportButtonGroup.Layout.Row = [1 3]; ExportButtonGroup.Layout.Column = 2;
            ExportButtonGroup.BorderType = 'none';
            ExportButtonGroup.BackgroundColor = UpperGrid.BackgroundColor;
            
            obj.ExportRadioButton = gobjects(3,1);
            for i = 1:3
                obj.ExportRadioButton(i) = uiradiobutton(ExportButtonGroup);
                obj.ExportRadioButton(i).Position([1,2,4]) = [3 (20+UpperGrid.RowSpacing)*(i-1)+2 20];
                obj.ExportRadioButton(i).Position(3) = UpperGrid.ColumnWidth{2} - obj.ExportRadioButton(i).Position(1);
            end
            obj.ExportRadioButton(3).Value = 1;

            obj.ExportDropdown = gobjects(4,1);
            obj.ExportDropdown(1) = uidropdown(UpperGrid);
            obj.ExportDropdown(1).Layout.Row = 1; obj.ExportDropdown(1).Layout.Column = 5;

            for i = 1:3
                obj.ExportDropdown(i+1) = uidropdown(UpperGrid);
                obj.ExportDropdown(i+1).Layout.Row = i; obj.ExportDropdown(i+1).Layout.Column = 7;
            end
            set(obj.ExportDropdown,"BackgroundColor",[1 1 1]);

            obj.ExportDropdown(2).Items = {'PNG','JPEG','TIFF'};
            obj.ExportDropdown(3).Items = {'TXT','CSV','XLSX (Excel)','PTS (Creo)'};
            obj.ExportDropdown(4).Items = {'GIF','AVI','MP4'};

            % Callback function
            obj.ExportDropdown(1).ValueChangedFcn = @(src,event) exportGraphicSwitch(src);

            function exportGraphicSwitch(src)
                if src.ValueIndex == 1
                    obj.ExportDropdown(2).ValueIndex = 1;
                    obj.ExportDropdown(2).Items = {'PNG','JPEG','TIFF'};
                else
                    obj.ExportDropdown(2).ValueIndex = 1;
                    obj.ExportDropdown(2).Items = {'PDF','SVG'};
                end
            end

            obj.ExportSpinner = uispinner(UpperGrid);
            obj.ExportSpinner.Layout.Row = 3; obj.ExportSpinner.Layout.Column = 5;
            obj.ExportSpinner.BackgroundColor = [1 1 1];
            obj.ExportSpinner.Step = 1;
            obj.ExportSpinner.Limits(1) = 1;
            set(obj.ExportSpinner,'LowerLimitInclusive',1);

            % Lower grid components
            GridEditfield = uigridlayout(LowerGrid);
            GridEditfield.Layout.Row = 1; GridEditfield.Layout.Column = 1;
            GridEditfield.ColumnWidth = {'fit','1x'}; GridEditfield.RowHeight = {'1x'}; GridEditfield.Padding = [0 0 0 0];

            obj.PathEditFieldLabel = uilabel(GridEditfield);
            obj.PathEditFieldLabel.Layout.Row = 1;obj.PathEditFieldLabel.Layout.Column = 1;

            obj.PathEditField = uieditfield(GridEditfield);
            obj.PathEditField.Layout.Row = 1; obj.PathEditField.Layout.Column = 2;

            obj.OpenFolderButton = uibutton(LowerGrid);
            obj.OpenFolderButton.Layout.Row = 1; obj.OpenFolderButton.Layout.Column = 2;
            obj.OpenFolderButton.Icon = fullfile("Images","Folder_icon.png");
            obj.OpenFolderButton.Text = '';
            obj.OpenFolderButton.IconAlignment = "center";
            obj.OpenFolderButton.BackgroundColor = [1 1 1];
            % Callback function
            obj.OpenFolderButton.ButtonPushedFcn = @(src,event) exportPath(obj,app);

            obj.ExportButton = uibutton(LowerGrid);
            obj.ExportButton.Layout.Row = 1; obj.ExportButton.Layout.Column = 3;
            obj.ExportButton.FontWeight = 'bold';
            obj.ExportButton.BackgroundColor = obj.OpenFolderButton.BackgroundColor;
            obj.ExportButton.Enable = 0;
            % Callback function
            obj.ExportButton.ButtonPushedFcn = @(src,event) exportButtonPushed(obj,app);

            % Context Menu for Image settings
            ExportContextMenu = uicontextmenu(app.MainUIFigure);
            obj.ExportRadioButton(3).ContextMenu = ExportContextMenu;

            obj.ExportMenu = gobjects(3,1);
            for i = 1:numel(obj.ExportMenu)
                obj.ExportMenu(i) = uimenu(ExportContextMenu);
            end

            resolution_options = [50 100 150 200 250 300 350 400 450 500 550 600];
            obj.ResolutionMenu = gobjects(numel(resolution_options),1);
            for j = 1:numel(resolution_options)
                str_resolution = num2str(resolution_options(j)) + " DPI";
                obj.ResolutionMenu(j) = uimenu(obj.ExportMenu(1),"Text",str_resolution,...
                    "MenuSelectedFcn", @(src,event) resolutionFun(src,obj,j)); % Callback function
            end
            obj.ResolutionMenu(6).Checked = 1;

            obj.BackgroundMenu = gobjects(2,1);
            for j = 1:2
                obj.BackgroundMenu(j) = uimenu(obj.ExportMenu(2),...
                    "MenuSelectedFcn", @(src,event) backgroundFun(src,obj,j)); % Callback function
            end
            obj.BackgroundMenu(1).Checked = 1;

            obj.ColorSpaceMenu = gobjects(2,1);
            for j = 1:2
                obj.ColorSpaceMenu(j) = uimenu(obj.ExportMenu(3),...
                    "MenuSelectedFcn", @(src,event) colorSpaceFun(src,obj,j)); % Callback function
            end
            obj.ColorSpaceMenu(1).Checked = 1;

            obj = exportContextMenu(obj,app);

            % Callback functions
            function resolutionFun(src,obj,j)
                src.Checked = 1;
                other_elements = 1:numel(resolution_options);
                other_elements(j) = [];
                set(obj.ResolutionMenu(other_elements),"Checked",0);
                obj.ExportResolution = resolution_options(j);
            end

            function backgroundFun(src,obj,j)
                src.Checked = 1;
                other_element = 1:2;
                other_element(j) = [];
                obj.BackgroundMenu(other_element).Checked = 0;
                if j == 1
                    obj.ExportBackground = "current";
                else
                    obj.ExportBackground = "none";
                end
            end

            function colorSpaceFun(src,obj,j)
                src.Checked = 1;
                other_element = 1:2;
                other_element(j) = [];
                obj.ColorSpaceMenu(other_element).Checked = 0;
                if j == 1
                    obj.ExportColorSpace = "RGB";
                else
                    obj.ExportColorSpace = "Gray";
                end
            end
        end

        function obj = exportContextMenu(obj,app)
            switch app.LanguageUtils.LanguageChoice
                case "SK"
                    obj.ExportMenu(1).Text = "Rozlíšenie";
                    obj.ExportMenu(2).Text = "Farba pozadia";
                    obj.ExportMenu(3).Text = "Typ farebného priestoru";

                    obj.BackgroundMenu(1).Text = "Aktuálna";
                    obj.BackgroundMenu(2).Text = "Žiadna";

                    obj.ColorSpaceMenu(1).Text = "Farebný";
                    obj.ColorSpaceMenu(2).Text = "Čiernobiely";
                case "CZ"
                    obj.ExportMenu(1).Text = "Rozlišení";
                    obj.ExportMenu(2).Text = "Barva pozadí";
                    obj.ExportMenu(3).Text = "Typ barevného prostoru";

                    obj.BackgroundMenu(1).Text = "Aktuální";
                    obj.BackgroundMenu(2).Text = "Žádná";

                    obj.ColorSpaceMenu(1).Text = "Barebný";
                    obj.ColorSpaceMenu(2).Text = "Černobíly";
                case "EN"
                    obj.ExportMenu(1).Text = "Resolution";
                    obj.ExportMenu(2).Text = "Background color";
                    obj.ExportMenu(3).Text = "Color space type";

                    obj.BackgroundMenu(1).Text = "Current";
                    obj.BackgroundMenu(2).Text = "None";

                    obj.ColorSpaceMenu(1).Text = "Colorful";
                    obj.ColorSpaceMenu(2).Text = "Black-and-white";
            end
        end

        %% Start - Folder Icon Button pushed callback function 
        function exportPath(obj,app)
            switch app.LanguageUtils.LanguageChoice
                case "SK"
                    title = "Uloženie názvu súboru";
                case "CZ"
                    title = "Uložení názvu souboru";
                case "EN"
                    title = "Save file name";
            end

            if obj.ExportRadioButton(3).Value == 1 % Image selection
                if obj.ExportDropdown(1).ValueIndex == 1 % Raster selection
                    switch obj.ExportDropdown(2).ValueIndex
                        case 1
                            extension = {"*.png","Portable Network Graphics"};
                        case 2
                            extension = {"*.jpg","Joint Photographic Experts Group"};
                        case 3
                            extension = {"*.tif","Tagged Image File Format"};
                    end
                else % Vector selection
                    switch obj.ExportDropdown(2).ValueIndex
                        case 1
                            extension = {"*.pdf","Portable Document Format"};
                        case 2
                            extension = {"*.svg","Scalable Vector Graphics"};
                    end
                end

            elseif obj.ExportRadioButton(2).Value == 1 % Coordintes selection
                switch obj.ExportDropdown(3).ValueIndex
                    case 1
                        extension = {"*.txt","Text file"};
                    case 2
                        extension = {"*.csv","Comma-separated values"};
                    case 3
                        extension = {"*.xlsx","Excel XML Spreadsheet"};
                    case 4
                        extension = {"*.pts","Creo Points File"};
                end

            else % Video selection
                switch obj.ExportDropdown(4).ValueIndex
                    case 1
                        extension = {"*.gif","Graphics interchange format"};
                    case 2
                        extension = {"*.avi","Audio video interleave"};
                    case 3
                        extension = {"*.mp4","MPEG-4"};
                end
            end

            [file_name, file_location] = uiputfile(extension,title,obj.PathEditField.Value);
            if file_name ~= 0
                obj.ExportFileName = file_name;
                obj.PathEditField.Value = file_name;
                obj.ExportLocation = file_location;
            end
        end
        %% End - Folder Icon Button pushed callback function 

        % Callback function of the EXPORT BUTTON
        function exportButtonPushed(obj,app)
            if obj.ExportLocation == ""
                switch app.LanguageUtils.LanguageChoice
                case "SK"
                    str = "Nebola zadaná cesta súboru.";
                    str_title = "Varovanie";
                case "CZ"
                    str = "Nebyla zadaná cesta souboru.";
                    str_title = "Varování";
                case "EN"
                    str = "No file path was specified.";
                    str_title = "Warning";
                end
                warndlg(str,str_title);

            else
                str_path = join([obj.ExportLocation obj.ExportFileName]);
                
                if obj.ExportRadioButton(3).Value == 1 % Image selection
                    if obj.ExportDropdown(1).ValueIndex == 1 % Raster selection
                        exportgraphics(app.AnimationControl.AxisAnimation,str_path,"ContentType","image",...
                            "Resolution",obj.ExportResolution,"BackgroundColor",obj.ExportBackground,"Colorspace",obj.ExportColorSpace)
                    else % Vector selection
                        exportgraphics(app.AnimationControl.AxisAnimation,str_path,"ContentType","vector","BackgroundColor",obj.ExportBackground)
                    end

                elseif obj.ExportRadioButton(2).Value == 1 % Coordinates selection
                    [folder, name, ext] = fileparts(str_path);
                    if obj.ExportDropdown(3).ValueIndex ~= 4 % Other selections
                        matrix = ["XData","YData";...
                            app.AnimationControl.tooth.p(1,:)',...
                            app.AnimationControl.tooth.p(2,:)'];
                        pinion_or_wheel = "_pinion";
                        str_path = fullfile(folder, name + pinion_or_wheel + ext);
                        writematrix(matrix,str_path);

                        matrix = ["XData","YData";...
                            app.AnimationControl.tooth.w(1,:)',...
                            app.AnimationControl.tooth.w(2,:)' + app.AnimationControl.a_w];
                        pinion_or_wheel = "_wheel";
                        str_path = fullfile(folder, name + pinion_or_wheel + ext);
                        writematrix(matrix,str_path);

                    else % Creo PTS selection
                        pinion_or_wheel = "_pinion";
                        str_path = fullfile(folder, name + pinion_or_wheel + ext);
                        matrix = [...
                            app.AnimationControl.tooth.p(1,:)',...
                            app.AnimationControl.tooth.p(2,:)',...
                            zeros(numel(app.AnimationControl.tooth.p(1,:)),1)];
                        fileID = fopen(str_path, 'w');
                        formatSpec = "%.8f %.8f %.0f\n";
                        fprintf(fileID, formatSpec, matrix');
                        fclose(fileID);

                        pinion_or_wheel = "_wheel";
                        str_path = fullfile(folder, name + pinion_or_wheel + ext);
                        matrix = [...
                            app.AnimationControl.tooth.w(1,:)',...
                            app.AnimationControl.tooth.w(2,:)' + app.AnimationControl.a_w,...
                            zeros(numel(app.AnimationControl.tooth.w(1,:)),1)];
                        fileID = fopen(str_path, 'w');
                        formatSpec = "%.8f %.8f %.0f\n";
                        fprintf(fileID, formatSpec, matrix');
                        fclose(fileID);
                    end

                else % Video selection
                    app.StartPauseButton.Enable = 0;
                    obj.ExportButton.Enable = 0;
                    app.AnimationControl.start_state = 0;
                    obj.video_export_state = 1;
                    
                    if obj.ExportDropdown(4).ValueIndex == 1 % GIF selection
                        startAnimation(app.AnimationControl,app,str_path);
                    else
                        if obj.ExportDropdown(4).ValueIndex == 2 % AVI selection
                            startAnimation(app.AnimationControl,app,str_path,"Motion JPEG AVI");
                        else % MP4 selection
                            startAnimation(app.AnimationControl,app,str_path,"MPEG-4");
                        end

                    end

                    obj.video_export_state = 0;
                    obj.ExportButton.Enable = 1;
                end
            end
        end
    end
end
