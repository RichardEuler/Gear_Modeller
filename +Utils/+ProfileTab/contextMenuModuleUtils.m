% Copyright (c) 2026 Richard Timko
classdef contextMenuModuleUtils
    % Handles the dynamic creation of a uicontextmenu for standard module
    % selection.
    % This class manages the logic for displaying gear module series
    % in a context menu, allowing for a clean separation of concerns
    % from the main app code.

    properties
        ContextMenu % Uicontextmenu object
        SeriesMenu1 % Uimenu object for first series selection
        SeriesMenu2 % Uimenu object for second series selection
        ModuleSeries % Standard module series
    end

    methods
        function obj = contextMenuModuleUtils(app,arg)
            obj.ContextMenu = uicontextmenu(app.MainUIFigure);

            obj.ModuleSeries(:,2) = readmatrix(fullfile(app.appFolder,"Standard_module_series","Module_series_2.txt"));
            obj.ModuleSeries(:,1) = readmatrix(fullfile(app.appFolder,"Standard_module_series","Module_series_1.txt"));

            % Create Series menu items
            obj.SeriesMenu1 = uimenu(obj.ContextMenu,"Text", "Rada 1");
            for j = 1:size(obj.ModuleSeries,1)
                str_module = num2str(obj.ModuleSeries(j,1)) + " mm";
                uimenu(obj.SeriesMenu1,"Text",str_module,...
                    "MenuSelectedFcn", @(src,event) set(arg,"Value",obj.ModuleSeries(j,1)));
            end

            obj.SeriesMenu2 = uimenu(obj.ContextMenu,"Text", "Rada 2");
            for j = 1:size(obj.ModuleSeries,1)
                str_module = num2str(obj.ModuleSeries(j,2)) + " mm";
                uimenu(obj.SeriesMenu2,"Text",str_module,...
                    "MenuSelectedFcn", @(src,event) set(arg,"Value",obj.ModuleSeries(j,2)));
            end
        end
    end
end