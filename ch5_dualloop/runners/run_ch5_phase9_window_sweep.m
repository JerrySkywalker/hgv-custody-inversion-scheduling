function out = run_ch5_phase9_window_sweep(scene_preset, verbose)
%RUN_CH5_PHASE9_WINDOW_SWEEP
% Phase 9
% Main sweep over window length T_w.

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
local_write_summary(txt_path, scene_preset, rows, tw_grid);

mat_path = fullfile(mat_dir, ['phase9_window_sweep_', scene_preset, '.mat']);
save(mat_path, 'rows', 'tw_grid');

fig_files = plot_ch5_phase9_window_sweep(rows, scene_preset, fig_dir);

if verbose
    disp('=== Phase 9 window sweep ===')
    disp(struct2table(rows))
    disp('=== fig files ===')
    disp(fig_files)
end

out = struct();
out.rows = rows;
out.tw_grid = tw_grid;
out.text_file = txt_path;
out.mat_file = mat_path;
out.fig_dir = fig_dir;
out.fig_files = fig_files;
end

function row = local_run_one(scene_preset, method_name, Tw)
cfg = default_ch5_params(scene_preset);
cfg = local_apply_phase9_defaults(cfg, Tw, method_name);

switch method_name
    case 'T'
        out_phase = run_ch5_phase4_static_vs_tracking(cfg, false);
        S = load(out_phase.mat_file);
        tracking = S.trackingT;
        custody = S.custodyT;
        trackingStats = S.trackingStatsT;

    case 'C'
        out_phase = run_ch5_phase7A_dualloop_ck(cfg, false);
        S = load(out_phase.mat_file);
        tracking = S.trackingC;
        custody = S.custodyC;
        trackingStats = S.trackingStatsC;

    case 'CK'
        out_phase = run_ch5_phase7A_dualloop_ck(cfg, false);
        S = load(out_phase.mat_file);
        tracking = S.trackingCK;
        custody = S.custodyCK;
        trackingStats = S.trackingStatsCK;

    case 'CK_dwell'
        out_phase = run_ch5_phase7A_dualloop_ck(cfg, false);
        S = load(out_phase.mat_file);
        tracking = S.trackingCK;
        custody = S.custodyCK;
        trackingStats = S.trackingStatsCK;

    otherwise
        error('Unknown method_name: %s', method_name);
end

row = struct();
row.scene_preset = string(scene_preset);
row.method = string(method_name);
row.Tw = Tw;

row.q_worst_window = custody.q_worst_window;
row.q_worst_point = custody.q_worst_point;
row.phi_mean = custody.phi_mean;
row.outage_ratio = custody.outage_ratio;
row.longest_outage_steps = custody.longest_outage_steps;

row.mean_rmse = trackingStats.mean_rmse;
row.max_rmse = trackingStats.max_rmse;

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

fprintf(fid, 'method,Tw,q_worst_window,q_worst_point,phi_mean,outage_ratio,longest_outage_steps,mean_rmse,max_rmse,switch_count,applied_switch_count\n');
for i = 1:numel(rows)
    r = rows(i);
    fprintf(fid, '%s,%d,%.6f,%.6f,%.6f,%.6f,%d,%.6f,%.6f,%d,%.6f\n', ...
        char(r.method), ...
        r.Tw, ...
        r.q_worst_window, ...
        r.q_worst_point, ...
        r.phi_mean, ...
        r.outage_ratio, ...
        r.longest_outage_steps, ...
        r.mean_rmse, ...
        r.max_rmse, ...
        r.switch_count, ...
        r.applied_switch_count);
end
end
