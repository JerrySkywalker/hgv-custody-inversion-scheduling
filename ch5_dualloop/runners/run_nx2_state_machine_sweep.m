function out = run_nx2_state_machine_sweep(scene_preset, verbose)
%RUN_NX2_STATE_MACHINE_SWEEP
% NX-2 second round
% Minimal parameter sweep for:
%   - nx2_dwell_steps
%   - nx2_guard_ttl_steps
%   - nx2_guard_enable
%
% Output:
%   one row per parameter combination with CK-only metrics

if nargin < 1 || isempty(scene_preset)
    scene_preset = 'ref128';
end
if nargin < 2
    verbose = true;
end

cfg0 = default_ch5_params(scene_preset);
cfg0 = apply_nx2_state_machine_defaults(cfg0);

dwell_grid = [0 4 8 16];
guard_ttl_grid = [8 16 24];
guard_enable_grid = [false true];

out_root = fullfile(pwd, 'outputs', 'cpt5', 'nx2_state_machine_sweep', scene_preset);
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end

rows_cell = {};
irow = 0;

for ig = 1:numel(guard_enable_grid)
    for id = 1:numel(dwell_grid)
        for it = 1:numel(guard_ttl_grid)
            irow = irow + 1;

            cfg = cfg0;
            cfg.ch5.nx2_state_machine_enable = true;
            cfg.ch5.nx2_dwell_steps = dwell_grid(id);
            cfg.ch5.nx2_guard_ttl_steps = guard_ttl_grid(it);
            cfg.ch5.nx2_guard_enable = guard_enable_grid(ig);

            out_phase7a = run_ch5_phase7A_dualloop_ck(cfg, false);
            S = load(out_phase7a.mat_file);

            row = struct();
            row.scene_preset = string(scene_preset);
            row.guard_enable = logical(guard_enable_grid(ig));
            row.dwell_steps = dwell_grid(id);
            row.guard_ttl_steps = guard_ttl_grid(it);

            row.q_worst_window = S.custodyCK.q_worst_window;
            row.q_worst_point = S.custodyCK.q_worst_point;
            row.phi_mean = S.custodyCK.phi_mean;
            row.outage_ratio = S.custodyCK.outage_ratio;
            row.longest_outage_steps = S.custodyCK.longest_outage_steps;

            row.mean_rmse = S.trackingStatsCK.mean_rmse;
            row.max_rmse = S.trackingStatsCK.max_rmse;

            row.switch_count = local_count_switches(S.trackingCK);
            row.applied_switch_count = local_count_applied_switches(S.trackingCK);
            row.mean_sat_count = mean(S.trackingCK.tracking_sat_count(:));

            rows_cell{irow} = row; %#ok<AGROW>
        end
    end
end

rows = [rows_cell{:}];
summary = local_build_summary(rows);

txt_path = fullfile(tbl_dir, ['nx2_state_machine_sweep_', scene_preset, '.txt']);
local_write_summary(txt_path, scene_preset, rows, summary);

mat_path = fullfile(mat_dir, ['nx2_state_machine_sweep_', scene_preset, '.mat']);
save(mat_path, 'rows', 'summary');

figs = plot_nx2_state_machine_sweep(rows, scene_preset, fig_dir);

if verbose
    disp('=== NX-2 state machine sweep ===')
    disp(struct2table(rows))
    disp('=== summary ===')
    disp(summary)
    disp('=== fig files ===')
    disp(figs)
end

out = struct();
out.rows = rows;
out.summary = summary;
out.text_file = txt_path;
out.mat_file = mat_path;
out.fig_dir = fig_dir;
out.fig_files = figs;
end

function n = local_count_switches(trackingCK)
n = 0;
if isfield(trackingCK, 'selected_sets')
    ss = trackingCK.selected_sets;
    for i = 2:numel(ss)
        n = n + ~isequal(ss{i-1}, ss{i});
    end
end
end

function n = local_count_applied_switches(trackingCK)
n = NaN;
if isfield(trackingCK, 'switch_applied')
    n = sum(trackingCK.switch_applied(:) ~= 0);
end
end

function summary = local_build_summary(rows)
[~, idx_best_q] = max([rows.q_worst_window]);
[~, idx_best_outage] = min([rows.outage_ratio]);
[~, idx_best_switch] = min([rows.switch_count]);

summary = struct();
summary.best_q_worst_window = rows(idx_best_q);
summary.best_outage_ratio = rows(idx_best_outage);
summary.best_switch_count = rows(idx_best_switch);
end

function local_write_summary(pathStr, scene_preset, rows, summary)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open summary file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== NX-2 state machine sweep ===\n');
fprintf(fid, 'scene_preset = %s\n\n', scene_preset);

fprintf(fid, 'guard_enable,dwell_steps,guard_ttl_steps,q_worst_window,q_worst_point,phi_mean,outage_ratio,longest_outage_steps,mean_rmse,max_rmse,switch_count,applied_switch_count,mean_sat_count\n');
for i = 1:numel(rows)
    r = rows(i);
    fprintf(fid, '%d,%d,%d,%.6f,%.6f,%.6f,%.6f,%d,%.6f,%.6f,%d,%.6f,%.6f\n', ...
        double(r.guard_enable), ...
        r.dwell_steps, ...
        r.guard_ttl_steps, ...
        r.q_worst_window, ...
        r.q_worst_point, ...
        r.phi_mean, ...
        r.outage_ratio, ...
        r.longest_outage_steps, ...
        r.mean_rmse, ...
        r.max_rmse, ...
        r.switch_count, ...
        r.applied_switch_count, ...
        r.mean_sat_count);
end

fprintf(fid, '\n=== best q_worst_window ===\n');
local_dump_row(fid, summary.best_q_worst_window);

fprintf(fid, '\n=== best outage_ratio ===\n');
local_dump_row(fid, summary.best_outage_ratio);

fprintf(fid, '\n=== best switch_count ===\n');
local_dump_row(fid, summary.best_switch_count);
end

function local_dump_row(fid, r)
fprintf(fid, 'guard_enable = %d\n', double(r.guard_enable));
fprintf(fid, 'dwell_steps = %d\n', r.dwell_steps);
fprintf(fid, 'guard_ttl_steps = %d\n', r.guard_ttl_steps);
fprintf(fid, 'q_worst_window = %.6f\n', r.q_worst_window);
fprintf(fid, 'outage_ratio = %.6f\n', r.outage_ratio);
fprintf(fid, 'switch_count = %d\n', r.switch_count);
fprintf(fid, 'applied_switch_count = %.6f\n', r.applied_switch_count);
fprintf(fid, 'mean_rmse = %.6f\n', r.mean_rmse);
end
