function out = run_ch5_phase9_window_sweep(scene_preset, verbose)
%RUN_CH5_PHASE9_WINDOW_SWEEP
% Phase 9
% Main sweep over window length T_w.
%
% Patched version:
%   - Phase4: prefer loading existing mat output
%   - C: use Phase5 single-loop custody runner
%   - CK / CK_dwell: use Phase7A dual-loop runner

if nargin < 1 || isempty(scene_preset)
    scene_preset = 'ref128';
end
if nargin < 2
    verbose = true;
end

tw_grid = [10 20 30 40 60 80];

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase9_window_sweep', scene_preset);
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end

rows_cell = {};
irow = 0;

for itw = 1:numel(tw_grid)
    Tw = tw_grid(itw);

    % ----- T -----
    irow = irow + 1;
    rows_cell{irow} = local_run_one(scene_preset, 'T', Tw);

    % ----- C -----
    irow = irow + 1;
    rows_cell{irow} = local_run_one(scene_preset, 'C', Tw);

    % ----- CK -----
    irow = irow + 1;
    rows_cell{irow} = local_run_one(scene_preset, 'CK', Tw);

    % ----- CK + NX2 dwell final -----
    irow = irow + 1;
    rows_cell{irow} = local_run_one(scene_preset, 'CK_dwell', Tw);
end

rows = [rows_cell{:}];

txt_path = fullfile(tbl_dir, ['phase9_window_sweep_', scene_preset, '.txt']);
csv_path = fullfile(tbl_dir, ['phase9_window_sweep_', scene_preset, '.csv']);
local_write_summary(txt_path, scene_preset, rows, tw_grid);
local_write_csv(csv_path, rows);

mat_path = fullfile(mat_dir, ['phase9_window_sweep_', scene_preset, '.mat']);
save(mat_path, 'rows', 'tw_grid');

fig_files = plot_ch5_phase9_window_sweep(rows, scene_preset, fig_dir);

if verbose
    disp('=== Phase 9 window sweep ===')
    disp(struct2table(rows))
    disp('=== fig files ===')
    disp(fig_files)
    disp(['[phase9] text : ', txt_path])
    disp(['[phase9] csv  : ', csv_path])
    disp(['[phase9] mat  : ', mat_path])
end

out = struct();
out.rows = rows;
out.tw_grid = tw_grid;
out.text_file = txt_path;
out.csv_file = csv_path;
out.mat_file = mat_path;
out.fig_dir = fig_dir;
out.fig_files = fig_files;
end

function row = local_run_one(scene_preset, method_name, Tw)
cfg = default_ch5_params(scene_preset);
cfg = local_apply_phase9_defaults(cfg, Tw, method_name);

switch method_name
    case 'T'
        S = local_load_or_run_phase4(scene_preset, cfg);
        tracking = S.trackingT;
        custody = local_tracking_to_custody_if_needed(S, tracking, cfg, 'custodyT');
        trackingStats = S.trackingT;

    case 'C'
        out_phase = run_ch5_phase5_singleloop_custody(cfg, false);
        S = load(out_phase.mat_file);
        tracking = local_pick_field(S, {'trackingC'});
        custody = local_pick_field(S, {'custodyC'});
        trackingStats = local_tracking_stats_from_tracking(tracking);

    case 'CK'
        out_phase = run_ch5_phase7A_dualloop_ck(cfg, false);
        S = load(out_phase.mat_file);
        tracking = local_pick_field(S, {'trackingCK'});
        custody = local_pick_field(S, {'custodyCK'});
        trackingStats = local_pick_field_if_exists(S, {'trackingStatsCK'});
        if isempty(trackingStats)
            trackingStats = local_tracking_stats_from_tracking(tracking);
        end

    case 'CK_dwell'
        out_phase = run_ch5_phase7A_dualloop_ck(cfg, false);
        S = load(out_phase.mat_file);
        tracking = local_pick_field(S, {'trackingCK'});
        custody = local_pick_field(S, {'custodyCK'});
        trackingStats = local_pick_field_if_exists(S, {'trackingStatsCK'});
        if isempty(trackingStats)
            trackingStats = local_tracking_stats_from_tracking(tracking);
        end

    otherwise
        error('Unknown method_name: %s', method_name);
