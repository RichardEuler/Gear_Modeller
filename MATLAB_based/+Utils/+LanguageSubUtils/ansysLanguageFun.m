% Copyright (c) 2026 Richard Timko
function ansysLanguageFun(dlg)
    % ansysLanguageFun — Assign text from the ANSYS-dialog language file to
    % every label, button, and group title inside ansysIntegrationUtils.
    %
    % Called once at the end of ansysIntegrationUtils.create() and again
    % whenever the user changes the application language.
    %
    % Usage:
    %   ansysLanguageFun(dlg)          % dlg = ansysIntegrationUtils handle
    %
    % The language file is:
    %   Text/<Language>/<PREFIX>_ansys_integration.txt
    %
    % Line order in the text file (one string per line):
    %
    %   Line  1  — Dialog window title   (F.Name)
    %   Line  2  — TVMS tab title        (TVMSTab.Title)
    %   Line  3  — ModelTypeGroup title  (button group)
    %   Line  4  — ModelContactless text
    %   Line  5  — ModelContact text
    %   Line  6  — BodyTypeGroup title
    %   Line  7  — BodyFull text
    %   Line  8  — BodyHollow text
    %   Line  9  — ParamLabels(1)  Pinion hole diameter
    %   Line 10  — ParamLabels(2)  Wheel hole diameter
    %   Line 11  — ParamLabels(3)  Gear width
    %   Line 12  — ParamLabels(4)  Angular steps
    %   Line 13  — ParamLabels(5)  Applied torque
    %   Line 14  — ParamLabels(6)  Young's modulus
    %   Line 15  — ParamLabels(7)  Poisson's ratio
    %   Line 16  — ParamLabels(8)  Fillet mesh size
    %   Line 17  — ParamLabels(9)  RunWB2 path
    %   Line 18  — ParamLabels(10) Work folder
    %   Line 19  — LaunchButton text
    %   Line 20  — StatusLabel initial text  (shown at start / after language change)
    %   --- Status strings stored in StatusLabel.UserData (not visible at rest) ---
    %   Line 21  — Status: contact-stub warning             [UserData{1}]
    %   Line 22  — Status: step 1 — preparing folder        [UserData{2}]
    %   Line 23  — Status: step 2 — collecting parameters   [UserData{3}]
    %   Line 24  — Status: step 3 — writing profile pts     [UserData{4}]
    %   Line 25  — Status: step 4 — writing positions       [UserData{5}]
    %   Line 26  — Status: step 5 — writing SC script       [UserData{6}]
    %   Line 27  — Status: step 6 — writing Mech script     [UserData{7}]
    %   Line 28  — Status: step 7 — writing WB journal      [UserData{8}]
    %   Line 29  — Status: step 8 — launching Workbench     [UserData{9}]
    %   Line 30  — Status: success prefix                   [UserData{10}]
    %   Line 31  — Status: error prefix                     [UserData{11}]
    %   --- Placeholder text for the two path edit fields ---
    %   Line 32  — AnsysPathEdit placeholder  (shown when field is empty)
    %   Line 33  — WorkFolderEdit placeholder (shown when field is empty)

    % --- Load the text file --------------------------------------------------
    app    = dlg.AppRef;
    lang   = app.LanguageUtils.lang_storage;   % {folder, prefix}
    folder = lang{1};
    prefix = lang{2};
    tf     = readlines(fullfile(app.appFolder, 'Text', folder, ...
                                prefix + "_ansys_integration.txt"));

    % Sequential line counter — identical pattern to animationTabLanguageFun
    c = 0;
    function ln = seq
        c  = c + 1;
        ln = c;
    end

    % --- Window & tab --------------------------------------------------------
    dlg.F.Name        = tf{seq};    % line  1
    dlg.TVMSTab.Title = tf{seq};    % line  2

    % --- Button groups (Title property of uibuttongroup) ---------------------
    dlg.ModelTypeGroup.Title = tf{seq};     % line  3
    dlg.ModelContactless.Text = tf{seq};    % line  4
    dlg.ModelContact.Text     = tf{seq};    % line  5

    dlg.BodyTypeGroup.Title   = tf{seq};    % line  6
    dlg.BodyFull.Text         = tf{seq};    % line  7
    dlg.BodyHollow.Text       = tf{seq};    % line  8

    % --- Parameter labels (lines 9-18) ---------------------------------------
    for k = 1:10
        dlg.ParamLabels(k).Text = tf{seq};
    end

    % --- Launch button & status line initial text (lines 19-20) --------------
    dlg.LaunchButton.Text = tf{seq};    % line 19
    dlg.StatusLabel.Text  = tf{seq};    % line 20

    % --- Status strings stored in UserData (lines 21-31) --------------------
    % setStatus() retrieves these by index without needing the language file.
    ud = cell(11, 1);
    for k = 1:11
        ud{k} = tf{seq};
    end
    dlg.StatusLabel.UserData = ud;

    % --- Placeholder text for path edit fields (lines 32-33) ----------------
    % Shown inside the edit box when the field is empty, grey italic hint.
    dlg.AnsysPathEdit.Placeholder  = tf{seq};   % line 32
    dlg.WorkFolderEdit.Placeholder = tf{seq};   % line 33
end