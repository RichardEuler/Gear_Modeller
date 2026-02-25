% Copyright (c) 2026 Richard Timko
function line_style = profileLineStyleFunction(id)
    % Function for specifying the line style from the drop down component

    switch id
        case 1
            line_style = "-";
        case 2
            line_style = "--";
        case 3
            line_style = ":";
        case 4
            line_style = "-.";
    end
end