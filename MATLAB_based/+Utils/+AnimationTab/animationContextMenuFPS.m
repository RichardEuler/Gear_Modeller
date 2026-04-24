% Copyright (c) 2026 Richard Timko
classdef animationContextMenuFPS < handle
    % animationContextMenuFPS — Context menu with a single "Live FPS"
    % checkable item that toggles a LaTeX annotation showing the measured
    % live frame rate above the animation axes.
    %
    % When unchecked or the animation is not running, the annotation reads
    % "-- Hz". While the animation is running it reads "X.X Hz" (one
    % decimal), updated from animationControl each frame.

    properties
        Menu        matlab.ui.container.Menu        % "Live FPS" checkable item
        Annotation  matlab.graphics.primitive.Text  % Axes-anchored text object
        Axes        matlab.graphics.axis.Axes       % The animation axes
        Fig                                         % Parent uifigure (for parenting the context menu)
    end

    methods
        function obj = animationContextMenuFPS(parentFig, axAnim, attachTargets)
            % Build the context menu and the hidden annotation.
            %
            %   parentFig     - uifigure that owns the context menu
            %   axAnim        - animation axes (annotation is anchored to it)
            %   attachTargets - array of UI components to receive the menu
            %                   (e.g. the FPS spinner and its label)
            obj.Fig  = parentFig;
            obj.Axes = axAnim;

            % Context menu with a single checkable item.
            cm = uicontextmenu(parentFig);
            obj.Menu = uimenu(cm, ...
                'Text',    'Live FPS', ...
                'Checked', 'off', ...
                'MenuSelectedFcn', @(src,~) obj.toggle(src));

            % Attach the menu to every requested target.
            for k = 1:numel(attachTargets)
                t = attachTargets(k);
                if isgraphics(t) && isvalid(t)
                    t.ContextMenu = cm;
                end
            end

            % LaTeX text object anchored to the axes, top-right (outside
            % the axis box). Hidden by default — toggled by the menu.
            obj.Annotation = text(axAnim, 1, 1.03, '$-\!-\ \mathrm{Hz}$', ...
                'Units',               'normalized', ...
                'Interpreter',         'latex', ...
                'HorizontalAlignment', 'right', ...
                'VerticalAlignment',   'bottom', ...
                'FontSize',            11, ...
                'Visible',             'off', ...
                'HandleVisibility',    'off');
        end

        function toggle(obj, src)
            % Flip the checked state and the annotation visibility.
            if strcmp(src.Checked, 'on')
                src.Checked           = 'off';
                obj.Annotation.Visible = 'off';
            else
                src.Checked           = 'on';
                obj.Annotation.Visible = 'on';
                obj.showIdle();
            end
        end

        function update(obj, fps)
            % Update the annotation with the current measured FPS.
            % Called from the animation loop every rendered frame.
            if ~obj.isActive(), return; end
            obj.Annotation.String = sprintf('$%.1f \\ \\mathrm{Hz}$', fps);
        end

        function showIdle(obj)
            % Reset the annotation to the idle placeholder "-- Hz".
            % Called when the animation is not running (paused/stopped).
            if ~isgraphics(obj.Annotation) || ~isvalid(obj.Annotation), return; end
            obj.Annotation.String = '$-\!-\ \mathrm{Hz}$';
        end

        function tf = isActive(obj)
            % True if the menu is checked and the annotation still exists.
            tf = isgraphics(obj.Menu) && isvalid(obj.Menu) && ...
                 strcmp(obj.Menu.Checked, 'on') && ...
                 isgraphics(obj.Annotation) && isvalid(obj.Annotation);
        end
    end
end