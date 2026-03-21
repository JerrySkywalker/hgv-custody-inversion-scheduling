function out_path = finalize_managed_figure_export(fig, out_path, cfg_or_runtime, metadata)
%FINALIZE_MANAGED_FIGURE_EXPORT Export and optionally close a managed figure.

if nargin < 4
    metadata = struct(); %#ok<NASGU>
end
if isempty(fig) || ~ishandle(fig)
    out_path = "";
    return;
end

runtime = get_plot_runtime_config(cfg_or_runtime);
[parent_dir, ~, ~] = fileparts(out_path);
if ~isempty(parent_dir)
    ensure_dir(parent_dir);
end

exportgraphics(fig, out_path, 'Resolution', runtime.export_dpi);
close_figure_if_headless(fig, runtime);
end
