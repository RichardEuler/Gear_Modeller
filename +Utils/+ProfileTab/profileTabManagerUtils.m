% Copyright (c) 2026 Richard Timko
classdef profileTabManagerUtils < handle
    % Auxiliary functions

    properties
        LockChecker (1,1) logical = false % Checker for view lock
        ProfileCounter int8 {mustBeScalarOrEmpty} = 0 % Counter for profiles drawn
        ProfilePlot % Plot property for all profiles in figure

        ReadOutLabels
        ReadOutValues string % String values of parameters for read out panel
    end

    methods
        function obj = profileTabManagerUtils(app)
            obj.ReadOutLabels = gobjects(numel(app.LanguageUtils.TextFileProfileTabParametersEquations),2);
            obj.ProfilePlot = gobjects(1);
            app.EvolventnButton.Position = [1 1 85 20];
            app.CykloidnButton.Position = [86 1 85 20];

            app.ButtonGroup.SelectionChangedFcn = @(src, event) gearProfileSwitch(obj,app);
            app.Option2EditField_1.Value = app.NumberOfTeethEditField_1.Value/4;

            app.Option2EditField_1.Limits(1) = (1.25-app.ProfileShiftCoefficientEditField_1.Value)*app.ModuleEditField_1.Value/2;
            app.Option2EditField_1.Limits(2) = (app.ModuleEditField_1.Value*app.NumberOfTeethEditField_1.Value - (1.25-app.ProfileShiftCoefficientEditField_1.Value)*app.ModuleEditField_1.Value)/2;
            app.Option2EditField_2.Limits(2) = app.Option2EditField_1.Limits(2);
        end

        function profileSettingFunction(obj,app)
            if app.JednotlivprofilButton.Value == 1
                app.NumberOfProfilesSpinner.Enable = 0;
                set([app.ModuleButton ...
                    app.NumberOfTeethButton ...
                    app.Option1Button ...
                    app.ProfileShiftCoefficientButton ...
                    app.ModuleEditField_2 ...
                    app.Option1EditField_2 ...
                    app.NumberOfTeethEditField_2 ...
                    app.ProfileShiftCoefficientEditField_2], ...
                    "Enable",0,"Visible",0);
            elseif app.ParametricksekvenciaprofilovButton.Value == 1
                app.NumberOfProfilesSpinner.Enable = 1;
                set([app.ModuleButton ...
                    app.NumberOfTeethButton ...
                    app.Option1Button ...
                    app.ProfileShiftCoefficientButton], ...
                    "Enable",1,"Visible",1);
                profileSettingParameterFunction(obj,app);
            end

            if app.CykloidnButton.Value == 1
                if app.JednotlivprofilButton.Value == 1
                    set([app.Option2Button app.Option1EditField_2],"Enable",0,"Visible",0)
                elseif app.ParametricksekvenciaprofilovButton.Value == 1
                    set(app.Option2Button,"Enable",1,"Visible",1)
                end
            end
        end

        function profileSettingParameterFunction(obj,app)
            if app.ModuleButton.Value == 1
                set(app.ModuleEditField_2,"Enable",1,"Visible",1);
                set([app.Option1EditField_2 ...
                    app.Option2EditField_2 ...
                    app.NumberOfTeethEditField_2 ...
                    app.ProfileShiftCoefficientEditField_2], ...
                    "Enable",0,"Visible",0);
            elseif app.Option1Button.Value == 1
                set(app.Option1EditField_2,"Enable",1,"Visible",1);
                set([app.ModuleEditField_2 ...
                    app.NumberOfTeethEditField_2 ...
                    app.Option2EditField_2 ...
                    app.ProfileShiftCoefficientEditField_2], ...
                    "Enable",0,"Visible",0);
            elseif app.NumberOfTeethButton.Value == 1
                set(app.NumberOfTeethEditField_2,"Enable",1,"Visible",1);
                set([app.ModuleEditField_2 ...
                    app.Option1EditField_2 ...
                    app.Option2EditField_2 ...
                    app.ProfileShiftCoefficientEditField_2], ...
                    "Enable",0,"Visible",0);
            elseif app.ProfileShiftCoefficientButton.Value == 1
                set(app.ProfileShiftCoefficientEditField_2,"Enable",1,"Visible",1);
                set([app.ModuleEditField_2 ...
                    app.Option1EditField_2 ...
                    app.Option2EditField_2 ...
                    app.NumberOfTeethEditField_2], ...
                    "Enable",0,"Visible",0);
            elseif app.Option2Button.Value == 1
                set(app.Option2EditField_2,"Enable",1,"Visible",1);
                set([app.ModuleEditField_2 ...
                    app.NumberOfTeethEditField_2 ...
                    app.Option1EditField_2 ...
                    app.ProfileShiftCoefficientEditField_2], ...
                    "Enable",0,"Visible",0);
            end
        end

        function profileDrawerFunction(obj, app, module, teeth)
            if isempty(obj.ProfileCounter) || obj.ProfileCounter == 0
                obj.ProfileCounter = 1;
                app.HomeUtils.FigureText.Visible = 0;

                if app.OsiCheckBox.Value
                    axis(app.AxisOutput,1)
                else
                    axis(app.AxisOutput,0)
                end

                if app.MriekaCheckBox.Value
                    grid(app.AxisOutput,1)
                else
                    grid(app.AxisOutput,0)
                end

                hold(app.AxisOutput,1); axis(app.AxisOutput,"equal");
                obj.ProfilePlot(obj.ProfileCounter) = plot(app.AxisOutput, app.Gen.tooth(1,:), app.Gen.tooth(2,:));

                circlePlot(obj,app);
                if obj.LockChecker == true
                    set(obj.ProfilePlot(obj.ProfileCounter),"YData",get(obj.ProfilePlot(obj.ProfileCounter),"YData") - module*teeth/2);
                    if any(app.CirclesUtils.Checkers)
                        for j = 1:4
                            if app.CirclesUtils.Checkers(j) == true
                                set(app.CirclesUtils.CirclePlot(j,obj.ProfileCounter),"YData",get(app.CirclesUtils.CirclePlot(j,obj.ProfileCounter),"YData") - module*teeth/2);
                            end
                        end
                    end
                end

            else

                obj.ProfileCounter = obj.ProfileCounter + 1;
                obj.ProfilePlot(obj.ProfileCounter) = plot(app.AxisOutput, app.Gen.tooth(1,:), app.Gen.tooth(2,:));

                circlePlot(obj,app);
                if obj.LockChecker == true
                    set(obj.ProfilePlot(obj.ProfileCounter),"YData",get(obj.ProfilePlot(obj.ProfileCounter),"YData") - module*teeth/2);
                    if any(app.CirclesUtils.Checkers)
                        for j = 1:4
                            if app.CirclesUtils.Checkers(j) == true
                                set(app.CirclesUtils.CirclePlot(j,obj.ProfileCounter),"YData",get(app.CirclesUtils.CirclePlot(j,obj.ProfileCounter),"YData") - module*teeth/2);
                            end
                        end
                    end
                end
            end

            if app.FarbaColorPicker.Enable == 1
                set(obj.ProfilePlot(obj.ProfileCounter),"Color",app.FarbaColorPicker.Value);
            end
            set(obj.ProfilePlot(obj.ProfileCounter),"LineWidth",app.HrbkaSpinner.Value,"LineStyle",Utils.ProfileTab.profileLineStyleFunction(app.tlDropDown.ValueIndex));

            if obj.ProfileCounter > 0
                app.ExportUtils.ExportButton.Enable = 1;
                app.ExportUtils.ExportSpinner.Limits = [1 double(obj.ProfileCounter)];
                app.ExportUtils.ExportSpinner.Value = double(obj.ProfileCounter);
            end
        end

        function updateReadOutValues(obj,app)
            obj.ReadOutValues([1:2,5]) = "";
            if obj.ProfileCounter > 0 && ( (~isnan(app.Gen.R_b) && app.EvolventnButton.Value == 1) || (isnan(app.Gen.R_b) && app.EvolventnButton.Value == 0) )
                if ~isnan(app.Gen.R_b)
                    obj.ReadOutValues(3) = num2str(app.Gen.h_f,"%.2f");
                    obj.ReadOutValues(4) = num2str(app.Gen.h_a,"%.2f");
                    obj.ReadOutValues(6) = num2str(2*app.Gen.R,"%.2f");
                    obj.ReadOutValues(7) = num2str(2*app.Gen.R_b,"%.2f");
                    obj.ReadOutValues(8) = num2str(2*app.Gen.R_f,"%.2f");
                    obj.ReadOutValues(9) = num2str(2*app.Gen.R_a,"%.2f");
                else
                    obj.ReadOutValues(3) = num2str(app.Gen.h_f,"%.2f");
                    obj.ReadOutValues(4) = num2str(app.Gen.h_a,"%.2f");
                    obj.ReadOutValues(6) = num2str(2*app.Gen.R,"%.2f");
                    obj.ReadOutValues(7) = num2str(2*app.Gen.R_f,"%.2f");
                    obj.ReadOutValues(8) = num2str(2*app.Gen.R_a,"%.2f");
                end
            else
                obj.ReadOutValues([3,4,6:numel(app.LanguageUtils.TextFileProfileTabParametersEquations)]) = "...";
            end

            for i = 1:numel(app.LanguageUtils.TextFileProfileTabParametersEquations)
                str = strrep(app.LanguageUtils.TextFileProfileTabParametersEquations{i},'???',obj.ReadOutValues(i));
                obj.ReadOutLabels(i,2).Text = string(str);
            end
        end

        function circlePlot(obj,app)
            if any(app.CirclesUtils.Checkers)
                t = linspace(-pi/app.Gen.z,pi/app.Gen.z);
                R = [app.Gen.R app.Gen.R_b app.Gen.R_a app.Gen.R_f];
                % Four  circles
                for i = 1:4
                    if app.CirclesUtils.Checkers(i+1) == 1
                        LS = Utils.ProfileTab.profileLineStyleFunction(app.CirclesUtils.Style(i));
                        app.CirclesUtils.CirclePlot(i,obj.ProfileCounter) = plot(app.AxisOutput,R(i)*sin(t),R(i)*cos(t));
                        % Circle colour setting
                        if isvalid(app.CirclesUtils.F)
                            if app.CirclesUtils.Components(i,2).Enable == 1
                                set(app.CirclesUtils.CirclePlot(i,obj.ProfileCounter),"Color",app.CirclesUtils.Colours(i,:));
                            end
                        else
                            if app.CirclesUtils.ActiveColour(i) == 1
                                set(app.CirclesUtils.CirclePlot(i,obj.ProfileCounter),"Color",app.CirclesUtils.Colours(i,:));
                            end
                        end
                        % Remaining settings
                        set(app.CirclesUtils.CirclePlot(i,obj.ProfileCounter), ...
                            "LineWidth",app.CirclesUtils.Width(i), ...
                            "LineStyle",LS);
                    end
                end
            else
                app.CirclesUtils.CirclePlot(:,obj.ProfileCounter) = gobjects(4,1);
            end
        end

        function gearProfileSwitch(obj,app)
            if app.EvolventnButton.Value == 1
                if app.Option2Button.Value == 1 && app.ParametricksekvenciaprofilovButton.Value == 1
                    app.ModuleButton.Value = 1;
                    set(app.ModuleEditField_2,"Enable",1,"Visible",1);
                end
                
                set([app.Option2Label, ...
                    app.Option2SymbolicLabel, ...
                    app.Option2Button, ...
                    app.Option2EditField_1, ...
                    app.Option2EditField_2], ...
                    "Enable",0,"Visible",0);

                str_language = ["Uhol profilu"; "Úhel profilu"; "Profile angle"];

                switch app.LanguageUtils.LanguageChoice
                    case "SK"
                        app.Option1Label.Text = str_language(1);
                    case "CZ"
                        app.Option1Label.Text = str_language(2);
                    case "EN"
                        app.Option1Label.Text = str_language(3);
                end

                app.Option1SymbolicLabel.Text = "$\alpha \: \mathrm{[^\circ]}$";

            else
                set([app.Option2Label, ...
                    app.Option2SymbolicLabel, ...
                    app.Option2EditField_1], ...
                    "Enable",1,"Visible",1);

                if app.ParametricksekvenciaprofilovButton.Value == 1
                    set(app.Option2Button,"Enable",1,"Visible",1);
                end

                str_language = ["Polomer tvoriacej kružnice epicykloidy"; ...
                    "Poloměr tvořící kružnice epicykloidy"; ...
                    "Radius of epicycloid generating circle"];

                switch app.LanguageUtils.LanguageChoice
                    case "SK"
                        app.Option1Label.Text = str_language(1);
                    case "CZ"
                        app.Option1Label.Text = str_language(2);
                    case "EN"
                        app.Option1Label.Text = str_language(3);
                end

                app.Option1SymbolicLabel.Text = "$\rho_e  \: \mathrm{[mm]}$";
                app.CirclesUtils.Checkers(3) = 0;
            end

            if isgraphics(app.FurtherParametersUtils.F)
                obj.ReadOutValues([3,4,6:numel(app.LanguageUtils.TextFileProfileTabParametersEquations)]) = "...";
                app.FurtherParametersUtils = updateLabels(app.FurtherParametersUtils,app);

                for i = 1:numel(app.LanguageUtils.TextFileProfileTabParametersEquations)
                    str = strrep(app.LanguageUtils.TextFileProfileTabParametersEquations{i},'???',obj.ReadOutValues(i));
                    obj.ReadOutLabels(i,2).Text = string(str);
                end

                if app.EvolventnButton.Value == 1
                    set(obj.ReadOutLabels(end,:),"Visible",1);
                else
                    set(obj.ReadOutLabels(end,:),"Visible",0);
                end
            end

            if isgraphics(app.CirclesUtils.F)
                if app.EvolventnButton.Value == 1
                    set(app.CirclesUtils.Components(2,:),"Enable",1);
                else
                    set(app.CirclesUtils.Components(2,1),"Value",0);
                    set(app.CirclesUtils.Components(2,:),"Enable",0);
                end
            end
        end
    end
end