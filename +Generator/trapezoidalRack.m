% Copyright (c) 2026 Richard Timko
classdef trapezoidalRack
    % trapezoidalRack — Generates the trapezoidal basic tooth profile
    % for involute gearing (rack-cutter reference profile).

    properties
        m_n   (1,1) double  % Normal module [mm]
        alpha (1,1) double  % Profile angle [rad]
        x     (1,1) double  % Profile shift coefficient [-]
        Cs    (1,1) double {mustBeNumeric, mustBePositive} = 0.5 % Tooth thickness coefficient [-]
    end

    properties (SetAccess = private)
        r_a0  (1,1) double  % Tool addendum rounding radius [mm]
        r_f0  (1,1) double  % Tool dedendum rounding radius [mm]
        c_0   (1,1) double  % Tool tip clearance [mm]
        h_a0  (1,1) double  % Tool addendum height [mm]
        h_f0  (1,1) double  % Tool dedendum height [mm]
        X_d   (1,1) double  % Radial tool shift [mm]

        p     (1,1) double  % Pitch [mm]

        c_koef  (1,1) double {mustBeNumeric, mustBePositive} = 0.25
        rf_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.38

        Cs_lower  (1,1) double
        Cs_upper  (1,1) double
        alpha_max (1,1) double
    end

    properties (SetAccess = private, Hidden)
        quality (1,1) uint8
        points  double
        profile double
        tooth   double
    end

    methods
        function obj = trapezoidalRack(modul, profile_angle, unit_shift, quality)
            % Constructor — create a trapezoidalRack object.
            arguments
                modul         (1,1) double {mustBeNumeric, mustBePositive} = 1
                profile_angle (1,1) double {mustBeNumeric, mustBePositive} = 20
                unit_shift    (1,1) double {mustBeNumeric}                 = 0
                quality       (1,1) uint8  {mustBeInteger}                 = 25
            end
            obj.quality = quality;

            obj.m_n   = modul;
            obj.alpha = deg2rad(profile_angle);
            obj.x     = unit_shift;
            obj.X_d   = obj.m_n * obj.x;

            obj = computeToolRounding(obj);
            obj.c_0  = ceil(4 * sqrt(obj.m_n)) / 10;
            obj.h_a0 = obj.m_n * (1 + obj.c_koef);
            obj.h_f0 = obj.m_n + obj.c_0;

            obj.p = obj.m_n * pi;

            % Maximum profile angle from the rack geometry
            obj.alpha_max = fzero(@(par) obj.Cs*obj.m_n*pi/2 - obj.h_a0*tan(par) - obj.r_a0*tan(pi/4-par/2), deg2rad(20));
            obj.alpha_max = floor(rad2deg(obj.alpha_max)*1e4) * 1e-4;

            if profile_angle > obj.alpha_max
                warning('The entered profile angle exceeds the maximum (%.4f°).', obj.alpha_max);
            end

            obj.Cs_lower = (obj.h_a0*tan(obj.alpha) + obj.r_a0*tan(pi/4-obj.alpha/2)) / (obj.m_n*pi);
            obj.Cs_upper = 1 - 2/(obj.m_n*pi) * (obj.h_f0*tan(obj.alpha) + obj.r_f0*tan(pi/4-obj.alpha/2));

            obj = profileFuncion(obj);
        end

        function obj = profileFuncion(obj)
            % Generate the trapezoidal rack tooth profile.

            % Significant profile points
            obj.points = zeros(2, 4);
            obj.points(1,4) = obj.Cs * obj.m_n * pi / 2;
            obj.points(1,1) = obj.points(1,4) - obj.h_a0*tan(obj.alpha) - obj.r_a0*tan(pi/4 - obj.alpha/2);
            obj.points(1,2) = obj.points(1,1);
            obj.points(1,3) = obj.points(1,1) + obj.r_a0*cos(obj.alpha);

            obj.points(2,1:2) = [-obj.h_a0 + obj.r_a0,  -obj.h_a0];
            obj.points(2,3)   = obj.points(2,1) - obj.r_a0*sin(obj.alpha);
            obj.points(2,4)   = 0;

            % Root fillet centre
            O_f(1) = obj.points(1,4) + obj.h_f0*tan(obj.alpha) + obj.r_f0*tan(pi/4 - obj.alpha/2);
            O_f(2) = obj.h_f0 - obj.r_f0;

            % Parameter for fillet arcs
            t = linspace(0, pi/2 - obj.alpha, obj.quality);

            % Assemble the half-tooth profile
            obj.profile = [0  obj.r_a0*sin(t)+obj.points(1,1)  -obj.r_f0*cos(t+obj.alpha)+O_f(1)  obj.m_n*pi/2; ...
                           -obj.h_a0  -obj.r_a0*cos(t)+obj.points(2,1)  obj.r_f0*sin(t+obj.alpha)+O_f(2)  obj.h_f0];

            % Apply profile shift
            obj.points(2,:) = obj.points(2,:) + obj.X_d;
            obj.profile(2,:) = obj.profile(2,:) + obj.X_d;

            % Mirror to full tooth
            obj.tooth = [fliplr([-obj.profile(1,2:end); obj.profile(2,2:end)])  obj.profile(:,2:end)];
            obj.points = [fliplr([-obj.points(1,:); obj.points(2,:)])  obj.points];
        end

        function obj = computeToolRounding(obj)
            % Determine hob tool rounding radii per CSN 01 4608
            obj.r_f0 = Generator.toolRootRounding(obj.m_n);
            obj.r_a0 = obj.rf_koef * obj.m_n;
        end
    end
end
