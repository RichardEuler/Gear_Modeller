% Copyright (c) 2026 Richard Timko
function outerLanguageFun(app, text_file)
    % outerLanguageFun — Assign text from the "outer" language file to
    % top-level application components (figure titles, tab titles, etc.).

    % Sequential counter that returns the next line index on each call
    c = 0;
    function current_number = seq
        c = c + 1;
        current_number = c;
    end

    % Line 1: standby annotation text on the output figure
    app.HomeUtils.FigureText.String = text_file{seq};
    % Line 2: main UI figure title
    app.MainUIFigure.Name = text_file{seq};
    % Line 3: output figure title
    app.OutputFigure.Name = text_file{seq};
    % Line 4: Home tab title
    app.HomeTab.Title = text_file{seq};
    % Line 5: Profile tab title
    app.ProfileTab.Title = text_file{seq};
end
