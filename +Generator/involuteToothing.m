% Copyright (c) 2026 Richard Timko
classdef involuteToothing
    % This class generates the tooth profile for involute gearing,
    % which was manufactured primarily by the generating method.
    %
    % The tooth shape will correspond to the ideal when machined by the following methods:
    % 1) rack-cutter shaping (MAAG system)
    % 2) hobbing
    %
    % Class creator: Richard Timko

    properties
        m_n % Normal module of gearing [mm]
        z % Number of gear teeth [-]
        alpha % Profile angle [rad]
        x % Profile shift coefficient of the tool [-]
        Cs (1,1) double {mustBeNumeric, mustBePositive} = 0.5 % Coefficient for modifying the rack tooth thickness [-]
    end

    properties (SetAccess = private)
        % DIMENSIONS OF THE CUTTING TOOL TOOTH
        r_a0 % Tool addendum rounding radius [mm]
        r_f0 % Tool dedendum rounding radius [mm]
        c_0 % Tool tip clearance [mm]
        h_a0 % Tool addendum height [mm]
        h_f0 % Tool dedendum height [mm]
        X_d % (Radial) tool shift during gear manufacturing [mm]

        % PITCHES
        p % Pitch [mm]
        p_b % Base pitch [mm]
        p_a % Addendum pitch [mm]
        p_f % Dedendum pitch [mm]

        % DIMENSIONS OF THE GEAR
        c_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.25 % Tip clearance coefficient [-]
        rf_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.38 % Root fillet radius coefficient [-]
        r_f % Tooth root fillet radius [mm]
        h_a % Tooth addendum height [mm]
        h_f % Tooth dedendum height [mm]
        R % Pitch circle radius [mm]
        R_b % Base circle radius [mm]
        R_a % Addendum circle radius [mm]
        R_f % Dedendum circle radius [mm]

        % Limits of the rack tooth thickness modification coefficient [-]
        Cs_lower % Lower limit of the rack tooth thickness modification coefficient [-]
        Cs_upper % Upper limit of the rack tooth thickness modification coefficient [-]
    end

    properties (SetAccess = private)
        Inv_X % Function expressing the x-component of the circle involute
        Inv_Y % Function expressing the y-component of the circle involute
        Inv_R % Function expressing the polar radius of the circle involute
        Inv_t % Inverse function expressing the parameter from the circle involute polar radius function

        Tr1_X % Function expressing the x-component of the primary trochoid
        Tr1_Y % Function expressing the y-component of the primary trochoid
        Tr1_dX % Function expressing the derivative of the primary trochoid's x-component with respect to the parameter
        Tr1_dY % Function expressing the derivative of the primary trochoid's y-component with respect to the parameter

        Tr2_X % Function expressing the x-component of the secondary trochoid
        Tr2_Y % Function expressing the y-component of the secondary trochoid
        Tr2_R % Function expressing the polar radius of the secondary trochoid
    end

    properties (SetAccess = private, Hidden)
        % TOOTH PROFILE
        psi % Angular rotation of the circle involute [rad]
        Oa_X % X-coordinate of the tooth tip rounding center in the local coordinate system of the cutting tool [mm]
        Oa_Y % Y-coordinate of the tooth tip rounding center in the local coordinate system of the cutting tool [mm]
        initial_guess (1,1) double {mustBeNumeric,mustBePositive} = 3 % Upper boundary limit of the interval for the fzero algorithm

        quality (1,1) uint16 % Number of points forming the individual curves of the tooth profile
        trochoid % Transition curve of the tooth - secondary trochoid
        involute % Tooth profile curve - circle involute
        foot % Dedendum circle
        head % Addendum circle

        profile % Total profile of half a tooth
        tooth % Total profile of the entire tooth

        PointedTips % Logical value for pointed teeth
        x_lower % Lower boundary of the profile shift coefficient (disappearance of the profile curve)
        x_upper % Upper boundary of the profile shift coefficient (pointedness)
        alpha_max % Maximum possible profile angle of the specified tool
    end

    methods
        function obj = involuteToothing(modul, uhol_profilu, pocet_zubov, jednotkove_posunutie, kvalita)
            % Constructor - creates an object of the "InvoluteToothing" class
            arguments % Validation of function arguments
                modul (1,1) double {mustBeNumeric, mustBePositive} = 1
                uhol_profilu (1,1) double {mustBeNumeric, mustBePositive} = 20
                pocet_zubov (1,1) double {mustBeNumeric, mustBeInteger} = 30
                jednotkove_posunutie (1,1) double {mustBeNumeric} = 0
                kvalita (1,1) uint16 {mustBeInteger} = 200;
            end

            if mod(kvalita,4) == 1
                kvalita = kvalita + 1;
            elseif mod(kvalita,4) == 2
                kvalita = kvalita + 2;
            else
                kvalita = kvalita + 3;
            end
            obj.quality = kvalita;

            obj.PointedTips = false; % Resetting the logical value for checking pointed teeth

            % Overwriting object attributes
            obj.m_n = modul;
            obj.z = pocet_zubov;
            obj.alpha = deg2rad(uhol_profilu);
            obj.x = jednotkove_posunutie;
            obj.X_d = obj.m_n*obj.x;

            obj = toothRoundingTool(obj);
            obj.c_0 = ceil(4*sqrt(obj.m_n))/10;
            obj.h_a0 = obj.m_n*(1+obj.c_koef);
            obj.h_f0 = obj.m_n + obj.c_0;

            obj.r_f = obj.r_a0;
            obj.h_a = obj.m_n + obj.X_d;
            obj.h_f = obj.m_n*(1+obj.c_koef) - obj.X_d;
            obj.R = obj.m_n*obj.z/2;
            obj.R_b = obj.R*cos(obj.alpha);
            obj.R_a = obj.R + obj.h_a;
            obj.R_f = obj.R - obj.h_f;

            % PITCHES
            obj.p = obj.m_n*pi; % Pitch on the pitch circle
            obj.p_b = (2*pi/obj.z)*obj.R_b; % Base pitch
            obj.p_f = (2*pi/obj.z)*obj.R_f; % Dedendum pitch
            obj.p_a = (2*pi/obj.z)*obj.R_a; % Addendum pitch

            % Maximum profile angle (arising from the geometry of the rack tool tooth)
            obj.alpha_max = fzero(@(par) obj.Cs*obj.m_n*pi/2 - obj.h_a0*tan(par) - obj.r_a0*tan(pi/4-par/2),deg2rad(20));
            obj.alpha_max = floor(rad2deg(obj.alpha_max)*1e4)*1e-4;

            if uhol_profilu > obj.alpha_max
                warning("The entered profile angle is greater than the maximum.")
            end

            % Limits of the rack tooth thickness modification coefficient [-]
            obj.Cs_lower = ( obj.h_a0*tan(obj.alpha) + obj.r_a0*tan(pi/4-obj.alpha/2) )/(obj.m_n*pi);
            obj.Cs_upper = 1 - 2/(obj.m_n*pi)*( obj.h_f0*tan(obj.alpha) + obj.r_f0*tan(pi/4-obj.alpha/2) );

            % Saving profile curve functions
            obj = curveFuncions(obj);

            % Determining the lower boundary of the profile shift coefficient
            obj = lowerLimitProfileShift(obj);

            % Determining the upper boundary of the profile shift coefficient
            obj = upperLimitProfileShift(obj);

            % Mathematical description of the tooth profile
            obj = toothInvoluteProfile(obj);
        end
    end

    methods (Access = private)
        function obj = toothInvoluteProfile(obj)
            % Tooth profile generator

            % Function subject to minimization
            function distance = intersectionPoint(t_inv)
                common_radius = obj.Inv_R(t_inv);
                try
                    t_tr = fzero(@(par) common_radius - obj.Tr2_R(par,obj.x),[t_tr_start t_tr_end]);
                catch err
                    if strcmp(err.identifier,'MATLAB:fzero:ValuesAtEndPtsSameSign')
                        if common_radius < obj.Tr2_R(t_tr_start,obj.x)
                            t_tr = t_tr_start;
                        else
                            t_tr = t_tr_end;
                        end
                    else
                        rethrow(err);
                    end
                end
                distance = sqrt( (obj.Tr2_X(t_tr,obj.x) - obj.Inv_X(t_inv,obj.x)).^2 + (obj.Tr2_Y(t_tr,obj.x) - obj.Inv_Y(t_inv,obj.x)).^2 );
            end

            % Initial value of the secondary trochoid parameter - corresponds to the intersection between the dedendum circle and the transition curve
            t_tr_start = 0;
            if obj.x > obj.x_lower
                % Value of the secondary trochoid parameter corresponding to the intersection with the addendum circle
                t_tr_end = fzero(@(par) obj.R_a - obj.Tr2_R(par,obj.x),[t_tr_start obj.initial_guess]);

                t_inv_tip = obj.Inv_t(obj.R_a);
                angle_tip = atan( obj.Inv_X(t_inv_tip,obj.x)./obj.Inv_Y(t_inv_tip,obj.x) );
                if angle_tip > pi/obj.z
                    t_inv_tip = fzero(@(par) atan( obj.Inv_X(par,obj.x)./obj.Inv_Y(par,obj.x) ) - pi/obj.z, [t_inv_tip 0]);
                    obj.PointedTips = true;
                end
                t_inv_intersection = fminbnd(@intersectionPoint,t_inv_tip,0);
                t_tr_intersection = fzero(@(par) obj.Inv_R(t_inv_intersection) - obj.Tr2_R(par,obj.x),[t_tr_start t_tr_end]);

                t_involute = linspace(t_inv_intersection, t_inv_tip, obj.quality);
                obj.involute = [obj.Inv_X(t_involute,obj.x); obj.Inv_Y(t_involute,obj.x)];

                if obj.PointedTips == false
                    t_a_start = atan(obj.involute(1,end)/obj.involute(2,end)); t_a_end = pi/obj.z;
                    t_head = linspace(t_a_start,t_a_end,uint8(obj.quality/4));
                    obj.head = [obj.R_a*sin(t_head); obj.R_a*cos(t_head)];
                else
                    obj.head = NaN;
                end
            else
                t_tr_intersection = fzero(@(par) obj.R_a - obj.Tr2_R(par,obj.x),[t_tr_start obj.initial_guess]);
                obj.involute = NaN;
                t_a_start = atan(obj.Tr2_X(t_tr_intersection,obj.x)./obj.Tr2_Y(t_tr_intersection,obj.x)); t_a_end = pi/obj.z;
                t_head = linspace(t_a_start,t_a_end,uint8(obj.quality/4));
                obj.head = [obj.R_a*sin(t_head); obj.R_a*cos(t_head)];
            end

            t_trochoid = linspace(t_tr_start, t_tr_intersection, obj.quality);
            obj.trochoid = [obj.Tr2_X(t_trochoid,obj.x); obj.Tr2_Y(t_trochoid,obj.x)];
            angle_trochoid = atan(obj.trochoid(1,:)./obj.trochoid(2,:));
            id_no_head = find(angle_trochoid > pi/obj.z,1,"first");
            if ~isempty(id_no_head)
                t_no_head = fzero(@(par) atan(obj.Tr2_X(par,obj.x)./obj.Tr2_Y(par,obj.x)) - pi/obj.z, [0 t_trochoid(id_no_head)]);
                t_trochoid = linspace(t_tr_start, t_no_head, obj.quality);
                obj.trochoid = [obj.Tr2_X(t_trochoid,obj.x); obj.Tr2_Y(t_trochoid,obj.x)];
            end
            t_f_start = 0; t_f_end = atan(obj.trochoid(1,1)/obj.trochoid(2,1));
            t_foot = linspace(t_f_start,t_f_end,uint8(obj.quality/4));
            obj.foot = [obj.R_f*sin(t_foot); obj.R_f*cos(t_foot)];

            id_no_foot = find(obj.trochoid(1,:) < 0,1,"last");
            if ~isempty(id_no_foot)
                obj.trochoid = obj.trochoid(:,id_no_foot+1:end);
                obj.foot = NaN;
                if obj.x > obj.x_lower
                    if obj.PointedTips == false
                        obj.profile = [obj.trochoid(:,1:end-1) obj.involute obj.head(:,2:end)];
                    else
                        obj.profile = [obj.trochoid(:,1:end-1) obj.involute];
                    end
                else
                    if isempty(id_no_head)
                        obj.profile = [obj.trochoid obj.head(:,2:end)];
                    else
                        obj.profile = obj.trochoid;
                    end
                end
            else
                if obj.x > obj.x_lower
                    if obj.PointedTips == false
                        obj.profile = [obj.foot(:,1:end-1) obj.trochoid(:,1:end-1) obj.involute obj.head(:,2:end)];
                    else
                        obj.profile = [obj.foot(:,1:end-1) obj.trochoid(:,1:end-1) obj.involute];
                    end
                else
                    if isempty(id_no_head)
                        obj.profile = [obj.foot(:,1:end-1) obj.trochoid obj.head(:,2:end)];
                    else
                        obj.profile = [obj.foot(:,1:end-1) obj.trochoid];
                    end
                end
            end

            if obj.x > obj.x_lower
                if obj.PointedTips == false
                    obj.profile = [obj.foot(:,1:end-1) obj.trochoid(:,1:end-1) obj.involute obj.head(:,2:end)];
                else
                    obj.profile = [obj.foot(:,1:end-1) obj.trochoid(:,1:end-1) obj.involute];
                end
            else
                if isempty(id_no_head)
                    obj.profile = [obj.foot(:,1:end-1) obj.trochoid obj.head(:,2:end)];
                else
                    obj.profile = [obj.foot(:,1:end-1) obj.trochoid];
                end
            end

            T_rotate = [cos(pi/obj.z) -sin(pi/obj.z); sin(pi/obj.z) cos(pi/obj.z)];
            left_profile = T_rotate*obj.profile;
            right_profile = [-left_profile(1,:); left_profile(2,:)];
            obj.tooth = [left_profile(1,1:end-1) fliplr(right_profile(1,:)); left_profile(2,1:end-1) fliplr(right_profile(2,:))];
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

        function obj = curveFuncions(obj)
            % Saving necessary functions

            % Tooth tip rounding center in the local coordinate system of the cutting tool
            obj.Oa_X = obj.Cs*obj.m_n*pi/2 - obj.h_a0*tan(obj.alpha) - obj.r_a0*tan(pi/4-obj.alpha/2);
            obj.Oa_Y = @(par) -obj.h_a0 + obj.r_a0 + obj.m_n*par;

            % Angular rotation of the circle involute
            obj.psi = @(par) tan(obj.alpha) - obj.alpha - ( obj.Cs*obj.m_n*pi - 2*obj.m_n*par*tan(obj.alpha) )/(2*obj.R);

            % Function expressing the x-component of the circle involute
            obj.Inv_X = @(par1,par2) obj.R_b*par1.*cos(obj.psi(par2)+par1) - obj.R_b*sin(obj.psi(par2)+par1);
            % Function expressing the y-component of the circle involute
            obj.Inv_Y = @(par1,par2) obj.R_b*par1.*sin(obj.psi(par2)+par1) + obj.R_b*cos(obj.psi(par2)+par1);

            % Function expressing the x-component of the primary trochoid
            obj.Tr1_X = @(par1,par2) obj.R*par1.*cos(par1-obj.Oa_X./obj.R) - (obj.Oa_Y(par2)+obj.R).*sin(par1-obj.Oa_X./obj.R); 
            % Function expressing the y-component of the primary trochoid
            obj.Tr1_Y = @(par1,par2) obj.R*par1.*sin(par1-obj.Oa_X./obj.R) + (obj.Oa_Y(par2)+obj.R).*cos(par1-obj.Oa_X./obj.R); 
            % Function expressing the derivative of the primary trochoid's x-component with respect to the parameter
            obj.Tr1_dX = @(par1,par2) -obj.Oa_Y(par2).*cos(par1-obj.Oa_X./obj.R) - obj.R*par1.*sin(par1-obj.Oa_X./obj.R); 
            % Function expressing the derivative of the primary trochoid's y-component with respect to the parameter
            obj.Tr1_dY = @(par1,par2) -obj.Oa_Y(par2).*sin(par1-obj.Oa_X./obj.R) + obj.R*par1.*cos(par1-obj.Oa_X./obj.R); 

            % Function expressing the x-component of the secondary trochoid
            if obj.x >= 1 + obj.c_koef - obj.rf_koef
                obj.Tr2_X = @(par1,par2) obj.Tr1_X(-par1,par2) + obj.r_a0*cos(atan2( -obj.Tr1_dX(-par1,par2), obj.Tr1_dY(-par1,par2) ) + pi); % X-component of the secondary trochoid
                obj.Tr2_Y = @(par1,par2) obj.Tr1_Y(-par1,par2) + obj.r_a0*sin(atan2( -obj.Tr1_dX(-par1,par2), obj.Tr1_dY(-par1,par2) ) + pi); % Y-component of the secondary trochoid
            else
                obj.Tr2_X = @(par1,par2) obj.Tr1_X(par1,par2) + obj.r_a0*cos(atan2( -obj.Tr1_dX(par1,par2), obj.Tr1_dY(par1,par2) )); % X-component of the secondary trochoid
                obj.Tr2_Y = @(par1,par2) obj.Tr1_Y(par1,par2) + obj.r_a0*sin(atan2( -obj.Tr1_dX(par1,par2), obj.Tr1_dY(par1,par2) )); % Y-component of the secondary trochoid
            end

            % Parametric functions of the polar radius of the circle involute and both trochoids
            obj.Inv_R = @(par) obj.R_b*sqrt(1+par.^2);
            obj.Tr2_R = @(par1,par2) sqrt( obj.Tr2_X(par1,par2).^2 + obj.Tr2_Y(par1,par2).^2 );

            % Function for obtaining the circle involute parameter from a given polar radius
            obj.Inv_t = @(rho) -sqrt(rho.^2 - obj.R_b^2)/obj.R_b;
        end

        function obj = lowerLimitProfileShift(obj)
            % Function to determine the lower boundary of the profile shift coefficient

            % Necessary to redefine functions, as the user might select a shift x > 1 + obj.c_koef - obj.rf_koef, overwriting the functions in the IF scope
            fun_Tr2_X = @(par1,par2) obj.Tr1_X(par1,par2) + obj.r_a0*cos(atan2( -obj.Tr1_dX(par1,par2), obj.Tr1_dY(par1,par2) )); % X-component of the secondary trochoid
            fun_Tr2_Y = @(par1,par2) obj.Tr1_Y(par1,par2) + obj.r_a0*sin(atan2( -obj.Tr1_dX(par1,par2), obj.Tr1_dY(par1,par2) )); % Y-component of the secondary trochoid
            function distance = involuteAbsenceFunction(x_lim)
                t_inv_lim = obj.Inv_t(obj.R + (1+x_lim)*obj.m_n);
                t_tr_lim = fzero(@(par) obj.Inv_R(t_inv_lim) - obj.Tr2_R(par,x_lim),[0 obj.initial_guess]);
                distance = sqrt( (fun_Tr2_X(t_tr_lim,x_lim) - obj.Inv_X(t_inv_lim,x_lim)).^2 + (fun_Tr2_Y(t_tr_lim,x_lim) - obj.Inv_Y(t_inv_lim,x_lim)).^2 );
            end
            x_start = obj.z/2*(cos(obj.alpha) - 1) - 1;
            x_end = 0;
            obj.x_lower = fminbnd(@involuteAbsenceFunction,x_start,x_end);
            obj.x_lower = ceil(obj.x_lower*1e4)*1e-4;
        end

        function obj = upperLimitProfileShift(obj)
            % Function to determine the upper boundary of the profile shift coefficient
            function delta = pointedTipFunction(x_lim)
                t_intersection = obj.Inv_t(obj.R + (1+x_lim)*obj.m_n);
                angle_inv = atan( obj.Inv_X(t_intersection,x_lim)./obj.Inv_Y(t_intersection,x_lim) );
                delta = abs(angle_inv - pi/obj.z);
            end

            obj.x_upper = fminbnd(@pointedTipFunction,obj.x_lower,1+obj.c_koef);
            obj.x_upper = floor(obj.x_upper*1e4)*1e-4;
        end
    end
end