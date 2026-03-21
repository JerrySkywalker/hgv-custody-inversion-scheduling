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
runtime.close_after_save = false;
file_path = finalize_managed_figure_export(fig, file_path, runtime, struct());
end
