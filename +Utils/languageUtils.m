% Copyright (c) 2026 Richard Timko
classdef languageUtils < handle
    % Auxiliary counter functions for language management

    properties
        LanguageChoice (1,1) string {mustBeMember(LanguageChoice,["SK","CZ","EN"])} = "EN" % Selected language
        lang_storage

        % Text files
        OuterTextFile string % Outer language text file
        HomeTabTextFile string % Language text file for Home Tab
        ProfileTabTextFile string % Language text file for Profile Tab
        AnimationTabTextFile string % Language text file for Animation Tab

        % Auxilary text files for profile Tab (pop-up windows)
        TextFileProfileTabParameters string % Figure language text file for parameters in Profile Tab
        TextFileProfileTabParametersEquations string % Figure text file for mathematical expressions in Profile Tab
        TextFileProfileTabCircle string % Figure language text file for significant circles in Profile Tab

        TextFileAnimationTabGraphicalAdditions string % Figure language text file for graphical additions in Animation Tab
        TextFileAnimationTabParameters string % Figure language text file for further parameters in Animation Tab
    end

    methods
        function obj = switchProfile(obj,app)
            if app.EvolventnButton.Value == 1
                obj.TextFileProfileTabParametersEquations = readlines(fullfile(app.appFolder,"Text","Profile_tab_parameters_equations_involute.txt"));
            else
                obj.TextFileProfileTabParametersEquations = readlines(fullfile(app.appFolder,"Text","Profile_tab_parameters_equations_cycloid.txt"));
            end
        end

        function obj = profileSwitcher(obj,app,lang)
            if app.AnimationTabUtils.ToothingChoices(1).Value == 1
                file_name = lang{2} + "_animation_tab_involute.txt";
                obj.AnimationTabTextFile = readlines(fullfile(app.appFolder,"Text",lang{1},file_name));
            else
                file_name = lang{2} + "_animation_tab_cykloid.txt";
                obj.AnimationTabTextFile = readlines(fullfile(app.appFolder,"Text",lang{1},file_name));
            end
        end

        function obj = languageSetUp(obj,app)
            switch obj.LanguageChoice
                case "SK"
                    obj.lang_storage = {"Slovak", "SK"};
                    obj.OuterTextFile = readlines(fullfile(app.appFolder,"Text","Slovak","SK_outer.txt"));
                    obj.HomeTabTextFile = readlines(fullfile(app.appFolder,"Text","Slovak","SK_home_tab.txt"));
                    obj.ProfileTabTextFile = readlines(fullfile(app.appFolder,"Text","Slovak","SK_profile_tab.txt"));
                    obj = profileSwitcher(obj,app,obj.lang_storage);

                    obj.TextFileProfileTabParameters = readlines(fullfile(app.appFolder,"Text","Slovak","SK_profile_tab_parameters.txt"));
                    obj.TextFileProfileTabCircle = readlines(fullfile(app.appFolder,"Text","Slovak","SK_profile_tab_circles.txt"));
                    
                    obj.TextFileAnimationTabGraphicalAdditions = readlines(fullfile(app.appFolder,"Text","Slovak","SK_animation_tab_graphical_additions.txt"));
                    obj.TextFileAnimationTabParameters = readlines(fullfile(app.appFolder,"Text","Slovak","SK_animation_tab_parameters.txt"));
                    
                    app.HomeUtils.FacultyImage.ImageSource = fullfile(app.appFolder,"Images","FSI_logo_CZ.png");
                    app.HomeUtils.FacultyImage.Position(3) = app.HomeUtils.FacultyImage.Position(4)*app.HomeUtils.RatioFacultyCZ;

                    % Language text manager functions
                    Utils.LanguageSubUtils.outerLanguageFun(app, obj.OuterTextFile);
                    app.HomeUtils.HomeLabel(1).Text = obj.HomeTabTextFile;
                    Utils.LanguageSubUtils.profileTabLanguageFun(app, obj.ProfileTabTextFile);
                    Utils.LanguageSubUtils.animationTabLanguageFun(app, obj.AnimationTabTextFile);

                case "CZ"
                    obj.lang_storage = {"Czech", "CZ"};
                    obj.OuterTextFile = readlines(fullfile(app.appFolder,"Text","Czech","CZ_outer.txt"));
                    obj.HomeTabTextFile = readlines(fullfile(app.appFolder,"Text","Czech","CZ_home_tab.txt"));
                    obj.ProfileTabTextFile = readlines(fullfile(app.appFolder,"Text","Czech","CZ_profile_tab.txt"));
                    obj = profileSwitcher(obj,app,obj.lang_storage);

                    obj.TextFileProfileTabParameters = readlines(fullfile(app.appFolder,"Text","Czech","CZ_profile_tab_parameters.txt"));
                    obj.TextFileProfileTabCircle = readlines(fullfile(app.appFolder,"Text","Czech","CZ_profile_tab_circles.txt"));

                    obj.TextFileAnimationTabGraphicalAdditions = readlines(fullfile(app.appFolder,"Text","Czech","CZ_animation_tab_graphical_additions.txt"));
                    obj.TextFileAnimationTabParameters = readlines(fullfile(app.appFolder,"Text","Czech","CZ_animation_tab_parameters.txt"));

                    app.HomeUtils.FacultyImage.ImageSource = fullfile(app.appFolder,"Images","FSI_logo_CZ.png");
                    app.HomeUtils.FacultyImage.Position(3) = app.HomeUtils.FacultyImage.Position(4)*app.HomeUtils.RatioFacultyCZ;

                    % Language text manager functions
                    Utils.LanguageSubUtils.outerLanguageFun(app, obj.OuterTextFile);
                    app.HomeUtils.HomeLabel(1).Text = obj.HomeTabTextFile;
                    Utils.LanguageSubUtils.profileTabLanguageFun(app, obj.ProfileTabTextFile);
                    Utils.LanguageSubUtils.animationTabLanguageFun(app, obj.AnimationTabTextFile);

                case "EN"
                    obj.lang_storage = {"English", "EN"};
                    obj.OuterTextFile = readlines(fullfile(app.appFolder,"Text","English","EN_outer.txt"));
                    obj.HomeTabTextFile = readlines(fullfile(app.appFolder,"Text","English","EN_home_tab.txt"));
                    obj.ProfileTabTextFile = readlines(fullfile(app.appFolder,"Text","English","EN_profile_tab.txt"));
                    obj = profileSwitcher(obj,app,obj.lang_storage);

                    obj.TextFileProfileTabParameters = readlines(fullfile(app.appFolder,"Text","English","EN_profile_tab_parameters.txt"));
                    obj.TextFileProfileTabCircle = readlines(fullfile(app.appFolder,"Text","English","EN_profile_tab_circles.txt"));

                    obj.TextFileAnimationTabGraphicalAdditions = readlines(fullfile(app.appFolder,"Text","English","EN_animation_tab_graphical_additions.txt"));
                    obj.TextFileAnimationTabParameters = readlines(fullfile(app.appFolder,"Text","English","EN_animation_tab_parameters.txt"));

                    app.HomeUtils.FacultyImage.ImageSource = fullfile(app.appFolder,"Images","FSI_logo_EN.png");
                    app.HomeUtils.FacultyImage.Position(3) = app.HomeUtils.FacultyImage.Position(4)*app.HomeUtils.RatioFacultyEN;

                    % Language text manager functions
                    Utils.LanguageSubUtils.outerLanguageFun(app, obj.OuterTextFile);
                    app.HomeUtils.HomeLabel(1).Text = obj.HomeTabTextFile;
                    Utils.LanguageSubUtils.profileTabLanguageFun(app, obj.ProfileTabTextFile);
                    Utils.LanguageSubUtils.animationTabLanguageFun(app, obj.AnimationTabTextFile);

            end
        end
    end
end