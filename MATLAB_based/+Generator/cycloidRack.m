% Copyright (c) 2026 Richard Timko
classdef cycloidRack
    % cycloidRack — Generates the basic tooth profile for a cycloidal gear rack.
    %
    % The rack profile is composed of addendum and dedendum cycloids with
    % appropriate fillet rounding arcs at the tooth tip and root.

    properties
        m_n   (1,1) double  % Normal module [mm]
        rho_a0 (1,1) double % Generating circle radius for the addendum cycloid [mm]
        rho_f0 (1,1) double % Generating circle radius for the dedendum cycloid [mm]
        x     (1,1) double  % Profile shift coefficient [-]
    end

    properties (SetAccess = private)
        % Tool tooth dimensions
        r_a0  (1,1) double  % Tool addendum rounding radius [mm]
        r_f0  (1,1) double  % Tool dedendum rounding radius [mm]
        c_0   (1,1) double  % Tool tip clearance [mm]
        h_a0  (1,1) double  % Tool addendum height [mm]
        h_f0  (1,1) double  % Tool dedendum height [mm]
        X_d   (1,1) double  % Radial tool shift during manufacturing [mm]
        profile_shift (1,1) double % Horizontal shift ensuring pitch property on the pitch line

        % Pitch
        p              % Pitch on the pitch circle [mm]

        % Gear dimension coefficients
        c_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.25  % Tip clearance coefficient [-]
        rf_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.38 % Root fillet radius coefficient [-]

        % Limits of generating circle radii
        rho_a0_lim (1,2) double % Addendum cycloid generating circle radius limits
        rho_f0_lim (1,2) double % Dedendum cycloid generating circle radius limits

        % Implicit functions for finding fillet centres
        footCenterFun function_handle
        tipCenterFun  function_handle

        % Cycloid curve storage
        cycloid_a double  % Addendum cycloid of the rack tool
        cycloid_f double  % Dedendum cycloid of the rack tool

        % Fillet arc storage
        circle_a double   % Tip fillet arc
        circle_f double   % Root fillet arc
    end

    properties (SetAccess = private, Hidden)
        quality (1,1) uint8   % Number of points for fillet arcs
        points  double        % Significant points on the tooth profile
        profile double        % Half-tooth profile
        tooth   double        % Full symmetric tooth profile
    end

    properties (Constant)
        Cs (1,1) double {mustBeNumeric, mustBePositive} = 0.5 % Rack tooth thickness coefficient [-]
    end

    methods
        function obj = cycloidRack(modul, rho_a, rho_f, unit_shift, quality)
            % Constructor — create a cycloidRack object.
            %   modul   : normal module [mm]
            %   rho_a   : addendum cycloid generating circle radius [mm]
            %   rho_f   : dedendum cycloid generating circle radius [mm]
            %   unit_shift : profile shift coefficient [-] (default 0)
            %   quality : number of points for fillet arcs (default 50)
            arguments
                modul     (1,1) double {mustBeNumeric, mustBePositive}
                rho_a     (1,1) double {mustBeNumeric, mustBePositive}
                rho_f     (1,1) double {mustBeNumeric, mustBePositive}
                unit_shift (1,1) double {mustBeNumeric} = 0
                quality   (1,1) uint8  {mustBeInteger}  = 50
            end

            % Ensure quality is even (required by half-arc splitting)
            if mod(quality, 2) == 1
                quality = quality + 1;
                warning('Quality increased to %d to be divisible by two.', quality);
            end
            obj.quality = quality;

            % Store input parameters
            obj.m_n   = modul;
            obj.rho_a0 = rho_a;
            obj.rho_f0 = rho_f;
            obj.x     = unit_shift;
            obj.X_d   = obj.m_n * obj.x;

            % Compute tool rounding radii from standard CSN 01 4608
            obj = computeToolRounding(obj);
            obj.c_0  = ceil(4 * sqrt(obj.m_n)) / 10;
            obj.h_a0 = obj.m_n * (1 + obj.c_koef);
            obj.h_f0 = obj.m_n + obj.c_0;

            obj.p = obj.m_n * pi;  % Pitch on the pitch circle

            % Generating circle radius limits
            obj.rho_a0_lim(1) = obj.h_a0 / 2;
            obj.rho_f0_lim(1) = obj.h_f0 / 2;

            % Horizontal profile shift to maintain the pitch property
            if obj.X_d > 0
                parameter = acos(1 - obj.X_d / obj.rho_f0);
                obj.profile_shift = -obj.rho_f0 * (parameter - sin(parameter));
            elseif obj.X_d < 0
                parameter = acos(1 + obj.X_d / obj.rho_a0);
                obj.profile_shift = obj.rho_a0 * (parameter - sin(parameter));
            else
                obj.profile_shift = 0;
            end

            % Determine the minimum generating circle radius values
            obj = limFun(obj);

            % Build the cycloidal tooth profile (with validity checks)
            if obj.rho_a0 <= max(obj.rho_a0_lim)
                warning(['Addendum cycloid creation is not possible with the given parameters.\n' ...
                    'The generating circle radius should be greater than %.3f mm.'], max(obj.rho_a0_lim));
            elseif obj.rho_f0 <= max(obj.rho_f0_lim)
                warning(['Dedendum cycloid creation is not possible with the given parameters.\n' ...
                    'The generating circle radius should be greater than %.3f mm.'], max(obj.rho_f0_lim));
            else
                obj = profileFuncion(obj);
            end
        end

        function obj = profileFuncion(obj)
            % Generate the cycloidal tooth profile on the rack, choosing
            % the correct branch depending on profile shift magnitude.

            if obj.X_d < obj.h_a0 - obj.r_a0 && obj.X_d > -obj.h_f0 + obj.r_f0
                % Profile uses both addendum and dedendum cycloids
                obj = bothCycloidProfile(obj);
            elseif obj.X_d <= -obj.h_f0 + obj.r_f0
                % Profile uses only the addendum cycloid
                obj = headCycloidProfile(obj);
            elseif obj.X_d >= obj.h_a0 - obj.r_a0
                % Profile uses only the dedendum cycloid
                obj = footCycloidProfile(obj);
            else
                error('Unexpected condition during cycloidal rack profile creation.');
            end

            % Apply the radial shift to the y-coordinate
            obj.tooth(2,:) = obj.tooth(2,:) + obj.X_d;
        end

        %% Profile branch: both cycloids present
        function obj = bothCycloidProfile(obj)
            % Build the profile from both addendum and dedendum cycloids.

            % Implicit functions for tangent-point search
            obj.footCenterFun = @(par) obj.rho_f0*(1-cos(par)) ...
                - obj.r_f0*(1-cos(par))./sqrt(2*(1-cos(par))) ...
                - obj.h_f0 + obj.r_f0 - obj.X_d;
            obj.tipCenterFun = @(par) -obj.rho_a0*(1-cos(par)) ...
                + obj.r_a0*(1-cos(par))./sqrt(2*(1-cos(par))) ...
                + obj.h_a0 - obj.r_a0 - obj.X_d;

            % Bracket for dedendum tangent point
            tau_f_lim(1) = acos((obj.r_f0 - obj.h_f0 - obj.X_d) / obj.rho_f0 + 1);
            tau_f_lim(2) = acos((-obj.h_f0 - obj.X_d) / obj.rho_f0 + 1);

            % Bracket for addendum tangent point
            tau_a_lim(1) = acos((obj.r_a0 - obj.h_a0 + obj.X_d) / obj.rho_a0 + 1);
            tau_a_lim(2) = acos((-obj.h_a0 + obj.X_d) / obj.rho_a0 + 1);

            tau_f = fzero(obj.footCenterFun, tau_f_lim);
            tau_a = fzero(obj.tipCenterFun,  tau_a_lim);

            % Parametrise the cycloids
            t_f = linspace(0, tau_f, obj.quality);
            t_a = linspace(0, tau_a, obj.quality);

            obj.cycloid_f(1,:) = obj.rho_f0*(t_f - sin(t_f)) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
            obj.cycloid_f(2,:) = obj.rho_f0*(1 - cos(t_f)) - obj.X_d;

            obj.cycloid_a(1,:) = -obj.rho_a0*(t_a - sin(t_a)) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
            obj.cycloid_a(2,:) = -obj.rho_a0*(1 - cos(t_a)) - obj.X_d;

            % Centres of the fillet arcs
            O_f(1) = obj.rho_f0*(tau_f - sin(tau_f)) + obj.r_f0*sin(tau_f)/sqrt(2*(1-cos(tau_f))) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
            O_f(2) = obj.rho_f0*(1 - cos(tau_f)) + obj.r_f0*(cos(tau_f)-1)/sqrt(2*(1-cos(tau_f))) - obj.X_d;

            O_a(1) = -obj.rho_a0*(tau_a - sin(tau_a)) - obj.r_a0*sin(tau_a)/sqrt(2*(1-cos(tau_a))) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
            O_a(2) = -obj.rho_a0*(1 - cos(tau_a)) - obj.r_a0*(cos(tau_a)-1)/sqrt(2*(1-cos(tau_a))) - obj.X_d;

            % Root fillet arc
            tau_Cf = acos((obj.cycloid_f(2,end) + obj.r_f0 - obj.h_f0) / obj.r_f0);
            t_Cf = linspace(0, tau_Cf, obj.quality/2);
            obj.circle_f(1,:) = O_f(1) - obj.r_f0*sin(t_Cf);
            obj.circle_f(2,:) = O_f(2) + obj.r_f0*cos(t_Cf);

            % Tip fillet arc
            tau_Ca = acos((obj.r_a0 - obj.h_a0 - obj.cycloid_a(2,end)) / obj.r_a0);
            t_Ca = linspace(0, tau_Ca, obj.quality/2);
            obj.circle_a(1,:) = O_a(1) + obj.r_a0*sin(t_Ca);
            obj.circle_a(2,:) = O_a(2) - obj.r_a0*cos(t_Ca);

            % Assemble half-tooth profile and mirror to full tooth
            obj.profile(1,:) = [0  obj.circle_a(1,:)  fliplr(obj.cycloid_a(1,2:end-1))  obj.cycloid_f(1,1:end-1)  fliplr(obj.circle_f(1,:))  obj.m_n*pi/2];
            obj.profile(2,:) = [-obj.h_a0  obj.circle_a(2,:)  fliplr(obj.cycloid_a(2,2:end-1))  obj.cycloid_f(2,1:end-1)  fliplr(obj.circle_f(2,:))  obj.h_f0];

            obj.tooth = obj.profile(:,2:end);
            obj.tooth = [fliplr([-obj.tooth(1,:); obj.tooth(2,:)])  obj.tooth];
        end

        %% Profile branch: addendum cycloid only
        function obj = headCycloidProfile(obj)
            % Build the profile when only the addendum cycloid is present.

            % Find tangent point between addendum cycloid and root fillet
            if obj.X_d == -obj.h_f0 + obj.r_f0
                tau_f = 0;
            else
                obj.footCenterFun = @(par) -obj.rho_a0*(1-cos(par)) ...
                    - obj.r_f0*(1-cos(par))/sqrt(2*(1-cos(par))) ...
                    - obj.h_f0 + obj.r_f0 - obj.X_d;
                if obj.X_d > -obj.h_f0
                    tau_f_lim(1) = 1e-6;
                else
                    tau_f_lim(1) = acos((obj.h_f0 + obj.X_d) / obj.rho_a0 + 1);
                end
                tau_f_lim(2) = acos((obj.h_f0 - obj.r_f0 + obj.X_d) / obj.rho_a0 + 1);
                tau_f = fzero(obj.footCenterFun, tau_f_lim);
            end

            % Find tangent point between addendum cycloid and tip fillet
            obj.tipCenterFun = @(par) -obj.rho_a0*(1-cos(par)) ...
                + obj.r_a0*(1-cos(par))/sqrt(2*(1-cos(par))) ...
                + obj.h_a0 - obj.r_a0 - obj.X_d;

            tau_a0(1) = acos((obj.r_a0 - obj.h_a0 + obj.X_d) / obj.rho_a0 + 1);
            tau_a0(2) = acos((-obj.h_a0 + obj.X_d) / obj.rho_a0 + 1);
            tau_a = fzero(obj.tipCenterFun, tau_a0);

            % Addendum cycloid
            t_a = linspace(tau_f, tau_a);
            obj.cycloid_a(1,:) = -obj.rho_a0*(t_a - sin(t_a)) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
            obj.cycloid_a(2,:) = -obj.rho_a0*(1 - cos(t_a)) - obj.X_d;

            % Root fillet centre and arc
            if obj.X_d == -obj.h_f0 + obj.r_f0
                tau_Cf = pi/2;
                O_f(1) = -obj.rho_a0*(tau_f - sin(tau_f)) + obj.r_f0 + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
                O_f(2) = obj.h_f0 - obj.r_f0;
            else
                tau_Cf = acos((obj.cycloid_a(2,1) + obj.r_f0 - obj.h_f0) / obj.r_f0);
                O_f(1) = -obj.rho_a0*(tau_f - sin(tau_f)) + obj.r_f0*sin(tau_f)/sqrt(2*(1-cos(tau_f))) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
                O_f(2) = -obj.rho_a0*(1 - cos(tau_f)) + obj.r_f0*(cos(tau_f)-1)/sqrt(2*(1-cos(tau_f))) - obj.X_d;
            end

            % Tip fillet centre
            O_a(1) = -obj.rho_a0*(tau_a - sin(tau_a)) - obj.r_a0*sin(tau_a)/sqrt(2*(1-cos(tau_a))) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
            O_a(2) = -obj.rho_a0*(1 - cos(tau_a)) - obj.r_a0*(cos(tau_a)-1)/sqrt(2*(1-cos(tau_a))) - obj.X_d;

            % Root fillet arc
            t_Cf = linspace(0, tau_Cf);
            obj.circle_f(1,:) = O_f(1) - obj.r_f0*sin(t_Cf);
            obj.circle_f(2,:) = O_f(2) + obj.r_f0*cos(t_Cf);

            % Tip fillet arc
            tau_Ca = acos((obj.r_a0 - obj.h_a0 - obj.cycloid_a(2,end)) / obj.r_a0);
            t_Ca = linspace(0, tau_Ca);
            obj.circle_a(1,:) = O_a(1) + obj.r_a0*sin(t_Ca);
            obj.circle_a(2,:) = O_a(2) - obj.r_a0*cos(t_Ca);

            % Assemble and mirror
            obj.profile(1,:) = [0  obj.circle_a(1,:)  fliplr(obj.cycloid_a(1,2:end-1))  fliplr(obj.circle_f(1,:))  obj.m_n*pi/2];
            obj.profile(2,:) = [-obj.h_a0  obj.circle_a(2,:)  fliplr(obj.cycloid_a(2,2:end-1))  fliplr(obj.circle_f(2,:))  obj.h_f0];

            obj.tooth = obj.profile(:,2:end);
            obj.tooth = [fliplr([-obj.tooth(1,:); obj.tooth(2,:)])  obj.tooth];
        end

        %% Profile branch: dedendum cycloid only
        function obj = footCycloidProfile(obj)
            % Build the profile when only the dedendum cycloid is present.

            % Find tangent point between dedendum cycloid and tip fillet
            if obj.X_d == obj.h_a0 - obj.r_a0
                tau_a = 0;
            else
                obj.tipCenterFun = @(par) obj.rho_f0*(1-cos(par)) ...
                    + obj.r_a0*(1-cos(par))./sqrt(2*(1-cos(par))) ...
                    + obj.h_a0 - obj.r_a0 - obj.X_d;
                if obj.X_d < obj.h_a0
                    tau_a_lim(1) = 1e-6;
                else
                    tau_a_lim(1) = acos((obj.h_a0 - obj.X_d) / obj.rho_f0 + 1);
                end
                tau_a_lim(2) = acos((obj.h_a0 - obj.r_a0 - obj.X_d) / obj.rho_f0 + 1);
                tau_a = fzero(obj.tipCenterFun, tau_a_lim);
            end

            % Find tangent point between dedendum cycloid and root fillet
            obj.footCenterFun = @(par) obj.rho_f0*(1-cos(par)) ...
                - obj.r_f0*(1-cos(par))./sqrt(2*(1-cos(par))) ...
                - obj.h_f0 + obj.r_f0 - obj.X_d;

            tau_f_lim(1) = acos((obj.r_f0 - obj.h_f0 - obj.X_d) / obj.rho_f0 + 1);
            tau_f_lim(2) = acos((-obj.h_f0 - obj.X_d) / obj.rho_f0 + 1);
            tau_f = fzero(obj.footCenterFun, tau_f_lim);

            % Dedendum cycloid
            t_f = linspace(tau_a, tau_f);
            obj.cycloid_f(1,:) = obj.rho_f0*(t_f - sin(t_f)) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
            obj.cycloid_f(2,:) = obj.rho_f0*(1 - cos(t_f)) - obj.X_d;

            % Tip fillet centre and arc
            if obj.X_d == obj.h_a0 - obj.r_a0
                tau_Ca = pi/2;
                O_a(1) = obj.rho_f0*(tau_a - sin(tau_a)) - obj.r_a0 + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
                O_a(2) = -obj.h_a0 + obj.r_a0;
            else
                tau_Ca = acos((obj.r_a0 - obj.h_a0 - obj.cycloid_f(2,1)) / obj.r_a0);
                O_a(1) = obj.rho_f0*(tau_a - sin(tau_a)) - obj.r_a0*sin(tau_a)/sqrt(2*(1-cos(tau_a))) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
                O_a(2) = obj.rho_f0*(1 - cos(tau_a)) - obj.r_a0*(cos(tau_a)-1)/sqrt(2*(1-cos(tau_a))) - obj.X_d;
            end

            % Root fillet centre
            O_f(1) = obj.rho_f0*(tau_f - sin(tau_f)) + obj.r_f0*sin(tau_f)/sqrt(2*(1-cos(tau_f))) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
            O_f(2) = obj.rho_f0*(1 - cos(tau_f)) + obj.r_f0*(cos(tau_f)-1)/sqrt(2*(1-cos(tau_f))) - obj.X_d;

            % Root fillet arc
            tau_Cf = acos((obj.cycloid_f(2,1) + obj.r_f0 - obj.h_f0) / obj.r_f0);
            t_Cf = linspace(0, tau_Cf);
            obj.circle_f(1,:) = O_f(1) - obj.r_f0*sin(t_Cf);
            obj.circle_f(2,:) = O_f(2) + obj.r_f0*cos(t_Cf);

            % Tip fillet arc
            t_Ca = linspace(0, tau_Ca);
            obj.circle_a(1,:) = O_a(1) + obj.r_a0*sin(t_Ca);
            obj.circle_a(2,:) = O_a(2) - obj.r_a0*cos(t_Ca);

            % Assemble and mirror
            obj.profile(1,:) = [0  obj.circle_a(1,:)  obj.cycloid_f(1,2:end-1)  fliplr(obj.circle_f(1,:))  obj.m_n*pi/2];
            obj.profile(2,:) = [-obj.h_a0  obj.circle_a(2,:)  obj.cycloid_f(2,2:end-1)  fliplr(obj.circle_f(2,:))  obj.h_f0];

            obj.tooth = obj.profile(:,2:end);
            obj.tooth = [fliplr([-obj.tooth(1,:); obj.tooth(2,:)])  obj.tooth];
        end

        %% Tool rounding radii according to CSN 01 4608
        function obj = computeToolRounding(obj)
            obj.r_f0 = Generator.toolRootRounding(obj.m_n);
            obj.r_a0 = obj.rf_koef * obj.m_n;
        end

        %% Determine minimum generating circle radius limits
        function obj = limFun(obj)
            % Minimum value for the dedendum cycloid generating circle
            if obj.X_d < obj.h_f0 - obj.r_f0
                A = obj.h_f0 - obj.r_f0 + obj.X_d;
                B = obj.profile_shift - obj.m_n*pi/2*(1 - obj.Cs);
                fun_f = @(t) sqrt(2*(1-cos(t))) * ((t-sin(t))*A + (1-cos(t))*B) ...
                    + t*obj.r_f0*(1-cos(t));
                t_f_lim = fzero(fun_f, [1e-6 pi]);
                obj.rho_f0_lim(2) = 1/(1-cos(t_f_lim)) * ...
                    (A + obj.r_f0*(1-cos(t_f_lim))/sqrt(2*(1-cos(t_f_lim))));
            else
                obj.rho_f0_lim(2) = obj.rho_f0_lim(1);
            end

            % Minimum value for the addendum cycloid generating circle
            if obj.X_d > -obj.h_a0 + obj.r_a0
                A = obj.h_a0 - obj.r_a0 - obj.X_d;
                B = obj.profile_shift + obj.Cs*obj.m_n*pi/2;
                fun_a = @(t) sqrt(2*(1-cos(t))) * ((1-cos(t))*B - (t-sin(t))*A) ...
                    - t*obj.r_a0*(1-cos(t));
                t_a_lim = fzero(fun_a, [1e-6 pi]);
                obj.rho_a0_lim(2) = 1/(1-cos(t_a_lim)) * ...
                    (A + obj.r_a0*(1-cos(t_a_lim))/sqrt(2*(1-cos(t_a_lim))));
            else
                obj.rho_a0_lim(2) = obj.rho_a0_lim(1);
            end
        end
    end
end
