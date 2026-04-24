% Copyright (c) 2026 Richard Timko
classdef homeUtils < handle
    % homeUtils — Helper class for the Home tab.
    %
    % Creates the home-tab UI components (labels, flag images, faculty logo,
    % background image), the output figure with its annotation text, and
    % wires the language-switching callbacks on the flag images.

    properties
        HomeLabel                % Two HTML labels (title and copyright)
        SKImage;  CZImage;  ENImage  % Flag images for language selection
        FacultyImage             % Faculty logo image
        BackgroundHomeImage      % Background image

        RatioFacultyCZ           % Aspect ratio of the CZ faculty logo
        RatioFacultyEN           % Aspect ratio of the EN faculty logo

        Screen                   % Primary monitor dimensions
        FigureText               % Annotation used as a standby placeholder
        LineWindowsPosition      % Horizontal split between the main and output windows
    end

    methods
        function obj = homeUtils(app)
            % Build all home-tab UI components and the output figure.

            % Create image and label components (initially hidden)
            obj.BackgroundHomeImage = uiimage(app.HomeTab, 'Visible', 'off');
            obj.FacultyImage        = uiimage(app.HomeTab, 'Visible', 'off');
            obj.SKImage             = uiimage(app.HomeTab, 'Visible', 'off');
            obj.CZImage             = uiimage(app.HomeTab, 'Visible', 'off');
            obj.ENImage             = uiimage(app.HomeTab, 'Visible', 'off');

            obj.HomeLabel = gobjects(1, 2);
            for i = 1:2
                obj.HomeLabel(i) = uilabel(app.HomeTab, 'Visible', 'off', 'Interpreter', 'html', 'WordWrap', 'on');
            end

            % Set image sources
            obj.SKImage.ImageSource             = fullfile(app.appFolder, 'Images', 'SK_flag.svg');
            obj.CZImage.ImageSource             = fullfile(app.appFolder, 'Images', 'CZ_flag.svg');
            obj.ENImage.ImageSource             = fullfile(app.appFolder, 'Images', 'EN_flag.svg');
            obj.FacultyImage.ImageSource        = fullfile(app.appFolder, 'Images', 'FSI_logo_CZ.png');
            obj.BackgroundHomeImage.ImageSource = fullfile(app.appFolder, 'Images', 'HomeBackground.png');

            % Position the main window on the left side of the screen
            obj.Screen = get(groot, 'MonitorPositions');
            obj.LineWindowsPosition = 535;
            app.MainUIFigure.Position = [obj.Screen(1,1) 50 obj.LineWindowsPosition obj.Screen(1,4)-80];

            % Wait for the home tab to settle its position
            waitfor(app.HomeTab, 'Position');
            difference = 1;
            while difference ~= 0
                d1 = app.HomeTab.Position;
                waitfor(app.HomeTab, 'Position');
                d2 = app.HomeTab.Position;
                difference = d2 - d1;
            end

            % Create the output figure and its axes
            app.OutputFigure = figure('Visible', 'on');
            app.OutputFigure.Position = [obj.LineWindowsPosition+5  50  ...
                obj.Screen(1,3)-obj.LineWindowsPosition-5  obj.Screen(1,4)-108];
            app.OutputFigure.Icon = fullfile(app.appFolder, 'Images', 'Gear_icon.png');

            app.AxisOutput = axes(app.OutputFigure, 'Visible', 'off', 'HandleVisibility', 'off');

            % Standby placeholder text in the centre of the figure
            obj.FigureText = annotation(app.OutputFigure, 'textbox', [0.5 0.5 0.01 0.01], ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment',   'middle', ...
                'EdgeColor',           'none', ...
                'FitBoxToText',        'on', ...
                'FontSize',            24, ...
                'FontWeight',          'bold');

            % Compute aspect ratios for the two faculty-logo variants
            img = imread(fullfile(app.appFolder, 'Images', 'FSI_logo_CZ.png'));
            obj.RatioFacultyCZ = size(img, 2) / size(img, 1);
            img = imread(fullfile(app.appFolder, 'Images', 'FSI_logo_EN.png'));
            obj.RatioFacultyEN = size(img, 2) / size(img, 1);
            img = imread(fullfile(app.appFolder, 'Images', 'HomeBackground.png'));
            RatioHomeBackground = size(img, 2) / size(img, 1);

            % Position images within the home tab
            obj.FacultyImage.Position([1 2 4]) = [20  app.HomeTab.InnerPosition(4)-(75+20)  75];

            obj.BackgroundHomeImage.Position([1 2 4]) = [0  0  app.HomeTab.InnerPosition(4)];
            obj.BackgroundHomeImage.Position(3) = obj.BackgroundHomeImage.Position(4) * RatioHomeBackground;

            flag_dim = 20;
            obj.SKImage.Position = [app.HomeTab.InnerPosition(3)-40  obj.FacultyImage.Position(2)+obj.FacultyImage.Position(4)-flag_dim  flag_dim  flag_dim];
            obj.CZImage.Position = [app.HomeTab.InnerPosition(3)-40  obj.SKImage.Position(2)-flag_dim-7.5  flag_dim  flag_dim];
            obj.ENImage.Position = [app.HomeTab.InnerPosition(3)-40  obj.CZImage.Position(2)-flag_dim-7.5  flag_dim  flag_dim];

            obj.HomeLabel(1).Position(4) = 400;
            obj.HomeLabel(1).Position(1:3) = [obj.FacultyImage.Position(1)  ...
                obj.FacultyImage.Position(2)-20-obj.HomeLabel(1).Position(4)  ...
                obj.SKImage.Position(1)+flag_dim-obj.FacultyImage.Position(1)];

            set(obj.HomeLabel(2), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'FontColor', [0.3 0.3 0.3]);
            obj.HomeLabel(2).Position(4) = 50;
            obj.HomeLabel(2).Position(1:3) = [obj.HomeLabel(1).Position(1)  20  obj.HomeLabel(1).Position(3)];
            obj.HomeLabel(2).Text = char(169) + " 2026 Richard Timko | v1.1.1";

            % Make all home-tab components visible
            set([obj.BackgroundHomeImage  obj.FacultyImage  obj.SKImage  ...
                 obj.CZImage  obj.ENImage  obj.HomeLabel], 'Visible', 'on');

            % Wire language-switch callbacks on the flag images
            obj.SKImage.ImageClickedFcn = @(~,~) switchLanguage(app, 'SK');
            obj.CZImage.ImageClickedFcn = @(~,~) switchLanguage(app, 'CZ');
            obj.ENImage.ImageClickedFcn = @(~,~) switchLanguage(app, 'EN');

            function switchLanguage(app, language)
                % Change the application language and refresh all UI text
                app.LanguageUtils.LanguageChoice = language;
                app.LanguageUtils   = languageSetUp(app.LanguageUtils, app);
                app.ExportUtils     = exportContextMenu(app.ExportUtils, app);
                app.AnimationExport = exportContextMenu(app.AnimationExport, app);
            end
        end
    end
end