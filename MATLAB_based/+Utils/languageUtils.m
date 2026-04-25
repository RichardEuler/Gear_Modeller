% Copyright (c) 2026 Richard Timko
classdef languageUtils < handle
    % languageUtils — Manages language selection and text-file loading.
    %
    % All UI text is stored in external text files. This class loads the
    % correct file set for the chosen language (SK / CZ / EN) and triggers
    % the sub-utility functions that assign the text to every component.

    properties
        LanguageChoice (1,1) string {mustBeMember(LanguageChoice,["SK","CZ","EN"])} = "EN"
        lang_storage   % Cell array: {folder_name, prefix}

        % Loaded text-file contents (string arrays)
        OuterTextFile                          string
        HomeTabTextFile                        string
        ProfileTabTextFile                     string
        AnimationTabTextFile                   string

        TextFileProfileTabParameters           string
        TextFileProfileTabParametersEquations  string
        TextFileProfileTabCircle               string

        TextFileAnimationTabGraphicalAdditions string
        TextFileAnimationTabParameters         string
    end

    methods
        function obj = switchProfile(obj, app)
            % Reload the equations text file matching the active toothing type.
            if app.InvoluteButton.Value == 1
                obj.TextFileProfileTabParametersEquations = readlines(fullfile(app.appFolder, 'Text', 'Profile_tab_parameters_equations_involute.txt'));
            else
                obj.TextFileProfileTabParametersEquations = readlines(fullfile(app.appFolder, 'Text', 'Profile_tab_parameters_equations_cycloid.txt'));
            end
        end

        function obj = profileSwitcher(obj, app, lang)
            % Reload the animation-tab text file for the active toothing type.
            if app.AnimationTabUtils.ToothingChoices(1).Value == 1
                file_name = lang{2} + "_animation_tab_involute.txt";
            else
                file_name = lang{2} + "_animation_tab_cycloid.txt";
            end
            obj.AnimationTabTextFile = readlines(fullfile(app.appFolder, 'Text', lang{1}, file_name));
        end

        function obj = languageSetUp(obj, app)
            % Load every text file for the chosen language and populate all UI text.

            switch obj.LanguageChoice
                case "SK"
                    obj.lang_storage = {"Slovak", "SK"};
                    logoFile = "FSI_logo_CZ.png";
                    logoRatio = app.HomeUtils.RatioFacultyCZ;
                case "CZ"
                    obj.lang_storage = {"Czech", "CZ"};
                    logoFile = "FSI_logo_CZ.png";
                    logoRatio = app.HomeUtils.RatioFacultyCZ;
                case "EN"
                    obj.lang_storage = {"English", "EN"};
                    logoFile = "FSI_logo_EN.png";
                    logoRatio = app.HomeUtils.RatioFacultyEN;
            end

            folder = obj.lang_storage{1};
            prefix = obj.lang_storage{2};

            obj.OuterTextFile       = readlines(fullfile(app.appFolder, 'Text', folder, prefix + "_outer.txt"));
            obj.HomeTabTextFile     = readlines(fullfile(app.appFolder, 'Text', folder, prefix + "_home_tab.txt"));
            obj.ProfileTabTextFile  = readlines(fullfile(app.appFolder, 'Text', folder, prefix + "_profile_tab.txt"));
            obj = profileSwitcher(obj, app, obj.lang_storage);

            obj.TextFileProfileTabParameters = readlines(fullfile(app.appFolder, 'Text', folder, prefix + "_profile_tab_parameters.txt"));
            obj.TextFileProfileTabCircle     = readlines(fullfile(app.appFolder, 'Text', folder, prefix + "_profile_tab_circles.txt"));

            obj.TextFileAnimationTabGraphicalAdditions = readlines(fullfile(app.appFolder, 'Text', folder, prefix + "_animation_tab_graphical_additions.txt"));
            obj.TextFileAnimationTabParameters         = readlines(fullfile(app.appFolder, 'Text', folder, prefix + "_animation_tab_parameters.txt"));

            % Update the faculty logo
            app.HomeUtils.FacultyImage.ImageSource = fullfile(app.appFolder, 'Images', logoFile);
            app.HomeUtils.FacultyImage.Position(3) = app.HomeUtils.FacultyImage.Position(4) * logoRatio;

            % Assign the loaded text to all UI components
            Utils.LanguageSubUtils.outerLanguageFun(app, obj.OuterTextFile);
            app.HomeUtils.HomeLabel(1).Text = obj.HomeTabTextFile;
            Utils.LanguageSubUtils.profileTabLanguageFun(app, obj.ProfileTabTextFile);
            Utils.LanguageSubUtils.animationTabLanguageFun(app, obj.AnimationTabTextFile);

            if ~isempty(app.AnimationTabUtils.AnsysDialog) && ...
                    isvalid(app.AnimationTabUtils.AnsysDialog) && ...
                    isgraphics(app.AnimationTabUtils.AnsysDialog.F)
                Utils.LanguageSubUtils.ansysLanguageFun(app.AnimationTabUtils.AnsysDialog);
            end
        end
    end
end
