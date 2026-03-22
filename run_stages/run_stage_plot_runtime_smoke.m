function summary = run_stage_plot_runtime_smoke(root_tag)
%RUN_STAGE_PLOT_RUNTIME_SMOKE Verify Stage plotting works in visible/headless modes.

if nargin < 1 || isempty(root_tag)
    root_tag = datestr(now, 'yyyymmdd_HHMMSS');
end

cfg = default_params();
out_root = fullfile(cfg.paths.milestones, sprintf('STAGE_plot_runtime_smoke_%s', char(string(root_tag))));
fig_dir = fullfile(out_root, 'figures');
tab_dir = fullfile(out_root, 'tables');
ensure_dir(fig_dir);
ensure_dir(tab_dir);

cases = {
    struct('stage_name', "stage01_scenario_disk", 'mode', "headless", 'runner', @local_run_stage01)
    struct('stage_name', "stage01_scenario_disk", 'mode', "visible", 'runner', @local_run_stage01)
    struct('stage_name', "stage09_inverse_plot", 'mode', "headless", 'runner', @local_run_stage09_plot)
    struct('stage_name', "stage09_inverse_plot", 'mode', "visible", 'runner', @local_run_stage09_plot)
    };

rows = cell(numel(cases), 7);
for idx = 1:numel(cases)
    case_info = cases{idx};
    local_cfg = default_params();
    local_cfg.runtime.figure_visibility_mode = char(case_info.mode);
    local_cfg.runtime.plotting.mode = char(case_info.mode);
    local_cfg.runtime.plotting.default_visible = strcmpi(case_info.mode, 'visible');
    local_cfg.plot_manager.visible = strcmpi(case_info.mode, 'visible');
    apply_plot_runtime_config(local_cfg);

    notes = "";
    success = false;
    popup_expected = strcmpi(case_info.mode, 'visible');
    export_probe = "";
    try
        export_probe = case_info.runner(local_cfg);
        success = strlength(string(export_probe)) > 0 && isfile(char(export_probe));
        if success
            notes = "export verified";
        else
            notes = "runner returned without a verifiable export file";
        end
    catch ME
        notes = string(ME.identifier) + " | " + string(ME.message);
    end

    rows(idx, :) = {case_info.stage_name, case_info.mode, success, popup_expected, ...
        string(get(groot, 'DefaultFigureVisible')), string(export_probe), notes};
end

summary = cell2table(rows, 'VariableNames', { ...
    'stage_name', 'mode', 'figure_export_success', 'popup_observed_expected', ...
    'default_figure_visible', 'export_probe', 'notes'});
summary.figure_export_success = logical(summary.figure_export_success);
summary.popup_observed_expected = logical(summary.popup_observed_expected);
summary.stage_name = string(summary.stage_name);
summary.mode = string(summary.mode);
summary.default_figure_visible = string(summary.default_figure_visible);
summary.export_probe = string(summary.export_probe);
summary.notes = string(summary.notes);

summary_csv = fullfile(tab_dir, 'STAGE_headless_smoke_summary.csv');
writetable(summary, summary_csv);
fprintf('[run_stages] Stage plot runtime smoke summary saved to %s\n', summary_csv);
end

function export_probe = local_run_stage01(cfg)
cfg.stage01.make_plot = true;
out = run_stage01_scenario_disk(cfg, false, struct());
export_probe = local_probe_file(local_getfield_or(out, 'plot_path', ""));
if strlength(export_probe) == 0
    export_probe = local_find_latest_file(fullfile(cfg.paths.stage_outputs, 'stage01', 'figs'), '*.png');
end
end

function export_probe = local_run_stage09_plot(cfg)
cfg.stage09.scheme_type = 'validation_small';
cfg.stage09.run_tag = 'default';
out = run_stage09_inverse_plot(cfg, false, struct());
export_probe = local_probe_file(local_getfield_or(out, 'fig_path', ""));
if strlength(export_probe) == 0
    export_probe = local_find_latest_file(fullfile(cfg.paths.stage_outputs, 'stage09', 'figs'), '*.png');
end
end

function file_path = local_probe_file(value)
file_path = string(value);
if strlength(file_path) == 0 || ~isfile(char(file_path))
    file_path = "";
end
end

function latest_file = local_find_latest_file(folder_path, pattern)
latest_file = "";
if ~isfolder(folder_path)
    return;
end
files = dir(fullfile(folder_path, pattern));
if isempty(files)
    return;
end
[~, idx] = max([files.datenum]);
latest_file = string(fullfile(files(idx).folder, files(idx).name));
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
