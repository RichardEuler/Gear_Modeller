% Copyright (c) 2026 Richard Timko
classdef contextMenuModuleUtils
    % contextMenuModuleUtils — Creates a context menu for selecting
    % standard module values from predefined series (Series 1 and 2).

    properties
        ContextMenu   % The uicontextmenu object
        SeriesMenu1   % Submenu for Series 1
        SeriesMenu2   % Submenu for Series 2
        ModuleSeries  % Nx2 matrix of standard module values
    end

    methods
        function obj = contextMenuModuleUtils(app, editField)
            % Build the context menu and attach it to the given edit field.
            obj.ContextMenu = uicontextmenu(app.MainUIFigure);

            obj.ModuleSeries(:,1) = readmatrix(fullfile(app.appFolder, 'Standard_module_series', 'Module_series_1.txt'));
            obj.ModuleSeries(:,2) = readmatrix(fullfile(app.appFolder, 'Standard_module_series', 'Module_series_2.txt'));

            obj.SeriesMenu1 = uimenu(obj.ContextMenu, 'Text', 'Series 1');
            for j = 1:size(obj.ModuleSeries, 1)
                uimenu(obj.SeriesMenu1, 'Text', num2str(obj.ModuleSeries(j,1)) + " mm", ...
                    'MenuSelectedFcn', @(~,~) set(editField, 'Value', obj.ModuleSeries(j,1)));
            end

            obj.SeriesMenu2 = uimenu(obj.ContextMenu, 'Text', 'Series 2');
            for j = 1:size(obj.ModuleSeries, 1)
                uimenu(obj.SeriesMenu2, 'Text', num2str(obj.ModuleSeries(j,2)) + " mm", ...
                    'MenuSelectedFcn', @(~,~) set(editField, 'Value', obj.ModuleSeries(j,2)));
            end
        end
    end
end
