% Copyright (c) 2026 Richard Timko
classdef cycloidToothing
    % This class generates the tooth profile for cycloidal gearing,
    % which was fictitiously manufactured primarily by the generating method.
    %
    % The tooth shape will correspond to the fictitious ideal when machined by the following methods:
    % 1) rack-cutter shaping (MAAG system)
    % 2) hobbing
    %
    % Class creator: Richard Timko

    properties
        m_n % Normal module of gearing [mm]
        a_e % Radius of the generating circle for creating the epicycloid (tooth addendum) [mm]
        a_h % Radius of the generating circle for creating the hypocycloid (tooth dedendum) [mm]
        z % Number of gear teeth [-]
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

        % DIMENSIONS OF THE GEAR
        c_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.25 % Tip clearance coefficient [-]
        rf_koef (1,1) double {mustBeNumeric, mustBePositive} = 0.38 % Root fillet radius coefficient [-]
        r_f % Tooth root fillet radius [mm]
        h_a % Tooth addendum height [mm]
        h_f % Tooth dedendum height [mm]
        R % Pitch circle radius [mm]
        R_b single  = NaN; % Base circle radius [mm]
        R_a % Addendum circle radius [mm]
        R_f % Dedendum circle radius [mm]
    end

    properties (SetAccess = private)
        Hypo_X % Function expressing the x-component of the hypocycloid
        Hypo_Y % Function expressing the y-component of the hypocycloid
        Hypo_R % Function expressing the polar radius of the hypocycloid
        Hypo_t % Inverse function expressing the parameter from the hypocycloid polar radius function

        Epi_X % Function expressing the x-component of the epicycloid
        Epi_Y % Function expressing the y-component of the epicycloid
        Epi_R % Function expressing the polar radius of the epicycloid
        Epi_t % Inverse function expressing the parameter from the epicycloid polar radius function

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
        psi % Angular rotation of the epicycloid and hypocycloid [rad]
        X_shift % Horizontal profile shift to ensure standard pitch in corrected cycloidal gearing
        Oa_X % X-coordinate of the tooth tip rounding center in the local coordinate system of the cutting tool [mm]
        Oa_Y % Y-coordinate of the tooth tip rounding center in the local coordinate system of the cutting tool [mm]
        initial_guess (1,1) double {mustBeNumeric,mustBePositive} = 3 % Upper boundary limit of the interval for the fzero algorithm

        quality (1,1) uint16 % Number of points forming the individual curves of the tooth profile
        trochoid % Transition curve of the tooth - secondary trochoid
        epicycloid % Addendum profile curve - epicycloid
        hypocycloid % Dedendum profile curve - hypocycloid
        foot % Dedendum circle
        head % Addendum circle

        profile % Total profile of half a tooth
        tooth % Total profile of the entire tooth

        PointedTips % Logical value for pointed teeth
    end

    methods
        function obj = cycloidToothing(modul, polomer_tvoriacej_kruznice_epicykloidy, polomer_tvoriacej_kruznice_hypocykloidy, pocet_zubov, jednotkove_posunutie, kvalita)
            % Constructor - creates an object of the "CycloidToothing" class
            arguments % Validation of function arguments
                modul (1,1) double {mustBeNumeric, mustBePositive}
                polomer_tvoriacej_kruznice_epicykloidy (1,1) double {mustBeNumeric, mustBePositive}
                polomer_tvoriacej_kruznice_hypocykloidy (1,1) double {mustBeNumeric, mustBePositive}
                pocet_zubov (1,1) double {mustBeNumeric, mustBeInteger}
                jednotkove_posunutie (1,1) double {mustBeNumeric}
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
            obj.a_e = polomer_tvoriacej_kruznice_epicykloidy;
            obj.a_h = polomer_tvoriacej_kruznice_hypocykloidy;
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
            obj.R_a = obj.R + obj.h_a;
            obj.R_f = obj.R - obj.h_f;

            % PITCHES
            obj.p = obj.m_n*pi; % Pitch on the pitch circle
            
            % Saving profile curve functions
            obj = curveFuncions(obj);

            % Mathematical description of the tooth profile with exclusion conditions
            if obj.m_n*obj.z == 2*obj.a_h
                warning("Hypocycloid creation is not possible with the given parameters.\n The hypocycloid has been reduced to a point")
                obj.profile = [NaN; NaN];
            elseif obj.a_h > obj.R-obj.h_f/2 || obj.a_h < obj.h_f/2
                warning("Hypocycloid creation is not possible with the given parameters.\n The hypocycloid has no intersection with the dedendum circle.")
                obj.profile = [NaN; NaN];
            else
                obj = toothCycloidProfile(obj);
            end
        end
    end

    methods (Access = private)
        function obj = toothCycloidProfile(obj)
            % Tooth profile generator

            % Function subject to minimization
            function distance = chordLengthFun(t_curve, curveFun) % Calculation of the chord length between points lying on the same circle
                common_radius = curveFun{3}(t_curve);
                tau_tr = fzero(@(par) common_radius - obj.Tr2_R(par), t_tr0);
                distance = sqrt( (obj.Tr2_X(tau_tr) - curveFun{1}(t_curve)).^2 + (obj.Tr2_Y(tau_tr) - curveFun{2}(t_curve)).^2 );
            end

            % DETERMINATION OF THE SECONDARY TROCHOID POINT LYING ON THE ADDENDUM CIRCLE
            % Robust method to prevent searching in the negative numbers domain using the built-in "fzero" function and a transformed function
            t_tr_Ra = fzero(@(par) obj.R_a - obj.Tr2_R(par.^2),0);
            t_tr_Ra = t_tr_Ra^2;

            angle_epi_tip = NaN; % Initialization of the tooth tip angle variable

            % Determining the orientation of the vector between points on the addendum circle of individual curves
            if obj.x < -1
                t_hypo_Ra = obj.Hypo_t(obj.R_a);
                vector_Ra = [obj.Hypo_X(t_hypo_Ra) - obj.Tr2_X(t_tr_Ra), obj.Hypo_Y(t_hypo_Ra) - obj.Tr2_Y(t_tr_Ra)];
            else
                t_epi_Ra = obj.Epi_t(obj.R_a);
                vector_Ra = [obj.Epi_X(t_epi_Ra) - obj.Tr2_X(t_tr_Ra), obj.Epi_Y(t_epi_Ra) - obj.Tr2_Y(t_tr_Ra)];
            end
            orientation_Ra = sign(dot([obj.Tr2_Y(t_tr_Ra), -obj.Tr2_X(t_tr_Ra)],vector_Ra)); % Vector orientation determined via dot product

            if orientation_Ra == 1 % Orientation of the difference vector on the addendum circle in a clockwise direction
                if obj.x > -1 && obj.x < 1+obj.c_koef
                    % DETERMINATION OF THE SECONDARY TROCHOID POINT LYING ON THE PITCH CIRCLE

                    t_tr_R = fzero(@(par) obj.R - obj.Tr2_R(par),[0 t_tr_Ra]);

                    % Determining the orientation of the vector between points on the pitch circle of individual curves
                    vector_R = [obj.Hypo_X(0) - obj.Tr2_X(t_tr_R), obj.Hypo_Y(0) - obj.Tr2_Y(t_tr_R)];
                    orientation_R = sign(dot([obj.Tr2_Y(t_tr_R), -obj.Tr2_X(t_tr_R)],vector_R)); % Vector orientation determined via dot product
                    
                    if obj.x >= 1 + obj.c_koef - obj.rf_koef
                        direction_vector_R = [obj.Tr1_dX(-t_tr_R), obj.Tr1_dY(-t_tr_R)];
                    else
                        direction_vector_R = [obj.Tr1_dX(t_tr_R), obj.Tr1_dY(t_tr_R)];
                    end
                    direction_orientation_R = sign(dot([obj.Tr2_X(t_tr_R), obj.Tr2_Y(t_tr_R)],direction_vector_R)); % Vector orientation determined via dot product

                    % Orientation of the difference vector on the pitch circle in a clockwise direction
                    % OR
                    % Orientation of the secondary trochoid's direction vector on the pitch circle is counterclockwise
                    if orientation_R == 1 && direction_orientation_R == 1
                        % The secondary trochoid intersects with the hypocycloid
                        t_tr0 = [0 t_tr_R];
                        curveFun = {obj.Hypo_X, obj.Hypo_Y, obj.Hypo_R};
                        chordLengthHypo = @(par) chordLengthFun(par, curveFun);
                        t_hypo_intersection = fminbnd(chordLengthHypo,0,obj.Hypo_t(obj.R_f));
                        t_tr_intersection = fzero(@(par) obj.Hypo_R(t_hypo_intersection) - obj.Tr2_R(par), t_tr0);

                        t_hypo = linspace(0, t_hypo_intersection, obj.quality);
                        obj.hypocycloid = [obj.Hypo_X(t_hypo); obj.Hypo_Y(t_hypo)];

                        t_epi_tip = obj.Epi_t(obj.R_a);
                        angle_epi_tip = atan(obj.Epi_X(t_epi_tip)/obj.Epi_Y(t_epi_tip));
                        t_epi = linspace(0, t_epi_tip, obj.quality);
                        obj.epicycloid = [obj.Epi_X(t_epi); obj.Epi_Y(t_epi)];

                    % Orientation of the difference vector on the pitch circle is counterclockwise
                    % OR
                    % Orientation of the secondary trochoid's direction vector on the pitch circle is clockwise
                    elseif orientation_R == -1 || direction_orientation_R == -1
                        % The secondary trochoid intersects with the epicycloid or the addendum circle
                        obj.hypocycloid = [NaN; NaN];

                        t_tr0 = [t_tr_R t_tr_Ra];
                        curveFun = {obj.Epi_X, obj.Epi_Y, obj.Epi_R};
                        chordLengthEpi = @(par) chordLengthFun(par, curveFun);
                        t_epi_intersection = fminbnd(chordLengthEpi,0,obj.Epi_t(obj.R_a));
                        t_tr_intersection = fzero(@(par) obj.Epi_R(t_epi_intersection) - obj.Tr2_R(par), t_tr0);

                        t_epi_tip = obj.Epi_t(obj.R_a);
                        angle_epi_tip = atan(obj.Epi_X(t_epi_tip)/obj.Epi_Y(t_epi_tip));
                        t_epi = linspace(t_epi_intersection, t_epi_tip, obj.quality);
                        obj.epicycloid = [obj.Epi_X(t_epi); obj.Epi_Y(t_epi)];

                    elseif orientation_R == 0 % Exceptional case
                        % The secondary trochoid intersects the profile curve exactly on the pitch circle
                        obj.hypocycloid = [NaN; NaN];

                        t_tr0 = [t_tr_R t_tr_Ra];
                        t_epi_tip = obj.Epi_t(obj.R_a);
                        angle_epi_tip = atan(obj.Epi_X(t_epi_tip)/obj.Epi_Y(t_epi_tip));
                        t_epi = linspace(0, t_epi_tip, obj.quality);
                        obj.epicycloid = [obj.Epi_X(t_epi); obj.Epi_Y(t_epi)];

                    else
                        error("A case occurred that does not meet any defined conditions.")
                    end

                elseif obj.x <= -1
                    obj.epicycloid = [NaN; NaN];

                    t_tr0 = [0 t_tr_Ra];
                    curveFun = {obj.Hypo_X, obj.Hypo_Y, obj.Hypo_R};
                    chordLengthHypo = @(par) chordLengthFun(par, curveFun);
                    t_hypo_intersection = fminbnd(chordLengthHypo,obj.Hypo_t(obj.R_a),obj.Hypo_t(obj.R_f));
                    t_tr_intersection = fzero(@(par) obj.Hypo_R(t_hypo_intersection) - obj.Tr2_R(par), t_tr0);

                    t_hypo = linspace(obj.Hypo_t(obj.R_a), t_hypo_intersection, obj.quality);
                    obj.hypocycloid = [obj.Hypo_X(t_hypo); obj.Hypo_Y(t_hypo)];

                elseif obj.x >= 1+obj.c_koef
                    % The secondary trochoid intersects with the epicycloid or the addendum circle
                    obj.hypocycloid = [NaN; NaN];

                    t_tr0 = [0 t_tr_Ra];
                    curveFun = {obj.Epi_X, obj.Epi_Y, obj.Epi_R};
                    chordLengthEpi = @(par) chordLengthFun(par, curveFun);
                    t_epi_intersection = fminbnd(chordLengthEpi,obj.Epi_t(obj.R_f),obj.Epi_t(obj.R_a));
                    t_tr_intersection = fzero(@(par) obj.Epi_R(t_epi_intersection) - obj.Tr2_R(par), t_tr0);

                    t_epi_tip = obj.Epi_t(obj.R_a);
                    angle_epi_tip = atan(obj.Epi_X(t_epi_tip)/obj.Epi_Y(t_epi_tip));
                    t_epi = linspace(t_epi_intersection, t_epi_tip, obj.quality);
                    obj.epicycloid = [obj.Epi_X(t_epi); obj.Epi_Y(t_epi)];
                else
                    error("A case occurred that does not meet any defined conditions.")
                end

                t_tr = linspace(0,t_tr_intersection, obj.quality);
                obj.trochoid = [obj.Tr2_X(t_tr); obj.Tr2_Y(t_tr)];

            % THE PROFILE CURVE CONSISTS PURELY OF THE SECONDARY TROCHOID
            elseif orientation_Ra == -1 || orientation_Ra == 0 % Orientation of the difference vector on the addendum circle is counterclockwise, or the vector magnitude is zero
                obj.hypocycloid = [NaN; NaN];
                obj.epicycloid = [NaN; NaN];
                t_tr = linspace(0,t_tr_Ra, obj.quality);
                obj.trochoid = [obj.Tr2_X(t_tr); obj.Tr2_Y(t_tr)];

            else
                error("A case occurred that does not meet any defined conditions.")
            end

            
            if isnan(angle_epi_tip) || angle_epi_tip < pi/obj.z
                if ~anynan(obj.epicycloid)
                    tau_a(1) = atan(obj.epicycloid(1,end)/obj.epicycloid(2,end)); tau_a(2) = pi/obj.z;
                elseif anynan(obj.epicycloid) && ~anynan(obj.hypocycloid)
                    tau_a(1) = atan(obj.hypocycloid(1,1)/obj.hypocycloid(2,1)); tau_a(2) = pi/obj.z;
                else
                    tau_a(1) = atan(obj.trochoid(1,end)/obj.trochoid(2,end)); tau_a(2) = pi/obj.z;
                end

                t_a = linspace(tau_a(1), tau_a(2), uint8(obj.quality/4));
                obj.head = [obj.R_a*sin(t_a); obj.R_a*cos(t_a)];
            else
                obj.PointedTips = true;
                obj.head = [NaN; NaN];
                t_epi_tip = fzero(@(par) atan(obj.Epi_X(par)/obj.Epi_Y(par)) - pi/obj.z, t_epi_tip);
                id_epi = find(t_epi >= t_epi_tip,1,"first");
                obj.epicycloid(:,id_epi:end) = [];
                obj.epicycloid(:,end+1) = [obj.Epi_X(t_epi_tip); obj.Epi_Y(t_epi_tip)];
            end

            tau_f(1) = 0; tau_f(2) = atan(obj.trochoid(1,1)/obj.trochoid(2,1));
            t_foot = linspace(tau_f(1),tau_f(2), uint8(obj.quality/4));
            obj.foot = [obj.R_f*sin(t_foot); obj.R_f*cos(t_foot)];

            obj.profile = [obj.foot obj.trochoid fliplr(obj.hypocycloid) obj.epicycloid obj.head];
            obj.profile = rmmissing(obj.profile')'; % Cleaning data from invalid values

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

        function obj = tipCenterFunction(obj)
            % Determining the coordinates of the tooth tip rounding center in the cutting tool's local coordinate system

            % Calculating the y-coordinate of the tooth tip rounding center
            obj.Oa_Y = -obj.h_a0 + obj.r_a0 + obj.X_d;

            % Definition of the profile shift
            if obj.X_d > 0
                par = acos(1-obj.X_d/obj.a_e);
                obj.X_shift = -obj.a_e*(par-sin(par));
            elseif obj.X_d < 0
                par = acos(1+obj.X_d/obj.a_h);
                obj.X_shift = obj.a_h*(par-sin(par));
            else
                obj.X_shift = 0;
            end

            % Calculating the x-coordinate of the tooth tip rounding center
            if obj.X_d < obj.h_a0-obj.r_a0  &&  obj.X_d > -obj.h_f0+obj.r_f0
                % The rack tool tooth profile consists of both cycloids
                tipZeroFunction = @(par) -obj.a_h.*(1-cos(par)) - obj.r_a0.*(cos(par)-1)./sqrt(2*( 1-cos(par) )) + obj.h_a0 - obj.r_a0 - obj.X_d;

                tau_0(1) = acos( (obj.r_a0 - obj.h_a0 + obj.X_d)./obj.a_h + 1 );
                tau_0(2) = acos( (-obj.h_a0 + obj.X_d)./obj.a_h + 1 );

                tau = fzero(tipZeroFunction,tau_0); % Numerical solver to find the zero of the function in the specified interval

                obj.Oa_X = -obj.a_h*(tau-sin(tau)) - obj.r_a0*sin(tau)/sqrt(2*( 1-cos(tau) )) + (1-obj.Cs)*obj.m_n*pi/2 + obj.X_shift;

            elseif obj.X_d <= -obj.h_f0+obj.r_f0
                % The rack tool tooth profile consists only of the addendum cycloid
                tipZeroFunction = @(par) -obj.a_h.*(1-cos(par)) - obj.r_a0.*(cos(par)-1)./sqrt(2*( 1-cos(par) )) + obj.h_a0 - obj.r_a0 - obj.X_d;

                tau_0(1) = acos( (obj.r_a0 - obj.h_a0 + obj.X_d)./obj.a_h + 1 );
                tau_0(2) = acos( (-obj.h_a0 + obj.X_d)./obj.a_h + 1 );

                tau = fzero(tipZeroFunction,tau_0); % Numerical solver to find the zero of the function in the specified interval

                obj.Oa_X = -obj.a_h*(tau-sin(tau)) - obj.r_a0*sin(tau)/sqrt(2*( 1-cos(tau) )) + (1-obj.Cs)*obj.m_n*pi/2 + obj.X_shift;

            elseif obj.X_d >= obj.h_a0-obj.r_a0
                % The rack tool tooth profile consists only of the dedendum cycloid
                if obj.X_d == obj.h_a0-obj.r_a0
                    tau = 0;
                    obj.Oa_X = obj.a_e*(tau-sin(tau)) - obj.r_a0 + (1-obj.Cs)*obj.m_n*pi/2;
                else
                    tipZeroFunction = @(par) obj.a_e.*(1-cos(par)) - obj.r_a0.*(cos(par)-1)./sqrt(2*( 1-cos(par) )) + obj.h_a0 - obj.r_a0 - obj.X_d;
                    if obj.X_d < obj.h_a0
                        tau_0(1) = 1e-6;
                    else
                        tau_0(1) = acos( (obj.h_a0 - obj.X_d)./obj.a_e + 1 );
                    end
                    tau_0(2) = acos( (obj.h_a0 - obj.r_a0 - obj.X_d)./obj.a_e + 1 );
                    tau = fzero(tipZeroFunction,tau_0); % Numerical solver to find the zero of the function in the specified interval

                    obj.Oa_X = obj.a_e*(tau-sin(tau)) - obj.r_a0*sin(tau)/sqrt(2*( 1-cos(tau) )) + (1-obj.Cs)*obj.m_n*pi/2 + obj.X_shift;
                end
            end
        end

        function obj = curveFuncions(obj)
            % Saving necessary functions

            % Determining the coordinates of the tooth tip rounding center in the cutting tool's local coordinate system
            obj = tipCenterFunction(obj);

            % Angular rotation of the epicycloid and hypocycloid [rad]
            obj.psi = asin( (obj.Cs*obj.m_n*pi/2 + obj.X_shift)/obj.R );

            % Function expressing the x-component of the hypocycloid
            obj.Hypo_X = @(par) obj.a_h*sin( (obj.R-obj.a_h)/obj.a_h*par+obj.psi ) - (obj.R-obj.a_h)*sin(par-obj.psi);
            % Function expressing the y-component of the hypocycloid
            obj.Hypo_Y = @(par) obj.a_h*cos( (obj.R-obj.a_h)/obj.a_h*par+obj.psi ) + (obj.R-obj.a_h)*cos(par-obj.psi);

            % Function expressing the x-component of the epicycloid
            obj.Epi_X = @(par) (obj.R+obj.a_e)*sin(par+obj.psi) - obj.a_e*sin( (obj.R+obj.a_e)/obj.a_e*par+obj.psi );
            % Function expressing the y-component of the epicycloid
            obj.Epi_Y = @(par) (obj.R+obj.a_e)*cos(par+obj.psi) - obj.a_e*cos( (obj.R+obj.a_e)/obj.a_e*par+obj.psi );

            % Function expressing the x-component of the primary trochoid
            obj.Tr1_X = @(par) obj.R*par.*cos(par-obj.Oa_X./obj.R) - (obj.Oa_Y+obj.R)*sin(par-obj.Oa_X/obj.R); 
            % Function expressing the y-component of the primary trochoid
            obj.Tr1_Y = @(par) obj.R*par.*sin(par-obj.Oa_X./obj.R) + (obj.Oa_Y+obj.R)*cos(par-obj.Oa_X/obj.R); 
            % Function expressing the derivative of the primary trochoid's x-component with respect to the parameter
            obj.Tr1_dX = @(par) -obj.Oa_Y*cos(par-obj.Oa_X./obj.R) - obj.R*par.*sin(par-obj.Oa_X/obj.R); 
            % Function expressing the derivative of the primary trochoid's y-component with respect to the parameter
            obj.Tr1_dY = @(par) -obj.Oa_Y*sin(par-obj.Oa_X./obj.R) + obj.R*par.*cos(par-obj.Oa_X/obj.R); 

            % Function expressing the x-component of the secondary trochoid
            if obj.x >= 1 + obj.c_koef - obj.rf_koef
                obj.Tr2_X = @(par) obj.Tr1_X(-par) + obj.r_a0*cos(atan2( -obj.Tr1_dX(-par), obj.Tr1_dY(-par) ) + pi); % X-component of the secondary trochoid
                obj.Tr2_Y = @(par) obj.Tr1_Y(-par) + obj.r_a0*sin(atan2( -obj.Tr1_dX(-par), obj.Tr1_dY(-par) ) + pi); % Y-component of the secondary trochoid
            else
                obj.Tr2_X = @(par) obj.Tr1_X(par) + obj.r_a0*cos(atan2( -obj.Tr1_dX(par), obj.Tr1_dY(par) )); % X-component of the secondary trochoid
                obj.Tr2_Y = @(par) obj.Tr1_Y(par) + obj.r_a0*sin(atan2( -obj.Tr1_dX(par), obj.Tr1_dY(par) )); % Y-component of the secondary trochoid
            end

            % Parametric functions for the polar radius of the hypocycloid, epicycloid, and secondary trochoid
            obj.Hypo_R = @(par) sqrt( (obj.R - obj.a_h)^2 + obj.a_h^2 + 2*obj.a_h*(obj.R-obj.a_h)*cos(par*obj.R/obj.a_h) );
            obj.Epi_R = @(par) sqrt( (obj.R + obj.a_e)^2 + obj.a_e^2 - 2*obj.a_e*(obj.R+obj.a_e)*cos(par*obj.R/obj.a_e) );
            obj.Tr2_R = @(par) sqrt( obj.Tr2_X(par).^2 + obj.Tr2_Y(par).^2 );

            % Function for obtaining the hypocycloid and epicycloid parameter from a given polar radius
            obj.Hypo_t = @(rho) obj.a_h/obj.R * acos( (rho.^2 - (obj.R-obj.a_h)^2 - obj.a_h^2)/( 2*obj.a_h*(obj.R-obj.a_h) ) );
            obj.Epi_t = @(rho) obj.a_e/obj.R * acos( (-rho.^2 + (obj.R+obj.a_e)^2 + obj.a_e^2)/( 2*obj.a_e*(obj.R+obj.a_e) ) );
        end
    end
end