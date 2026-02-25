% Copyright (c) 2026 Richard Timko
classdef exportUtils < handle
    properties
        OpenFolderButton
        ExportButton

        ExportLabels
        ExportRadioButton
        ExportDropdown
        ExportSpinner

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
    end

    methods
        function obj = exportUtils(app)
            UpperGrid = uigridlayout(app.ExportGridLayout);
            LowerGrid = uigridlayout(app.ExportGridLayout);

            UpperGrid.BackgroundColor = [0.94 0.94 0.94];
            LowerGrid.BackgroundColor = UpperGrid.BackgroundColor;

            UpperGrid.Layout.Row = 1; UpperGrid.Layout.Column = 1;
            UpperGrid.ColumnWidth = {'fit', 90, '1x', 'fit', 100, '1x', 70}; UpperGrid.RowHeight = [20,20]; UpperGrid.Padding = [0 0 0 0];
            set(UpperGrid,"RowSpacing",4,"ColumnSpacing",5);

            LowerGrid.Layout.Row = 2; LowerGrid.Layout.Column = 1;
            LowerGrid.ColumnWidth = {'1x', 30, 120}; LowerGrid.RowHeight = {'1x'}; LowerGrid.Padding = [0 0 0 0];

            obj.ExportLabels = gobjects(3,1);

            % Upper grid components
            for i = 1:numel(obj.ExportLabels)
                obj.ExportLabels(i) = uilabel(UpperGrid);
            end

            obj.ExportLabels(1).Layout.Row = 1; obj.ExportLabels(1).Layout.Column = 1;
            obj.ExportLabels(2).Layout.Row = 1; obj.ExportLabels(2).Layout.Column = 4;
            obj.ExportLabels(3).Layout.Row = 2; obj.ExportLabels(3).Layout.Column = 4;

            ExportButtonGroup = uibuttongroup(UpperGrid);
            ExportButtonGroup.Layout.Row = [1 2]; ExportButtonGroup.Layout.Column = 2;
            ExportButtonGroup.BorderType = 'none';
            ExportButtonGroup.BackgroundColor = UpperGrid.BackgroundColor;

            obj.ExportRadioButton = gobjects(2,1);
            for i = 1:2
                obj.ExportRadioButton(i) = uiradiobutton(ExportButtonGroup);
                obj.ExportRadioButton(i).Position([1,2,4]) = [3 (20+UpperGrid.RowSpacing)*(i-1)+2 20];
                obj.ExportRadioButton(i).Position(3) = UpperGrid.ColumnWidth{2} - obj.ExportRadioButton(i).Position(1);
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
            obj.ExportSpinner.Layout.Row = 2; obj.ExportSpinner.Layout.Column = 5;
            obj.ExportSpinner.BackgroundColor = [1 1 1];
            obj.ExportSpinner.Step = 1;
            obj.ExportSpinner.Limits = [0 0];
            set(obj.ExportSpinner,'UpperLimitInclusive',1,'LowerLimitInclusive',1);

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
            obj.OpenFolderButton.ButtonPushedFcn = @(src,event) exportPath(obj,app);

            obj.ExportButton = uibutton(LowerGrid);
            obj.ExportButton.Layout.Row = 1; obj.ExportButton.Layout.Column = 3;
            obj.ExportButton.FontWeight = 'bold';
            obj.ExportButton.BackgroundColor = obj.OpenFolderButton.BackgroundColor;
            obj.ExportButton.Enable = 0;
            obj.ExportButton.ButtonPushedFcn = @(src,event) exportButtonPushed(obj,app);

            % Context Menu for Image settings
            ExportContextMenu = uicontextmenu(app.MainUIFigure);
            obj.ExportRadioButton(2).ContextMenu = ExportContextMenu;

            obj.ExportMenu = gobjects(3,1);
            for i = 1:numel(obj.ExportMenu)
                obj.ExportMenu(i) = uimenu(ExportContextMenu);
            end

            resolution_options = [50 100 150 200 250 300 350 400 450 500 550 600];
            obj.ResolutionMenu = gobjects(numel(resolution_options),1);
            for j = 1:numel(resolution_options)
                str_resolution = num2str(resolution_options(j)) + " DPI";
                obj.ResolutionMenu(j) = uimenu(obj.ExportMenu(1),"Text",str_resolution,...
                    "MenuSelectedFcn", @(src,event) resolutionFun(src,obj,j));
            end
            obj.ResolutionMenu(6).Checked = 1;

            obj.BackgroundMenu = gobjects(2,1);
            for j = 1:2
                obj.BackgroundMenu(j) = uimenu(obj.ExportMenu(2),...
                    "MenuSelectedFcn", @(src,event) backgroundFun(src,obj,j));
            end
            obj.BackgroundMenu(1).Checked = 1;

            obj.ColorSpaceMenu = gobjects(2,1);
            for j = 1:2
                obj.ColorSpaceMenu(j) = uimenu(obj.ExportMenu(3),...
                    "MenuSelectedFcn", @(src,event) colorSpaceFun(src,obj,j));
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

        function exportPath(obj,app)
            switch app.LanguageUtils.LanguageChoice
                case "SK"
                    title = "Uloženie názvu súboru";
                case "CZ"
                    title = "Uložení názvu souboru";
                case "EN"
                    title = "Save file name";
            end

            if obj.ExportRadioButton(2).Value == 1
                if obj.ExportDropdown(1).ValueIndex == 1
                    switch obj.ExportDropdown(2).ValueIndex
                        case 1
                            extension = {"*.png","Portable Network Graphics"};
                        case 2
                            extension = {"*.jpg","Joint Photographic Experts Group"};
                        case 3
                            extension = {"*.tif","Tagged Image File Format"};
                    end
                else
                    switch obj.ExportDropdown(2).ValueIndex
                        case 1
                            extension = {"*.pdf","Portable Document Format"};
                        case 2
                            extension = {"*.svg","Scalable Vector Graphics"};
                    end
                end
            else
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
            end

            [file_name, file_location] = uiputfile(extension,title,obj.PathEditField.Value);
            if file_name ~= 0
                obj.ExportFileName = file_name;
                obj.PathEditField.Value = file_name;
                obj.ExportLocation = file_location;
            end
        end

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
                if obj.ExportRadioButton(2).Value == 1
                    if obj.ExportDropdown(1).ValueIndex == 1
                        exportgraphics(app.AxisOutput,str_path,"ContentType","image",...
                            "Resolution",obj.ExportResolution,"BackgroundColor",obj.ExportBackground,"Colorspace",obj.ExportColorSpace)
                    else
                        exportgraphics(app.AxisOutput,str_path,"ContentType","vector","BackgroundColor",obj.ExportBackground)
                    end
                else
                    if obj.ExportDropdown(3).ValueIndex ~= 4
                        matrix = ["XData","YData";...
                            app.ProfileTabManagerUtils.ProfilePlot(obj.ExportSpinner.Value).XData',...
                            app.ProfileTabManagerUtils.ProfilePlot(obj.ExportSpinner.Value).YData'];
                        writematrix(matrix,str_path)
                    else
                        matrix = [...
                            app.ProfileTabManagerUtils.ProfilePlot(obj.ExportSpinner.Value).XData',...
                            app.ProfileTabManagerUtils.ProfilePlot(obj.ExportSpinner.Value).YData',...
                            zeros(numel(app.ProfileTabManagerUtils.ProfilePlot(obj.ExportSpinner.Value).XData),1)];
                        fileID = fopen(str_path, 'w');
                        formatSpec = "%.8f %.8f %.0f\n";
                        fprintf(fileID, formatSpec, matrix');
                        fclose(fileID);
                    end
                end
            end
        end
    end
end
