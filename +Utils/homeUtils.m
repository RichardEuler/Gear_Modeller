% Copyright (c) 2026 Richard Timko
classdef homeUtils < handle
    % Auxiliary functions for home tab

    properties
        % Text properties
        HomeLabel

        % Image properties
        SKImage
        CZImage
        ENImage
        FacultyImage
        BackgroundHomeImage

        % Image ratios
        RatioFacultyCZ % Aspect ratio of the FSI logo image in Czech
        RatioFacultyEN % FSI logo image aspect ratio in English

        % Other properties
        Screen % Screen dimensions
        FigureText % Centered annotation for the output figure on standby
        LineWindowsPosition % Horizontal position of the common window border
    end

    methods
        function obj = homeUtils(app)
            % UI Components creations
            obj.BackgroundHomeImage = uiimage(app.HomeTab,"Visible","off");
            obj.FacultyImage = uiimage(app.HomeTab,"Visible","off");
            obj.SKImage = uiimage(app.HomeTab,"Visible","off");
            obj.CZImage = uiimage(app.HomeTab,"Visible","off");
            obj.ENImage = uiimage(app.HomeTab,"Visible","off");

            obj.HomeLabel = gobjects(1,2);
            for i = 1:2
                obj.HomeLabel(i) = uilabel(app.HomeTab,"Visible","off","Interpreter","html","WordWrap","on");
            end

            % Setting the path of the image source
            obj.SKImage.ImageSource = fullfile(app.appFolder,"Images","SK_flag.svg");
            obj.CZImage.ImageSource = fullfile(app.appFolder,"Images","CZ_flag.svg");
            obj.ENImage.ImageSource = fullfile(app.appFolder,"Images","EN_flag.svg");
            obj.FacultyImage.ImageSource = fullfile(app.appFolder,"Images","FSI_logo_CZ.png");
            obj.BackgroundHomeImage.ImageSource = fullfile(app.appFolder,"Images","HomeBackground.png");


            % Visual settings
            obj.Screen = get(groot, 'MonitorPositions');
            obj.LineWindowsPosition = 535;
            app.MainUIFigure.Position = [obj.Screen(1,1) 50 obj.LineWindowsPosition obj.Screen(1,4)-80];

            waitfor(app.HomeTab,"Position");
            
            difference = 1;
            while difference ~= 0
                d1 = app.HomeTab.Position;
                waitfor(app.HomeTab,"Position");
                d2 = app.HomeTab.Position;
                difference = d2 - d1;
            end

            % Output figure
            app.OutputFigure = figure(1);
            set(app.OutputFigure,"Renderer","opengl")
            app.AxisOutput = axes(app.OutputFigure,"Visible",0,"HandleVisibility","off");
            set(app.OutputFigure,"Position",[obj.LineWindowsPosition+5 50 obj.Screen(1,3)-obj.LineWindowsPosition-5 obj.Screen(1,4)-108],...
                "Icon",fullfile(app.appFolder,"Images","Gear_icon.png"));
            obj.FigureText = annotation(app.OutputFigure,'textbox', [0.5 0.5 0.01 0.01], ... % [x y w h], w and h will auto-adjust with FitBoxToText
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'EdgeColor', 'none', ... % Hide the box border
                'FitBoxToText', 'on', ... % Automatically adjust box size to fit text
                'FontSize', 24, ...
                'FontWeight', 'bold');

            % Image positioning
            img = imread(fullfile(app.appFolder,"Images","FSI_logo_CZ.png")); obj.RatioFacultyCZ = size(img,2)/size(img,1);
            img = imread(fullfile(app.appFolder,"Images","FSI_logo_EN.png")); obj.RatioFacultyEN = size(img,2)/size(img,1);
            img = imread(fullfile(app.appFolder,"Images","HomeBackground.png")); RatioHomeBackground = size(img,2)/size(img,1);

            obj.FacultyImage.Position([1:2,4]) = [20 app.HomeTab.InnerPosition(4)-(75+20) 75];

            obj.BackgroundHomeImage.Position([1:2,4]) = [0 0 app.HomeTab.InnerPosition(4)];
            obj.BackgroundHomeImage.Position(3) = obj.BackgroundHomeImage.Position(4)*RatioHomeBackground;

            flag_dim = 20;
            obj.SKImage.Position = [app.HomeTab.InnerPosition(3)-40 obj.FacultyImage.Position(2)+obj.FacultyImage.Position(4)-flag_dim flag_dim flag_dim];
            obj.CZImage.Position = [app.HomeTab.InnerPosition(3)-40 obj.SKImage.Position(2)-flag_dim-7.5 flag_dim flag_dim];
            obj.ENImage.Position = [app.HomeTab.InnerPosition(3)-40 obj.CZImage.Position(2)-flag_dim-7.5 flag_dim flag_dim];

            obj.HomeLabel(1).Position(4) = 400;
            obj.HomeLabel(1).Position(1:3) = [obj.FacultyImage.Position(1) obj.FacultyImage.Position(2)-20-obj.HomeLabel(1).Position(4) ...
                                           obj.SKImage.Position(1)+flag_dim-obj.FacultyImage.Position(1)];
            
            set(obj.HomeLabel(2),"VerticalAlignment","bottom","HorizontalAlignment","right","FontColor",[0.3 0.3 0.3]);
            obj.HomeLabel(2).Position(4) = 50;
            obj.HomeLabel(2).Position(1:3) = [obj.HomeLabel(1).Position(1) 20 obj.HomeLabel(1).Position(3)];
            obj.HomeLabel(2).Text = "&copy; 2026 Richard Timko | v1.0-beta";

            set([obj.BackgroundHomeImage obj.FacultyImage obj.SKImage ...
                 obj.CZImage obj.ENImage obj.HomeLabel],"Visible","on");

            % Callback Functions of the images when clicked on
            obj.SKImage.ImageClickedFcn = @(src,event) ImageClicked("SK");
            obj.CZImage.ImageClickedFcn = @(src,event) ImageClicked("CZ");
            obj.ENImage.ImageClickedFcn = @(src,event) ImageClicked("EN");

            function ImageClicked(language)
            app.LanguageUtils.LanguageChoice = language;
            app.LanguageUtils = languageSetUp(app.LanguageUtils,app);
            app.ExportUtils = exportContextMenu(app.ExportUtils,app);
        end
        end
    end
end