end

row = struct();
row.scene_preset = string(scene_preset);
row.method = string(method_name);
row.T_w = Tw;

row.q_worst_window = custody.q_worst_window;
row.q_worst_point = custody.q_worst_point;
row.phi_mean = custody.phi_mean;
row.outage_ratio = custody.outage_ratio;
row.longest_outage_steps = custody.longest_outage_steps;

row.mean_rmse = trackingStats.mean_rmse;
row.max_rmse = trackingStats.max_rmse;

row.coverage_ratio_ge2 = local_get_field_or_nan(trackingStats, 'coverage_ratio_ge2');
row.switch_count = local_count_switches(tracking);
row.applied_switch_count = local_count_applied_switches(tracking);
end

function cfg = local_apply_phase9_defaults(cfg, Tw, method_name)
if ~isfield(cfg, 'ch5') || isempty(cfg.ch5)
    cfg.ch5 = struct();
end

cfg.ch5.window_steps = Tw;

switch method_name
    case 'CK_dwell'
        cfg = apply_nx2_state_machine_defaults(cfg);
        cfg.ch5.nx2_dwell_steps = 16;
        cfg.ch5.nx2_guard_enable = false;
        cfg.ch5.nx2_guard_ttl_steps = 8;

        if isfield(cfg.ch5, 'nx3_guard_enable')
            cfg.ch5.nx3_guard_enable = false;
        end
        if isfield(cfg.ch5, 'nx4_soft_enable')
            cfg.ch5.nx4_soft_enable = false;
        end

    case 'CK'
        cfg = apply_nx2_state_machine_defaults(cfg);
        cfg.ch5.nx2_dwell_steps = 0;
        cfg.ch5.nx2_guard_enable = false;
        cfg.ch5.nx2_guard_ttl_steps = 8;

        if isfield(cfg.ch5, 'nx3_guard_enable')
            cfg.ch5.nx3_guard_enable = false;
        end
        if isfield(cfg.ch5, 'nx4_soft_enable')
            cfg.ch5.nx4_soft_enable = false;
        end

    otherwise
        % T / C: no extra settings
end
end

function S = local_load_or_run_phase4(scene_preset, cfg)
mat_path = fullfile(pwd, 'outputs', 'cpt5', 'phase4', 'mats', 'phase4_static_hold.mat');
if exist(mat_path, 'file')
    S = load(mat_path);
    return
end

runner_candidates = { ...
    'run_ch5_phase4_static_hold', ...
    'run_ch5_phase4_static_hold_vs_tracking', ...
    'run_ch5_phase4_static_vs_tracking'};

for i = 1:numel(runner_candidates)
    f = str2func(runner_candidates{i});
    try
        if exist(runner_candidates{i}, 'file') || exist(runner_candidates{i}, 'builtin')
            out_phase = f(cfg, false);
            if isstruct(out_phase) && isfield(out_phase, 'mat_file') && exist(out_phase.mat_file, 'file')
                S = load(out_phase.mat_file);
                return
            end
        end
    catch
    end
end

error('Phase4 runner/mat not available for scene %s.', scene_preset);
end

function custody = local_tracking_to_custody_if_needed(S, tracking, cfg, custody_name)
if isfield(S, custody_name)
    custody = S.(custody_name);
    return
end

phi_series = 1 ./ (1 + tracking.rmse_pos(:));
threshold = 0.45;
if isfield(cfg, 'ch5') && isfield(cfg.ch5, 'custody_threshold') && ~isempty(cfg.ch5.custody_threshold)
    threshold = cfg.ch5.custody_threshold;
end

Tw = 20;
if isfield(cfg, 'ch5') && isfield(cfg.ch5, 'window_steps') && ~isempty(cfg.ch5.window_steps)
    Tw = cfg.ch5.window_steps;
end
Tw = max(1, min(Tw, numel(phi_series)));

q_window = inf(numel(phi_series)-Tw+1,1);
for i = 1:numel(q_window)
    q_window(i) = min(phi_series(i:i+Tw-1));
end

bad = phi_series < threshold;
longest = 0;
cur = 0;
for i = 1:numel(bad)
    if bad(i)
        cur = cur + 1;
        if cur > longest
            longest = cur;
        end
    else
        cur = 0;
    end
