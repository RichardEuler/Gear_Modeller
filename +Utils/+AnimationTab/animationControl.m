% Copyright (c) 2026 Richard Timko
classdef animationControl < handle
    % animationControl — Manages the gear animation playback loop, frame
    % generation, and graphical output for both gear-meshing and hobbing modes.

    properties
        % Gear parameters (editable from the animation tab)
        m       (1,1) double {mustBeInteger}      = 1
        z       (2,1) double {mustBeInteger}      = [20; 30]
        x       (2,1) double {mustBeNumeric}      = [0; 0]
        alpha   (1,1) double {mustBePositive}     = 20
        rho_a   (2,1) double {mustBePositive}     = [5; 5]
        rho_f   (2,1) double {mustBePositive}     = [5; 5]
        j_b     (1,1) double {mustBeNonnegative}  = 0
        alpha_w (1,1) double {mustBePositive}     = 20
        a_w     (1,1) double {mustBePositive}     = 25
        y       (1,1) double {mustBeNumeric}      = 0

        % Derived properties
        a       (1,1) double {mustBePositive}     = 25
        d       (2,1) double {mustBePositive}     = [20; 30]
        d_w     (2,1) double {mustBePositive}     = [20; 30]
        u       (1,1) double {mustBePositive}     = 1.5
        eps_a   (1,1) double                      % Profile contact ratio
        length_action_line (1,1) double           % Length of the path of contact

        gear    struct
        tooth   struct
        tool    struct

        rack    double
        wheel   double
        pinion  double

        T_fun   function_handle   % 2-D rotation matrix function
        T       struct            % Pre-computed transformation matrices per frame
        n       (2,1) double      % Rotational frequencies [1/s]
        FPS     (1,1) double      % Frames per second
        frames_mesh    cell       % Frames within one pitch (meshing mode)
        action_frames  cell       % Contact-point frames along the action line
        frames_hobbing cell       % Frames for the moving rack (hobbing mode)
        AxisAnimation  matlab.graphics.axis.Axes
        quality (1,1) uint8

        start_state (1,1) logical {mustBeMember(start_state,[0 1])} = 0
        t_p                       % Frame period [s]
        P;  W;  R                 % Plot handles (pinion, wheel, rack)
        H;  Z                     % Handles for circles and action-line objects
        theta;  phi
    end

    methods
        function obj = animationControl(ut, fig, quality)
            % Constructor — initialise the animation controller.
            arguments
                ut;  fig;  quality (1,1) uint8 {mustBeInteger} = 50
            end

            obj.quality = quality;

            obj.T_fun = @(x) [cos(x) sin(x); -sin(x) cos(x)];
            obj.T     = struct('p', zeros(2), 'w', zeros(2));
            obj.tooth = struct('p', [], 'w', [], 'r', []);

            obj.theta = 6*pi / obj.z(1);
            updateAnimationSetting(obj, ut);

            % Synchronise the edit fields with the default parameter values
            ordered_variables = [obj.m  obj.z'  obj.x'  obj.alpha  obj.rho_a(2)];
            for j = 1:numel(ut.ValueEdit1)
                if j <= numel(ordered_variables)
                    ut.ValueEdit1(j).Value = ordered_variables(j);
                end
            end

            obj.alpha   = deg2rad(obj.alpha);
            obj.alpha_w = deg2rad(obj.alpha_w);

            obj.gear = struct('p', [], 'w', [], 'r', []);

            obj.AxisAnimation = axes(fig, 'HandleVisibility', 'off', 'Visible', 'off');
            axis(obj.AxisAnimation, 'equal');
            hold(obj.AxisAnimation, 'on');

            obj.P = gobjects(2, 1);
            obj.W = gobjects(2, 1);
            obj.R = gobjects(2, 1);
            obj.H = gobjects(2, 4);
            obj.Z = gobjects(7, 1);
        end

        function updateAnimationSetting(obj, ut)
            % Recalculate frame timing when spinner values change.

            obj.n(1) = ut.AnimationSpinners(1).Value / 3600;   % rev/s
            obj.n(2) = obj.n(1) / obj.u;
            ut.AnimationSpinners(2).Limits = [max(obj.z)*obj.n(1)  Inf];
            obj.FPS = ut.AnimationSpinners(2).Value;

            obj.phi = 2*pi * obj.n / obj.FPS;                  % rad/frame
            obj.T.p = obj.T_fun(-obj.phi(1));
            obj.T.w = obj.T_fun( obj.phi(2));

            if ut.Mode.ValueIndex == 1
                frames_in_pitch = round(obj.FPS ./ (obj.z(1) .* obj.n(1)));
                obj.frames_mesh = cell(2, frames_in_pitch);
            else
                frames_rack = round(2*obj.theta / obj.phi(1));
                obj.frames_hobbing = cell(1, frames_rack);
            end
        end

        function assignValues(obj, ut)
            % Read current parameter values from the animation-tab edit fields.

            obj.m = ut.ValueEdit1(1).Value;

            if ut.Mode.ValueIndex == 1
                % Gear meshing mode
                for j = 1:2
                    if mod(ut.ValueEdit1(j+1).Value, 1) ~= 0
                        ut.ValueEdit1(j+1).Value = round(ut.ValueEdit1(j+1).Value);
                    end
                    obj.z(j) = ut.ValueEdit1(j+1).Value;
                    obj.x(j) = ut.ValueEdit1(j+3).Value;
                end

                if ut.ToothingChoices(1).Value == 1
                    ut.ValueEdit1(6).Limits = [0 Inf];
                    obj.alpha = deg2rad(ut.ValueEdit1(6).Value);
                else
                    ut.ValueEdit1(6).Limits(1) = (1.25-obj.x(2)) * obj.m/2;
                    ut.ValueEdit1(6).Limits(2) = (obj.z(2)-1.25-obj.x(2)) * obj.m/2;
                    ut.ValueEdit1(7).Limits(1) = (1.25-obj.x(1)) * obj.m/2;
                    ut.ValueEdit1(7).Limits(2) = (obj.z(1)-1.25-obj.x(1)) * obj.m/2;
                    for j = 1:2
                        obj.rho_a(j) = ut.ValueEdit1(j+5).Value;
                        obj.rho_f(j) = ut.ValueEdit1(8-j).Value;
                    end
                end

                ut.AnimationSpinners(2).Limits = [max(obj.z)*obj.n(1) Inf];
                obj.d = obj.m * obj.z;
                obj.a = sum(obj.d) / 2;
                obj.u = obj.z(2) / obj.z(1);

            else
                % Hobbing mode
                if mod(ut.ValueEdit1(2).Value, 1) ~= 0
                    ut.ValueEdit1(2).Value = round(ut.ValueEdit1(2).Value);
                end
                obj.z(1) = ut.ValueEdit1(2).Value;
                obj.x(1) = ut.ValueEdit1(4).Value;
                obj.theta = 6*pi / obj.z(1);

                if ut.ToothingChoices(1).Value == 1
                    ut.ValueEdit1(6).Limits = [0 Inf];
                    obj.alpha = deg2rad(ut.ValueEdit1(6).Value);
                else
                    ut.ValueEdit1(6).Limits(1) = max([(1+obj.x(1))*obj.m, obj.m+ceil(4*sqrt(obj.m))/10]) / 2;
                    ut.ValueEdit1(6).Limits(2) = Inf;
                    ut.ValueEdit1(7).Limits(1) = max([1.25-obj.x(1), 1.25]) * obj.m/2;
                    ut.ValueEdit1(7).Limits(2) = (obj.z(1)-1.25-obj.x(1)) * obj.m/2;
                    obj.rho_a(1) = ut.ValueEdit1(6).Value;
                    obj.rho_f(1) = ut.ValueEdit1(7).Value;
                end

                ut.AnimationSpinners(2).Limits = [obj.z(1)*obj.n(1) Inf];
                obj.d(1) = obj.m * obj.z(1);
            end
        end

        function calculationFun(obj, ut, route1, route2, route3, switch_route)
            % Perform gear-parameter calculations and update edit-field values.
            arguments
                obj;  ut
                route1       (1,1) uint8  {mustBeMember(route1,[0 1])}  = 0
                route2       (1,1) uint8  {mustBeMember(route2,[0 2 3])}= 0
                route3       (1,1) uint8  {mustBeMember(route3,[0 2 3])}= 0
                switch_route (1,1) logical = false
            end

            % Enforce z_pinion <= z_wheel
            if route2 == 2
                if ut.ValueEdit1(2).Value > ut.ValueEdit1(3).Value
                    ut.ValueEdit1(3).Value = ut.ValueEdit1(2).Value;
                end
            elseif route2 == 3
                if ut.ValueEdit1(3).Value < ut.ValueEdit1(2).Value
                    ut.ValueEdit1(2).Value = ut.ValueEdit1(3).Value;
                end
            end

            % For cycloidal meshing, enforce x1 + x2 = 0
            if ut.Mode.ValueIndex && ~ut.ToothingChoices(1).Value
                if route3 == 2
                    ut.ValueEdit1(5).Value = -ut.ValueEdit1(4).Value + 0;
                elseif route3 == 3
                    ut.ValueEdit1(4).Value = -ut.ValueEdit1(5).Value + 0;
                end
            end

            if ~switch_route
                assignValues(obj, ut);
            end

            if ut.Mode.ValueIndex
                if ut.ToothingChoices(1).Value
                    % Involute meshing parameter calculations
                    alpha_w_lim = 2*sum(obj.x)/sum(obj.z)*tan(obj.alpha) + involuteFun(obj.alpha);
                    alpha_w_lim = arcInvoluteFun(alpha_w_lim);
                    a_w_lim     = cos(obj.alpha)/cos(alpha_w_lim) * obj.a;
                    y_lim       = sum(obj.x) - (a_w_lim - obj.a)/obj.m;

                    ut.ValueEdit2(2).Limits(1) = rad2deg(alpha_w_lim);
                    ut.ValueEdit2(3).Limits(1) = a_w_lim;
                    ut.ValueEdit2(4).Limits(2) = y_lim;

                    if ut.MeshingChoices(1).Value == 1 || route1 == 1
                        obj.j_b     = ut.ValueEdit2(1).Value * 1e-3;
                        inv_alpha_w = (2*sum(obj.x)*obj.m*sin(obj.alpha) + obj.j_b) / (sum(obj.z)*obj.m*cos(obj.alpha)) + involuteFun(obj.alpha);
                        obj.alpha_w = arcInvoluteFun(inv_alpha_w);
                        obj.a_w     = cos(obj.alpha)/cos(obj.alpha_w) * obj.a;
                        obj.y       = sum(obj.x) - (obj.a_w - obj.a)/obj.m;
                        excluded = 1;
                    elseif ut.MeshingChoices(2).Value == 1
                        obj.alpha_w = deg2rad(ut.ValueEdit2(2).Value);
                        obj.j_b     = sum(obj.z)*(involuteFun(obj.alpha_w) - involuteFun(obj.alpha))*obj.m*cos(obj.alpha) - 2*sum(obj.x)*obj.m*sin(obj.alpha);
                        obj.a_w     = cos(obj.alpha)/cos(obj.alpha_w) * obj.a;
                        obj.y       = sum(obj.x) - (obj.a_w - obj.a)/obj.m;
                        excluded = 2;
                    elseif ut.MeshingChoices(3).Value == 1
                        obj.a_w     = ut.ValueEdit2(3).Value;
                        obj.alpha_w = acos(cos(obj.alpha)*obj.a / obj.a_w);
                        obj.j_b     = sum(obj.z)*(involuteFun(obj.alpha_w) - involuteFun(obj.alpha))*obj.m*cos(obj.alpha) - 2*sum(obj.x)*obj.m*sin(obj.alpha);
                        obj.y       = sum(obj.x) - (obj.a_w - obj.a)/obj.m;
                        excluded = 3;
                    else
                        obj.y       = ut.ValueEdit2(4).Value;
                        obj.a_w     = sum(obj.x)*obj.m + obj.a - obj.y*obj.m;
                        obj.alpha_w = acos(cos(obj.alpha)*obj.a / obj.a_w);
                        obj.j_b     = sum(obj.z)*(involuteFun(obj.alpha_w) - involuteFun(obj.alpha))*obj.m*cos(obj.alpha) - 2*sum(obj.x)*obj.m*sin(obj.alpha);
                        excluded = 4;
                    end

                    obj.d_w(1) = 2*obj.a_w / (1 + obj.u);
                    obj.d_w(2) = obj.d_w(1) * obj.u;

                    ordered = [obj.j_b*1e3  rad2deg(obj.alpha_w)  obj.a_w  obj.y];
                    vars = 1:4;  vars(excluded) = [];
                    for j = vars
                        ut.ValueEdit2(j).Value = ordered(j);
                    end
                else
                    % Cycloidal meshing
                    obj.a_w    = obj.a;
                    obj.d_w(1) = 2*obj.a_w / (1 + obj.u);
                    obj.d_w(2) = obj.d_w(1) * obj.u;
                end
            end

            % ---- Local helper functions ----
            function phi = involuteFun(alfa)
                phi = tan(alfa) - alfa;
            end

            function alfa = arcInvoluteFun(phi)
                fun  = @(gamma) tan(gamma) - gamma - phi;
                alfa = fzero(fun, 0);
                mustBeLessThan(alfa, pi/2);
            end
        end

        function displayFun(obj, app)
            % Generate gears, compute animation frames, and draw the initial state.

            if app.ProfileTabManagerUtils.ProfileCounter > 0
                CancelAllFun(app);
            end

            app.StartPauseButton.Enable = 'on';
            ut = app.AnimationTabUtils;
            app.AnimationExport.ExportButton.Enable = 'on';

            if ut.Mode.ValueIndex == 1
                % ---- Gear Meshing Mode ----
                if ut.ToothingChoices(1).Value == 1
                    obj.gear.p = Generator.involuteToothing(obj.m, rad2deg(obj.alpha), obj.z(1), obj.x(1), obj.quality);
                    obj.gear.w = Generator.involuteToothing(obj.m, rad2deg(obj.alpha), obj.z(2), obj.x(2), obj.quality);
                    in_angle(1) = pi/obj.z(1) + obj.gear.p.psi(obj.x(1)) - (tan(obj.alpha_w) - obj.alpha_w);
                    in_angle(2) = pi/obj.z(2) + obj.gear.w.psi(obj.x(2)) - (tan(obj.alpha_w) - obj.alpha_w) + pi;
                else
                    obj.gear.p = Generator.cycloidToothing(obj.m, obj.rho_a(1), obj.rho_f(1), obj.z(1), obj.x(1), obj.quality);
                    obj.gear.w = Generator.cycloidToothing(obj.m, obj.rho_a(2), obj.rho_f(2), obj.z(2), obj.x(2), obj.quality);
                    in_angle(1) = pi/obj.z(1) - obj.gear.p.psi;
                    in_angle(2) = pi/obj.z(2) - obj.gear.w.psi + pi;
                end

                obj.tooth.p = obj.T_fun(in_angle(1)) * obj.gear.p.tooth;
                obj.tooth.w = obj.T_fun(in_angle(2)) * obj.gear.w.tooth;

                obj.pinion = buildWheel(obj, obj.z(1), obj.tooth.p(:,1:end-1));
                obj.wheel  = buildWheel(obj, obj.z(2), obj.tooth.w(:,1:end-1));
                obj.pinion(:, end+1) = obj.pinion(:, 1);
                obj.wheel(:, end+1)  = obj.wheel(:, 1);
            else
                % ---- Hobbing Mode ----
                if ut.ToothingChoices(1).Value == 1
                    obj.gear.p = Generator.involuteToothing(obj.m, rad2deg(obj.alpha), obj.z(1), obj.x(1), obj.quality);
                    obj.gear.r = Generator.trapezoidalRack(obj.m, rad2deg(obj.alpha), obj.x(1), obj.quality);
                else
                    obj.gear.p = Generator.cycloidToothing(obj.m, obj.rho_a(1), obj.rho_f(1), obj.z(1), obj.x(1), obj.quality);
                    obj.gear.r = Generator.cycloidRack(obj.m, obj.rho_f(1), obj.rho_a(1), obj.x(1), obj.quality);
                end

                obj.tooth.p = obj.gear.p.tooth;
                obj.tooth.r = obj.gear.r.tooth + [-obj.d(1)/2*obj.theta; obj.d(1)/2];

                obj.pinion = buildWheel(obj, obj.z(1), obj.tooth.p(:,1:end-1));
                obj.pinion(:, end+1) = obj.pinion(:, 1);
                obj.pinion = obj.T_fun(pi/obj.z(1)) * obj.pinion;
            end

            obj.t_p = 1 / obj.FPS;
            plotAnimation(obj, ut, app);
        end

        function plotAnimation(obj, ut, app)
            % Render the initial animation frame on the output axes.

            if app.ProfileTabManagerUtils.ProfileCounter > 0
                CancelAllFun(app);
            end
            if ~isempty(obj.AxisAnimation) && isvalid(obj.AxisAnimation)
                delete(findobj(obj.AxisAnimation, 'Type', 'Line'));
            end

            app.HomeUtils.FigureText.Visible = 'off';
            set(obj.AxisAnimation, 'HandleVisibility', 'on', 'Visible', 'on');
            axis(obj.AxisAnimation, 'equal');
            hold(obj.AxisAnimation, 'on');

            if ut.Checkers(1).Value, grid(obj.AxisAnimation, 'on'); else, grid(obj.AxisAnimation, 'off'); end
            if ut.Checkers(2).Value, axis(obj.AxisAnimation, 'on'); else, axis(obj.AxisAnimation, 'off'); end

            circlesPlot(obj, app.GraphicalAdditions, app);

            % Delete old patch objects before recreating
            if isgraphics(obj.P(2)) && isvalid(obj.P(2)), delete(obj.P(2)); end
            if isgraphics(obj.W(2)) && isvalid(obj.W(2)), delete(obj.W(2)); end
            if isgraphics(obj.R(2)) && isvalid(obj.R(2)), delete(obj.R(2)); end

            lineStyle = Utils.ProfileTab.profileLineStyleFunction(ut.StyleLine.ValueIndex);

            if ut.Mode.ValueIndex == 1
                % Pre-compute every frame within one pitch
                obj.frames_mesh{1,1} = obj.pinion;
                obj.frames_mesh{2,1} = obj.wheel;
                for j = 1:size(obj.frames_mesh, 2)-1
                    obj.frames_mesh{1, j+1} = obj.T.p * obj.frames_mesh{1, j};
                    obj.frames_mesh{2, j+1} = obj.T.w * obj.frames_mesh{2, j};
                end
                for j = 1:size(obj.frames_mesh, 2)
                    obj.frames_mesh{2, j}(2,:) = obj.frames_mesh{2, j}(2,:) + obj.a_w;
                end

                if ut.Menus(3).Checked == 0
                    obj.P(2) = patch(obj.AxisAnimation, 'XData', obj.frames_mesh{1,1}(1,:), 'YData', obj.frames_mesh{1,1}(2,:), ...
                        'FaceColor', ut.ColorChoice(2).Value, 'EdgeColor', 'none', 'FaceAlpha', ut.Transparency);
                    obj.W(2) = patch(obj.AxisAnimation, 'XData', obj.frames_mesh{2,1}(1,:), 'YData', obj.frames_mesh{2,1}(2,:), ...
                        'FaceColor', ut.ColorChoice(2).Value, 'EdgeColor', 'none', 'FaceAlpha', ut.Transparency);
                end

                obj.P(1) = plot(obj.AxisAnimation, obj.frames_mesh{1,1}(1,:), obj.frames_mesh{1,1}(2,:), ...
                    'Color', ut.ColorChoice(1).Value, 'LineWidth', ut.AnimationSpinners(3).Value, 'LineStyle', lineStyle);
                obj.W(1) = plot(obj.AxisAnimation, obj.frames_mesh{2,1}(1,:), obj.frames_mesh{2,1}(2,:), ...
                    'Color', ut.ColorChoice(1).Value, 'LineWidth', ut.AnimationSpinners(3).Value, 'LineStyle', lineStyle);
            else
                % Hobbing mode frames
                for j = 1:numel(obj.frames_hobbing)
                    obj.frames_hobbing{j} = obj.tooth.r + [(j-1)*obj.phi(1)*obj.d(1)/2; 0];
                    obj.frames_hobbing{j} = obj.T_fun(obj.theta - (j-1)*obj.phi(1)) * obj.frames_hobbing{j};
                end
                obj.P(1) = plot(obj.AxisAnimation, obj.pinion(1,:), obj.pinion(2,:), ...
                    'Color', ut.ColorChoice(1).Value, 'LineWidth', ut.AnimationSpinners(3).Value, 'LineStyle', lineStyle);
                obj.R(1) = plot(obj.AxisAnimation, obj.frames_hobbing{1}(1,:), obj.frames_hobbing{1}(2,:), ...
                    'Color', ut.ColorChoice(1).Value, 'LineWidth', ut.AnimationSpinners(3).Value, 'LineStyle', lineStyle);

                if ut.Menus(3).Checked == 0
                    obj.P(2) = patch(obj.AxisAnimation, 'XData', obj.pinion(1,:), 'YData', obj.pinion(2,:), ...
                        'FaceColor', ut.ColorChoice(2).Value, 'EdgeColor', 'none', 'FaceAlpha', ut.Transparency);
                    obj.R(2) = patch(obj.AxisAnimation, 'XData', obj.frames_hobbing{1}(1,:), 'YData', obj.frames_hobbing{1}(2,:), ...
                        'FaceColor', ut.ColorChoice(2).Value, 'EdgeColor', 'none', 'FaceAlpha', ut.Transparency);
                end
            end

            % Draw or hide the line of action
            if app.GraphicalAdditions.Checkers(2) == 1
                actionLinePlot(obj, app.GraphicalAdditions, app, 1);
            else
                actionLinePlot(obj, app.GraphicalAdditions, app, 0);
            end

            % Update the additional-parameters dialog if it is open
            if ~isempty(app.AnimationParameters.F) && isgraphics(app.AnimationParameters.F)
                textValueAssignment(app.AnimationParameters, obj);
            end
        end

        function startAnimation(obj, app, path_text, format)
            % Run the animation loop (play/pause toggle, optional video export).
            arguments
                obj;  app
                path_text = "none"
                format    = "none"
            end

            % Toggle play/pause
            obj.start_state = ~obj.start_state;

            % Read localised Play/Pause labels
            line = numel(app.LanguageUtils.AnimationTabTextFile) - 1;
            itemsCellArray = strtrim(split(app.LanguageUtils.AnimationTabTextFile{line}, ','));

            if obj.start_state == 1
                app.AnimationExport.ExportButton.Enable = 'off';
                app.StartPauseButton.Text = itemsCellArray{2};  % "Pause"
            else
                app.AnimationExport.ExportButton.Enable = 'on';
                app.StartPauseButton.Text = itemsCellArray{1};  % "Play"
                return
            end

            % ---- Gear Meshing Mode ----
            if app.AnimationTabUtils.Mode.ValueIndex == 1
                if isgraphics(obj.P(2)) && isvalid(obj.P(2))
                    id = [1 2];
                else
                    id = 1;
                end

                if app.AnimationExport.video_export_state
                    exportMeshingVideo(obj, app, id, path_text, format);
                else
                    % Live playback loop
                    while obj.start_state == 1
                        for j = 1:size(obj.frames_mesh, 2)
                            if obj.start_state == 0, break; end
                            if ~isgraphics(obj.P(1)) || ~isvalid(obj.P(1)) || ~isgraphics(obj.W(1)) || ~isvalid(obj.W(1))
                                obj.start_state = 0; return
                            end
                            set(obj.P(id), 'XData', obj.frames_mesh{1,j}(1,:), 'YData', obj.frames_mesh{1,j}(2,:));
                            set(obj.W(id), 'XData', obj.frames_mesh{2,j}(1,:), 'YData', obj.frames_mesh{2,j}(2,:));
                            updateActionPoints(obj, app, j);
                            drawnow; pause(obj.t_p);
                        end
                    end
                end

            % ---- Hobbing Mode ----
            else
                % Build id_r so set() only touches valid graphics objects.
                % R(2) is the fill patch and is only created when the fill
                % option is enabled in the UI.
                if isgraphics(obj.R(2)) && isvalid(obj.R(2))
                    id_r = [1 2];
                else
                    id_r = 1;
                end

                if app.AnimationExport.video_export_state
                    exportHobbingVideo(obj, app, id_r, path_text, format);
                else
                    while obj.start_state == 1
                        for j = 1:numel(obj.frames_hobbing)
                            if obj.start_state == 0, break; end
                            if ~isgraphics(obj.R(1)) || ~isvalid(obj.R(1)), obj.start_state = 0; return; end
                            set(obj.R(id_r), 'XData', obj.frames_hobbing{j}(1,:), 'YData', obj.frames_hobbing{j}(2,:));
                            drawnow; pause(obj.t_p);
                        end
                    end
                end
            end

            % Reset state after the loop exits
            obj.start_state = 0;
            if isvalid(app.StartPauseButton)
                app.StartPauseButton.Text = itemsCellArray{1};
            end
            if isvalid(app.AnimationExport.ExportButton)
                app.AnimationExport.ExportButton.Enable = 'on';
            end
        end

        function circlesPlot(obj, ut, app)
            % Draw significant circles (pitch, base, addendum, dedendum).
            t = 0:360;
            if app.AnimationTabUtils.Mode.ValueIndex == 1
                radii = [obj.gear.p.R  obj.gear.p.R_b  obj.gear.p.R_a  obj.gear.p.R_f; ...
                         obj.gear.w.R  obj.gear.w.R_b  obj.gear.w.R_a  obj.gear.w.R_f];
                circles = cell(2, 4);
                for j = 1:4
                    circles{1,j} = [radii(1,j)*cosd(t); radii(1,j)*sind(t)];
                    circles{2,j} = [radii(2,j)*cosd(t); radii(2,j)*sind(t)+obj.a_w];
                end
                checkers = ut.Checkers(3:end);
                for i = find(checkers)
                    if isnan(radii(1,i)) || isnan(radii(2,i)), continue; end
                    ls = Utils.ProfileTab.profileLineStyleFunction(ut.Style(i+1));
                    obj.H(1,i) = plot(obj.AxisAnimation, circles{1,i}(1,:), circles{1,i}(2,:), 'Color', ut.Colours(i+1,:), 'LineWidth', ut.Width(i+1), 'LineStyle', ls);
                    obj.H(2,i) = plot(obj.AxisAnimation, circles{2,i}(1,:), circles{2,i}(2,:), 'Color', ut.Colours(i+1,:), 'LineWidth', ut.Width(i+1), 'LineStyle', ls);
                end
            else
                radii = [obj.gear.p.R  obj.gear.p.R_b  obj.gear.p.R_a  obj.gear.p.R_f];
                circles = cell(1, 4);
                for j = 1:4
                    circles{1,j} = [radii(1,j)*cosd(t); radii(1,j)*sind(t)];
                end
                checkers = ut.Checkers(3:end);
                for i = find(checkers)
                    if isnan(radii(1,i)), continue; end
                    ls = Utils.ProfileTab.profileLineStyleFunction(ut.Style(i+1));
                    obj.H(1,i) = plot(obj.AxisAnimation, circles{1,i}(1,:), circles{1,i}(2,:), 'Color', ut.Colours(i+1,:), 'LineWidth', ut.Width(i+1), 'LineStyle', ls);
                end
            end
        end

        function actionLinePlot(obj, ut, app, cond)
            % Compute and optionally draw the line of action / path of contact.
            if app.AnimationTabUtils.Mode.ValueIndex ~= 1, return; end

            d_a = [2*obj.gear.p.R_a,  2*obj.gear.w.R_a];

            if app.AnimationTabUtils.ToothingChoices(1).Value == 1
                % ---- Involute ----
                X = zeros(1,3); Y = zeros(1,3);
                for i = 2:-1:1
                    A = tan(obj.alpha_w)^2 + 1;
                    B = 2*tan(obj.alpha_w) * obj.d_w(i)/d_a(i);
                    C = (obj.d_w(i)/d_a(i))^2 - 1;
                    D = B^2 - 4*A*C;
                    U = (-B + sqrt(D)) / (2*A);
                    Phi_i = -asin(U);
                    X(i) = d_a(i)/2 * sin(Phi_i);
                    Y(i) = d_a(i)/2 * cos(Phi_i);
                end
                Y(2) = obj.a_w - Y(2);  X(2) = -X(2);

                l1 = sqrt((Y(2)-obj.d_w(1)/2)^2 + X(2)^2);
                l2 = sqrt((Y(1)-obj.d_w(1)/2)^2 + X(1)^2);
                obj.length_action_line = l1 + l2;
                obj.eps_a = obj.length_action_line / obj.gear.p.p_b;

                if cond
                    X_pb = obj.gear.p.p_b*cos(obj.alpha_w);
                    Y_pb = obj.gear.p.p_b*sin(obj.alpha_w);
                    X_E  = [X(1)+X_pb, X(2)-X_pb];
                    Y_E  = [Y(1)-Y_pb, Y(2)+Y_pb];
                    X(3) = 0;  Y(3) = obj.d_w(1)/2;

                    ls = Utils.ProfileTab.profileLineStyleFunction(ut.Style(1));
                    obj.Z(1) = plot(obj.AxisAnimation, X(1:2), Y(1:2), 'Color', ut.Colours(1,:), 'LineWidth', ut.Width(1), 'LineStyle', ls);
                    obj.Z(2) = plot(obj.AxisAnimation, X, Y, '.', 'Color', ut.Colours(1,:), 'MarkerSize', 20);
                    obj.Z(3) = plot(obj.AxisAnimation, X_E, Y_E, '+', 'Color', ut.Colours(1,:), 'MarkerSize', 20);

                    % Lock action-frame length to exactly 4 pinion pitches
                    % so shift == frames_in_pitch is an exact integer and
                    % the 4 tracks stay aligned with the meshing loop.
                    shift   = size(obj.frames_mesh, 2);              % frames_in_pitch
                    nFrames = 4 * shift;
                    % Resample dX so one pitch (shift frames) advances
                    % exactly one base pitch along X.
                    dX_pb = X_pb / double(shift);
                    obj.action_frames = cell(4, 1);
                    obj.action_frames{1} = nan(2, nFrames);
                    for i = 1:nFrames
                        obj.action_frames{1}(1,i) = 2*X_pb - (i-1)*dX_pb;
                        obj.action_frames{1}(2,i) = -tan(obj.alpha_w)*obj.action_frames{1}(1,i) + obj.d_w(1)/2;
                    end
                    mask = obj.action_frames{1}(1,:) < X(1) | obj.action_frames{1}(1,:) > X(2);
                    obj.action_frames{1}(:, mask) = NaN;
                    obj.action_frames{2} = circshift(obj.action_frames{1}, shift, 2);
                    obj.action_frames{3} = circshift(obj.action_frames{2}, shift, 2);
                    obj.action_frames{4} = circshift(obj.action_frames{3}, shift, 2);

                    colour = getPointColour(app);
                    for j = 1:4
                        obj.Z(j+3) = plot(obj.AxisAnimation, obj.action_frames{j}(1,1), obj.action_frames{j}(2,1), colour, 'MarkerSize', 30);
                    end
                end

            else
                % ---- Cycloidal ----
                r_a = [obj.gear.p.R_a,  obj.gear.w.R_a];
                r   = obj.d / 2;
                X_act = zeros(2, 50);  Y_act = zeros(2, 50);
                Phi_c = zeros(1, 2);

                for i = 2:-1:1
                    L = r(i) + obj.rho_a(i);
                    Y_val = (r_a(i)^2 + L^2 - obj.rho_a(i)^2) / (2*L);
                    Phi_c(i) = acos((r(i)+obj.rho_a(i)-Y_val) / obj.rho_a(i));
                    tau = linspace(0, Phi_c(i), 50);
                    X_act(i,:) = obj.rho_a(i)*sin(tau);
                    Y_act(i,:) = obj.rho_a(i)*cos(tau);
                end
                X_act(1,:) = -X_act(1,:);
                Y_act(1,:) = -Y_act(1,:) + r(1) + obj.rho_a(1);
                Y_act(2,:) =  Y_act(2,:) + r(1) - obj.rho_a(2);
                X_act(2,:) = fliplr(X_act(2,:));
                Y_act(2,:) = fliplr(Y_act(2,:));
                action = [X_act(2,1:end-1) X_act(1,:); Y_act(2,1:end-1) Y_act(1,:)];

                obj.length_action_line = Phi_c(1)*obj.rho_a(1) + Phi_c(2)*obj.rho_a(2);
                obj.eps_a = obj.length_action_line / obj.gear.w.p;

                if cond
                    X = [action(1,1) action(1,end) 0];
                    Y = [action(2,1) action(2,end) r(1)];
                    eta = obj.gear.p.p ./ obj.rho_a;
                    X_E = zeros(1,2); Y_E = zeros(1,2);

                    if eta(1) < Phi_c(1)
                        beta1 = Phi_c(1) - eta(1);
                        X_E(1) = -obj.rho_a(1)*sin(beta1);
                        Y_E(1) = -obj.rho_a(1)*cos(beta1) + r(1) + obj.rho_a(1);
                    else
                        beta1 = eta(1) - Phi_c(1);
                        X_E(1) = obj.rho_a(2)*sin(beta1);
                        Y_E(1) = obj.rho_a(2)*cos(beta1) + r(1) - obj.rho_a(2);
                    end
                    if eta(2) < Phi_c(2)
                        beta2 = Phi_c(2) - eta(2);
                        X_E(2) = obj.rho_a(2)*sin(beta2);
                        Y_E(2) = obj.rho_a(2)*cos(beta2) + r(1) - obj.rho_a(2);
                    else
                        beta2 = eta(2) - Phi_c(2);
                        X_E(2) = -obj.rho_a(1)*sin(beta2);
                        Y_E(2) = -obj.rho_a(1)*cos(beta2) + r(1) + obj.rho_a(1);
                    end

                    ls = Utils.ProfileTab.profileLineStyleFunction(ut.Style(1));
                    obj.Z(1) = plot(obj.AxisAnimation, action(1,:), action(2,:), 'Color', ut.Colours(1,:), 'LineWidth', ut.Width(1), 'LineStyle', ls);
                    obj.Z(2) = plot(obj.AxisAnimation, X, Y, '.', 'Color', ut.Colours(1,:), 'MarkerSize', 20);
                    obj.Z(3) = plot(obj.AxisAnimation, X_E, Y_E, '+', 'Color', ut.Colours(1,:), 'MarkerSize', 20);

                    betaStep = r(1)*obj.phi(1) ./ obj.rho_a;
                    tau_1 = 0:betaStep(1):2*eta(1)-betaStep(1);
                    tau_2 = betaStep(2):betaStep(2):2*eta(2);
                    X_1 = -obj.rho_a(1)*sin(tau_1);  Y_1 = -obj.rho_a(1)*cos(tau_1) + r(1) + obj.rho_a(1);
                    X_2 =  obj.rho_a(2)*sin(tau_2);   Y_2 =  obj.rho_a(2)*cos(tau_2) + r(1) - obj.rho_a(2);
                    X_2 = fliplr(X_2);  Y_2 = fliplr(Y_2);

                    obj.action_frames = cell(4, 1);
                    obj.action_frames{1} = [X_2 X_1; Y_2 Y_1];
                    mask = obj.action_frames{1}(1,:) > X(1) | obj.action_frames{1}(1,:) < X(2);
                    obj.action_frames{1}(:, mask) = NaN;
                    nPts = size(obj.action_frames{1}, 2);
                    shift = round(nPts / 4);
                    obj.action_frames{2} = circshift(obj.action_frames{1}, shift, 2);
                    obj.action_frames{3} = circshift(obj.action_frames{2}, shift, 2);
                    obj.action_frames{4} = circshift(obj.action_frames{3}, shift, 2);

                    colour = getPointColour(app);
                    for j = 1:4
                        obj.Z(j+3) = plot(obj.AxisAnimation, obj.action_frames{j}(1,1), obj.action_frames{j}(2,1), colour, 'MarkerSize', 30);
                    end
                end
            end
        end
    end

    methods (Access = private)
        function K = buildWheel(obj, Z, WHEEL)
            % Replicate a single tooth Z times around the wheel centre.
            num = size(WHEEL, 2);
            K = zeros(2, num*Z);
            for j = 0:Z-1
                K(:, 1+num*j:num*(j+1)) = obj.T_fun(j*2*pi/Z) * WHEEL;
            end
            [~, id] = unique(K', 'rows', 'stable');
            K = K(:, id);
        end

        function updateActionPoints(obj, app, j)
            % Move the action-line contact markers for frame j.
            if app.GraphicalAdditions.Checkers(2)
                nPts = size(obj.action_frames{1}, 2);
                jj = mod(j-1, nPts) + 1;
                for k = 1:4
                    if isgraphics(obj.Z(k+3)) && isvalid(obj.Z(k+3))
                        obj.Z(k+3).XData = obj.action_frames{k}(1, jj);
                        obj.Z(k+3).YData = obj.action_frames{k}(2, jj);
                    end
                end
            end
        end

        function exportMeshingVideo(obj, app, id, path_text, format)
            % Export the gear-meshing animation to a video file.
            nRep   = app.AnimationExport.ExportSpinner.Value;
            nFrame = size(obj.frames_mesh, 2);

            if app.AnimationExport.ExportDropdown(4).ValueIndex == 1
                % GIF
                for i = 1:nRep
                    for j = 1:nFrame
                        set(obj.P(id), 'XData', obj.frames_mesh{1,j}(1,:), 'YData', obj.frames_mesh{1,j}(2,:));
                        set(obj.W(id), 'XData', obj.frames_mesh{2,j}(1,:), 'YData', obj.frames_mesh{2,j}(2,:));
                        updateActionPoints(obj, app, j);
                        drawnow; pause(obj.t_p);
                        fr = getframe(obj.AxisAnimation);
                        im = frame2im(fr);
                        [imind, cm] = rgb2ind(im, 256);
                        if i == 1 && j == 1
                            imwrite(imind, cm, path_text, 'gif', 'Loopcount', inf, 'DelayTime', 1/obj.FPS);
                        else
                            imwrite(imind, cm, path_text, 'gif', 'WriteMode', 'append', 'DelayTime', 1/obj.FPS);
                        end
                        if ~app.AnimationExport.video_export_state, return; end
                    end
                end
            else
                v = VideoWriter(path_text, format);
                v.Quality = 100; open(v);
                for i = 1:nRep
                    for j = 1:nFrame
                        set(obj.P(id), 'XData', obj.frames_mesh{1,j}(1,:), 'YData', obj.frames_mesh{1,j}(2,:));
                        set(obj.W(id), 'XData', obj.frames_mesh{2,j}(1,:), 'YData', obj.frames_mesh{2,j}(2,:));
                        updateActionPoints(obj, app, j);
                        drawnow; pause(obj.t_p);
                        writeVideo(v, getframe(obj.AxisAnimation));
                        if ~app.AnimationExport.video_export_state, break; end
                    end
                end
                close(v);
            end
        end

        function exportHobbingVideo(obj, app, id_r, path_text, format)
            % Export the hobbing animation to a video file.
            % id_r selects which elements of obj.R to update (line only, or
            % both line and fill patch) so set() never touches an invalid
            % graphics object.
            nFrame = numel(obj.frames_hobbing);

            if app.AnimationExport.ExportDropdown(4).ValueIndex == 1
                for j = 1:nFrame
                    set(obj.R(id_r), 'XData', obj.frames_hobbing{j}(1,:), 'YData', obj.frames_hobbing{j}(2,:));
                    drawnow; pause(obj.t_p);
                    fr = getframe(obj.AxisAnimation);
                    im = frame2im(fr);
                    [imind, cm] = rgb2ind(im, 256);
                    if j == 1
                        imwrite(imind, cm, path_text, 'gif', 'Loopcount', inf, 'DelayTime', 1/obj.FPS);
                    else
                        imwrite(imind, cm, path_text, 'gif', 'WriteMode', 'append', 'DelayTime', 1/obj.FPS);
                    end
                    if ~app.AnimationExport.video_export_state, return; end
                end
            else
                v = VideoWriter(path_text, format);
                v.Quality = 100; open(v);
                for j = 1:nFrame
                    set(obj.R(id_r), 'XData', obj.frames_hobbing{j}(1,:), 'YData', obj.frames_hobbing{j}(2,:));
                    drawnow; pause(obj.t_p);
                    writeVideo(v, getframe(obj.AxisAnimation));
                    if ~app.AnimationExport.video_export_state, break; end
                end
                close(v);
            end
        end
    end
end

function colour = getPointColour(app)
    % Return a point-marker colour string appropriate for the current theme.
    if strcmp(app.OutputFigure.Theme.BaseColorStyle, 'light')
        colour = 'k.';
    else
        colour = 'w.';
    end
end
