% Copyright (c) 2026 Richard Timko
classdef cycloidRack
    % This class generates the basic tooth profile for cycloidal gearing.
    %
    % Class creator: Richard Timko

    properties
        m_n (1,1) double % Normal module of gearing [mm]
        rho_a0 (1,1) double % Radius of the generating circle for the addendum cycloid [mm]
        rho_f0 (1,1) double % Radius of the generating circle for the dedendum cycloid [mm]
        x (1,1) double % Profile shift coefficient of the tool [-]
    end

    properties (SetAccess = private)
        % DIMENSIONS OF THE CUTTING TOOL TOOTH
        r_a0 (1,1) double % Tool addendum rounding radius [mm]
        r_f0 (1,1) double % Tool dedendum rounding radius [mm]
        c_0 (1,1) double % Tool tip clearance [mm]
        h_a0 (1,1) double % Tool addendum height [mm]
        h_f0 (1,1) double % Tool dedendum height [mm]
        X_d (1,1) double % (Radial) tool shift during gear manufacturing [mm]
        profile_shift (1,1) double % Horizontal profile shift to ensure pitch property on the pitch line

        % PITCHES
        p % Pitch [mm]

        % DIMENSIONS OF THE GEAR
        c_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.25 % Tip clearance coefficient [-]
        rf_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.38 % Root fillet radius coefficient [-]

        % Limits of generating circle radii for addendum and dedendum cycloids [-]
        rho_a0_lim (1,2) double % Radius limits of the addendum cycloid generating circle [-]
        rho_f0_lim (1,2) double % Radius limits of the dedendum cycloid generating circle [-]

        % Functions subject to minimization
        footCenterFun function_handle % Implicit function for determining the center of the root fillet circle
        tipCenterFun function_handle % Implicit function for determining the center of the tip rounding circle

        % Storage of cycloids
        cycloid_a double % Addendum cycloid of the rack tool
        cycloid_f double % Dedendum cycloid of the rack tool

        % Storage of rounding circles
        circle_a double % Rounding circle at the tip of the rack tool tooth
        circle_f double % Rounding circle at the root of the rack tool tooth
    end

    properties (SetAccess = private, Hidden)
        % TOOTH PROFILE
        quality (1,1) uint8 % Number of points forming the tooth rounding circles
        points double % Significant points on the tooth profile
        profile double % Total profile of half a tooth
        tooth double % Total profile of the entire tooth
    end

    properties (Constant)
        Cs (1,1) double {mustBeNumeric, mustBePositive} = 0.5 % Coefficient for modifying the rack tooth thickness [-]
    end

    methods
        function obj = cycloidRack(modul, polomer_tvoriacej_kruznice_hlavovej_cykloidy, polomer_tvoriacej_kruznice_patnej_cykloidy, jednotkove_posunutie, kvalita)
            % Constructor - creates an object of the "cycloidRack" class
            arguments % Validation of function arguments
                modul (1,1) double {mustBeNumeric, mustBePositive}
                polomer_tvoriacej_kruznice_hlavovej_cykloidy (1,1) double {mustBeNumeric, mustBePositive}
                polomer_tvoriacej_kruznice_patnej_cykloidy (1,1) double {mustBeNumeric, mustBePositive}
                jednotkove_posunutie (1,1) double {mustBeNumeric} = 0
                kvalita (1,1) uint8 {mustBeInteger} = 50;
            end

            if mod(kvalita,2) == 1
                kvalita = kvalita + 1; % Ensuring the variable is divisible by two
                warning("Quality was increased to %.0f to be divisible by two",kvalita)
            end
            obj.quality = kvalita;

            % Overwriting object attributes
            obj.m_n = modul;
            obj.rho_a0 = polomer_tvoriacej_kruznice_hlavovej_cykloidy;
            obj.rho_f0 = polomer_tvoriacej_kruznice_patnej_cykloidy;
            obj.x = jednotkove_posunutie;
            obj.X_d = obj.m_n*obj.x;

            obj = toothRoundingTool(obj);
            obj.c_0 = ceil(4*sqrt(obj.m_n))/10;
            obj.h_a0 = obj.m_n*(1+obj.c_koef);
            obj.h_f0 = obj.m_n + obj.c_0;

            obj.p = obj.m_n*pi; % Pitch on the pitch circle

            % Limits of generating circle radii for addendum and dedendum cycloids [-]
            obj.rho_a0_lim(1) = obj.h_a0/2;      
            obj.rho_f0_lim(1) = obj.h_f0/2;

            % Defining horizontal profile shift to ensure the pitch property on the pitch line
            % Pitch property: tooth thickness equals tooth space width
            if obj.X_d > 0
                parameter = acos(1-obj.X_d/obj.rho_f0);
                obj.profile_shift = -obj.rho_f0*(parameter-sin(parameter));
            elseif obj.X_d < 0
                parameter = acos(1+obj.X_d/obj.rho_a0);
                obj.profile_shift = obj.rho_a0*(parameter-sin(parameter));
            else
                obj.profile_shift = 0;
            end

            % Loading the minimum radius value of the generating circles
            obj = limFun(obj);

            % Creation of the cycloidal tooth profile on the gear rack
            if obj.rho_a0 <= max(obj.rho_a0_lim)
                warning("Addendum cycloid creation is not possible with the given parameters.\n" + ...
                        "The addendum cycloid has no intersection with the addendum circle, or the center of the tooth tip rounding circle is not in the expected interval.\n" + ...
                        "The generating circle radius should be greater than %.3f mm.\n",max(obj.rho_a0_lim))

            elseif obj.rho_f0 <= max(obj.rho_f0_lim)
                warning("Dedendum cycloid creation is not possible with the given parameters.\n" + ...
                        "The dedendum cycloid has no intersection with the dedendum circle, or the center of the tooth root rounding circle is not in the expected interval.\n" + ...
                        "The generating circle radius should be greater than %.3f mm.\n",max(obj.rho_f0_lim))
            else
                obj = profileFuncion(obj);
            end
            
        end

        function obj = profileFuncion(obj)
            % Generator of the cycloidal tooth profile on the gear rack

            if obj.X_d < obj.h_a0-obj.r_a0 && obj.X_d > -obj.h_f0+obj.r_f0
                % Profile consists of addendum and dedendum cycloids
                obj = bothCycloidProfile(obj);
            elseif obj.X_d <= -obj.h_f0+obj.r_f0
                % Profile consists only of the addendum cycloid
                obj = headCycloidProfile(obj);
            elseif obj.X_d >= obj.h_a0-obj.r_a0
                % Profile consists only of the dedendum cycloid
                obj = footCycloidProfile(obj);
            else
                error("A problem occurred during the creation of the cycloidal rack tool profile.")
            end

            obj.tooth(2,:) = obj.tooth(2,:) + obj.X_d;
        end

        %% FUNCTIONS DETERMINING THE RACK TOOTH PROFILE
        function obj = bothCycloidProfile(obj)
            % Profile consists of addendum and dedendum cycloids

            % Numerical search for the tangent point between cycloids and rounding circles
            obj.footCenterFun = @(par) obj.rho_f0*(1-cos(par)) - obj.r_f0*(1-cos(par))./sqrt(2*( 1-cos(par) )) - obj.h_f0 + obj.r_f0 - obj.X_d;
            obj.tipCenterFun = @(par) -obj.rho_a0*(1-cos(par)) + obj.r_a0*(1-cos(par))./sqrt(2*( 1-cos(par) )) + obj.h_a0 - obj.r_a0 - obj.X_d;

            tau_f_lim(1) = acos( (obj.r_f0 - obj.h_f0 - obj.X_d)./obj.rho_f0 + 1 );
            tau_f_lim(2) = acos( (-obj.h_f0 - obj.X_d)./obj.rho_f0 + 1 );

            tau_a_lim(1) = acos( (obj.r_a0 - obj.h_a0 + obj.X_d)./obj.rho_a0 + 1 );
            tau_a_lim(2) = acos( (-obj.h_a0 + obj.X_d)./obj.rho_a0 + 1 );

            tau_f = fzero(obj.footCenterFun,tau_f_lim);
            tau_a = fzero(obj.tipCenterFun,tau_a_lim);

            % Defining cycloids
            t_f = linspace(0,tau_f,obj.quality); % Dedendum cycloid parameter (rotation angle of generating circle)
            t_a = linspace(0,tau_a,obj.quality); % Addendum cycloid parameter (rotation angle of generating circle)

            obj.cycloid_f(1,:) = obj.rho_f0*(t_f-sin(t_f)) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift; % X-component of the dedendum cycloid
            obj.cycloid_f(2,:) = obj.rho_f0*(1-cos(t_f)) - obj.X_d; % Y-component of the dedendum cycloid

            obj.cycloid_a(1,:) = -obj.rho_a0*(t_a-sin(t_a)) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift; % X-component of the addendum cycloid
            obj.cycloid_a(2,:) = -obj.rho_a0*(1-cos(t_a)) - obj.X_d; % Y-component of the addendum cycloid

            % Centers of rounding circles
            O_f(1) = obj.rho_f0*(tau_f-sin(tau_f)) + obj.r_f0*sin(tau_f)/sqrt(2*( 1-cos(tau_f) )) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
            O_f(2) = obj.rho_f0*(1-cos(tau_f)) + obj.r_f0*(cos(tau_f)-1)/sqrt(2*( 1-cos(tau_f) )) - obj.X_d;

            O_a(1) = -obj.rho_a0*(tau_a-sin(tau_a)) - obj.r_a0*sin(tau_a)/sqrt(2*( 1-cos(tau_a) )) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
            O_a(2) = -obj.rho_a0*(1-cos(tau_a)) - obj.r_a0*(cos(tau_a)-1)/sqrt(2*( 1-cos(tau_a) )) - obj.X_d;

            % Arc of the rounding circle at the tooth root
            tau_Cf = acos( (obj.cycloid_f(2,end)+obj.r_f0-obj.h_f0)/obj.r_f0 );
            t_Cf = linspace(0,tau_Cf,obj.quality/2);
            obj.circle_f(1,:) = O_f(1) - obj.r_f0*sin(t_Cf);
            obj.circle_f(2,:) = O_f(2) + obj.r_f0*cos(t_Cf);

            % Arc of the rounding circle at the tooth tip
            tau_Ca = acos( (obj.r_a0-obj.h_a0-obj.cycloid_a(2,end))/obj.r_a0 );
            t_Ca = linspace(0,tau_Ca,obj.quality/2);
            obj.circle_a(1,:) = O_a(1) + obj.r_a0*sin(t_Ca);
            obj.circle_a(2,:) = O_a(2) - obj.r_a0*cos(t_Ca);

            % Writing data to final class attributes
            obj.profile(1,:) = [0 obj.circle_a(1,:) fliplr( obj.cycloid_a(1,2:end-1) ) obj.cycloid_f(1,1:end-1) fliplr(obj.circle_f(1,:)) obj.m_n*pi/2];
            obj.profile(2,:) = [-obj.h_a0 obj.circle_a(2,:) fliplr( obj.cycloid_a(2,2:end-1) ) obj.cycloid_f(2,1:end-1) fliplr(obj.circle_f(2,:)) obj.h_f0];

            obj.tooth = obj.profile(:,2:end);
            obj.tooth = [ fliplr([-obj.tooth(1,:); obj.tooth(2,:)]) obj.tooth];
        end

        function obj = headCycloidProfile(obj)
            % Profile consists only of the addendum cycloid

            % Numerical search for the tangent point between the addendum cycloid and the root fillet rounding circle
            if obj.X_d == -obj.h_f0+obj.r_f0
                tau_f = 0;
            else
                obj.footCenterFun = @(par) -obj.rho_a0*(1-cos(par)) - obj.r_f0.*(1-cos(par))/sqrt(2*( 1-cos(par) )) - obj.h_f0 + obj.r_f0 - obj.X_d;
                if obj.X_d > -obj.h_f0
                    tau_f_lim(1) = 1e-6;
                else
                    tau_f_lim(1) = acos( (obj.h_f0 + obj.X_d)./obj.rho_a0 + 1 );
                end
                tau_f_lim(2) = acos( (obj.h_f0 - obj.r_f0 + obj.X_d)./obj.rho_a0 + 1 );
                tau_f = fzero(obj.footCenterFun,tau_f_lim);
            end

            % Numerical search for the tangent point between the addendum cycloid and the tooth tip rounding circle
            obj.tipCenterFun = @(par) -obj.rho_a0*(1-cos(par)) + obj.r_a0.*(1-cos(par))/sqrt(2*( 1-cos(par) )) + obj.h_a0 - obj.r_a0 - obj.X_d;

            tau_a0(1) = acos( (obj.r_a0 - obj.h_a0 + obj.X_d)./obj.rho_a0 + 1 );
            tau_a0(2) = acos( (-obj.h_a0 + obj.X_d)./obj.rho_a0 + 1 );

            tau_a = fzero(obj.tipCenterFun,tau_a0);

            % Defining the addendum cycloid
            t_a = linspace(tau_f,tau_a); % Addendum cycloid parameter (rotation angle of generating circle)
            obj.cycloid_a(1,:) = -obj.rho_a0*(t_a-sin(t_a)) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift; % X-component of the addendum cycloid
            obj.cycloid_a(2,:) = -obj.rho_a0*(1-cos(t_a)) - obj.X_d; % Y-component of the addendum cycloid

            % Defining the center of the root fillet rounding circle
            if obj.X_d == -obj.h_f0+obj.r_f0
                tau_Cf = pi/2;
                O_f(1) = -obj.rho_a0*(tau_f-sin(tau_f)) + obj.r_f0 + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
                O_f(2) = obj.h_f0-obj.r_f0;
            else
                tau_Cf = acos( (obj.cycloid_a(2,1)+obj.r_f0-obj.h_f0)/obj.r_f0 );
                O_f(1) = -obj.rho_a0*(tau_f-sin(tau_f)) + obj.r_f0*sin(tau_f)/sqrt(2*( 1-cos(tau_f) )) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
                O_f(2) = -obj.rho_a0*(1-cos(tau_f)) + obj.r_f0*(cos(tau_f)-1)/sqrt(2*( 1-cos(tau_f) )) - obj.X_d;
            end

            % Defining the center of the tooth tip rounding circle
            O_a(1) = -obj.rho_a0*(tau_a-sin(tau_a)) - obj.r_a0*sin(tau_a)/sqrt(2*( 1-cos(tau_a) )) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
            O_a(2) = -obj.rho_a0*(1-cos(tau_a)) - obj.r_a0*(cos(tau_a)-1)/sqrt(2*( 1-cos(tau_a) )) - obj.X_d;

            % Defining the arc of the root fillet rounding circle
            t_Cf = linspace(0,tau_Cf);
            obj.circle_f(1,:) = O_f(1) - obj.r_f0*sin(t_Cf);
            obj.circle_f(2,:) = O_f(2) + obj.r_f0*cos(t_Cf);

            % Defining the arc of the tooth tip rounding circle
            tau_Ca = acos( (obj.r_a0-obj.h_a0-obj.cycloid_a(2,end))/obj.r_a0 );
            t_Ca = linspace(0,tau_Ca);
            obj.circle_a(1,:) = O_a(1) + obj.r_a0*sin(t_Ca);
            obj.circle_a(2,:) = O_a(2) - obj.r_a0*cos(t_Ca);

            % Writing data to final class attributes
            obj.profile(1,:) = [0 obj.circle_a(1,:) fliplr( obj.cycloid_a(1,2:end-1) ) fliplr(obj.circle_f(1,:)) obj.m_n*pi/2];
            obj.profile(2,:) = [-obj.h_a0 obj.circle_a(2,:) fliplr( obj.cycloid_a(2,2:end-1) ) fliplr(obj.circle_f(2,:)) obj.h_f0];

            obj.tooth = obj.profile(:,2:end);
            obj.tooth = [ fliplr([-obj.tooth(1,:); obj.tooth(2,:)]) obj.tooth];
        end

        function obj = footCycloidProfile(obj)
            % Profile consists only of the dedendum cycloid

            % Numerical search for the tangent point between the addendum cycloid and the tooth tip rounding circle
            if obj.X_d == obj.h_a0-obj.r_a0
                tau_a = 0;
            else
                obj.tipCenterFun = @(par) obj.rho_f0*(1-cos(par)) + obj.r_a0*(1-cos(par))./sqrt(2*( 1-cos(par) )) + obj.h_a0 - obj.r_a0 - obj.X_d;
                if obj.X_d < obj.h_a0
                    tau_a_lim(1) = 1e-6;
                else
                    tau_a_lim(1) = acos( (obj.h_a0 - obj.X_d)./obj.rho_f0 + 1 );
                end
                tau_a_lim(2) = acos( (obj.h_a0 - obj.r_a0 - obj.X_d)./obj.rho_f0 + 1 );
                tau_a = fzero(obj.tipCenterFun,tau_a_lim);
            end

            % Numerical search for the tangent point between the addendum cycloid and the root fillet rounding circle
            obj.footCenterFun = @(par) obj.rho_f0*(1-cos(par)) - obj.r_f0.*(1-cos(par))./sqrt(2*( 1-cos(par) )) - obj.h_f0 + obj.r_f0 - obj.X_d;

            tau_f_lim(1) = acos( (obj.r_f0 - obj.h_f0 - obj.X_d)./obj.rho_f0 + 1 );
            tau_f_lim(2) = acos( (-obj.h_f0 - obj.X_d)./obj.rho_f0 + 1 );

            tau_f = fzero(obj.footCenterFun,tau_f_lim);

            % Defining the dedendum cycloid
            t_f = linspace(tau_a,tau_f); % Dedendum cycloid parameter (rotation angle of generating circle)
            obj.cycloid_f(1,:) = obj.rho_f0*(t_f-sin(t_f)) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift; % X-component of the dedendum cycloid
            obj.cycloid_f(2,:) = obj.rho_f0*(1-cos(t_f)) - obj.X_d; % Y-component of the dedendum cycloid

            % Defining the center of the tooth tip rounding circle
            if obj.X_d == obj.h_a0-obj.r_a0
                tau_Ca = pi/2;
                O_a(1) = obj.rho_f0*(tau_a-sin(tau_a)) - obj.r_a0 + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
                O_a(2) = -obj.h_a0+obj.r_a0;
            else
                tau_Ca = acos( (obj.r_a0-obj.h_a0-obj.cycloid_f(2,1))/obj.r_a0 );
                O_a(1) = obj.rho_f0*(tau_a-sin(tau_a)) - obj.r_a0*sin(tau_a)/sqrt(2*( 1-cos(tau_a) )) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
                O_a(2) = obj.rho_f0*(1-cos(tau_a)) - obj.r_a0*(cos(tau_a)-1)/sqrt(2*( 1-cos(tau_a) )) - obj.X_d;
            end

            % Defining the center of the root fillet rounding circle
            O_f(1) = obj.rho_f0*(tau_f-sin(tau_f)) + obj.r_f0*sin(tau_f)/sqrt(2*( 1-cos(tau_f) )) + obj.Cs*obj.m_n*pi/2 + obj.profile_shift;
            O_f(2) = obj.rho_f0*(1-cos(tau_f)) + obj.r_f0*(cos(tau_f)-1)/sqrt(2*( 1-cos(tau_f) )) - obj.X_d;

            % Defining the arc of the root fillet rounding circle
            tau_Cf = acos( (obj.cycloid_f(2,1)+obj.r_f0-obj.h_f0)/obj.r_f0 );
            t_Cf = linspace(0,tau_Cf);
            obj.circle_f(1,:) = O_f(1) - obj.r_f0*sin(t_Cf);
            obj.circle_f(2,:) = O_f(2) + obj.r_f0*cos(t_Cf);

            % Defining the arc of the tooth tip rounding circle
            t_Ca = linspace(0,tau_Ca);
            obj.circle_a(1,:) = O_a(1) + obj.r_a0*sin(t_Ca);
            obj.circle_a(2,:) = O_a(2) - obj.r_a0*cos(t_Ca);

            % Writing data to final class attributes
            obj.profile(1,:) = [0 obj.circle_a(1,:) obj.cycloid_f(1,2:end-1) fliplr(obj.circle_f(1,:)) obj.m_n*pi/2];
            obj.profile(2,:) = [-obj.h_a0 obj.circle_a(2,:) obj.cycloid_f(2,2:end-1) fliplr(obj.circle_f(2,:)) obj.h_f0];

            obj.tooth = obj.profile(:,2:end);
            obj.tooth = [ fliplr([-obj.tooth(1,:); obj.tooth(2,:)]) obj.tooth];

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

        function obj = limFun(obj)
            % Function to determine the limit value of the generating circle radius

            % Minimum value of the generating circle radius for the dedendum cycloid
            if obj.X_d < obj.h_f0-obj.r_f0
                A = obj.h_f0 - obj.r_f0 + obj.X_d;
                B = obj.profile_shift - obj.m_n*pi/2*(1-obj.Cs);
                fun_f = @(t) sqrt( 2*(1-cos(t)) ) * ( (t-sin(t))*A + (1-cos(t))*B ) + t*obj.r_f0*( 1-cos(t) );

                t_f_lim = fzero(fun_f,[1e-6 pi]);
                obj.rho_f0_lim(2) = 1/( 1-cos(t_f_lim) ) * ( A+obj.r_f0*( 1-cos(t_f_lim) )/sqrt( 2*(1-cos(t_f_lim)) ) );
            else
                obj.rho_f0_lim(2) = obj.rho_f0_lim(1);
            end

            % Minimum value of the generating circle radius for the addendum cycloid
            if obj.X_d > -obj.h_a0+obj.r_a0
                A = obj.h_a0 - obj.r_a0 - obj.X_d;
                B = obj.profile_shift + obj.Cs*obj.m_n*pi/2;
                fun_a = @(t) sqrt( 2*(1-cos(t)) ) * ( (1-cos(t))*B - (t-sin(t))*A ) - t*obj.r_a0*( 1-cos(t) );

                t_a_lim = fzero(fun_a,[1e-6 pi]);
                obj.rho_a0_lim(2) = 1/( 1-cos(t_a_lim) ) * ( A+obj.r_a0*( 1-cos(t_a_lim) )/sqrt( 2*(1-cos(t_a_lim)) ) );
            else
                obj.rho_a0_lim(2) = obj.rho_a0_lim(1);
            end
        end
    end
end