end

custody = struct();
custody.time = tracking.time(:);
custody.phi_series = phi_series(:);
custody.threshold = threshold;
custody.q_worst_point = min(phi_series);
custody.q_worst_window = min(q_window);
custody.q_worst = custody.q_worst_window;
custody.phi_mean = mean(phi_series);
custody.outage_ratio = mean(bad);
custody.longest_outage_steps = longest;
custody.sc_ratio = mean(phi_series >= threshold);
custody.dc_ratio = mean(phi_series < threshold & phi_series >= 0.2);
custody.loc_ratio = mean(phi_series < 0.2);
end

function stats = local_tracking_stats_from_tracking(tracking)
stats = struct();
stats.time = tracking.time(:);
stats.tracking_sat_count = tracking.tracking_sat_count(:);
stats.rmse_pos = tracking.rmse_pos(:);
stats.coverage_ratio_ge1 = mean(tracking.tracking_sat_count(:) >= 1);
stats.coverage_ratio_ge2 = mean(tracking.tracking_sat_count(:) >= 2);
stats.mean_rmse = mean(tracking.rmse_pos(:));
stats.max_rmse = max(tracking.rmse_pos(:));
end

function val = local_pick_field(S, names)
for i = 1:numel(names)
    if isfield(S, names{i})
        val = S.(names{i});
        return
    end
end
error('Required field not found.');
end

function val = local_pick_field_if_exists(S, names)
val = [];
for i = 1:numel(names)
    if isfield(S, names{i})
        val = S.(names{i});
        return
    end
end
end

function x = local_get_field_or_nan(S, field_name)
if isstruct(S) && isfield(S, field_name)
    x = S.(field_name);
else
    x = NaN;
end
end

function n = local_count_switches(tracking)
n = 0;
if isfield(tracking, 'selected_sets')
    ss = tracking.selected_sets;
    for i = 2:numel(ss)
        n = n + ~isequal(ss{i-1}, ss{i});
    end
end
end

function n = local_count_applied_switches(tracking)
n = NaN;
if isfield(tracking, 'switch_applied')
    n = sum(tracking.switch_applied(:) ~= 0);
end
end

function local_write_summary(pathStr, scene_preset, rows, tw_grid)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open summary file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Phase 9 window sweep ===\n');
fprintf(fid, 'scene_preset = %s\n', scene_preset);
fprintf(fid, 'Tw_grid = [%s]\n\n', sprintf('%g ', tw_grid));

fprintf(fid, 'method,T_w,q_worst_window,q_worst_point,phi_mean,outage_ratio,longest_outage_steps,mean_rmse,max_rmse,coverage_ratio_ge2,switch_count,applied_switch_count\n');
for i = 1:numel(rows)
    r = rows(i);
    fprintf(fid, '%s,%d,%.6f,%.6f,%.6f,%.6f,%d,%.6f,%.6f,%.6f,%d,%.6f\n', ...
        char(r.method), ...
        r.T_w, ...
        r.q_worst_window, ...
        r.q_worst_point, ...
        r.phi_mean, ...
        r.outage_ratio, ...
        r.longest_outage_steps, ...
        r.mean_rmse, ...
        r.max_rmse, ...
        r.coverage_ratio_ge2, ...
        r.switch_count, ...
        r.applied_switch_count);
end
end

function local_write_csv(pathStr, rows)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open csv file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'scene_preset,method,T_w,q_worst_window,q_worst_point,phi_mean,outage_ratio,longest_outage_steps,mean_rmse,max_rmse,coverage_ratio_ge2,switch_count,applied_switch_count\n');
for i = 1:numel(rows)
    r = rows(i);
    fprintf(fid, '%s,%s,%d,%.6f,%.6f,%.6f,%.6f,%d,%.6f,%.6f,%.6f,%d,%.6f\n', ...
        char(r.scene_preset), ...
        char(r.method), ...
        r.T_w, ...
        r.q_worst_window, ...
        r.q_worst_point, ...
        r.phi_mean, ...
        r.outage_ratio, ...
        r.longest_outage_steps, ...
        r.mean_rmse, ...
        r.max_rmse, ...
        r.coverage_ratio_ge2, ...
        r.switch_count, ...
        r.applied_switch_count);
end
end
