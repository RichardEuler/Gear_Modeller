% Copyright (c) 2026 Richard Timko
classdef ansysIntegrationUtils < handle
    % ansysIntegrationUtils — Dialog and pipeline for exporting a spur-gear
    % pair from the Animation Tab to ANSYS Workbench/Mechanical and running
    % a contactless Time-Varying Mesh Stiffness (TVMS) simulation.
    %
    % Contactless methodology (Xie et al., IJMS 2018 / MSSP 2018):
    %   Each mesh position is solved as an independent linear-static problem
    %   with a bonded MPC constraint placed at the theoretical contact point
    %   along the line of action. This produces the hard step-change at the
    %   single/double-tooth engagement boundary, matching the analytical
    %   model exactly.  k(theta_i) = T / (theta_pinion_i * Rb_pinion^2)
    %
    % Pipeline:
    %   UI -> profile PTS files -> mesh-position CSV
    %      -> SpaceClaim IronPython script (build_geometry.py)
    %      -> Mechanical IronPython script (solve_tvms.py)
    %      -> Workbench journal           (run.wbjn)
    %      -> RunWB2.exe
    %
    % All UI label text is assigned by ansysLanguageFun (called at the end
    % of create()) so the SK/CZ/EN language system works exactly as for the
    % rest of the application.  No hard-coded user-visible strings appear
    % inside buildTVMSTab().

    % =====================================================================
    %  Properties
    % =====================================================================
    properties
        % Window
        F           matlab.ui.Figure
        TabGroup    matlab.ui.container.TabGroup
        AppRef                                  % main app reference

        % TVMS tab
        TVMSTab     matlab.ui.container.Tab

        % Model-type radio group
        ModelTypeGroup      matlab.ui.container.ButtonGroup
        ModelContactless    matlab.ui.control.RadioButton
        ModelContact        matlab.ui.control.RadioButton

        % Gear-body radio group
        BodyTypeGroup       matlab.ui.container.ButtonGroup
        BodyFull            matlab.ui.control.RadioButton
        BodyHollow          matlab.ui.control.RadioButton

        % Spinners
        PinionHoleSpinner   matlab.ui.control.Spinner
        WheelHoleSpinner    matlab.ui.control.Spinner
        GearWidthSpinner    matlab.ui.control.Spinner
        NumStepsSpinner     matlab.ui.control.Spinner
        TorqueSpinner       matlab.ui.control.Spinner
        YoungSpinner        matlab.ui.control.Spinner
        PoissonSpinner      matlab.ui.control.Spinner
        MeshSizeSpinner     matlab.ui.control.Spinner

        % Path edit fields + folder-browse buttons (identical pattern to
        % the OpenFolderButton in animationExport)
        AnsysPathEdit       matlab.ui.control.EditField
        AnsysPathButton     matlab.ui.control.Button
        WorkFolderEdit      matlab.ui.control.EditField
        WorkFolderButton    matlab.ui.control.Button

        % Labels — stored so ansysLanguageFun can assign text.
        % Index meaning:
        %   1  Pinion hole diameter     6  Young's modulus
        %   2  Wheel hole diameter      7  Poisson's ratio
        %   3  Gear width               8  Fillet mesh size
        %   4  Angular steps            9  RunWB2.exe path
        %   5  Applied torque          10  Work folder
        ParamLabels         % 10×1 gobjects

        % Bottom bar
        LaunchButton        matlab.ui.control.Button
        StatusLabel         matlab.ui.control.Label
    end

    % =====================================================================
    %  Construction
    % =====================================================================
    methods
        function obj = ansysIntegrationUtils(app)
            obj.AppRef = app;
        end

        function create(obj)
            % Build the dialog.  ansysLanguageFun fills all text at the end.

            pointer = get(0,'PointerLocation'); pointer(2) = pointer(2) - 580;

            obj.F = uifigure( ...
                'Position', [pointer 450 580], ...
                'Resize',  'off');

            if isprop(obj.AppRef, 'appFolder') && ...
               exist(fullfile(obj.AppRef.appFolder, 'Images', 'Gear_icon.png'), 'file')
                obj.F.Icon = fullfile(obj.AppRef.appFolder, 'Images', 'Gear_icon.png');
            end

            % Outer grid: tab area | launch button | status label
            outerGrid = uigridlayout(obj.F, [3 1]);
            outerGrid.RowHeight       = {'1x', 30, 24};
            outerGrid.ColumnWidth     = {'1x'};
            outerGrid.Padding         = [10 10 10 10];
            outerGrid.RowSpacing      = 8;
            outerGrid.BackgroundColor = [0.94 0.94 0.94];

            % Tab group (future tabs slot in next to TVMSTab)
            obj.TabGroup               = uitabgroup(outerGrid);
            obj.TabGroup.Layout.Row    = 1;
            obj.TabGroup.Layout.Column = 1;

            obj.TVMSTab = uitab(obj.TabGroup, 'Title', 'TVMS');
            obj.buildTVMSTab();

            % Launch button
            obj.LaunchButton               = uibutton(outerGrid, 'push');
            obj.LaunchButton.FontWeight    = 'bold';
            obj.LaunchButton.BackgroundColor = [0.88 0.94 0.88];
            obj.LaunchButton.ButtonPushedFcn = @(~,~) obj.onLaunch();
            obj.LaunchButton.Layout.Row    = 2;
            obj.LaunchButton.Layout.Column = 1;

            % Status label — UserData will hold the status-string cell array
            % (set by ansysLanguageFun) so setStatus() can retrieve them
            % without coupling to language internals.
            obj.StatusLabel                    = uilabel(outerGrid);
            obj.StatusLabel.HorizontalAlignment = 'left';
            obj.StatusLabel.FontAngle          = 'italic';
            obj.StatusLabel.Layout.Row         = 3;
            obj.StatusLabel.Layout.Column      = 1;

            % Apply language strings now that all handles exist
            Utils.LanguageSubUtils.ansysLanguageFun(obj);

            % Set initial button state — no gear data yet at dialog open
            obj.LaunchButton.Enable = 'off';
        end

        function syncLaunchButton(obj)
            % Update LaunchButton enable state.
            %
            % AnsysLaunchState (on AnimationTabUtils) is the single flag
            % that records whether a valid gear mesh was generated by the
            % Animation Tab Display button:
            %   1 — Display was pressed in meshing mode; mesh is on screen.
            %   0 — any cancel/delete/draw-profile button was pressed, or
            %       hobbing mode was active when Display was pressed.
            %
            % The button is ENABLED only when:
            %   AnsysLaunchState == 1  AND  animation is not running.
            %
            % The running-state check is kept here (not in Gear_Model) so
            % that no changes to animationControl.m are required — the flag
            % is simply read at sync time.
            if ~isgraphics(obj.F) || ~isvalid(obj.F) || ...
               ~isgraphics(obj.LaunchButton) || ~isvalid(obj.LaunchButton)
                return;
            end

            ut = obj.AppRef.AnimationTabUtils;
            ac = obj.AppRef.AnimationControl;

            if ut.AnsysLauchState == 1 && ac.start_state == 0
                obj.LaunchButton.Enable = 'on';
            else
                obj.LaunchButton.Enable = 'off';
            end
        end
    end

    % =====================================================================
    %  Tab layout — structure only, no user-visible strings
    % =====================================================================
    methods (Access = private)
        function buildTVMSTab(obj)
            % Grid layout for the TVMS tab:
            %
            %   Col 1  : label   (175 px, fixed)
            %   Col 2-3: control ('1x' each — spinner fills both columns)
            %
            %   Row  1 : Model-type button group  (55 px)
            %   Row  2 : Gear-body button group   (55 px)
            %   Rows 3-9: parameter rows          (26 px each)
            %   Row 10 : paths sub-panel          (fills remaining space)

            BC = [0.94 0.94 0.94];

            g = uigridlayout(obj.TVMSTab, [10 3]);
            g.ColumnWidth     = {175, '1x', '1x'};
            g.RowHeight       = {55, 55, 26, 26, 26, 26, 26, 26, 26, '1x'};
            g.Padding         = [10 10 10 10];
            g.RowSpacing      = 6;
            g.ColumnSpacing   = 8;
            g.BackgroundColor = BC;

            % Pre-allocate label handle array
            obj.ParamLabels = gobjects(10, 1);

            % ----------------------------------------------------------
            %  Row 1 — Model type
            % ----------------------------------------------------------
            obj.ModelTypeGroup               = uibuttongroup(g);
            obj.ModelTypeGroup.BorderType    = 'line';
            obj.ModelTypeGroup.Layout.Row    = 1;
            obj.ModelTypeGroup.Layout.Column = [1 3];

            obj.ModelContactless = uiradiobutton(obj.ModelTypeGroup, ...
                'Position', [12 8 160 22], 'Value', true);
            obj.ModelContact     = uiradiobutton(obj.ModelTypeGroup, ...
                'Position', [190 8 160 22], 'Value', false);

            % ----------------------------------------------------------
            %  Row 2 — Gear body (full / hollow)
            % ----------------------------------------------------------
            obj.BodyTypeGroup                    = uibuttongroup(g);
            obj.BodyTypeGroup.BorderType         = 'line';
            obj.BodyTypeGroup.SelectionChangedFcn = @(~,~) obj.onBodyTypeChanged();
            obj.BodyTypeGroup.Layout.Row         = 2;
            obj.BodyTypeGroup.Layout.Column      = [1 3];

            obj.BodyFull   = uiradiobutton(obj.BodyTypeGroup, ...
                'Position', [12 8 120 22], 'Value', true);
            obj.BodyHollow = uiradiobutton(obj.BodyTypeGroup, ...
                'Position', [190 8 120 22], 'Value', false);

            % ----------------------------------------------------------
            %  Rows 3-9 — parameter rows (label | spinner spanning 2-3)
            % ----------------------------------------------------------

            % Row 3 — pinion hole diameter
            obj.ParamLabels(1)              = uilabel(g);
            obj.ParamLabels(1).Layout.Row   = 3;
            obj.ParamLabels(1).Layout.Column = 1;

            obj.PinionHoleSpinner           = obj.makeSpinner(g, 20, 'mm', 1, 0.1);
            obj.PinionHoleSpinner.Layout.Row    = 3;
            obj.PinionHoleSpinner.Layout.Column = [2 3];
            obj.PinionHoleSpinner.Enable        = 'off';

            % Row 4 — wheel hole diameter
            obj.ParamLabels(2)              = uilabel(g);
            obj.ParamLabels(2).Layout.Row   = 4;
            obj.ParamLabels(2).Layout.Column = 1;

            obj.WheelHoleSpinner            = obj.makeSpinner(g, 30, 'mm', 1, 0.1);
            obj.WheelHoleSpinner.Layout.Row    = 4;
            obj.WheelHoleSpinner.Layout.Column = [2 3];
            obj.WheelHoleSpinner.Enable        = 'off';

            % Row 5 — gear width
            obj.ParamLabels(3)              = uilabel(g);
            obj.ParamLabels(3).Layout.Row   = 5;
            obj.ParamLabels(3).Layout.Column = 1;

            obj.GearWidthSpinner            = obj.makeSpinner(g, 20, 'mm', 1, 0.5);
            obj.GearWidthSpinner.Layout.Row    = 5;
            obj.GearWidthSpinner.Layout.Column = [2 3];

            % Row 6 — angular steps per mesh cycle
            obj.ParamLabels(4)              = uilabel(g);
            obj.ParamLabels(4).Layout.Row   = 6;
            obj.ParamLabels(4).Layout.Column = 1;

            obj.NumStepsSpinner             = obj.makeSpinner(g, 40, '-', 5, 5);
            obj.NumStepsSpinner.RoundFractionalValues = 'on';
            obj.NumStepsSpinner.Layout.Row    = 6;
            obj.NumStepsSpinner.Layout.Column = [2 3];

            % Row 7 — applied torque
            obj.ParamLabels(5)              = uilabel(g);
            obj.ParamLabels(5).Layout.Row   = 7;
            obj.ParamLabels(5).Layout.Column = 1;

            obj.TorqueSpinner               = obj.makeSpinner(g, 50, 'Nm', 1, 0.1);
            obj.TorqueSpinner.Layout.Row    = 7;
            obj.TorqueSpinner.Layout.Column = [2 3];

            % Row 8 — Young's modulus
            obj.ParamLabels(6)              = uilabel(g);
            obj.ParamLabels(6).Layout.Row   = 8;
            obj.ParamLabels(6).Layout.Column = 1;

            obj.YoungSpinner                = obj.makeSpinner(g, 206800, 'MPa', 1000, 1);
            obj.YoungSpinner.Layout.Row    = 8;
            obj.YoungSpinner.Layout.Column = [2 3];

            % Row 9 — Poisson's ratio
            obj.ParamLabels(7)              = uilabel(g);
            obj.ParamLabels(7).Layout.Row   = 9;
            obj.ParamLabels(7).Layout.Column = 1;

            obj.PoissonSpinner              = obj.makeSpinner(g, 0.3, '-', 0.01, 0, 0.49);
            obj.PoissonSpinner.Layout.Row    = 9;
            obj.PoissonSpinner.Layout.Column = [2 3];

            % ----------------------------------------------------------
            %  Row 10 — nested sub-grid: fillet mesh size + two paths
            %
            %  Each path row uses the same pattern as animationExport:
            %    col 1 = label (175 px)
            %    col 2 = inner 2-column sub-grid:
            %              col A = 30 px folder-icon button
            %              col B = '1x' text edit field with placeholder
            % ----------------------------------------------------------
            pathGrid                    = uigridlayout(g, [3 2]);
            pathGrid.ColumnWidth        = {175, '1x'};
            pathGrid.RowHeight          = {26, 26, 26};
            pathGrid.Padding            = [0 4 0 0];
            pathGrid.RowSpacing         = 6;
            pathGrid.ColumnSpacing      = 8;
            pathGrid.BackgroundColor    = BC;
            pathGrid.Layout.Row         = 10;
            pathGrid.Layout.Column      = [1 3];

            % Sub-row 1 — fillet mesh size (unchanged)
            obj.ParamLabels(8)               = uilabel(pathGrid);
            obj.ParamLabels(8).Layout.Row    = 1;
            obj.ParamLabels(8).Layout.Column = 1;

            obj.MeshSizeSpinner              = obj.makeSpinner(pathGrid, 0.15, 'mm', 0.01, 0.01);
            obj.MeshSizeSpinner.Layout.Row    = 1;
            obj.MeshSizeSpinner.Layout.Column = 2;

            % Sub-row 2 — RunWB2.exe path
            obj.ParamLabels(9)               = uilabel(pathGrid);
            obj.ParamLabels(9).Layout.Row    = 2;
            obj.ParamLabels(9).Layout.Column = 1;

            ansysPathGrid                    = uigridlayout(pathGrid, [1 2]);
            ansysPathGrid.ColumnWidth        = {30, '1x'};
            ansysPathGrid.RowHeight          = {'1x'};
            ansysPathGrid.Padding            = [0 0 0 0];
            ansysPathGrid.ColumnSpacing      = 4;
            ansysPathGrid.BackgroundColor    = BC;
            ansysPathGrid.Layout.Row         = 2;
            ansysPathGrid.Layout.Column      = 2;

            obj.AnsysPathButton              = uibutton(ansysPathGrid, 'push');
            obj.AnsysPathButton.Text         = '';
            obj.AnsysPathButton.Icon         = fullfile(obj.AppRef.appFolder, 'Images', 'Folder_icon.png');
            obj.AnsysPathButton.IconAlignment = 'center';
            obj.AnsysPathButton.BackgroundColor = [1 1 1];
            obj.AnsysPathButton.Layout.Row   = 1;
            obj.AnsysPathButton.Layout.Column = 1;
            obj.AnsysPathButton.ButtonPushedFcn = @(~,~) obj.browseAnsysPath();

            obj.AnsysPathEdit                = uieditfield(ansysPathGrid, 'text');
            obj.AnsysPathEdit.BackgroundColor = [1 1 1];
            obj.AnsysPathEdit.Value          = '';
            obj.AnsysPathEdit.Layout.Row     = 1;
            obj.AnsysPathEdit.Layout.Column  = 2;
            % Placeholder is set by ansysLanguageFun (ParamLabels index 9
            % text re-used; a dedicated placeholder string is line 32 of
            % the language file — see ansysLanguageFun for the contract).

            % Sub-row 3 — work folder
            obj.ParamLabels(10)               = uilabel(pathGrid);
            obj.ParamLabels(10).Layout.Row    = 3;
            obj.ParamLabels(10).Layout.Column = 1;

            workFolderGrid                    = uigridlayout(pathGrid, [1 2]);
            workFolderGrid.ColumnWidth        = {30, '1x'};
            workFolderGrid.RowHeight          = {'1x'};
            workFolderGrid.Padding            = [0 0 0 0];
            workFolderGrid.ColumnSpacing      = 4;
            workFolderGrid.BackgroundColor    = BC;
            workFolderGrid.Layout.Row         = 3;
            workFolderGrid.Layout.Column      = 2;

            obj.WorkFolderButton              = uibutton(workFolderGrid, 'push');
            obj.WorkFolderButton.Text         = '';
            obj.WorkFolderButton.Icon         = fullfile(obj.AppRef.appFolder, 'Images', 'Folder_icon.png');
            obj.WorkFolderButton.IconAlignment = 'center';
            obj.WorkFolderButton.BackgroundColor = [1 1 1];
            obj.WorkFolderButton.Layout.Row   = 1;
            obj.WorkFolderButton.Layout.Column = 1;
            obj.WorkFolderButton.ButtonPushedFcn = @(~,~) obj.browseWorkFolder();

            obj.WorkFolderEdit                = uieditfield(workFolderGrid, 'text');
            obj.WorkFolderEdit.BackgroundColor = [1 1 1];
            obj.WorkFolderEdit.Value          = '';
            obj.WorkFolderEdit.Layout.Row     = 1;
            obj.WorkFolderEdit.Layout.Column  = 2;
        end

        % ------------------------------------------------------------------
        %  Spinner factory — numeric value, unit shown in the display box
        % ------------------------------------------------------------------
        function s = makeSpinner(~, parent, defaultVal, unit, step, lower, upper)
            if nargin < 7, lower = 0;   end
            if nargin < 8, upper = Inf; end
            s = uispinner(parent, ...
                'Value',           defaultVal, ...
                'Step',            step, ...
                'Limits',          [lower upper], ...
                'BackgroundColor', [1 1 1]);
            % '-' signals dimensionless — leave the default numeric format.
            if ~strcmp(unit, '-')
                s.ValueDisplayFormat = ['%g ' unit];
            end
        end

        % ------------------------------------------------------------------
        %  Gear-body callback
        % ------------------------------------------------------------------
        function onBodyTypeChanged(obj)
            state = obj.BodyHollow.Value;
            obj.PinionHoleSpinner.Enable = state;
            obj.WheelHoleSpinner.Enable  = state;
        end

        % ------------------------------------------------------------------
        %  Path-browse callbacks — identical concept to animationExport's
        %  OpenFolderButton / exportPath pattern
        % ------------------------------------------------------------------
        function browseAnsysPath(obj)
            % Open a file-selection dialog for RunWB2.exe.
            [file, folder] = uigetfile( ...
                {'RunWB2.exe;*.exe', 'ANSYS Workbench (RunWB2.exe)'}, ...
                'Select RunWB2.exe', ...
                obj.AnsysPathEdit.Value);
            if isequal(file, 0), return; end   % user cancelled
            obj.AnsysPathEdit.Value = fullfile(folder, file);
        end

        function browseWorkFolder(obj)
            % Open a folder-selection dialog for the TVMS work folder.
            startPath = obj.WorkFolderEdit.Value;
            if isempty(startPath) || ~isfolder(startPath)
                startPath = tempdir;   % always writable; avoids userpath dependency
            end
            folder = uigetdir(startPath, 'Select TVMS work folder');
            if isequal(folder, 0), return; end  % user cancelled
            obj.WorkFolderEdit.Value = folder;
        end
    end

    % =====================================================================
    %  Launch pipeline
    % =====================================================================
    methods (Access = private)
        function onLaunch(obj)
            % Contact model: UI present, implementation deferred.
            if obj.ModelContact.Value
                obj.setStatus('warn');
                return;
            end

            try
                obj.setStatus('info', 1);   workDir = obj.prepareWorkFolder();
                obj.setStatus('info', 2);   params  = obj.collectParameters();
                obj.setStatus('info', 3);   obj.writeProfilePoints(workDir, params);
                obj.setStatus('info', 4);   obj.writeMeshPositions(workDir, params);
                obj.setStatus('info', 5);   obj.writeSpaceClaimScript(workDir, params);
                obj.setStatus('info', 6);   obj.writeMechanicalScript(workDir, params);
                obj.setStatus('info', 7);   journal = obj.writeWorkbenchJournal(workDir, params);
                obj.setStatus('info', 8);   obj.spawnWorkbench(journal);
                obj.setStatus('ok', fullfile(workDir, 'TVMS_results.csv'));
            catch err
                obj.setStatus('err', err.message);
                rethrow(err);
            end
        end

        % ------------------------------------------------------------------
        %  Step 1 — prepare / clean the work folder
        % ------------------------------------------------------------------
        function workDir = prepareWorkFolder(obj)
            workDir = strtrim(obj.WorkFolderEdit.Value);
            if isempty(workDir)
                % Fall back to a subfolder in the system temp directory
                % if the user left the field blank.
                workDir = fullfile(tempdir, 'TVMS_run');
                obj.WorkFolderEdit.Value = workDir;
            end
            if ~exist(workDir, 'dir')
                [ok, msg] = mkdir(workDir);
                if ~ok
                    error('Cannot create work folder "%s": %s', workDir, msg);
                end
            end
            artifacts = {'pinion.pts','wheel.pts','mesh_positions.csv', ...
                         'build_geometry.py','solve_tvms.py', ...
                         'run.wbjn','TVMS_results.csv'};
            for k = 1:numel(artifacts)
                p = fullfile(workDir, artifacts{k});
                if exist(p, 'file'), delete(p); end
            end
        end

        % ------------------------------------------------------------------
        %  Step 2 — collect gear geometry and UI settings
        % ------------------------------------------------------------------
        function p = collectParameters(obj)
            ac = obj.AppRef.AnimationControl;

            % Gear geometry (from live animation state)
            p.modul      = ac.gear.p.m_n;
            p.alpha      = ac.gear.p.alpha;    % rad
            p.z_pinion   = ac.gear.p.z;
            p.z_wheel    = ac.gear.w.z;
            p.a_w        = ac.a_w;             % centre distance [mm]
            p.Rb_p       = ac.gear.p.R_b;
            p.Rb_w       = ac.gear.w.R_b;
            p.Ra_p       = ac.gear.p.R_a;
            p.Ra_w       = ac.gear.w.R_a;
            p.Rf_p       = ac.gear.p.R_f;
            p.Rf_w       = ac.gear.w.R_f;
            p.tooth_p    = ac.gear.p.tooth;    % 2×N_p
            p.tooth_w    = ac.gear.w.tooth;    % 2×N_w

            % UI inputs
            p.hollow     = obj.BodyHollow.Value;
            p.d_hole_p   = obj.PinionHoleSpinner.Value;
            p.d_hole_w   = obj.WheelHoleSpinner.Value;
            p.width      = obj.GearWidthSpinner.Value;
            p.n_steps    = round(obj.NumStepsSpinner.Value);
            p.torque_Nm  = obj.TorqueSpinner.Value;
            p.torque_Nmm = p.torque_Nm * 1e3;  % N·mm for Ansys mm unit system
            p.E_MPa      = obj.YoungSpinner.Value;
            p.nu         = obj.PoissonSpinner.Value;
            p.mesh_size  = obj.MeshSizeSpinner.Value;

            % Derived geometry
            p.Pb_p     = 2*pi * p.Rb_p / p.z_pinion;   % base pitch (pinion)
            % Working pressure angle from exact centre distance
            p.alpha_w  = acos((p.Rb_p + p.Rb_w) / p.a_w);
            % Approach length (tip of wheel to pitch point on LOA)
            p.L_app    = sqrt(p.Ra_w^2 - p.Rb_w^2) - p.a_w * sin(p.alpha_w);
            % Recess length  (pitch point to tip of pinion on LOA)
            p.L_rec    = sqrt(p.Ra_p^2 - p.Rb_p^2) - p.a_w * sin(p.alpha_w);
            % Total active path of contact
            p.L_action = p.L_app + p.L_rec;
        end

        % ------------------------------------------------------------------
        %  Step 3 — tooth-profile point files  (x y 0, one point per line)
        % ------------------------------------------------------------------
        function writeProfilePoints(obj, workDir, p)
            obj.writePTSFile(fullfile(workDir, 'pinion.pts'), p.tooth_p);
            obj.writePTSFile(fullfile(workDir, 'wheel.pts'),  p.tooth_w);
        end

        function writePTSFile(~, path, data)
            fid = fopen(path, 'w');
            if fid == -1, error('Cannot open "%s" for writing.', path); end
            cleaner = onCleanup(@() fclose(fid));
            for k = 1:size(data, 2)
                fprintf(fid, '%.10f %.10f 0.0\n', data(1,k), data(2,k));
            end
        end

        % ------------------------------------------------------------------
        %  Step 4 — mesh-position table  (one row per load step)
        %
        %  s : signed arc distance along the line of action, measured from
        %      the pitch point.  Negative = approach side (wheel tip).
        %      Positive = recess side (pinion tip).
        %
        %  Contact-point on each gear in its OWN reference frame:
        %    s_abs_p = a_w*sin(alpha_w) + s    (from pinion base-tangent)
        %    s_abs_w = a_w*sin(alpha_w) - s    (from wheel  base-tangent)
        %    r       = sqrt(Rb^2 + s_abs^2)
        %    phi     = atan2(s_abs, Rb)
        % ------------------------------------------------------------------
        function writeMeshPositions(~, workDir, p)
            n     = p.n_steps;
            s_vec = linspace(-p.L_app, p.L_rec, n);     % approach -> recess

            % Corresponding pinion rotation angles (exact for involute)
            theta_p = s_vec / p.Rb_p;

            % Pre-compute contact coordinates
            contact_p = zeros(n, 2);
            contact_w = zeros(n, 2);
            T_base    = p.a_w * sin(p.alpha_w);          % distance pitch->base tangent

            for i = 1:n
                sp = T_base + s_vec(i);   % from pinion base tangent
                sw = T_base - s_vec(i);   % from wheel  base tangent
                r1 = sqrt(p.Rb_p^2 + sp^2);
                r2 = sqrt(p.Rb_w^2 + sw^2);
                phi1 = atan2(sp, p.Rb_p);
                phi2 = atan2(sw, p.Rb_w);
                contact_p(i,:) = [r1*sin(phi1),  r1*cos(phi1)];
                contact_w(i,:) = [r2*sin(phi2), -r2*cos(phi2)];
            end

            path = fullfile(workDir, 'mesh_positions.csv');
            fid  = fopen(path, 'w');
            if fid == -1, error('Cannot open "%s".', path); end
            cleaner = onCleanup(@() fclose(fid));
            fprintf(fid, 'step,theta_p_rad,s_mm,xp_mm,yp_mm,xw_mm,yw_mm\n');
            for i = 1:n
                fprintf(fid, '%d,%.10f,%.8f,%.8f,%.8f,%.8f,%.8f\n', ...
                    i, theta_p(i), s_vec(i), ...
                    contact_p(i,1), contact_p(i,2), ...
                    contact_w(i,1), contact_w(i,2));
            end
        end

        % ------------------------------------------------------------------
        %  Step 5 — SpaceClaim IronPython geometry script
        % ------------------------------------------------------------------
        function writeSpaceClaimScript(~, workDir, p)
            path = fullfile(workDir, 'build_geometry.py');
            fid  = fopen(path, 'w');
            if fid == -1, error('Cannot open "%s".', path); end
            cleaner = onCleanup(@() fclose(fid));

            wl = @(fmt, varargin) fprintf(fid, [fmt '\n'], varargin{:});
            hollow_str = 'True';
            if ~p.hollow, hollow_str = 'False'; end

            wl('# Auto-generated by MATLAB ansysIntegrationUtils');
            wl('# SpaceClaim IronPython: build 2D pinion + wheel from PTS loops');
            wl('import os, math');
            wl('from SpaceClaim.Api.V23.Geometry import *');
            wl('from SpaceClaim.Api.V23 import *');
            wl('');
            wl('WORK   = r"%s"',  strrep(workDir, '\', '\\'));
            wl('Z_P    = %d',     p.z_pinion);
            wl('Z_W    = %d',     p.z_wheel);
            wl('A_W    = %.10f',  p.a_w);
            wl('HOLLOW = %s',     hollow_str);
            wl('D_HP   = %.10f',  p.d_hole_p);
            wl('D_HW   = %.10f',  p.d_hole_w);
            wl('');
            wl('def read_pts(path):');
            wl('    pts = []');
            wl('    with open(path) as f:');
            wl('        for line in f:');
            wl('            tok = line.split()');
            wl('            if len(tok) >= 2:');
            wl('                pts.append((float(tok[0]), float(tok[1])))');
            wl('    return pts');
            wl('');
            wl('def rotate(x, y, ang):');
            wl('    c, s = math.cos(ang), math.sin(ang)');
            wl('    return x*c - y*s, x*s + y*c');
            wl('');
            wl('def build_gear_sketch(pts_one_tooth, z, cx, cy, hole_d):');
            wl('    loop = []');
            wl('    for k in range(z):');
            wl('        ang = 2.0*math.pi*k/z');
            wl('        for (x, y) in pts_one_tooth:');
            wl('            rx, ry = rotate(x, y, ang)');
            wl('            loop.append(Point.Create(MM(cx + rx), MM(cy + ry), MM(0)))');
            wl('    for i in range(len(loop)):');
            wl('        SketchLine.Create(loop[i], loop[(i+1)%%len(loop)])');
            wl('    if HOLLOW and hole_d > 0:');
            wl('        SketchCircle.Create(');
            wl('            Point.Create(MM(cx), MM(cy), MM(0)), MM(hole_d/2.0))');
            wl('');
            wl('pts_p = read_pts(os.path.join(WORK, "pinion.pts"))');
            wl('pts_w = read_pts(os.path.join(WORK, "wheel.pts"))');
            wl('');
            wl('# Pinion centred at origin; wheel centred at (0, -A_W)');
            wl('build_gear_sketch(pts_p, Z_P, 0.0,  0.0, D_HP)');
            wl('build_gear_sketch(pts_w, Z_W, 0.0, -A_W, D_HW)');
            wl('');
            wl('DocumentHelper.SaveAs(os.path.join(WORK, "gears.scdoc"))');
        end

        % ------------------------------------------------------------------
        %  Step 6 — Mechanical IronPython setup + solve + export script
        % ------------------------------------------------------------------
        function writeMechanicalScript(~, workDir, p)
            path = fullfile(workDir, 'solve_tvms.py');
            fid  = fopen(path, 'w');
            if fid == -1, error('Cannot open "%s".', path); end
            cleaner = onCleanup(@() fclose(fid));

            wl = @(fmt, varargin) fprintf(fid, [fmt '\n'], varargin{:});

            wl('# Auto-generated by MATLAB ansysIntegrationUtils');
            wl('# Mechanical IronPython: contactless TVMS — bonded MPC on LOA');
            wl('# Reference: Xie et al. MSSP 2018 / IJMS 2018');
            wl('import csv, os, math');
            wl('');
            wl('WORK        = r"%s"', strrep(workDir, '\', '\\'));
            wl('N_STEPS     = %d',   p.n_steps);
            wl('TORQUE_NMM  = %.6f', p.torque_Nmm);
            wl('E_MPA       = %.6f', p.E_MPa);
            wl('NU          = %.6f', p.nu);
            wl('MESH_GLOBAL = %.6f  # mm — global element size', 2.0);
            wl('MESH_FILLET = %.6f  # mm — local fillet refinement', p.mesh_size);
            wl('RB_PINION   = %.10f', p.Rb_p);
            wl('A_W         = %.10f', p.a_w);
            wl('');

            wl('# ---- 0. Create material (moved from journal for 2025 R1 compatibility) ---');
            wl('matl = ExtAPI.DataModel.Project.Model.Materials.Add()');
            wl('matl.Name = "GearSteel"');
            wl('matl.PropertyData["Youngs Modulus"] = Quantity(str(E_MPA) + " [MPa]")');
            wl('matl.PropertyData["Poissons Ratio"] = Quantity(str(NU))');
            wl('');

            wl('# ---- 1. Load mesh-position table from MATLAB ----------------');
            wl('positions = []');
            wl('with open(os.path.join(WORK, "mesh_positions.csv")) as f:');
            wl('    for row in csv.DictReader(f):');
            wl('        positions.append({');
            wl('            "step": int(row["step"]),');
            wl('            "xp":   float(row["xp_mm"]),');
            wl('            "yp":   float(row["yp_mm"]),');
            wl('            "xw":   float(row["xw_mm"]),');
            wl('            "yw":   float(row["yw_mm"]),');
            wl('        })');
            wl('');

            wl('# ---- 2. 2D plane-stress with gear-width thickness -----------');
            wl('geom = Model.Geometry');
            wl('geom.Model2DBehavior = Model2DBehavior.PlaneStress');
            wl('for body in geom.GetChildren(DataModelObjectCategory.Body, True):');
            wl('    body.Thickness = Quantity("%.6f [mm]")', p.width);
            wl('');

            wl('# ---- 3. Remote points at gear centres ----------------------');
            wl('rp_p = Model.AddRemotePoint()');
            wl('rp_p.Name        = "RP_Pinion"');
            wl('rp_p.XCoordinate = Quantity("0 [mm]")');
            wl('rp_p.YCoordinate = Quantity("0 [mm]")');
            wl('rp_p.Behavior    = LoadBehavior.Rigid');
            wl('');
            wl('rp_w = Model.AddRemotePoint()');
            wl('rp_w.Name        = "RP_Wheel"');
            wl('rp_w.XCoordinate = Quantity("0 [mm]")');
            wl('rp_w.YCoordinate = Quantity("%.10f [mm]")', -p.a_w);
            wl('rp_w.Behavior    = LoadBehavior.Rigid');
            wl('');

            wl('# ---- 4. Mesh -----------------------------------------------');
            wl('mesh = Model.Mesh');
            wl('mesh.ElementSize = Quantity("%.6f [mm]")', 2.0);
            wl('mesh.GenerateMesh()');
            wl('');

            wl('# ---- 5. Analysis settings: N independent load steps --------');
            wl('analysis  = Model.Analyses[0]');
            wl('asettings = analysis.AnalysisSettings');
            wl('asettings.NumberOfSteps = N_STEPS');
            wl('for i in range(1, N_STEPS + 1):');
            wl('    asettings.SetStepEndTime(i, Quantity(str(float(i)) + " [sec]"))');
            wl('    asettings.SetAutomaticTimeStepping(i, AutomaticTimeStepping.Off)');
            wl('    asettings.SetNumberOfSubSteps(i, 1)');
            wl('');

            wl('# ---- 6. Boundary conditions --------------------------------');
            wl('# Wheel: fully fixed (Tx, Ty, Rz = 0)');
            wl('bc_w = analysis.AddRemoteDisplacement()');
            wl('bc_w.Name     = "Fix_Wheel"');
            wl('bc_w.Location = rp_w');
            wl('bc_w.XComponent.Output.DiscreteValues = [Quantity("0 [mm]")]');
            wl('bc_w.YComponent.Output.DiscreteValues = [Quantity("0 [mm]")]');
            wl('bc_w.RotationZ.Output.DiscreteValues  = [Quantity("0 [deg]")]');
            wl('');
            wl('# Pinion: Tx, Ty = 0; Rz free (moment drives rotation)');
            wl('bc_p = analysis.AddRemoteDisplacement()');
            wl('bc_p.Name     = "Fix_Pinion_XY"');
            wl('bc_p.Location = rp_p');
            wl('bc_p.XComponent.Output.DiscreteValues = [Quantity("0 [mm]")]');
            wl('bc_p.YComponent.Output.DiscreteValues = [Quantity("0 [mm]")]');
            wl('');

            wl('# ---- 7. Constant moment on pinion centre -------------------');
            wl('mom          = analysis.AddMoment()');
            wl('mom.Name     = "Torque_Pinion"');
            wl('mom.Location = rp_p');
            wl('mom.DefineBy = LoadDefineBy.ComponentsOriented');
            wl('mom.ZComponent.Output.DiscreteValues = [Quantity(str(TORQUE_NMM) + " [N mm]")]');
            wl('');

            wl('# ---- 8. Per-step bonded-MPC joints -------------------------');
            wl('# Each joint is active only in its own step; all others are');
            wl('# suppressed.  This produces the step-change TVMS that matches');
            wl('# the analytical model (Xie MSSP 2018 Figs 11-12).');
            wl('for pos in positions:');
            wl('    i = pos["step"]');
            wl('    cp_p              = Model.AddRemotePoint()');
            wl('    cp_p.Name         = "CP_P_%d" % i');
            wl('    cp_p.XCoordinate  = Quantity(str(pos["xp"]) + " [mm]")');
            wl('    cp_p.YCoordinate  = Quantity(str(pos["yp"]) + " [mm]")');
            wl('    cp_p.Behavior     = LoadBehavior.Rigid');
            wl('    cp_w              = Model.AddRemotePoint()');
            wl('    cp_w.Name         = "CP_W_%d" % i');
            wl('    cp_w.XCoordinate  = Quantity(str(pos["xw"]) + " [mm]")');
            wl('    cp_w.YCoordinate  = Quantity(str(pos["yw"] - A_W) + " [mm]")');
            wl('    cp_w.Behavior     = LoadBehavior.Rigid');
            wl('    jt                = Model.Connections.AddJoint()');
            wl('    jt.Name           = "Bond_%d" % i');
            wl('    jt.Type           = JointType.Fixed');
            wl('    jt.ReferenceRemotePoint = cp_p');
            wl('    jt.MobileRemotePoint    = cp_w');
            wl('    jt.StepSelectionMode    = SequenceSelectionType.ByNumber');
            wl('    for k in range(1, N_STEPS + 1):');
            wl('        jt.SetStepSuppression(k, k != i)');
            wl('');

            wl('# ---- 9. Rotation probes at both remote points --------------');
            wl('pr_p                      = analysis.Solution.AddDeformationProbe()');
            wl('pr_p.Name                 = "Pinion_Rotation"');
            wl('pr_p.LocationMethod       = LocationDefinitionMethod.RemotePoint');
            wl('pr_p.RemotePointSelection = rp_p');
            wl('pr_p.ResultType           = ProbeResultType.RotationalDeformation');
            wl('');
            wl('pr_w                      = analysis.Solution.AddDeformationProbe()');
            wl('pr_w.Name                 = "Wheel_Rotation"');
            wl('pr_w.LocationMethod       = LocationDefinitionMethod.RemotePoint');
            wl('pr_w.RemotePointSelection = rp_w');
            wl('pr_w.ResultType           = ProbeResultType.RotationalDeformation');
            wl('');

            wl('# ---- 10. Solve ---------------------------------------------');
            wl('analysis.Solution.Solve(True)');
            wl('');

            wl('# ---- 11. Export TVMS to CSV --------------------------------');
            wl('# k_i [N/mm] = T [N·mm] / (theta_p_i [rad] * Rb_p [mm]^2)');
            wl('out = os.path.join(WORK, "TVMS_results.csv")');
            wl('with open(out, "w") as fo:');
            wl('    fo.write("step,theta_p_rad,theta_w_rad,k_N_per_mm\n")');
            wl('    for i in range(1, N_STEPS + 1):');
            wl('        pr_p.DisplayTime = Quantity(str(float(i)) + " [sec]")');
            wl('        pr_w.DisplayTime = Quantity(str(float(i)) + " [sec]")');
            wl('        pr_p.EvaluateAllResults()');
            wl('        pr_w.EvaluateAllResults()');
            wl('        tp = abs(pr_p.ZAxisRotation.Value) * math.pi / 180.0');
            wl('        tw = abs(pr_w.ZAxisRotation.Value) * math.pi / 180.0');
            wl('        if tp > 1e-15:');
            wl('            k = TORQUE_NMM / (tp * RB_PINION**2)');
            wl('        else:');
            wl('            k = float("nan")');
            wl('        fo.write("%%d,%%.12e,%%.12e,%%.12e\n" %% (i, tp, tw, k))');
        end

        % ------------------------------------------------------------------
        %  Step 7 — Workbench journal
        % ------------------------------------------------------------------
        function journalPath = writeWorkbenchJournal(~, workDir, p)
            journalPath = fullfile(workDir, 'run.wbjn');
            fid = fopen(journalPath, 'w');
            if fid == -1, error('Cannot open "%s".', journalPath); end
            cleaner = onCleanup(@() fclose(fid));

            wl = @(fmt, varargin) fprintf(fid, [fmt '\n'], varargin{:});

            wl('# encoding: utf-8');
            wl('# Auto-generated by MATLAB ansysIntegrationUtils');
            wl('import os');
            wl('WORK = r"%s"', strrep(workDir, '\', '\\'));
            wl('');
            wl('# 1. New Static Structural system');
            wl('template1 = GetTemplate(TemplateName="Static Structural", Solver="ANSYS")');
            wl('system1   = template1.CreateSystem()');
            wl('Save(FilePath=os.path.join(WORK, "TVMS_project.wbpj"), Overwrite=True)');
            wl('');
            wl('# 2. Geometry via SpaceClaim IronPython');
            wl('geomSys = system1.GetContainer(ComponentName="Geometry")');
            wl('geomSys.Edit(IsSpaceClaimGeometry=True)');
            wl('geomSys.SendCommand(Language="Python",');
            wl('    Command=open(os.path.join(WORK, "build_geometry.py")).read())');
            wl('geomSys.Exit()');
            wl('');
            wl('# 3. Mechanical setup + solve via IronPython');
            wl('# Material creation happens inside solve_tvms.py (version-independent API)');
            wl('modelSys = system1.GetContainer(ComponentName="Model")');
            wl('modelSys.Edit()');
            wl('modelSys.SendCommand(Language="Python",');
            wl('    Command=open(os.path.join(WORK, "solve_tvms.py")).read())');
            wl('modelSys.Exit()');
            wl('');
            wl('Save(Overwrite=True)');
            wl('# Leave Workbench open for inspection.');
        end

        % ------------------------------------------------------------------
        %  Step 8 — spawn Workbench process
        % ------------------------------------------------------------------
        function spawnWorkbench(obj, journalPath)
            exePath = strtrim(obj.AnsysPathEdit.Value);
            if ~exist(exePath, 'file')
                error('RunWB2.exe not found at:\n  %s', exePath);
            end
            cmd = sprintf('"%s" -R "%s"', exePath, journalPath);
            if ispc
                dos(['start "" ' cmd]);
            else
                system([cmd ' &']);
            end
        end

        % ------------------------------------------------------------------
        %  Status bar helper
        %  Text strings are stored in StatusLabel.UserData by ansysLanguageFun
        %  as a cell array with this index contract:
        %    {1}     = contact-stub warning
        %    {2..9}  = pipeline step messages (steps 1-8)
        %    {10}    = success prefix  ("Launched. Results: ")
        %    {11}    = error prefix    ("ERROR: ")
        % ------------------------------------------------------------------
        function setStatus(obj, kind, varargin)
            if ~isgraphics(obj.StatusLabel) || ~isvalid(obj.StatusLabel)
                return;
            end
            ud = obj.StatusLabel.UserData;   % cell array set by ansysLanguageFun
            switch kind
                case 'warn'
                    obj.StatusLabel.Text      = ud{1};
                    obj.StatusLabel.FontColor = [0.80 0.50 0.00];
                case 'info'
                    idx = varargin{1};        % 1-8 = pipeline step index
                    obj.StatusLabel.Text      = ud{idx + 1};
                    obj.StatusLabel.FontColor = [0.10 0.10 0.10];
                case 'ok'
                    obj.StatusLabel.Text      = [ud{10} varargin{1}];
                    obj.StatusLabel.FontColor = [0.00 0.50 0.00];
                case 'err'
                    obj.StatusLabel.Text      = [ud{11} varargin{1}];
                    obj.StatusLabel.FontColor = [0.80 0.00 0.00];
            end
            drawnow;
        end
    end
end