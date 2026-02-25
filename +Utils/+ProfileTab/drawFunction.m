% Copyright (c) 2026 Richard Timko
function drawFunction(app)
    % Function assigned to the draw button

    if app.AnimationControl.AxisAnimation.Visible == 1
        CancelAllFun(app)
    end

    app.AxisOutput.HandleVisibility = "on";
    set(app.AxisOutput,"XLimMode","auto","YLimMode","auto");

    %% Involute Gear Profile
    if app.EvolventnButton.Value == 1
        if app.JednotlivprofilButton.Value == 1
            app.Gen = Generator.involuteToothing(app.ModuleEditField_1.Value, ...
                                       app.Option1EditField_1.Value, ...
                                       app.NumberOfTeethEditField_1.Value, ...
                                       app.ProfileShiftCoefficientEditField_1.Value);
            profileDrawerFunction(app.ProfileTabManagerUtils,app,app.ModuleEditField_1.Value,app.NumberOfTeethEditField_1.Value);
        
        else
        
            if app.ModuleButton.Value == 1
                parameter = linspace(app.ModuleEditField_1.Value,app.ModuleEditField_2.Value,app.NumberOfProfilesSpinner.Value);
                for i = 1:length(parameter)
                    app.Gen = Generator.involuteToothing(parameter(i), ...
                                               app.Option1EditField_1.Value, ...
                                               app.NumberOfTeethEditField_1.Value, ...
                                               app.ProfileShiftCoefficientEditField_1.Value);
                    profileDrawerFunction(app.ProfileTabManagerUtils,app,parameter(i),app.NumberOfTeethEditField_1.Value);
                end
            
            elseif app.Option1Button.Value == 1
                parameter = linspace(app.Option1EditField_1.Value,app.Option1EditField_2.Value,app.NumberOfProfilesSpinner.Value);
                for i = 1:length(parameter)
                    app.Gen = Generator.involuteToothing(app.ModuleEditField_1.Value, ...
                                               parameter(i), ...
                                               app.NumberOfTeethEditField_1.Value, ...
                                               app.ProfileShiftCoefficientEditField_1.Value);
                    profileDrawerFunction(app.ProfileTabManagerUtils,app,app.ModuleEditField_1.Value,app.NumberOfTeethEditField_1.Value);
                end
    
            elseif app.NumberOfTeethButton.Value == 1
                parameter = linspace(app.NumberOfTeethEditField_1.Value,app.NumberOfTeethEditField_2.Value,app.NumberOfProfilesSpinner.Value);
                parameter = round(parameter);
                for i = 1:length(parameter)
                    app.Gen = Generator.involuteToothing(app.ModuleEditField_1.Value, ...
                                               app.Option1EditField_1.Value, ...
                                               parameter(i), ...
                                               app.ProfileShiftCoefficientEditField_1.Value);
                    profileDrawerFunction(app.ProfileTabManagerUtils,app,app.ModuleEditField_1.Value,parameter(i));
                end
    
            else
                parameter = linspace(app.ProfileShiftCoefficientEditField_1.Value,app.ProfileShiftCoefficientEditField_2.Value,app.NumberOfProfilesSpinner.Value);
                for i = 1:length(parameter)
                    app.Gen = Generator.involuteToothing(app.ModuleEditField_1.Value, ...
                                               app.Option1EditField_1.Value, ...
                                               app.NumberOfTeethEditField_1.Value, ...
                                               parameter(i));
                    profileDrawerFunction(app.ProfileTabManagerUtils,app,app.ModuleEditField_1.Value,app.NumberOfTeethEditField_1.Value);
                end
            end
        end
    
    %% Cycloid Gear Profile
    else
        if app.JednotlivprofilButton.Value == 1
            app.Gen = Generator.cycloidToothing(app.ModuleEditField_1.Value, ...
                                      app.Option1EditField_1.Value, ...
                                      app.Option2EditField_1.Value, ...
                                      app.NumberOfTeethEditField_1.Value, ...
                                      app.ProfileShiftCoefficientEditField_1.Value);
            profileDrawerFunction(app.ProfileTabManagerUtils,app,app.ModuleEditField_1.Value,app.NumberOfTeethEditField_1.Value);
        
        else
            if app.ModuleButton.Value == 1
                parameter = linspace(app.ModuleEditField_1.Value,app.ModuleEditField_2.Value,app.NumberOfProfilesSpinner.Value);
                for i = 1:length(parameter)
                    app.Gen = Generator.cycloidToothing(parameter(i), ...
                                              app.Option1EditField_1.Value, ...
                                              app.Option2EditField_1.Value, ...
                                              app.NumberOfTeethEditField_1.Value, ...
                                              app.ProfileShiftCoefficientEditField_1.Value);
                    profileDrawerFunction(app.ProfileTabManagerUtils,app,parameter(i),app.NumberOfTeethEditField_1.Value);
                end
            
            elseif app.Option1Button.Value == 1
                parameter = linspace(app.Option1EditField_1.Value,app.Option1EditField_2.Value,app.NumberOfProfilesSpinner.Value);
                for i = 1:length(parameter)
                    app.Gen = Generator.cycloidToothing(app.ModuleEditField_1.Value, ...
                                              parameter(i), ...
                                              app.Option2EditField_1.Value, ...
                                              app.NumberOfTeethEditField_1.Value, ...
                                              app.ProfileShiftCoefficientEditField_1.Value);
                    profileDrawerFunction(app.ProfileTabManagerUtils,app,app.ModuleEditField_1.Value,app.NumberOfTeethEditField_1.Value);
                end
            
            elseif app.Option2Button.Value == 1
                parameter = linspace(app.Option2EditField_1.Value,app.Option2EditField_2.Value,app.NumberOfProfilesSpinner.Value);
                for i = 1:length(parameter)
                    app.Gen = Generator.cycloidToothing(app.ModuleEditField_1.Value, ...
                                              app.Option1EditField_1.Value, ...
                                              parameter(i), ...
                                              app.NumberOfTeethEditField_1.Value, ...
                                              app.ProfileShiftCoefficientEditField_1.Value);
                    profileDrawerFunction(app.ProfileTabManagerUtils,app,app.ModuleEditField_1.Value,app.NumberOfTeethEditField_1.Value);
                end
            
            elseif app.NumberOfTeethButton.Value == 1
                parameter = linspace(app.NumberOfTeethEditField_1.Value,app.NumberOfTeethEditField_2.Value,app.NumberOfProfilesSpinner.Value);
                parameter = round(parameter);
                for i = 1:length(parameter)
                    app.Gen = Generator.cycloidToothing(app.ModuleEditField_1.Value, ...
                                              app.Option1EditField_1.Value, ...
                                              app.Option2EditField_1.Value, ...
                                              parameter(i), ...
                                              app.ProfileShiftCoefficientEditField_1.Value);
                    profileDrawerFunction(app.ProfileTabManagerUtils,app,app.ModuleEditField_1.Value,parameter(i));
                end
            
            else
                parameter = linspace(app.ProfileShiftCoefficientEditField_1.Value,app.ProfileShiftCoefficientEditField_2.Value,app.NumberOfProfilesSpinner.Value);
                for i = 1:length(parameter)
                    app.Gen = Generator.cycloidToothing(app.ModuleEditField_1.Value, ...
                                              app.Option1EditField_1.Value, ...
                                              app.Option2EditField_1.Value, ...
                                              app.NumberOfTeethEditField_1.Value, ...
                                              parameter(i));
                    profileDrawerFunction(app.ProfileTabManagerUtils,app,app.ModuleEditField_1.Value,app.NumberOfTeethEditField_1.Value);
                end
            end
        end
    end


    if isgraphics(app.FurtherParametersUtils.F)
        updateReadOutValues(app.ProfileTabManagerUtils,app);
    end
end