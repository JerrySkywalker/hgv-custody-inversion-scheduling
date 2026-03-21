function tf = is_plot_headless_mode(cfg_or_runtime)
%IS_PLOT_HEADLESS_MODE Return true when plotting should not raise windows.

runtime = get_plot_runtime_config(cfg_or_runtime);
tf = runtime.mode ~= "visible";
end
