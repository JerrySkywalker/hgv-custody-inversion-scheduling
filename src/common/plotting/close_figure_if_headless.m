function close_figure_if_headless(fig, cfg_or_runtime)
%CLOSE_FIGURE_IF_HEADLESS Close figure automatically for headless/offscreen runs.

if isempty(fig) || ~ishandle(fig)
    return;
end
runtime = get_plot_runtime_config(cfg_or_runtime);
if logical(runtime.close_after_save) && is_plot_headless_mode(runtime)
    close(fig);
end
end
