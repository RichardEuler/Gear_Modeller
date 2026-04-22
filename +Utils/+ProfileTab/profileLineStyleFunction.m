% Copyright (c) 2026 Richard Timko
function line_style = profileLineStyleFunction(id)
    % profileLineStyleFunction — Convert a 1-based dropdown index to a
    % MATLAB line-style string.

    styles = ["-", "--", ":", "-."];
    if id >= 1 && id <= numel(styles)
        line_style = styles(id);
    else
        line_style = "-";   % Default to solid
    end
end
