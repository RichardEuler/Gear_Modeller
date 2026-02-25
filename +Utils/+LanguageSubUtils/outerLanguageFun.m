% Copyright (c) 2026 Richard Timko
function outerLanguageFun(app, text_file)
    % Function language manager for outer app components

    % Counter function
    function current_number = seq
        persistent c; % Declare 'counter' as persistent
        if isempty(c)
            c = 0; % Initialize counter if it's the first call
        end
        c = c + 1; % Increment the counter
        current_number = c; %  Output the current number
        if c >= numel(text_file)
            c = 0; % Reset the counter when the maximum number of lines has been reached
        end
    end

app.HomeUtils.FigureText.String = text_file{seq};
app.MainUIFigure.Name = text_file{seq};
app.OutputFigure.Name = text_file{seq};

% Tab Titles
app.HomeTab.Title = text_file{seq};
app.ProfileTab.Title = text_file{seq};
end