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

detail_rows = cell(numel(cases), 8);
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
        if case_info.stage_name == "stage09_inverse_plot" && contains(string(ME.message), "No cache matched patterns")
            try
                run_stage09_inverse_scan(local_cfg, false, struct());
                export_probe = case_info.runner(local_cfg);
                success = strlength(string(export_probe)) > 0 && isfile(char(export_probe));
                if success
                    notes = "export verified after validation_small scan bootstrap";
                else
                    notes = "scan bootstrap ran, but plot export was still not verified";
                end
            catch ME2
                notes = "bootstrap_failed | " + string(ME2.identifier) + " | " + string(ME2.message);
            end
        else
        notes = string(ME.identifier) + " | " + string(ME.message);
        end
    end

    detail_rows(idx, :) = {case_info.stage_name, case_info.mode, success, popup_expected, ...
        string(get(groot, 'DefaultFigureVisible')), string(export_probe), ...
        local_detect_upstream_cache_missing(notes), local_extract_fail_reason(notes, success)};
end

detail = cell2table(detail_rows, 'VariableNames', { ...
    'stage_name', 'mode', 'figure_export_success', 'popup_observed_expected', ...
    'default_figure_visible', 'export_probe', 'upstream_cache_missing', 'fail_reason'});
detail.figure_export_success = logical(detail.figure_export_success);
detail.popup_observed_expected = logical(detail.popup_observed_expected);
detail.stage_name = string(detail.stage_name);
detail.mode = string(detail.mode);
detail.default_figure_visible = string(detail.default_figure_visible);
detail.export_probe = string(detail.export_probe);
detail.upstream_cache_missing = logical(detail.upstream_cache_missing);
detail.fail_reason = string(detail.fail_reason);

stage_names = unique(detail.stage_name, 'stable');
rows = cell(numel(stage_names), 7);
for idx = 1:numel(stage_names)
    stage_name = stage_names(idx);
    stage_rows = detail(detail.stage_name == stage_name, :);
    headless_rows = stage_rows(stage_rows.mode == "headless", :);
    visible_rows = stage_rows(stage_rows.mode == "visible", :);
    headless_pass = ~isempty(headless_rows) && all(headless_rows.figure_export_success);
    visible_pass = ~isempty(visible_rows) && all(visible_rows.figure_export_success);
    export_pass = any(stage_rows.figure_export_success);
    upstream_cache_missing = any(stage_rows.upstream_cache_missing);
    fail_reason = strjoin(unique(stage_rows.fail_reason(stage_rows.fail_reason ~= "")), " || ");
    notes = "headless=" + string(headless_pass) + ...
        ", visible=" + string(visible_pass) + ...
        ", probes=" + strjoin(unique(stage_rows.export_probe(stage_rows.export_probe ~= "")), " | ");
    notes = local_build_stage_notes(stage_name, headless_pass, visible_pass, export_pass, upstream_cache_missing, fail_reason, stage_rows);
    rows(idx, :) = {stage_name, headless_pass, visible_pass, export_pass, upstream_cache_missing, fail_reason, notes};
end

summary = cell2table(rows, 'VariableNames', { ...
    'stage_name', 'headless_pass', 'visible_pass', 'export_pass', ...
    'upstream_cache_missing', 'fail_reason', 'notes'});
summary.stage_name = string(summary.stage_name);
summary.headless_pass = logical(summary.headless_pass);
summary.visible_pass = logical(summary.visible_pass);
summary.export_pass = logical(summary.export_pass);
summary.upstream_cache_missing = logical(summary.upstream_cache_missing);
summary.fail_reason = string(summary.fail_reason);
summary.notes = string(summary.notes);

summary_csv = fullfile(tab_dir, 'STAGE_headless_smoke_summary.csv');
writetable(summary, summary_csv);
detail_csv = fullfile(tab_dir, 'STAGE_headless_smoke_detail.csv');
writetable(detail, detail_csv);
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

function tf = local_detect_upstream_cache_missing(notes)
note_text = lower(char(string(notes)));
tf = contains(note_text, 'no cache matched patterns') || ...
    contains(note_text, 'stage08.5') || contains(note_text, 'cache');
end

function fail_reason = local_extract_fail_reason(notes, success)
if success
    fail_reason = "";
    return;
end
note_text = string(notes);
if contains(lower(note_text), 'stage08.5')
    fail_reason = "missing_stage08_5_cache";
elseif contains(lower(note_text), 'no cache matched patterns')
    fail_reason = "missing_upstream_cache";
elseif contains(lower(note_text), 'bootstrap_failed')
    fail_reason = "bootstrap_failed";
elseif contains(lower(note_text), 'iostream stream error') || contains(lower(note_text), 'badbit')
    fail_reason = "batch_visible_output_stream_instability";
else
    fail_reason = note_text;
end
end

function notes = local_build_stage_notes(stage_name, headless_pass, visible_pass, export_pass, upstream_cache_missing, fail_reason, stage_rows)
probes = strjoin(unique(stage_rows.export_probe(stage_rows.export_probe ~= "")), " | ");
notes = "headless=" + string(headless_pass) + ", visible=" + string(visible_pass);
if export_pass
    notes = notes + ", export_verified=1";
else
    notes = notes + ", export_verified=0";
end
if strlength(probes) > 0
    notes = notes + ", probes=" + probes;
end
if upstream_cache_missing
    notes = notes + ", mechanism_configured=1, blocked_by_upstream_cache=1";
elseif fail_reason == "batch_visible_output_stream_instability"
    notes = notes + ", mechanism_configured=1, visible_batch_gui_unstable=1";
elseif export_pass
    notes = notes + ", mechanism_configured=1";
end
if stage_name == "stage09_inverse_plot" && ~upstream_cache_missing && ~export_pass
    notes = notes + ", plot_runtime_hooked_but_plot_chain_unverified=1";
end
end
