function runtime = apply_plot_runtime_config(cfg_or_runtime)
%APPLY_PLOT_RUNTIME_CONFIG Apply plotting runtime settings to root graphics.

runtime = get_plot_runtime_config(cfg_or_runtime);
setappdata(0, 'mb_plot_runtime_config', runtime);

visible_mode = runtime.mode == "visible" && logical(runtime.default_visible);
if visible_mode
    set(groot, 'DefaultFigureVisible', 'on');
else
    set(groot, 'DefaultFigureVisible', 'off');
end

set(groot, 'defaultFigureColor', 'w');
if runtime.renderer ~= "auto"
    set(groot, 'defaultFigureRenderer', char(runtime.renderer));
end
end
