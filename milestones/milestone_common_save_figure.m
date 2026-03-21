function file_path = milestone_common_save_figure(fig, file_path)
%MILESTONE_COMMON_SAVE_FIGURE Save milestone figure if handle is valid.

if isempty(fig) || ~ishandle(fig)
    file_path = "";
    return;
end

runtime = get_plot_runtime_config([]);
[parent_dir, ~, ~] = fileparts(file_path);
if ~isempty(parent_dir)
    ensure_dir(parent_dir);
end
exportgraphics(fig, file_path, 'Resolution', runtime.export_dpi);
end
