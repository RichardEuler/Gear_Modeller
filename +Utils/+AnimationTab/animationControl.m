% Copyright (c) 2026 Richard Timko
classdef animationControl < handle
    % This class is responsible for the animation control

    properties
        % Properties present in the editfields inside the animation tab
        m (1,1) double {mustBeInteger} = 1
        z (2,1) double {mustBeInteger} = [20; 30]
        x (2,1) double {mustBeNumeric} = [0; 0]
        alpha (1,1) double {mustBePositive} = 20
        rho_a (2,1) double {mustBePositive} = [5; 5]
        rho_f (2,1) double {mustBePositive} = [5; 5]
        j_b (1,1) double {mustBeNonnegative} = 0
        alpha_w (1,1) double {mustBePositive} = 20
        a_w (1,1) double {mustBePositive} = 25
        y (1,1) double {mustBeNumeric} = 0

        % Properties resulting from furter calculations inside the object
        a (1,1) double {mustBePositive} = 25
        d (2,1) double {mustBePositive} = [20; 30]
        d_w (2,1) double {mustBePositive} = [20; 30]
        u (1,1) double {mustBePositive} = 1.5
        eps_a (1,1) double % Súčiniteľ záberu profilu
        length_action_line (1,1) double % Dĺžka dráhy záberu

        gear struct
        tooth struct
        tool struct

        rack double
        wheel double
        pinion double

        T_fun function_handle % Tranformtin matrix function
        T struct % Transformation matrix for animated sequence
        n (2,1) double % Rotational frequency [1/s]
        FPS (1,1) double % Frames per second [Hz]
        frames_mesh cell % Frames inside a pitch
        action_frames cell % Frames of contact point along the action line
        frames_hobbing cell % Frames for moving rack
        AxisAnimation matlab.graphics.axis.Axes % Property to save axes for output figure
        quality (1,1) uint8

        start_state (1,1) logical {mustBeMember(start_state,[0 1])} = 0 % Checker for animation displayed on figure
        t_p
        P % Pinion plot object
        W % Wheel plot object
        R % Rack plot object
        H % Significant circles
        Z % Line of action
        theta
        phi
    end

    methods
        function obj = animationControl(ut,fig,quality)
            % Class constructor
            arguments
                ut 
                fig 
                quality (1,1) uint8 {mustBeInteger} = 50
            end

            obj.quality = quality;
            
            obj.T_fun = @(x) [cos(x) sin(x); -sin(x) cos(x)];
            obj.T = struct('p',zeros(2) ,'w',zeros(2));
            obj.tooth = struct('p',[],'w',[],'r',[]); % Structure for pinion, wheel and rack tooth

            obj.theta = 6*pi/obj.z(1);
            updateAnimationSetting(obj,ut);

            ordered_variables = [obj.m obj.z' obj.x' obj.alpha obj.rho_a(2)];
            for j = 1:length(ut.ValueEdit1)
                ut.ValueEdit1(j).Value = ordered_variables(j);
            end

            obj.alpha = deg2rad(obj.alpha);
            obj.alpha_w = deg2rad(obj.alpha_w);

            obj.gear = struct('p',[],'w',[],'r',[]); % Structure for pinion, wheel and rack object

            obj.AxisAnimation = axes(fig,"HandleVisibility","off","Visible",0);
            axis(obj.AxisAnimation,"equal");
            hold(obj.AxisAnimation,"on");

            obj.P = gobjects(2,1); obj.W = gobjects(2,1); obj.R = gobjects(2,1);
            obj.H = gobjects(2,4);
            obj.Z = gobjects(7,1);
        end

        function updateAnimationSetting(obj,ut)
            % Method function used as a callback for spinner components

            obj.n(1) = ut.AnimationSpinners(1).Value/3600; % Pinion revolutions per second [1/s]
            obj.n(2) = obj.n(1)/obj.u; % Gear wheel revolutions per second [1/s]
            ut.AnimationSpinners(2).Limits = [max(obj.z)*obj.n(1) Inf];
            obj.FPS = ut.AnimationSpinners(2).Value; % Frames per second [Hz]

            obj.phi = 2*pi*obj.n/obj.FPS; % Rotation angle [rad]
            obj.T.p = obj.T_fun(-obj.phi(1)); % Transformation matrix for pinion
            obj.T.w = obj.T_fun(obj.phi(2)); % Transformation matrix for gear wheel

            if ut.Mode.ValueIndex == 1 % Gear meshing mode active
                frames_in_pitch = round( obj.FPS./(obj.z(1) .* obj.n(1)) );
                obj.frames_mesh = cell(2,frames_in_pitch); % Initialize pinion and wheel frames
            else
                frames_rack = round(2*obj.theta/obj.phi(1));
                obj.frames_hobbing = cell(1,frames_rack); % Initialize rack frames
            end
        end

        function assignValues(obj,ut)
            % Method Function for properties assignment

            obj.m = ut.ValueEdit1(1).Value;

            if ut.Mode.ValueIndex == 1 % Gear meshing mode active
                for j = 1:2
                    if mod(ut.ValueEdit1(j+1).Value,1) ~= 0
                        ut.ValueEdit1(j+1).Value = round(ut.ValueEdit1(j+1).Value);
                    end
                    obj.z(j) = ut.ValueEdit1(j+1).Value;
                    obj.x(j) = ut.ValueEdit1(j+3).Value;
                end

                if ut.ToothingChoices(1).Value == 1 % Involute gear active
                    ut.ValueEdit1(6).Limits = [0 Inf];
                    obj.alpha = deg2rad(ut.ValueEdit1(6).Value);

                else % Cycloid gear active
                    ut.ValueEdit1(6).Limits(1) = ( 1.25-obj.x(2) ) * obj.m/2;
                    ut.ValueEdit1(6).Limits(2) = ( obj.z(2)-1.25-obj.x(2) ) * obj.m/2;

                    ut.ValueEdit1(7).Limits(1) = ( 1.25-obj.x(1) ) * obj.m/2;
                    ut.ValueEdit1(7).Limits(2) = ( obj.z(1)-1.25-obj.x(1) ) * obj.m/2;

                    for j = 1:2
                        obj.rho_a(j) = ut.ValueEdit1(j+5).Value;
                        obj.rho_f(j) = ut.ValueEdit1(8-j).Value;
                    end
                end

                ut.AnimationSpinners(2).Limits = [max(obj.z)*obj.n(1) Inf];
                obj.d = obj.m*obj.z; % Pitch circle diamater
                obj.a = sum(obj.d)/2; % Center distance
                obj.u = obj.z(2)/obj.z(1); % Gear ratio

            else % Hobbing mode active
                if mod(ut.ValueEdit1(2).Value,1) ~= 0
                    ut.ValueEdit1(2).Value = round(ut.ValueEdit1(2).Value);
                end
                obj.z(1) = ut.ValueEdit1(2).Value;
                obj.x(1) = ut.ValueEdit1(4).Value;

                obj.theta = 6*pi/obj.z(1);

                if ut.ToothingChoices(1).Value == 1 % Involute gear active
                    ut.ValueEdit1(6).Limits = [0 Inf];
                    obj.alpha = deg2rad(ut.ValueEdit1(6).Value);

                else % Cycloid gear active
                    ut.ValueEdit1(6).Limits(1) = max([( 1+obj.x(1) )*obj.m, obj.m+ceil(4*sqrt(obj.m))/10])/2;
                    ut.ValueEdit1(6).Limits(2) = Inf;

                    ut.ValueEdit1(7).Limits(1) = max([1.25-obj.x(1), 1.25])*obj.m/2 ;
                    ut.ValueEdit1(7).Limits(2) = ( obj.z(1)-1.25-obj.x(1) ) * obj.m/2;

                    obj.rho_a(1) = ut.ValueEdit1(6).Value;
                    obj.rho_f(1) = ut.ValueEdit1(7).Value;
                end

                ut.AnimationSpinners(2).Limits = [obj.z(1)*obj.n(1) Inf];
                obj.d(1) = obj.m*obj.z(1); % Pitch circle diamater
            end
        end

        function calculationFun(obj,ut,route1,route2,route3,switch_route)
            % Method function used for make calculations
            % ut - utils object responsible for managing the animation tab
            arguments
                obj 
                ut
                route1 (1,1) uint8 {mustBeMember(route1,[0 1])} = 0
                route2 (1,1) uint8 {mustBeMember(route2,[0 2 3])} = 0
                route3 (1,1) uint8 {mustBeMember(route3,[0 2 3])} = 0
                switch_route (1,1) logical = false
            end

            if route2 == 2 % Teeth number of pinion changed
                if ut.ValueEdit1(2).Value > ut.ValueEdit1(3).Value
                    ut.ValueEdit1(3).Value = ut.ValueEdit1(2).Value;
                end
            elseif route2 == 3 % Teeth number of gear wheel changed
                if ut.ValueEdit1(3).Value < ut.ValueEdit1(2).Value
                    ut.ValueEdit1(2).Value = ut.ValueEdit1(3).Value;
                end
            end

            if ut.Mode.ValueIndex && ~ut.ToothingChoices(1).Value % % Gear meshing mode active and Cycloid gear active
                if route3 == 2 % Changing the Profile Shift Coefficient of the pinion
                    if ut.ValueEdit1(4).Value == 0
                        ut.ValueEdit1(5).Value = 0; % Just simply to get rid off -0
                    else
                        ut.ValueEdit1(5).Value = -ut.ValueEdit1(4).Value;
                    end
                elseif route3 == 3 % Changing the Profile Shift Coefficient of the gear wheel
                    if ut.ValueEdit1(5).Value == 0
                        ut.ValueEdit1(4).Value = 0; % Just simply to get rid off -0
                    else
                        ut.ValueEdit1(4).Value = -ut.ValueEdit1(5).Value;
                    end
                end
            end

            if ~switch_route
                assignValues(obj,ut)
            end

            if ut.Mode.ValueIndex % Gear meshing mode active
                if ut.ToothingChoices(1).Value % Involute gear active
                    % Editfield Limits
                    alpha_w_lim = 2*sum(obj.x)/sum(obj.z)*tan(obj.alpha) + inv(obj.alpha);
                    alpha_w_lim = arcinv(alpha_w_lim);
                    a_w_lim = cos(obj.alpha)/cos(alpha_w_lim)*obj.a;
                    y_lim = sum(obj.x) - (a_w_lim-obj.a)/obj.m;

                    ut.ValueEdit2(2).Limits(1) = rad2deg(alpha_w_lim);
                    ut.ValueEdit2(3).Limits(1) = a_w_lim;
                    ut.ValueEdit2(4).Limits(2) = y_lim;

                    if ut.MeshingChoices(1).Value == 1 || route1 == 1 % Specifying from the gear backlash
                        obj.j_b = ut.ValueEdit2(1).Value*1e-3;
                        inv_alpha_w = ( 2*sum(obj.x)*obj.m*sin(obj.alpha) + obj.j_b )/( sum(obj.z)*obj.m*cos(obj.alpha) ) + inv(obj.alpha);
                        obj.alpha_w = arcinv(inv_alpha_w);
                        obj.a_w = cos(obj.alpha)/cos(obj.alpha_w)*obj.a;
                        obj.y = sum(obj.x) - (obj.a_w-obj.a)/obj.m;
                        escluded_variable = 1;

                    elseif ut.MeshingChoices(2).Value == 1 % Specifying from the working pressure angle
                        obj.alpha_w = deg2rad(ut.ValueEdit2(2).Value);
                        obj.j_b = sum(obj.z)*( inv(obj.alpha_w) - inv(obj.alpha) )*obj.m*cos(obj.alpha) - 2*sum(obj.x)*obj.m*sin(obj.alpha);
                        obj.a_w = cos(obj.alpha)/cos(obj.alpha_w)*obj.a;
                        obj.y = sum(obj.x) - (obj.a_w-obj.a)/obj.m;
                        escluded_variable = 2;

                    elseif ut.MeshingChoices(3).Value == 1 % Specifying from the working center distance
                        obj.a_w = ut.ValueEdit2(3).Value;
                        obj.alpha_w = acos( cos(obj.alpha)*obj.a/obj.a_w );
                        obj.j_b = sum(obj.z)*( inv(obj.alpha_w) - inv(obj.alpha) )*obj.m*cos(obj.alpha) - 2*sum(obj.x)*obj.m*sin(obj.alpha);
                        obj.y = sum(obj.x) - (obj.a_w-obj.a)/obj.m;
                        escluded_variable = 3;

                    else % Specifying from the center distance modification
                        obj.y = ut.ValueEdit2(4).Value;
                        obj.a_w = sum(obj.x)*obj.m + obj.a - obj.y*obj.m;
                        obj.alpha_w = acos( cos(obj.alpha)*obj.a/obj.a_w );
                        obj.j_b = sum(obj.z)*( inv(obj.alpha_w) - inv(obj.alpha) )*obj.m*cos(obj.alpha) - 2*sum(obj.x)*obj.m*sin(obj.alpha);
                        escluded_variable = 4;

                    end

                    obj.d_w(1) = 2*obj.a_w/(1+obj.u); obj.d_w(2) =  obj.d_w(1)*obj.u; % Rolling (working) circle diameters
                    ordered_variables = [obj.j_b*1e3 rad2deg(obj.alpha_w) obj.a_w obj.y];
                    variables = 1:4; variables(escluded_variable) = [];

                    for j = variables
                        ut.ValueEdit2(j).Value = ordered_variables(j);
                    end

                else % Cycloid gear active
                    obj.a_w = obj.a;
                    obj.d_w(1) = 2*obj.a_w/(1+obj.u); obj.d_w(2) =  obj.d_w(1)*obj.u;
                end
            end

            %% Additional functions
            function alfa = arcinv(phi)
                % Inverzná funkcia involuty počítaná numericky
                fun = @(gamma) tan(gamma) - gamma - phi;
                alfa = fzero(fun,0);
                mustBeLessThan(alfa,pi/2);
            end

            function phi = inv(alfa)
                % Funkcia involuty
                phi = tan(alfa) - alfa;
            end
        end

        function displayFun(obj,app)
            if app.ProfileTabManagerUtils.ProfileCounter > 0
                CancelAllFun(app)
            end

            app.StartPauseButton.Enable = 1;
            ut = app.AnimationTabUtils;
            app.AnimationExport.ExportButton.Enable = 1;

            if ut.Mode.ValueIndex == 1 % Gear meshing mode active
                if ut.ToothingChoices(1).Value == 1 % Involute gear active
                    obj.gear.p = Generator.involuteToothing(obj.m, rad2deg(obj.alpha), obj.z(1), obj.x(1), obj.quality);
                    obj.gear.w = Generator.involuteToothing(obj.m, rad2deg(obj.alpha), obj.z(2), obj.x(2), obj.quality);

                    % Initial positional angle of the tooth profle
                    in_angle(1) = pi/obj.z(1) + obj.gear.p.psi(obj.x(1)) - ( tan(obj.alpha_w) - obj.alpha_w );
                    in_angle(2) = pi/obj.z(2) + obj.gear.w.psi(obj.x(2)) - ( tan(obj.alpha_w) - obj.alpha_w ) + pi;

                else % Cycloid gear active
                    obj.gear.p = Generator.cycloidToothing(obj.m, obj.rho_a(1), obj.rho_f(1), obj.z(1), obj.x(1), obj.quality);
                    obj.gear.w = Generator.cycloidToothing(obj.m, obj.rho_a(2), obj.rho_f(2), obj.z(2), obj.x(2), obj.quality);

                    % Initial positional angle of the tooth profle
                    in_angle(1) = pi/obj.z(1) - obj.gear.p.psi;
                    in_angle(2) = pi/obj.z(2) - obj.gear.w.psi + pi;

                end

                obj.tooth.p = obj.gear.p.tooth; obj.tooth.w = obj.gear.w.tooth;

                obj.tooth.p = obj.T_fun( in_angle(1) ) * obj.tooth.p;
                obj.tooth.w = obj.T_fun( in_angle(2) ) * obj.tooth.w;

                obj.pinion = wheelGenerator(obj.z(1),obj.tooth.p(:,1:end-1));
                obj.wheel = wheelGenerator(obj.z(2),obj.tooth.w(:,1:end-1));

                obj.pinion(:,end+1) = obj.pinion(:,1);
                obj.wheel(:,end+1) = obj.wheel(:,1);

            else
                if ut.ToothingChoices(1).Value == 1 % Involute gear active
                    obj.gear.p = Generator.involuteToothing(obj.m, rad2deg(obj.alpha), obj.z(1), obj.x(1), obj.quality);
                    obj.gear.r = Generator.trapezoidalRack(obj.m, rad2deg(obj.alpha), obj.x(1), obj.quality);
                else % Cycloid gear active
                    obj.gear.p = Generator.cycloidToothing(obj.m, obj.rho_a(1), obj.rho_f(1), obj.z(1), obj.x(1), obj.quality);
                    obj.gear.r = Generator.cycloidRack(obj.m, obj.rho_f(1), obj.rho_a(1), obj.x(1), obj.quality);
                end

                obj.tooth.p = obj.gear.p.tooth;
                obj.tooth.r = obj.gear.r.tooth + [-obj.d(1)/2*obj.theta;obj.d(1)/2];

                obj.pinion = wheelGenerator(obj.z(1),obj.tooth.p(:,1:end-1));
                obj.pinion(:,end+1) = obj.pinion(:,1);
                obj.pinion = obj.T_fun(pi/obj.z(1))*obj.pinion;
            end

            function K = wheelGenerator(Z, WHEEL)
                num = length(WHEEL);
                K = zeros(2,num*Z);
                for j = 0:Z-1
                    K(:,1+num*j:num*(j+1)) = obj.T_fun( j*2*pi/Z ) * WHEEL;
                end
                [~, id] = unique(K', 'rows', 'stable');
                K = K(:,id);
            end

            obj.t_p = 1/obj.FPS;
            plot(obj,app.AnimationTabUtils,app);
        end

        function plot(obj,ut,app)
            % Method function concerning graphical output

            if app.ProfileTabManagerUtils.ProfileCounter > 0
                CancelAllProfilesButtonPushed(app, event);
            end
            delete(findobj(obj.AxisAnimation,'Type','Line'));

            app.HomeUtils.FigureText.Visible = 0;

            set(obj.AxisAnimation,"HandleVisibility","on","Visible",1);
            axis(obj.AxisAnimation,"equal");
            hold(obj.AxisAnimation,"on");
            
            if ut.Checkers(1).Value
                grid(obj.AxisAnimation,"on");
            else
                grid(obj.AxisAnimation,"off");
            end

            if ut.Checkers(2).Value
                axis(obj.AxisAnimation,"on");
            else
                axis(obj.AxisAnimation,"off");
            end

            circlesPlot(obj,app.GraphicalAdditions,app);

            delete([obj.P(2) obj.W(2) obj.R(2)]);
            if app.AnimationTabUtils.Mode.ValueIndex == 1 % Gear meshing mode active
                obj.frames_mesh{1,1} = [obj.pinion(1,:); obj.pinion(2,:)];
                obj.frames_mesh{2,1} = [obj.wheel(1,:); obj.wheel(2,:)];

                for j = 1:length(obj.frames_mesh)-1
                    obj.frames_mesh{1,j+1} = obj.T.p * obj.frames_mesh{1,j};
                    obj.frames_mesh{2,j+1} = obj.T.w * obj.frames_mesh{2,j};
                end

                for j = 1:length(obj.frames_mesh)
                    obj.frames_mesh{2,j}(2,:) = obj.frames_mesh{2,j}(2,:) + obj.a_w;
                end

                if ut.Menus(3).Checked == 0
                    obj.P(2) = patch(obj.AxisAnimation,"XData",obj.frames_mesh{1,1}(1,:),"YData",obj.frames_mesh{1,1}(2,:),"FaceColor",ut.ColorChoice(2).Value,"EdgeColor","none","FaceAlpha",ut.Transparency);
                    obj.W(2) = patch(obj.AxisAnimation,"XData",obj.frames_mesh{2,1}(1,:),"YData",obj.frames_mesh{2,1}(2,:),"FaceColor",ut.ColorChoice(2).Value,"EdgeColor","none","FaceAlpha",ut.Transparency);
                end

                obj.P(1) = plot(obj.AxisAnimation,obj.frames_mesh{1,1}(1,:),obj.frames_mesh{1,1}(2,:),"Color",ut.ColorChoice(1).Value,"LineWidth",ut.AnimationSpinners(3).Value,"LineStyle",Utils.ProfileTab.profileLineStyleFunction(ut.StyleLine.ValueIndex));
                obj.W(1) = plot(obj.AxisAnimation,obj.frames_mesh{2,1}(1,:),obj.frames_mesh{2,1}(2,:),"Color",ut.ColorChoice(1).Value,"LineWidth",ut.AnimationSpinners(3).Value,"LineStyle",Utils.ProfileTab.profileLineStyleFunction(ut.StyleLine.ValueIndex));

            else % Hobbing mode active
                for j = 1:length(obj.frames_hobbing)
                    obj.frames_hobbing{j} = obj.tooth.r + [(j-1)*obj.phi(1)*obj.d(1)/2; 0];
                    obj.frames_hobbing{j} = obj.T_fun(obj.theta-(j-1)*obj.phi(1)) * obj.frames_hobbing{j};
                end
                obj.P(1) = plot(obj.AxisAnimation,obj.pinion(1,:),obj.pinion(2,:),"Color",ut.ColorChoice(1).Value,"LineWidth",ut.AnimationSpinners(3).Value,"LineStyle",Utils.ProfileTab.profileLineStyleFunction(ut.StyleLine.ValueIndex));
                obj.R(1) = plot(obj.AxisAnimation,obj.frames_hobbing{1}(1,:),obj.frames_hobbing{1}(2,:),"Color",ut.ColorChoice(1).Value,"LineWidth",ut.AnimationSpinners(3).Value,"LineStyle",Utils.ProfileTab.profileLineStyleFunction(ut.StyleLine.ValueIndex));

                if ut.Menus(3).Checked == 0
                    obj.P(2) = patch(obj.AxisAnimation,"XData",obj.pinion(1,:),"YData",obj.pinion(2,:),"FaceColor",ut.ColorChoice(2).Value,"EdgeColor","none","FaceAlpha",ut.Transparency);
                    obj.R(2) = patch(obj.AxisAnimation,"XData",obj.frames_hobbing{1}(1,:),"YData",obj.frames_hobbing{1}(2,:),"FaceColor",ut.ColorChoice(2).Value,"EdgeColor","none","FaceAlpha",ut.Transparency);
                end
            end

            if app.GraphicalAdditions.Checkers(2) == 1
                actionLinePlot(obj,app.GraphicalAdditions,app,1);
            else
                actionLinePlot(obj,app.GraphicalAdditions,app,0);
            end

            if isgraphics(app.AnimationParameters.F)
                textValueAssignment(app.AnimationParameters,obj)
            end
        end

        function startAnimation(obj,app,path_text,format)
            arguments
                obj 
                app
                path_text = "none"
                format = "none"
            end

            obj.start_state = 1;

            if obj.start_state
                app.AnimationExport.ExportButton.Enable = 0;
            else
                app.AnimationExport.ExportButton.Enable = 1;
            end

            line = numel(app.LanguageUtils.AnimationTabTextFile) - 1;
            itemsCellArray = split(app.LanguageUtils.AnimationTabTextFile{line}, ',');
            itemsCellArray = strtrim(itemsCellArray);
            if app.AnimationControl.start_state == 0
                app.StartPauseButton.Text = itemsCellArray{1};
            else
                app.StartPauseButton.Text = itemsCellArray{2};
            end

            %% GEAR MESHING MODE ACTIVE
            if app.AnimationTabUtils.Mode.ValueIndex == 1
                if isvalid(obj.P(2))
                    id = [1 2];
                else
                    id = 1;
                end

                if app.AnimationExport.video_export_state

                    % VIDEO EXPORTING OPTION
                    if app.AnimationExport.ExportDropdown(4).ValueIndex == 1 % GIF SELECTION
                        for i = 1:app.AnimationExport.ExportSpinner.Value
                            for j = 1:length(obj.frames_mesh)
                                % Assign the transformed results

                                set(obj.P(id),"XData",obj.frames_mesh{1,j}(1,:),"YData",obj.frames_mesh{1,j}(2,:))
                                set(obj.W(id),"XData",obj.frames_mesh{2,j}(1,:),"YData",obj.frames_mesh{2,j}(2,:))

                                if app.GraphicalAdditions.Checkers(2)
                                    obj.Z(4).XData = obj.action_frames{1}(1,j); obj.Z(4).YData = obj.action_frames{1}(2,j);
                                    obj.Z(5).XData = obj.action_frames{2}(1,j); obj.Z(5).YData = obj.action_frames{2}(2,j);
                                    obj.Z(6).XData = obj.action_frames{3}(1,j); obj.Z(6).YData = obj.action_frames{3}(2,j);
                                    obj.Z(7).XData = obj.action_frames{4}(1,j); obj.Z(7).YData = obj.action_frames{4}(2,j);
                                end

                                drawnow;
                                pause(obj.t_p);

                                frame = getframe(obj.AxisAnimation);
                                image = frame2im(frame);
                                [imind, cm] = rgb2ind(image, 256);

                                if j == 1
                                    % Create the file
                                    imwrite(imind, cm, path_text, 'gif', 'Loopcount', inf, 'DelayTime', 1/obj.FPS);
                                else
                                    % Append to the existing file
                                    imwrite(imind, cm, path_text, 'gif', 'WriteMode', 'append', 'DelayTime', 1/obj.FPS);
                                end

                                if ~app.AnimationExport.video_export_state
                                    break
                                end
                            end
                        end

                    else % AVI or MP4 SELECTION

                        v = VideoWriter(path_text,format);
                        v.Quality = 100;
                        open(v);
                        for i = 1:app.AnimationExport.ExportSpinner.Value
                            for j = 1:length(obj.frames_mesh)
                                % Assign the transformed results
                                set(obj.P(id),"XData",obj.frames_mesh{1,j}(1,:),"YData",obj.frames_mesh{1,j}(2,:))
                                set(obj.W(id),"XData",obj.frames_mesh{2,j}(1,:),"YData",obj.frames_mesh{2,j}(2,:))

                                if app.GraphicalAdditions.Checkers(2)
                                    obj.Z(4).XData = obj.action_frames{1}(1,j); obj.Z(4).YData = obj.action_frames{1}(2,j);
                                    obj.Z(5).XData = obj.action_frames{2}(1,j); obj.Z(5).YData = obj.action_frames{2}(2,j);
                                    obj.Z(6).XData = obj.action_frames{3}(1,j); obj.Z(6).YData = obj.action_frames{3}(2,j);
                                    obj.Z(7).XData = obj.action_frames{4}(1,j); obj.Z(7).YData = obj.action_frames{4}(2,j);
                                end

                                drawnow;
                                pause(obj.t_p);

                                frame = getframe(obj.AxisAnimation);
                                writeVideo(v, frame);

                                if ~app.AnimationExport.video_export_state
                                    break
                                end
                            end
                        end

                        close(v);
                    end

                else
                    % ONLY PLAY BUTTON OPTION
                    while obj.start_state == 1
                        for j = 1:length(obj.frames_mesh)
                            % Assign the transformed results
                            set(obj.P(id),"XData",obj.frames_mesh{1,j}(1,:),"YData",obj.frames_mesh{1,j}(2,:))
                            set(obj.W(id),"XData",obj.frames_mesh{2,j}(1,:),"YData",obj.frames_mesh{2,j}(2,:))

                            if app.GraphicalAdditions.Checkers(2)
                                obj.Z(4).XData = obj.action_frames{1}(1,j); obj.Z(4).YData = obj.action_frames{1}(2,j);
                                obj.Z(5).XData = obj.action_frames{2}(1,j); obj.Z(5).YData = obj.action_frames{2}(2,j);
                                obj.Z(6).XData = obj.action_frames{3}(1,j); obj.Z(6).YData = obj.action_frames{3}(2,j);
                                obj.Z(7).XData = obj.action_frames{4}(1,j); obj.Z(7).YData = obj.action_frames{4}(2,j);
                            end

                            drawnow;
                            pause(obj.t_p);
                        end
                    end
                end

            %% HOBBING MODE ACTIVE
            else

                if app.AnimationExport.video_export_state
                    % VIDEO EXPORTING OPTION
                    if app.AnimationExport.ExportDropdown(4).ValueIndex == 1 % GIF SELECTION
                        for j = 1:length(obj.frames_hobbing)
                            % Assign the transformed results
                            set(obj.R,"XData",obj.frames_hobbing{j}(1,:),"YData",obj.frames_hobbing{j}(2,:))

                            drawnow;
                            pause(obj.t_p);

                            frame = getframe(obj.AxisAnimation);
                            image = frame2im(frame);
                            [imind, cm] = rgb2ind(image, 256);

                            if j == 1
                                % Create the file
                                imwrite(imind, cm, path_text, 'gif', 'Loopcount', inf, 'DelayTime', 1/obj.FPS);
                            else
                                % Append to the existing file
                                imwrite(imind, cm, path_text, 'gif', 'WriteMode', 'append', 'DelayTime', 1/obj.FPS);
                            end

                            if ~app.AnimationExport.video_export_state
                                break
                            end
                        end

                    else % AVI or MP4 SELECTION

                        v = VideoWriter(path_text,format);
                        v.Quality = 100;
                        open(v);

                        for j = 1:length(obj.frames_hobbing)
                            % Assign the transformed results
                            set(obj.R,"XData",obj.frames_hobbing{j}(1,:),"YData",obj.frames_hobbing{j}(2,:))

                            drawnow;
                            pause(obj.t_p);

                            frame = getframe(obj.AxisAnimation);
                            writeVideo(v, frame);

                            if ~app.AnimationExport.video_export_state
                                break
                            end
                        end
                        close(v);
                    end
                else
                    % ONLY PLAY BUTTON OPTION
                    for j = 1:length(obj.frames_hobbing)
                        if obj.start_state == 0
                            continue
                        end
                        % Assign the transformed results
                        set(obj.R,"XData",obj.frames_hobbing{j}(1,:),"YData",obj.frames_hobbing{j}(2,:))

                        drawnow;
                        pause(obj.t_p);
                    end
                end
                obj.start_state = 0;
                app.StartPauseButton.Text = itemsCellArray{1};
            end
        end

        function circlesPlot(obj,ut,app)
            if app.AnimationTabUtils.Mode.ValueIndex == 1 % Gear meshing mode active
                circles = cell(2,5);

                t = 0:360;
                radii = [obj.gear.p.R obj.gear.p.R_b obj.gear.p.R_a obj.gear.p.R_f; obj.gear.w.R obj.gear.w.R_b obj.gear.w.R_a obj.gear.w.R_f];
                for j = 1:4
                    circles{1,j}(1,:) = radii(1,j)*cosd(t); circles{1,j}(2,:) = radii(1,j)*sind(t);
                    circles{2,j}(1,:) = radii(2,j)*cosd(t); circles{2,j}(2,:) = radii(2,j)*sind(t)+obj.a_w;
                end

                checkers = ut.Checkers(3:end);
                for i = find(checkers)
                    obj.H(1,i) = plot(obj.AxisAnimation, circles{1,i}(1,:), circles{1,i}(2,:),"Color",ut.Colours(i+1,:),"LineWidth",ut.Width(i+1),"LineStyle",Utils.ProfileTab.profileLineStyleFunction(ut.Style(i+1)));
                    obj.H(2,i) = plot(obj.AxisAnimation, circles{2,i}(1,:), circles{2,i}(2,:),"Color",ut.Colours(i+1,:),"LineWidth",ut.Width(i+1),"LineStyle",Utils.ProfileTab.profileLineStyleFunction(ut.Style(i+1)));
                end

            else % Hobbing mode active
                circles = cell(1,5);

                t = 0:360;
                radii = [obj.gear.p.R obj.gear.p.R_b obj.gear.p.R_a obj.gear.p.R_f];
                for j = 1:4
                    circles{1,j}(1,:) = radii(1,j)*cosd(t); circles{1,j}(2,:) = radii(1,j)*sind(t);
                end

                checkers = ut.Checkers(3:end);
                for i = find(checkers)
                    obj.H(1,i) = plot(obj.AxisAnimation, circles{1,i}(1,:), circles{1,i}(2,:),"Color",ut.Colours(i+1,:),"LineWidth",ut.Width(i+1),"LineStyle",Utils.ProfileTab.profileLineStyleFunction(ut.Style(i+1)));
                end

            end
        end

        function actionLinePlot(obj,ut,app,cond)
            if app.AnimationTabUtils.Mode.ValueIndex == 1 % Gear meshing mode active
                d_a(1) = 2*obj.gear.p.R_a; d_a(2) = 2*obj.gear.w.R_a;
                    if app.AnimationTabUtils.ToothingChoices(1).Value == 1 % Involute gear active
                        for i = 2:-1:1
                            % Solution of quadratic equatiion
                            A = tan(obj.alpha_w)^2 + 1;
                            B = 2*tan(obj.alpha_w) * obj.d_w(i)/d_a(i);
                            C = ( obj.d_w(i)/d_a(i) )^2 - 1;
                            D = B^2 - 4*A*C;
                            U = ( -B + sqrt(D) )/( 2*A );
                            Phi(i) = -asin(U);
                            X(i) = d_a(i)/2 * sin(Phi(i));
                            Y(i) = d_a(i)/2 * cos(Phi(i));
                        end
                        Y(2) = obj.a_w-Y(2); X(2) = -X(2);

                        length_action_line_1 = sqrt( (Y(2) - obj.d_w(1)/2)^2 + X(2)^2 );
                        length_action_line_2 = sqrt( (Y(1) - obj.d_w(1)/2)^2 + X(1)^2 );
                        obj.length_action_line = length_action_line_1 + length_action_line_2;
                        obj.eps_a = obj.length_action_line/obj.gear.p.p_b;

                        if cond
                            X_pb = obj.gear.p.p_b*cos(obj.alpha_w); Y_pb = obj.gear.p.p_b*sin(obj.alpha_w);
                            X_E(1) = X(1) + X_pb; Y_E(1) = Y(1) - Y_pb;
                            X_E(2) = X(2) - X_pb; Y_E(2) = Y(2) + Y_pb;

                            X(3) = 0; Y(3) = obj.d_w(1)/2; % Rolling point

                            obj.Z(1) = plot(obj.AxisAnimation,X(1:2),Y(1:2),"Color",ut.Colours(1,:),"LineWidth",ut.Width(1),"LineStyle",Utils.ProfileTab.profileLineStyleFunction(ut.Style(1)));
                            obj.Z(2) = plot(obj.AxisAnimation,X,Y,".","Color",ut.Colours(1,:),"MarkerSize",20);
                            obj.Z(3) = plot(obj.AxisAnimation,X_E,Y_E,"+","Color",ut.Colours(1,:),"MarkerSize",20);

                            dX_pb = obj.gear.p.R_b*obj.phi(1)*cos(obj.alpha_w);
                            obj.action_frames = cell(2,1);
                            obj.action_frames{1} = nan(2, int32( 8*pi/( obj.z(1)*obj.phi(1) ) ));
                            for i = 1:size(obj.action_frames{1},2)
                                obj.action_frames{1}(1,i) = 2*X_pb-(i-1)*dX_pb;
                                obj.action_frames{1}(2,i) = -tan(obj.alpha_w)*obj.action_frames{1}(1,i) + obj.d_w(1)/2;
                            end
                            mask = obj.action_frames{1}(1,:) < X(1) | obj.action_frames{1}(1,:) > X(2);
                            obj.action_frames{1}(:, mask) = NaN;
                            obj.action_frames{2} = circshift(obj.action_frames{1},size(obj.action_frames{1},2)/4,2);
                            obj.action_frames{3} = circshift(obj.action_frames{2},size(obj.action_frames{1},2)/4,2);
                            obj.action_frames{4} = circshift(obj.action_frames{3},size(obj.action_frames{1},2)/4,2);

                            if strcmp(app.OutputFigure.Theme.BaseColorStyle,"light")
                                colour = "k.";
                            else
                                colour = "w.";
                            end

                            for j = 1:4
                                obj.Z(j+3) = plot(obj.AxisAnimation,obj.action_frames{j}(1,1),obj.action_frames{j}(2,1),colour,"MarkerSize",30);
                            end
                        end
                    else % Cycloid gear active
                        r_a(1) = obj.gear.p.R_a; r_a(2) = obj.gear.w.R_a; r = obj.d/2;
                        
                        for i = 2:-1:1
                            L = r(i) + obj.rho_a(i);
                            Y(i) = ( r_a(i)^2 + L^2 - obj.rho_a(i)^2 )/( 2*L );
                            Phi(i) = acos( ( r(i)+obj.rho_a(i)-Y(i) )/obj.rho_a(i) );

                            tau = linspace(0,Phi(i),50);
                            X_act(i,:) = obj.rho_a(i)*sin( tau ); Y_act(i,:) = obj.rho_a(i)*cos( tau );
                        end
                        X_act(1,:) = -X_act(1,:);
                        Y_act(1,:) = -Y_act(1,:) + r(1) + obj.rho_a(1); Y_act(2,:) = Y_act(2,:) + r(1) - obj.rho_a(2);

                        X_act(2,:) = fliplr(X_act(2,:)); Y_act(2,:) = fliplr(Y_act(2,:));
                        action = [X_act(2,1:end-1) X_act(1,:); Y_act(2,1:end-1) Y_act(1,:) ];

                        length_action_line_1 = Phi(1)*obj.rho_a(1);
                        length_action_line_2 = Phi(2)*obj.rho_a(2);
                        obj.length_action_line = length_action_line_1 + length_action_line_2;
                        obj.eps_a = obj.length_action_line/obj.gear.w.p;

                        if cond
                            X = [action(1,1) action(1,end) 0]; Y = [action(2,1) action(2,end) r(1)];

                            eta = obj.gear.p.p./obj.rho_a;

                            if eta(1) < Phi(1)
                                beta(1) = Phi(1) - eta(1);
                                X_E(1) = -obj.rho_a(1)*sin( beta(1) );
                                Y_E(1) = -obj.rho_a(1)*cos( beta(1) )  + r(1) + obj.rho_a(1);
                            else
                                beta(1) = eta(1)-Phi(1);
                                X_E(1) = obj.rho_a(2)*sin( beta(1) );
                                Y_E(1) = obj.rho_a(2)*cos( beta(1) )  + r(1) - obj.rho_a(2);
                            end

                            if eta(2) < Phi(2)
                                beta(2) = Phi(2) - eta(2);
                                X_E(2) = obj.rho_a(2)*sin( beta(2) );
                                Y_E(2) = obj.rho_a(2)*cos( beta(2) )  + r(1) - obj.rho_a(2);
                            else
                                beta(2) = eta(2)-Phi(2);
                                X_E(2) = -obj.rho_a(1)*sin( beta(2) );
                                Y_E(2) = -obj.rho_a(1)*cos( beta(2) )  + r(1) + obj.rho_a(1);
                            end

                            obj.Z(1) = plot(obj.AxisAnimation,action(1,:),action(2,:),"Color",ut.Colours(1,:),"LineWidth",ut.Width(1),"LineStyle",Utils.ProfileTab.profileLineStyleFunction(ut.Style(1)));
                            obj.Z(2) = plot(obj.AxisAnimation,X,Y,".","Color",ut.Colours(1,:),"MarkerSize",20);
                            obj.Z(3) = plot(obj.AxisAnimation,X_E,Y_E,"+","Color",ut.Colours(1,:),"MarkerSize",20);

                            beta = r(1)*obj.phi(1)./obj.rho_a;
                            tau_1 = 0:beta(1):2*eta(1)-beta(1); tau_2 = beta(2):beta(2):2*eta(2);

                            X_1 = -obj.rho_a(1)*sin( tau_1 ); Y_1 = -obj.rho_a(1)*cos( tau_1 ) + r(1) + obj.rho_a(1);
                            X_2 = obj.rho_a(2)*sin( tau_2 );  Y_2 = obj.rho_a(2)*cos( tau_2 ) + r(1) - obj.rho_a(2);

                            X_2 = fliplr(X_2); Y_2 = fliplr(Y_2);

                            obj.action_frames{1} = [X_2 X_1; Y_2 Y_1];

                            mask = obj.action_frames{1}(1,:) > X(1) | obj.action_frames{1}(1,:) < X(2);
                            obj.action_frames{1}(:, mask) = NaN;
                            obj.action_frames{2} = circshift(obj.action_frames{1},size(obj.action_frames{1},2)/4,2);
                            obj.action_frames{3} = circshift(obj.action_frames{2},size(obj.action_frames{1},2)/4,2);
                            obj.action_frames{4} = circshift(obj.action_frames{3},size(obj.action_frames{1},2)/4,2);

                            if strcmp(app.OutputFigure.Theme.BaseColorStyle,"light")
                                colour = "k.";
                            else
                                colour = "w.";
                            end

                            for j = 1:4
                                obj.Z(j+3) = plot(obj.AxisAnimation,obj.action_frames{j}(1,1),obj.action_frames{j}(2,1),colour,"MarkerSize",30);
                            end
                        end
                    end
            end
        end
    end
end