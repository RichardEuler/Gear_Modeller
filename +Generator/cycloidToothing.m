% Copyright (c) 2026 Richard Timko
classdef cycloidToothing
    % cycloidToothing — Generates the tooth profile for cycloidal gearing.
    %
    % The tooth shape corresponds to the ideal when machined by:
    %   1) Rack-cutter shaping (MAAG system)
    %   2) Hobbing

    properties
        m_n   % Normal module [mm]
        a_e   % Generating circle radius for the epicycloid (addendum) [mm]
        a_h   % Generating circle radius for the hypocycloid (dedendum) [mm]
        z     % Number of gear teeth [-]
        x     % Profile shift coefficient [-]
        Cs (1,1) double {mustBeNumeric, mustBePositive} = 0.5 % Rack tooth thickness coefficient [-]
    end

    properties (SetAccess = private)
        % Tool dimensions
        r_a0   % Tool addendum rounding radius [mm]
        r_f0   % Tool dedendum rounding radius [mm]
        c_0    % Tool tip clearance [mm]
        h_a0   % Tool addendum height [mm]
        h_f0   % Tool dedendum height [mm]
        X_d    % Radial tool shift [mm]

        p      % Pitch [mm]

        % Gear dimensions
        c_koef  (1,1) double {mustBeNumeric, mustBePositive} = 0.25
        rf_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.38
        r_f    % Tooth root fillet radius [mm]
        h_a    % Tooth addendum height [mm]
        h_f    % Tooth dedendum height [mm]
        R      % Pitch circle radius [mm]
        R_b    single = NaN   % Base circle radius (NaN for cycloidal gearing)
        R_a    % Addendum circle radius [mm]
        R_f    % Dedendum circle radius [mm]
    end

    properties (SetAccess = private)
        % Parametric curve functions
        Hypo_X;  Hypo_Y;  Hypo_R;  Hypo_t
        Epi_X;   Epi_Y;   Epi_R;   Epi_t
        Tr1_X;   Tr1_Y;   Tr1_dX;  Tr1_dY
        Tr2_X;   Tr2_Y;   Tr2_R
    end

    properties (SetAccess = private, Hidden)
        psi              % Angular rotation of epi/hypocycloid [rad]
        X_shift          % Horizontal shift for corrected cycloidal gearing
        Oa_X;  Oa_Y      % Tip rounding centre in tool coordinates
        initial_guess (1,1) double {mustBeNumeric, mustBePositive} = 3

        quality (1,1) uint16
        trochoid;  epicycloid;  hypocycloid
        foot;  head
        profile;  tooth
        PointedTips       % true when teeth are pointed
    end

    methods
        function obj = cycloidToothing(modul, rho_epi, rho_hypo, num_teeth, unit_shift, quality)
            % Constructor — create a cycloidToothing object.
            arguments
                modul      (1,1) double {mustBeNumeric, mustBePositive}
                rho_epi    (1,1) double {mustBeNumeric, mustBePositive}
                rho_hypo   (1,1) double {mustBeNumeric, mustBePositive}
                num_teeth  (1,1) double {mustBeNumeric, mustBeInteger}
                unit_shift (1,1) double {mustBeNumeric}
                quality    (1,1) uint16 {mustBeInteger} = 200
            end

            % Round quality up to the next multiple of 4
            rem4 = mod(quality, 4);
            if rem4 ~= 0
                quality = quality + (4 - rem4);
            end
            obj.quality = quality;

            obj.PointedTips = false;

            obj.m_n = modul;
            obj.z   = num_teeth;
            obj.a_e = rho_epi;
            obj.a_h = rho_hypo;
            obj.x   = unit_shift;
            obj.X_d = obj.m_n * obj.x;

            obj = computeToolRounding(obj);
            obj.c_0  = ceil(4 * sqrt(obj.m_n)) / 10;
            obj.h_a0 = obj.m_n * (1 + obj.c_koef);
            obj.h_f0 = obj.m_n + obj.c_0;

            obj.r_f = obj.r_a0;
            obj.h_a = obj.m_n + obj.X_d;
            obj.h_f = obj.m_n * (1 + obj.c_koef) - obj.X_d;
            obj.R   = obj.m_n * obj.z / 2;
            obj.R_a = obj.R + obj.h_a;
            obj.R_f = obj.R - obj.h_f;

            obj.p = obj.m_n * pi;

            % Build parametric curve functions
            obj = curveFuncions(obj);

            % Validity checks and profile generation
            if obj.m_n * obj.z == 2 * obj.a_h
                warning('Hypocycloid creation is not possible: the hypocycloid reduces to a point.');
                obj.profile = [NaN; NaN];
            elseif obj.a_h > obj.R - obj.h_f/2 || obj.a_h < obj.h_f/2
                warning('Hypocycloid creation is not possible: no intersection with the dedendum circle.');
                obj.profile = [NaN; NaN];
            else
                obj = toothCycloidProfile(obj);
            end
        end
    end

    methods (Access = private)
        function obj = toothCycloidProfile(obj)
            % Generate the complete tooth profile for cycloidal gearing.

            % Nested helper: compute chord length between a curve point and
            % the trochoid point at the same polar radius.
            function distance = chordLengthFun(t_curve, curveFun)
                common_radius = curveFun{3}(t_curve);
                tau_tr = fzero(@(par) common_radius - obj.Tr2_R(par), t_tr0);
                distance = sqrt((obj.Tr2_X(tau_tr) - curveFun{1}(t_curve))^2 ...
                              + (obj.Tr2_Y(tau_tr) - curveFun{2}(t_curve))^2);
            end

            % Find the trochoid parameter at the addendum circle
            t_tr_Ra = fzero(@(par) obj.R_a - obj.Tr2_R(par.^2), 0);
            t_tr_Ra = t_tr_Ra^2;

            angle_epi_tip = NaN;

            % Determine orientation of the vector between curve points on the addendum circle
            if obj.x < -1
                t_hypo_Ra = obj.Hypo_t(obj.R_a);
                vector_Ra = [obj.Hypo_X(t_hypo_Ra) - obj.Tr2_X(t_tr_Ra), ...
                             obj.Hypo_Y(t_hypo_Ra) - obj.Tr2_Y(t_tr_Ra)];
            else
                t_epi_Ra = obj.Epi_t(obj.R_a);
                vector_Ra = [obj.Epi_X(t_epi_Ra) - obj.Tr2_X(t_tr_Ra), ...
                             obj.Epi_Y(t_epi_Ra) - obj.Tr2_Y(t_tr_Ra)];
            end
            orientation_Ra = sign(dot([obj.Tr2_Y(t_tr_Ra), -obj.Tr2_X(t_tr_Ra)], vector_Ra));

            if orientation_Ra == 1
                if obj.x > -1 && obj.x < 1 + obj.c_koef
                    % Find trochoid parameter at the pitch circle
                    t_tr_R = fzero(@(par) obj.R - obj.Tr2_R(par), [0 t_tr_Ra]);

                    vector_R = [obj.Hypo_X(0) - obj.Tr2_X(t_tr_R), ...
                                obj.Hypo_Y(0) - obj.Tr2_Y(t_tr_R)];
                    orientation_R = sign(dot([obj.Tr2_Y(t_tr_R), -obj.Tr2_X(t_tr_R)], vector_R));

                    if obj.x >= 1 + obj.c_koef - obj.rf_koef
                        direction_vector_R = [obj.Tr1_dX(-t_tr_R), obj.Tr1_dY(-t_tr_R)];
                    else
                        direction_vector_R = [obj.Tr1_dX(t_tr_R), obj.Tr1_dY(t_tr_R)];
                    end
                    direction_orientation_R = sign(dot([obj.Tr2_X(t_tr_R), obj.Tr2_Y(t_tr_R)], direction_vector_R));

                    if orientation_R == 1 && direction_orientation_R == 1
                        % Trochoid intersects with the hypocycloid
                        t_tr0 = [0 t_tr_R];
                        curveFun = {obj.Hypo_X, obj.Hypo_Y, obj.Hypo_R};
                        chordLengthHypo = @(par) chordLengthFun(par, curveFun);
                        t_hypo_intersection = fminbnd(chordLengthHypo, 0, obj.Hypo_t(obj.R_f));
                        t_tr_intersection = fzero(@(par) obj.Hypo_R(t_hypo_intersection) - obj.Tr2_R(par), t_tr0);

                        t_hypo = linspace(0, t_hypo_intersection, obj.quality);
                        obj.hypocycloid = [obj.Hypo_X(t_hypo); obj.Hypo_Y(t_hypo)];

                        t_epi_tip = obj.Epi_t(obj.R_a);
                        angle_epi_tip = atan(obj.Epi_X(t_epi_tip) / obj.Epi_Y(t_epi_tip));
                        t_epi = linspace(0, t_epi_tip, obj.quality);
                        obj.epicycloid = [obj.Epi_X(t_epi); obj.Epi_Y(t_epi)];

                    elseif orientation_R == -1 || direction_orientation_R == -1
                        % Trochoid intersects with the epicycloid or addendum circle
                        obj.hypocycloid = [NaN; NaN];

                        t_tr0 = [t_tr_R t_tr_Ra];
                        curveFun = {obj.Epi_X, obj.Epi_Y, obj.Epi_R};
                        chordLengthEpi = @(par) chordLengthFun(par, curveFun);
                        t_epi_intersection = fminbnd(chordLengthEpi, 0, obj.Epi_t(obj.R_a));
                        t_tr_intersection = fzero(@(par) obj.Epi_R(t_epi_intersection) - obj.Tr2_R(par), t_tr0);

                        t_epi_tip = obj.Epi_t(obj.R_a);
                        angle_epi_tip = atan(obj.Epi_X(t_epi_tip) / obj.Epi_Y(t_epi_tip));
                        t_epi = linspace(t_epi_intersection, t_epi_tip, obj.quality);
                        obj.epicycloid = [obj.Epi_X(t_epi); obj.Epi_Y(t_epi)];

                    elseif orientation_R == 0
                        % Trochoid meets the profile exactly at the pitch circle
                        obj.hypocycloid = [NaN; NaN];

                        t_tr0 = [t_tr_R t_tr_Ra];
                        t_epi_tip = obj.Epi_t(obj.R_a);
                        angle_epi_tip = atan(obj.Epi_X(t_epi_tip) / obj.Epi_Y(t_epi_tip));
                        t_epi = linspace(0, t_epi_tip, obj.quality);
                        obj.epicycloid = [obj.Epi_X(t_epi); obj.Epi_Y(t_epi)];
                        t_tr_intersection = t_tr_R;
                    else
                        error('Unexpected condition in cycloidal profile generation.');
                    end

                elseif obj.x <= -1
                    obj.epicycloid = [NaN; NaN];
                    t_tr0 = [0 t_tr_Ra];
                    curveFun = {obj.Hypo_X, obj.Hypo_Y, obj.Hypo_R};
                    chordLengthHypo = @(par) chordLengthFun(par, curveFun);
                    t_hypo_intersection = fminbnd(chordLengthHypo, obj.Hypo_t(obj.R_a), obj.Hypo_t(obj.R_f));
                    t_tr_intersection = fzero(@(par) obj.Hypo_R(t_hypo_intersection) - obj.Tr2_R(par), t_tr0);

                    t_hypo = linspace(obj.Hypo_t(obj.R_a), t_hypo_intersection, obj.quality);
                    obj.hypocycloid = [obj.Hypo_X(t_hypo); obj.Hypo_Y(t_hypo)];

                elseif obj.x >= 1 + obj.c_koef
                    obj.hypocycloid = [NaN; NaN];
                    t_tr0 = [0 t_tr_Ra];
                    curveFun = {obj.Epi_X, obj.Epi_Y, obj.Epi_R};
                    chordLengthEpi = @(par) chordLengthFun(par, curveFun);
                    t_epi_intersection = fminbnd(chordLengthEpi, obj.Epi_t(obj.R_f), obj.Epi_t(obj.R_a));
                    t_tr_intersection = fzero(@(par) obj.Epi_R(t_epi_intersection) - obj.Tr2_R(par), t_tr0);

                    t_epi_tip = obj.Epi_t(obj.R_a);
                    angle_epi_tip = atan(obj.Epi_X(t_epi_tip) / obj.Epi_Y(t_epi_tip));
                    t_epi = linspace(t_epi_intersection, t_epi_tip, obj.quality);
                    obj.epicycloid = [obj.Epi_X(t_epi); obj.Epi_Y(t_epi)];
                else
                    error('Unexpected condition in cycloidal profile generation.');
                end

                t_tr = linspace(0, t_tr_intersection, obj.quality);
                obj.trochoid = [obj.Tr2_X(t_tr); obj.Tr2_Y(t_tr)];

            elseif orientation_Ra == -1 || orientation_Ra == 0
                % Profile is purely the secondary trochoid
                obj.hypocycloid = [NaN; NaN];
                obj.epicycloid  = [NaN; NaN];
                t_tr = linspace(0, t_tr_Ra, obj.quality);
                obj.trochoid = [obj.Tr2_X(t_tr); obj.Tr2_Y(t_tr)];
            else
                error('Unexpected condition in cycloidal profile generation.');
            end

            % Addendum arc (or pointed tip truncation)
            if isnan(angle_epi_tip) || angle_epi_tip < pi/obj.z
                if ~anynan(obj.epicycloid)
                    tau_a_range = [atan(obj.epicycloid(1,end)/obj.epicycloid(2,end)),  pi/obj.z];
                elseif ~anynan(obj.hypocycloid)
                    tau_a_range = [atan(obj.hypocycloid(1,1)/obj.hypocycloid(2,1)),  pi/obj.z];
                else
                    tau_a_range = [atan(obj.trochoid(1,end)/obj.trochoid(2,end)),  pi/obj.z];
                end
                t_a = linspace(tau_a_range(1), tau_a_range(2), uint8(obj.quality/4));
                obj.head = [obj.R_a*sin(t_a); obj.R_a*cos(t_a)];
            else
                obj.PointedTips = true;
                obj.head = [NaN; NaN];
                t_epi_tip = fzero(@(par) atan(obj.Epi_X(par)/obj.Epi_Y(par)) - pi/obj.z, t_epi_tip);
                id_epi = find(t_epi >= t_epi_tip, 1, 'first');
                obj.epicycloid(:, id_epi:end) = [];
                obj.epicycloid(:, end+1) = [obj.Epi_X(t_epi_tip); obj.Epi_Y(t_epi_tip)];
            end

            % Dedendum arc
            tau_f_range = [0,  atan(obj.trochoid(1,1)/obj.trochoid(2,1))];
            t_foot = linspace(tau_f_range(1), tau_f_range(2), uint8(obj.quality/4));
            obj.foot = [obj.R_f*sin(t_foot); obj.R_f*cos(t_foot)];

            % Assemble the half-profile and clean NaN values
            obj.profile = [obj.foot  obj.trochoid  fliplr(obj.hypocycloid)  obj.epicycloid  obj.head];
            obj.profile = rmmissing(obj.profile')';

            % Mirror to produce the full symmetric tooth
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

        function obj = tipCenterFunction(obj)
            % Compute the tip rounding centre in the cutting tool coordinate system.

            obj.Oa_Y = -obj.h_a0 + obj.r_a0 + obj.X_d;

            % Profile shift for pitch-property maintenance
            if obj.X_d > 0
                par = acos(1 - obj.X_d / obj.a_e);
                obj.X_shift = -obj.a_e * (par - sin(par));
            elseif obj.X_d < 0
                par = acos(1 + obj.X_d / obj.a_h);
                obj.X_shift = obj.a_h * (par - sin(par));
            else
                obj.X_shift = 0;
            end

            % X-coordinate depends on which cycloid branches are present
            if obj.X_d < obj.h_a0 - obj.r_a0 && obj.X_d > -obj.h_f0 + obj.r_f0
                tipZeroFun = @(par) -obj.a_h*(1-cos(par)) - obj.r_a0*(cos(par)-1)./sqrt(2*(1-cos(par))) + obj.h_a0 - obj.r_a0 - obj.X_d;
                tau_0 = [acos((obj.r_a0-obj.h_a0+obj.X_d)/obj.a_h+1), acos((-obj.h_a0+obj.X_d)/obj.a_h+1)];
                tau = fzero(tipZeroFun, tau_0);
                obj.Oa_X = -obj.a_h*(tau-sin(tau)) - obj.r_a0*sin(tau)/sqrt(2*(1-cos(tau))) + (1-obj.Cs)*obj.m_n*pi/2 + obj.X_shift;

            elseif obj.X_d <= -obj.h_f0 + obj.r_f0
                tipZeroFun = @(par) -obj.a_h*(1-cos(par)) - obj.r_a0*(cos(par)-1)./sqrt(2*(1-cos(par))) + obj.h_a0 - obj.r_a0 - obj.X_d;
                tau_0 = [acos((obj.r_a0-obj.h_a0+obj.X_d)/obj.a_h+1), acos((-obj.h_a0+obj.X_d)/obj.a_h+1)];
                tau = fzero(tipZeroFun, tau_0);
                obj.Oa_X = -obj.a_h*(tau-sin(tau)) - obj.r_a0*sin(tau)/sqrt(2*(1-cos(tau))) + (1-obj.Cs)*obj.m_n*pi/2 + obj.X_shift;

            elseif obj.X_d >= obj.h_a0 - obj.r_a0
                if obj.X_d == obj.h_a0 - obj.r_a0
                    tau = 0;
                    obj.Oa_X = obj.a_e*(tau-sin(tau)) - obj.r_a0 + (1-obj.Cs)*obj.m_n*pi/2;
                else
                    tipZeroFun = @(par) obj.a_e*(1-cos(par)) - obj.r_a0*(cos(par)-1)./sqrt(2*(1-cos(par))) + obj.h_a0 - obj.r_a0 - obj.X_d;
                    if obj.X_d < obj.h_a0
                        tau_0(1) = 1e-6;
                    else
                        tau_0(1) = acos((obj.h_a0-obj.X_d)/obj.a_e + 1);
                    end
                    tau_0(2) = acos((obj.h_a0-obj.r_a0-obj.X_d)/obj.a_e + 1);
                    tau = fzero(tipZeroFun, tau_0);
                    obj.Oa_X = obj.a_e*(tau-sin(tau)) - obj.r_a0*sin(tau)/sqrt(2*(1-cos(tau))) + (1-obj.Cs)*obj.m_n*pi/2 + obj.X_shift;
                end
            end
        end

        function obj = curveFuncions(obj)
            % Build all parametric curve function handles.

            obj = tipCenterFunction(obj);

            obj.psi = asin((obj.Cs*obj.m_n*pi/2 + obj.X_shift) / obj.R);

            % Hypocycloid
            obj.Hypo_X = @(par) obj.a_h*sin((obj.R-obj.a_h)/obj.a_h*par + obj.psi) - (obj.R-obj.a_h)*sin(par - obj.psi);
            obj.Hypo_Y = @(par) obj.a_h*cos((obj.R-obj.a_h)/obj.a_h*par + obj.psi) + (obj.R-obj.a_h)*cos(par - obj.psi);

            % Epicycloid
            obj.Epi_X = @(par) (obj.R+obj.a_e)*sin(par+obj.psi) - obj.a_e*sin((obj.R+obj.a_e)/obj.a_e*par + obj.psi);
            obj.Epi_Y = @(par) (obj.R+obj.a_e)*cos(par+obj.psi) - obj.a_e*cos((obj.R+obj.a_e)/obj.a_e*par + obj.psi);

            % Primary trochoid and its derivatives
            obj.Tr1_X  = @(par) obj.R*par.*cos(par - obj.Oa_X/obj.R) - (obj.Oa_Y+obj.R)*sin(par - obj.Oa_X/obj.R);
            obj.Tr1_Y  = @(par) obj.R*par.*sin(par - obj.Oa_X/obj.R) + (obj.Oa_Y+obj.R)*cos(par - obj.Oa_X/obj.R);
            obj.Tr1_dX = @(par) -obj.Oa_Y*cos(par - obj.Oa_X/obj.R) - obj.R*par.*sin(par - obj.Oa_X/obj.R);
            obj.Tr1_dY = @(par) -obj.Oa_Y*sin(par - obj.Oa_X/obj.R) + obj.R*par.*cos(par - obj.Oa_X/obj.R);

            % Secondary trochoid (equidistant to the primary trochoid)
            if obj.x >= 1 + obj.c_koef - obj.rf_koef
                obj.Tr2_X = @(par) obj.Tr1_X(-par) + obj.r_a0*cos(atan2(-obj.Tr1_dX(-par), obj.Tr1_dY(-par)) + pi);
                obj.Tr2_Y = @(par) obj.Tr1_Y(-par) + obj.r_a0*sin(atan2(-obj.Tr1_dX(-par), obj.Tr1_dY(-par)) + pi);
            else
                obj.Tr2_X = @(par) obj.Tr1_X(par) + obj.r_a0*cos(atan2(-obj.Tr1_dX(par), obj.Tr1_dY(par)));
                obj.Tr2_Y = @(par) obj.Tr1_Y(par) + obj.r_a0*sin(atan2(-obj.Tr1_dX(par), obj.Tr1_dY(par)));
            end

            % Polar radius functions
            obj.Hypo_R = @(par) sqrt((obj.R-obj.a_h)^2 + obj.a_h^2 + 2*obj.a_h*(obj.R-obj.a_h)*cos(par*obj.R/obj.a_h));
            obj.Epi_R  = @(par) sqrt((obj.R+obj.a_e)^2 + obj.a_e^2 - 2*obj.a_e*(obj.R+obj.a_e)*cos(par*obj.R/obj.a_e));
            obj.Tr2_R  = @(par) sqrt(obj.Tr2_X(par).^2 + obj.Tr2_Y(par).^2);

            % Inverse functions: parameter from polar radius
            obj.Hypo_t = @(rho) obj.a_h/obj.R * acos((rho.^2 - (obj.R-obj.a_h)^2 - obj.a_h^2) / (2*obj.a_h*(obj.R-obj.a_h)));
            obj.Epi_t  = @(rho) obj.a_e/obj.R * acos((-rho.^2 + (obj.R+obj.a_e)^2 + obj.a_e^2) / (2*obj.a_e*(obj.R+obj.a_e)));
        end
    end
end
