% Copyright (c) 2026 Richard Timko
classdef contextMenuPlotColourUtils
    % contextMenuPlotColourUtils — Creates a context menu that lets the user
    % switch between random and manual colour selection for a colour picker.

    properties
        ContextMenu;  Menu1;  Menu2
    end

    methods
        function obj = contextMenuPlotColourUtils(fig, lang, varargin)
            % Build the context menu.
            %   fig  — parent figure
            %   lang — language code ("SK", "CZ", "EN")
            %   varargin{1} — colour picker handle
            %   varargin{2} — (optional) colour label handle

            switch lang
                case "SK",  str1 = "Náhodný výber farby";  str2 = "Užívateľský výber farby";
                case "CZ",  str1 = "Náhodný výběr barvy";  str2 = "Uživatelský výběr barvy";
                case "EN",  str1 = "Random color selection"; str2 = "User color selection";
            end

            colour_picker = varargin{1};
            obj.ContextMenu = uicontextmenu(fig);

            if nargin == 5
                colour_label = varargin{2};
                targets = [colour_picker colour_label];
            else
                targets = colour_picker;
            end

            obj.Menu1 = uimenu(obj.ContextMenu, 'Text', str1, ...
                'MenuSelectedFcn', @(~,~) set(targets, 'Enable', 0));
            obj.Menu2 = uimenu(obj.ContextMenu, 'Text', str2, ...
                'MenuSelectedFcn', @(~,~) set(targets, 'Enable', 1));
            set(targets, 'ContextMenu', obj.ContextMenu);
        end
    end
end
