% Copyright (c) 2026 Richard Timko
classdef involuteToothing
    % involuteToothing — Generates the tooth profile for involute gearing.
    %
    % The tooth shape corresponds to the ideal when machined by:
    %   1) Rack-cutter shaping (MAAG system)
    %   2) Hobbing

    properties
        m_n    % Normal module [mm]
        z      % Number of gear teeth [-]
        alpha  % Profile angle [rad]
        x      % Profile shift coefficient [-]
        Cs (1,1) double {mustBeNumeric, mustBePositive} = 0.5
    end

    properties (SetAccess = private)
        r_a0;  r_f0;  c_0;  h_a0;  h_f0;  X_d
        p;  p_b;  p_a;  p_f

        c_koef  (1,1) double {mustBeNumeric, mustBePositive} = 0.25
        rf_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.38
        r_f;  h_a;  h_f;  R;  R_b;  R_a;  R_f
        Cs_lower;  Cs_upper
    end

    properties (SetAccess = private)
        Inv_X;  Inv_Y;  Inv_R;  Inv_t
        Tr1_X;  Tr1_Y;  Tr1_dX;  Tr1_dY
        Tr2_X;  Tr2_Y;  Tr2_R
    end

    properties (SetAccess = private, Hidden)
        psi;  Oa_X;  Oa_Y
        initial_guess (1,1) double {mustBeNumeric, mustBePositive} = 3
        quality (1,1) uint16

        trochoid;  involute;  foot;  head
        profile;  tooth
        PointedTips;  x_lower;  x_upper;  alpha_max
    end

    methods
        function obj = involuteToothing(modul, profile_angle, num_teeth, unit_shift, quality)
            % Constructor — create an involuteToothing object.
            arguments
                modul        (1,1) double {mustBeNumeric, mustBePositive} = 1
                profile_angle (1,1) double {mustBeNumeric, mustBePositive} = 20
                num_teeth    (1,1) double {mustBeNumeric, mustBeInteger}  = 30
                unit_shift   (1,1) double {mustBeNumeric}                 = 0
                quality      (1,1) uint16 {mustBeInteger}                 = 200
            end

            % Round quality up to the next multiple of 4
            rem4 = mod(quality, 4);
            if rem4 ~= 0
                quality = quality + (4 - rem4);
            end
            obj.quality = quality;

            obj.PointedTips = false;

            obj.m_n   = modul;
            obj.z     = num_teeth;
            obj.alpha = deg2rad(profile_angle);
            obj.x     = unit_shift;
            obj.X_d   = obj.m_n * obj.x;

            obj = computeToolRounding(obj);
            obj.c_0  = ceil(4 * sqrt(obj.m_n)) / 10;
            obj.h_a0 = obj.m_n * (1 + obj.c_koef);
            obj.h_f0 = obj.m_n + obj.c_0;

            obj.r_f = obj.r_a0;
            obj.h_a = obj.m_n + obj.X_d;
            obj.h_f = obj.m_n * (1 + obj.c_koef) - obj.X_d;
            obj.R   = obj.m_n * obj.z / 2;
            obj.R_b = obj.R * cos(obj.alpha);
            obj.R_a = obj.R + obj.h_a;
            obj.R_f = obj.R - obj.h_f;

            obj.p   = obj.m_n * pi;
            obj.p_b = (2*pi/obj.z) * obj.R_b;
            obj.p_f = (2*pi/obj.z) * obj.R_f;
            obj.p_a = (2*pi/obj.z) * obj.R_a;

            % Maximum profile angle from rack geometry
            obj.alpha_max = fzero(@(par) obj.Cs*obj.m_n*pi/2 - obj.h_a0*tan(par) - obj.r_a0*tan(pi/4-par/2), deg2rad(20));
            obj.alpha_max = floor(rad2deg(obj.alpha_max)*1e4) * 1e-4;

            if profile_angle > obj.alpha_max
                warning('The entered profile angle exceeds the maximum (%.4f°).', obj.alpha_max);
            end

            obj.Cs_lower = (obj.h_a0*tan(obj.alpha) + obj.r_a0*tan(pi/4-obj.alpha/2)) / (obj.m_n*pi);
            obj.Cs_upper = 1 - 2/(obj.m_n*pi) * (obj.h_f0*tan(obj.alpha) + obj.r_f0*tan(pi/4-obj.alpha/2));

            obj = curveFuncions(obj);
            obj = lowerLimitProfileShift(obj);
            obj = upperLimitProfileShift(obj);
            obj = toothInvoluteProfile(obj);
        end
    end

    methods (Access = private)
        function obj = toothInvoluteProfile(obj)
            % Generate the complete involute tooth profile.

            % Nested helper: distance between involute and trochoid at a common radius
            function distance = intersectionPoint(t_inv)
                common_radius = obj.Inv_R(t_inv);
                try
                    t_tr = fzero(@(par) common_radius - obj.Tr2_R(par, obj.x), [t_tr_start t_tr_end]);
                catch err
                    if strcmp(err.identifier, 'MATLAB:fzero:ValuesAtEndPtsSameSign')
                        if common_radius < obj.Tr2_R(t_tr_start, obj.x)
                            t_tr = t_tr_start;
                        else
                            t_tr = t_tr_end;
                        end
                    else
                        rethrow(err);
                    end
                end
                distance = sqrt((obj.Tr2_X(t_tr, obj.x) - obj.Inv_X(t_inv, obj.x))^2 ...
                              + (obj.Tr2_Y(t_tr, obj.x) - obj.Inv_Y(t_inv, obj.x))^2);
            end

            t_tr_start = 0;
            if obj.x > obj.x_lower
                t_tr_end = fzero(@(par) obj.R_a - obj.Tr2_R(par, obj.x), [t_tr_start obj.initial_guess]);

                t_inv_tip = obj.Inv_t(obj.R_a);
                angle_tip = atan(obj.Inv_X(t_inv_tip, obj.x) ./ obj.Inv_Y(t_inv_tip, obj.x));
                if angle_tip > pi/obj.z
                    t_inv_tip = fzero(@(par) atan(obj.Inv_X(par, obj.x)./obj.Inv_Y(par, obj.x)) - pi/obj.z, [t_inv_tip 0]);
                    obj.PointedTips = true;
                end
                t_inv_intersection = fminbnd(@intersectionPoint, t_inv_tip, 0);
                t_tr_intersection = fzero(@(par) obj.Inv_R(t_inv_intersection) - obj.Tr2_R(par, obj.x), [t_tr_start t_tr_end]);

                t_involute = linspace(t_inv_intersection, t_inv_tip, obj.quality);
                obj.involute = [obj.Inv_X(t_involute, obj.x); obj.Inv_Y(t_involute, obj.x)];

                if ~obj.PointedTips
                    t_a_start = atan(obj.involute(1,end)/obj.involute(2,end));
                    t_head = linspace(t_a_start, pi/obj.z, uint8(obj.quality/4));
                    obj.head = [obj.R_a*sin(t_head); obj.R_a*cos(t_head)];
                else
                    obj.head = NaN;
                end
            else
                t_tr_intersection = fzero(@(par) obj.R_a - obj.Tr2_R(par, obj.x), [t_tr_start obj.initial_guess]);
                obj.involute = NaN;
                t_a_start = atan(obj.Tr2_X(t_tr_intersection, obj.x) ./ obj.Tr2_Y(t_tr_intersection, obj.x));
                t_head = linspace(t_a_start, pi/obj.z, uint8(obj.quality/4));
                obj.head = [obj.R_a*sin(t_head); obj.R_a*cos(t_head)];
            end

            % Build trochoid curve
            t_trochoid = linspace(t_tr_start, t_tr_intersection, obj.quality);
            obj.trochoid = [obj.Tr2_X(t_trochoid, obj.x); obj.Tr2_Y(t_trochoid, obj.x)];
            angle_trochoid = atan(obj.trochoid(1,:) ./ obj.trochoid(2,:));
            id_no_head = find(angle_trochoid > pi/obj.z, 1, 'first');
            if ~isempty(id_no_head)
                t_no_head = fzero(@(par) atan(obj.Tr2_X(par,obj.x)./obj.Tr2_Y(par,obj.x)) - pi/obj.z, [0 t_trochoid(id_no_head)]);
                t_trochoid = linspace(t_tr_start, t_no_head, obj.quality);
                obj.trochoid = [obj.Tr2_X(t_trochoid, obj.x); obj.Tr2_Y(t_trochoid, obj.x)];
            end

            % Dedendum arc
            t_f_end = atan(obj.trochoid(1,1)/obj.trochoid(2,1));
            t_foot = linspace(0, t_f_end, uint8(obj.quality/4));
            obj.foot = [obj.R_f*sin(t_foot); obj.R_f*cos(t_foot)];

            % Check if the trochoid crosses the y-axis (no foot arc needed)
            id_no_foot = find(obj.trochoid(1,:) < 0, 1, 'last');

            % Assemble the half-profile
            if ~isempty(id_no_foot)
                obj.trochoid = obj.trochoid(:, id_no_foot+1:end);
                obj.foot = NaN;
            end

            % Build full profile from available segments
            if obj.x > obj.x_lower
                if ~obj.PointedTips
                    obj.profile = [obj.foot(:,1:end-1)  obj.trochoid(:,1:end-1)  obj.involute  obj.head(:,2:end)];
                else
                    obj.profile = [obj.foot(:,1:end-1)  obj.trochoid(:,1:end-1)  obj.involute];
                end
            else
                if isempty(id_no_head)
                    obj.profile = [obj.foot(:,1:end-1)  obj.trochoid  obj.head(:,2:end)];
                else
                    obj.profile = [obj.foot(:,1:end-1)  obj.trochoid];
                end
            end

            % Remove NaN columns that arise from missing segments
            validCols = ~any(isnan(obj.profile), 1);
            obj.profile = obj.profile(:, validCols);

            % Mirror the half-profile to create the full symmetric tooth
            T_rotate = [cos(pi/obj.z) -sin(pi/obj.z); sin(pi/obj.z) cos(pi/obj.z)];
            left_profile  = T_rotate * obj.profile;
            right_profile = [-left_profile(1,:); left_profile(2,:)];
            obj.tooth = [left_profile(1, 1:end-1)  fliplr(right_profile(1,:)); ...
                         left_profile(2, 1:end-1)  fliplr(right_profile(2,:))];
        end

        function obj = computeToolRounding(obj)
            % Determine hob tool rounding radii per CSN 01 4608
            obj.r_f0 = Generator.toolRootRounding(obj.m_n);
            obj.r_a0 = obj.rf_koef * obj.m_n;
        end

        function obj = curveFuncions(obj)
            % Build all parametric function handles for the involute profile.

            obj.Oa_X = obj.Cs*obj.m_n*pi/2 - obj.h_a0*tan(obj.alpha) - obj.r_a0*tan(pi/4-obj.alpha/2);
            obj.Oa_Y = @(par) -obj.h_a0 + obj.r_a0 + obj.m_n*par;

            obj.psi = @(par) tan(obj.alpha) - obj.alpha - (obj.Cs*obj.m_n*pi - 2*obj.m_n*par*tan(obj.alpha))/(2*obj.R);

            obj.Inv_X = @(par1,par2) obj.R_b*par1.*cos(obj.psi(par2)+par1) - obj.R_b*sin(obj.psi(par2)+par1);
            obj.Inv_Y = @(par1,par2) obj.R_b*par1.*sin(obj.psi(par2)+par1) + obj.R_b*cos(obj.psi(par2)+par1);

            obj.Tr1_X  = @(par1,par2) obj.R*par1.*cos(par1-obj.Oa_X./obj.R) - (obj.Oa_Y(par2)+obj.R).*sin(par1-obj.Oa_X./obj.R);
            obj.Tr1_Y  = @(par1,par2) obj.R*par1.*sin(par1-obj.Oa_X./obj.R) + (obj.Oa_Y(par2)+obj.R).*cos(par1-obj.Oa_X./obj.R);
            obj.Tr1_dX = @(par1,par2) -obj.Oa_Y(par2).*cos(par1-obj.Oa_X./obj.R) - obj.R*par1.*sin(par1-obj.Oa_X./obj.R);
            obj.Tr1_dY = @(par1,par2) -obj.Oa_Y(par2).*sin(par1-obj.Oa_X./obj.R) + obj.R*par1.*cos(par1-obj.Oa_X./obj.R);

            if obj.x >= 1 + obj.c_koef - obj.rf_koef
                obj.Tr2_X = @(par1,par2) obj.Tr1_X(-par1,par2) + obj.r_a0*cos(atan2(-obj.Tr1_dX(-par1,par2), obj.Tr1_dY(-par1,par2)) + pi);
                obj.Tr2_Y = @(par1,par2) obj.Tr1_Y(-par1,par2) + obj.r_a0*sin(atan2(-obj.Tr1_dX(-par1,par2), obj.Tr1_dY(-par1,par2)) + pi);
            else
                obj.Tr2_X = @(par1,par2) obj.Tr1_X(par1,par2) + obj.r_a0*cos(atan2(-obj.Tr1_dX(par1,par2), obj.Tr1_dY(par1,par2)));
                obj.Tr2_Y = @(par1,par2) obj.Tr1_Y(par1,par2) + obj.r_a0*sin(atan2(-obj.Tr1_dX(par1,par2), obj.Tr1_dY(par1,par2)));
            end

            obj.Inv_R  = @(par) obj.R_b*sqrt(1 + par.^2);
            obj.Tr2_R  = @(par1,par2) sqrt(obj.Tr2_X(par1,par2).^2 + obj.Tr2_Y(par1,par2).^2);
            obj.Inv_t  = @(rho) -sqrt(rho.^2 - obj.R_b^2) / obj.R_b;
        end

        function obj = lowerLimitProfileShift(obj)
            % Find the lower boundary of the profile shift coefficient
            % (below which the involute disappears from the profile).

            fun_Tr2_X = @(par1,par2) obj.Tr1_X(par1,par2) + obj.r_a0*cos(atan2(-obj.Tr1_dX(par1,par2), obj.Tr1_dY(par1,par2)));
            fun_Tr2_Y = @(par1,par2) obj.Tr1_Y(par1,par2) + obj.r_a0*sin(atan2(-obj.Tr1_dX(par1,par2), obj.Tr1_dY(par1,par2)));
            fun_Tr2_R = @(par1,par2) sqrt(fun_Tr2_X(par1,par2).^2 + fun_Tr2_Y(par1,par2).^2);

            function distance = involuteAbsenceFunction(x_lim)
                t_inv_lim = obj.Inv_t(obj.R + (1+x_lim)*obj.m_n);
                t_tr_lim = fzero(@(par) obj.Inv_R(t_inv_lim) - fun_Tr2_R(par, x_lim), [0 obj.initial_guess]);
                distance = sqrt((fun_Tr2_X(t_tr_lim, x_lim) - obj.Inv_X(t_inv_lim, x_lim))^2 ...
                              + (fun_Tr2_Y(t_tr_lim, x_lim) - obj.Inv_Y(t_inv_lim, x_lim))^2);
            end

            x_start = obj.z/2*(cos(obj.alpha) - 1) - 1;
            obj.x_lower = fminbnd(@involuteAbsenceFunction, x_start, 0);
            obj.x_lower = ceil(obj.x_lower * 1e4) * 1e-4;
        end

        function obj = upperLimitProfileShift(obj)
            % Find the upper boundary of the profile shift coefficient
            % (above which the teeth become pointed).
            function delta = pointedTipFunction(x_lim)
                t_int = obj.Inv_t(obj.R + (1+x_lim)*obj.m_n);
                angle_inv = atan(obj.Inv_X(t_int, x_lim) ./ obj.Inv_Y(t_int, x_lim));
                delta = abs(angle_inv - pi/obj.z);
            end
            obj.x_upper = fminbnd(@pointedTipFunction, obj.x_lower, 1+obj.c_koef);
            obj.x_upper = floor(obj.x_upper * 1e4) * 1e-4;
        end
    end
end
