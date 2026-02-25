% Copyright (c) 2026 Richard Timko
classdef contextMenuPlotColourUtils
    % Handles the dynamic creation of a uicontextmenu for standard module
    % selection.
    % This class manages the logic for displaying gear module series
    % in a context menu, allowing for a clean separation of concerns
    % from the main app code.

    properties
        ContextMenu % Uicontextmenu object
        Menu1 % Uimenu object for first series selection
        Menu2 % Uimenu object for second series selection
    end

    methods
        function obj = contextMenuPlotColourUtils(fig,lan,varargin)
            switch lan
                case "SK"
                    str1 = "Náhodný výber farby";
                    str2 = "Užívateľský výber farby";
                case "CZ"
                    str1 = "Náhodný výběr barvy";
                    str2 = "Uživatelský výběr barvy";
                case "EN"
                    str1 = "Random color selection";
                    str2 = "User color selection";
            end
                
            if nargin == 4
                colour_picker = varargin{1};
                colour_label = varargin{2};
                obj.ContextMenu = uicontextmenu(fig);
                obj.Menu1 = uimenu(obj.ContextMenu,"Text", str1, ...
                    "MenuSelectedFcn", @(src,event) ...
                    set([colour_picker colour_label],"Enable",0));
                obj.Menu2 = uimenu(obj.ContextMenu,"Text", str2, ...
                    "MenuSelectedFcn", @(src,event) ...
                    set([colour_picker colour_label],"Enable",1));
                set([colour_picker colour_label],"ContextMenu",obj.ContextMenu);
            elseif nargin == 3
                colour_picker = varargin{1};
                obj.ContextMenu = uicontextmenu(fig);
                obj.Menu1 = uimenu(obj.ContextMenu,"Text", str1, ...
                    "MenuSelectedFcn", @(src,event) ...
                    set(colour_picker,"Enable",0));
                obj.Menu2 = uimenu(obj.ContextMenu,"Text", str2, ...
                    "MenuSelectedFcn", @(src,event) ...
                    set(colour_picker,"Enable",1));
                set(colour_picker,"ContextMenu",obj.ContextMenu);
            else
                error("Too many input arguments in function.");
            end
        end
    end
end