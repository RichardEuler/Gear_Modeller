% Copyright (c) 2026 Richard Timko
function drawFunction(app)
    % drawFunction — Generate and draw tooth profiles based on current settings.
    %
    % Handles both single-profile and parametric-sequence modes for
    % involute and cycloidal gearing.

    % Clear animation axes if they are visible
    if ~isempty(app.AnimationControl.AxisAnimation) && ...
            isvalid(app.AnimationControl.AxisAnimation) && ...
            strcmp(app.AnimationControl.AxisAnimation.Visible, 'on')
        CancelAllFun(app);
    end

    app.AxisOutput.HandleVisibility = 'on';
    set(app.AxisOutput, 'XLimMode', 'auto', 'YLimMode', 'auto');

    % Read common parameter values
    m_val = app.ModuleEditField.From.Value;
    z_val = app.NumberOfTeethEditField.From.Value;
    x_val = app.ProfileShiftCoefficientEditField.From.Value;

    if app.InvoluteButton.Value == 1
        alpha_val = app.ProfileAngleEditField.From.Value;
        genFun = @(m, a, z, x) Generator.involuteToothing(m, a, z, x);
    else
        alpha_val = app.ProfileAngleEditField.From.Value;   % epicycloid radius for cycloidal
        rho_h_val = app.HypocycloidRadiusEditField.From.Value;
        genFun = @(m, a, z, x) Generator.cycloidToothing(m, a, rho_h_val, z, x);
    end

    if app.SingleProfileButton.Value == 1
        % ---- Single profile ----
        app.Gen = genFun(m_val, alpha_val, z_val, x_val);
        profileDrawerFunction(app.ProfileTabManagerUtils, app, m_val, z_val);
    else
        % ---- Parametric sequence ----
        nProfiles = app.NumberOfProfilesSpinner.Value;

        if app.ModuleButton.Value == 1
            params = linspace(m_val, app.ModuleEditField.To.Value, nProfiles);
            for i = 1:numel(params)
                app.Gen = genFun(params(i), alpha_val, z_val, x_val);
                profileDrawerFunction(app.ProfileTabManagerUtils, app, params(i), z_val);
            end

        elseif app.ProfileAngleButton.Value == 1
            params = linspace(alpha_val, app.ProfileAngleEditField.To.Value, nProfiles);
            for i = 1:numel(params)
                app.Gen = genFun(m_val, params(i), z_val, x_val);
                profileDrawerFunction(app.ProfileTabManagerUtils, app, m_val, z_val);
            end

        elseif app.NumberOfTeethButton.Value == 1
            params = round(linspace(z_val, app.NumberOfTeethEditField.To.Value, nProfiles));
            for i = 1:numel(params)
                app.Gen = genFun(m_val, alpha_val, params(i), x_val);
                profileDrawerFunction(app.ProfileTabManagerUtils, app, m_val, params(i));
            end

        elseif app.ProfileShiftCoefficientButton.Value == 1
            params = linspace(x_val, app.ProfileShiftCoefficientEditField.To.Value, nProfiles);
            for i = 1:numel(params)
                app.Gen = genFun(m_val, alpha_val, z_val, params(i));
                profileDrawerFunction(app.ProfileTabManagerUtils, app, m_val, z_val);
            end

        elseif app.HypocycloidRadiusButton.Value == 1 && app.CycloidalButton.Value == 1
            params = linspace(rho_h_val, app.HypocycloidRadiusEditField.To.Value, nProfiles);
            for i = 1:numel(params)
                app.Gen = Generator.cycloidToothing(m_val, alpha_val, params(i), z_val, x_val);
                profileDrawerFunction(app.ProfileTabManagerUtils, app, m_val, z_val);
            end
        end
    end

    % Refresh the additional-parameters dialog if it is open
    if ~isempty(app.FurtherParametersUtils.F) && isgraphics(app.FurtherParametersUtils.F)
        updateReadOutValues(app.ProfileTabManagerUtils, app);
    end
end
