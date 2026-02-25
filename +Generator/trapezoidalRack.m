% Copyright (c) 2026 Richard Timko
classdef trapezoidalRack
    % This class generates the trapezoidal basic tooth profile for involute gearing.
    %
    % Class creator: Richard Timko

    properties
        m_n (1,1) double % Normal module of gearing [mm]
        alpha (1,1) double % Profile angle [rad]
        x (1,1) double % Profile shift coefficient of the tool [-]
        Cs (1,1) double {mustBeNumeric, mustBePositive} = 0.5 % Coefficient for modifying the rack tooth thickness [-]
    end

    properties (SetAccess = private)
        % DIMENSIONS OF THE CUTTING TOOL TOOTH
        r_a0 (1,1) double % Tool addendum rounding radius [mm]
        r_f0 (1,1) double % Tool dedendum rounding radius [mm]
        c_0 (1,1) double % Tool tip clearance [mm]
        h_a0 (1,1) double % Tool addendum height [mm]
        h_f0 (1,1) double % Tool dedendum height [mm]
        X_d (1,1) double % (Radial) tool shift during gear manufacturing [mm]

        % PITCHES
        p (1,1) double % Pitch [mm]

        % DIMENSIONS OF THE GEAR
        c_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.25 % Tip clearance coefficient [-]
        rf_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.38 % Root fillet radius coefficient [-]

        % Limits of the rack tooth thickness modification coefficient [-]
        Cs_lower (1,1) double % Lower limit of the rack tooth thickness modification coefficient [-]
        Cs_upper (1,1) double % Upper limit of the rack tooth thickness modification coefficient [-]

        alpha_max (1,1) double % Maximum possible profile angle of the specified tool
    end

    properties (SetAccess = private, Hidden)
        % TOOTH PROFILE
        quality (1,1) uint8 % Number of points forming the tooth rounding circles
        points double % Significant points on the tooth profile
        profile double % Total profile of half a tooth
        tooth double % Total profile of the entire tooth
    end

    methods
        function obj = trapezoidalRack(modul, uhol_profilu, jednotkove_posunutie, kvalita)
            % Constructor - creates an object of the "rackToothing" class
            arguments % Validation of function arguments
                modul (1,1) double {mustBeNumeric, mustBePositive} = 1
                uhol_profilu (1,1) double {mustBeNumeric, mustBePositive} = 20
                jednotkove_posunutie (1,1) double {mustBeNumeric} = 0
                kvalita (1,1) uint8 {mustBeInteger} = 25;
            end
            obj.quality = kvalita;

            % Overwriting object attributes
            obj.m_n = modul;
            obj.alpha = deg2rad(uhol_profilu);
            obj.x = jednotkove_posunutie;
            obj.X_d = obj.m_n*obj.x;

            obj = toothRoundingTool(obj);
            obj.c_0 = ceil(4*sqrt(obj.m_n))/10;
            obj.h_a0 = obj.m_n*(1+obj.c_koef);
            obj.h_f0 = obj.m_n + obj.c_0;

            obj.p = obj.m_n*pi; % Pitch on the pitch circle

            % Maximum profile angle (arising from the geometry of the rack tool tooth)
            obj.alpha_max = fzero(@(par) obj.Cs*obj.m_n*pi/2 - obj.h_a0*tan(par) - obj.r_a0*tan(pi/4-par/2),deg2rad(20));
            obj.alpha_max = floor(rad2deg(obj.alpha_max)*1e4)*1e-4;

            if uhol_profilu > obj.alpha_max
                warning("The entered profile angle is greater than the maximum.")
            end

            % Limits of the rack tooth thickness modification coefficient [-]
            obj.Cs_lower = ( obj.h_a0*tan(obj.alpha) + obj.r_a0*tan(pi/4-obj.alpha/2) )/(obj.m_n*pi);
            obj.Cs_upper = 1 - 2/(obj.m_n*pi)*( obj.h_f0*tan(obj.alpha) + obj.r_f0*tan(pi/4-obj.alpha/2) );

            % Creation of the trapezoidal tooth profile on the gear rack
            obj = profileFuncion(obj);
        end

        function obj = profileFuncion(obj)
            % Generator of the trapezoidal tooth profile on the gear rack
            
            % Significant points on the tooth profile
            obj.points = zeros(2,4);

            % X-coordinates of significant points
            obj.points(1,4) = obj.Cs*obj.m_n*pi/2; % Point on the pitch line
            
            obj.points(1,1) = obj.points(1,4) - obj.h_a0*tan(obj.alpha) - obj.r_a0*tan( pi/4-obj.alpha/2 );
            obj.points(1,2) = obj.points(1,1);
            obj.points(1,3) = obj.points(1,1) + obj.r_a0*cos(obj.alpha);
            
            % Y-coordinates of significant points
            obj.points(2,1:2) = [-obj.h_a0+obj.r_a0 -obj.h_a0];

            obj.points(2,3) = obj.points(2,1) - obj.r_a0*sin(obj.alpha);
            obj.points(2,4) = 0;
            
            % Center of the rounding circle at the tooth root
            O_f(1) = obj.points(1,4) + obj.h_f0*tan(obj.alpha) + obj.r_f0*tan( pi/4-obj.alpha/2 );
            O_f(2) = obj.h_f0-obj.r_f0;

            % Parameter of circular roundings
            t = linspace(0,pi/2-obj.alpha,obj.quality);
            
            % Total profile of half a tooth
            obj.profile = [0 obj.r_a0*sin(t)+obj.points(1,1) -obj.r_f0*cos(t+obj.alpha)+O_f(1) obj.m_n*pi/2;
                           -obj.h_a0 -obj.r_a0*cos(t)+obj.points(2,1) obj.r_f0*sin(t+obj.alpha)+O_f(2) obj.h_f0];

            % Profile shift
            obj.points(2,:) = obj.points(2,:) + obj.X_d;
            obj.profile(2,:) = obj.profile(2,:) + obj.X_d;

            % Total profile of the entire tooth
            obj.tooth = [ [fliplr([-obj.profile(1,2:end);obj.profile(2,2:end)])] obj.profile(:,2:end)];
            obj.points = [ fliplr([-obj.points(1,:); obj.points(2,:)]) obj.points];
        end

        %% ADDITIONAL FUNCTIONS
        function obj = toothRoundingTool(obj)
            % Determining the hob tool root rounding according to standard CSN 01 4608
            if obj.m_n < 1
                obj.r_f0 = 0.1;
            elseif 1 <= obj.m_n && obj.m_n < 2
                obj.r_f0 = 0.2;
            elseif 2 <= obj.m_n && obj.m_n < 4.5
                obj.r_f0 = 0.5;
            elseif 4.5 <= obj.m_n && obj.m_n < 7
                obj.r_f0 = 1;
            elseif 7 <= obj.m_n && obj.m_n < 10
                obj.r_f0 = 1.5;
            elseif 10 <= obj.m_n && obj.m_n < 18
                obj.r_f0 = 2;
            elseif obj.m_n >= 18
                obj.r_f0 = 2.5;
            end
            obj.r_a0 = obj.rf_koef*obj.m_n;
        end
    end
end