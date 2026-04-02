function out = run_nx2_parameter_finalize_export(verbose)
%RUN_NX2_PARAMETER_FINALIZE_EXPORT
% NX-2 third round
% Finalize a temporary recommended NX-2 parameter set and export
% markdown-ready summary artifacts.

if nargin < 1
    verbose = true;
end

scene_list = {'ref128', 'stress96'};

% Temporary recommended setting from NX-2 sweep:
rec = struct();
rec.nx2_dwell_steps = 16;
rec.nx2_guard_enable = false;
rec.nx2_guard_ttl_steps = 8;

out_root = fullfile(pwd, 'outputs', 'cpt5', 'nx2_parameter_finalize');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end

records_cell = cell(1, numel(scene_list));

for i = 1:numel(scene_list)
    scene_preset = scene_list{i};

    cfg = default_ch5_params(scene_preset);
    cfg = apply_nx2_state_machine_defaults(cfg);
    cfg.ch5.nx2_state_machine_enable = true;
    cfg.ch5.nx2_dwell_steps = rec.nx2_dwell_steps;
    cfg.ch5.nx2_guard_enable = rec.nx2_guard_enable;
    cfg.ch5.nx2_guard_ttl_steps = rec.nx2_guard_ttl_steps;

    out_phase7a = run_ch5_phase7A_dualloop_ck(cfg, false);
    S = load(out_phase7a.mat_file);

    r = struct();
    r.scene_preset = string(scene_preset);
    r.nx2_dwell_steps = rec.nx2_dwell_steps;
    r.nx2_guard_enable = rec.nx2_guard_enable;
    r.nx2_guard_ttl_steps = rec.nx2_guard_ttl_steps;

    r.q_worst_window = S.custodyCK.q_worst_window;
    r.q_worst_point = S.custodyCK.q_worst_point;
    r.phi_mean = S.custodyCK.phi_mean;
    r.outage_ratio = S.custodyCK.outage_ratio;
    r.longest_outage_steps = S.custodyCK.longest_outage_steps;

    r.mean_rmse = S.trackingStatsCK.mean_rmse;
    r.max_rmse = S.trackingStatsCK.max_rmse;

    r.switch_count = local_count_switches(S.trackingCK);
    r.applied_switch_count = local_count_applied_switches(S.trackingCK);
    r.mean_sat_count = mean(S.trackingCK.tracking_sat_count(:));

    records_cell{i} = r;

    local_copy_latest_phase7a_fig(scene_preset, fig_dir);
end

records = [records_cell{:}];

summary = struct();
summary.recommended = rec;
summary.records = records;

txt_path = fullfile(tbl_dir, 'nx2_parameter_finalize_summary.txt');
local_write_summary(txt_path, records, rec);

md_path = fullfile(tbl_dir, 'nx2_parameter_finalize_summary.md');
local_write_markdown(md_path, records, rec);

mat_path = fullfile(mat_dir, 'nx2_parameter_finalize_summary.mat');
save(mat_path, 'records', 'summary');

if verbose
    disp('=== NX-2 parameter finalize ===')
    disp(struct2table(records))
    disp('=== recommended ===')
    disp(rec)
    disp('=== files ===')
    disp(txt_path)
    disp(md_path)
    disp(mat_path)
end

out = struct();
out.records = records;
out.recommended = rec;
out.text_file = txt_path;
out.markdown_file = md_path;
out.mat_file = mat_path;
out.fig_dir = fig_dir;
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

function local_write_summary(pathStr, records, rec)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open summary file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== NX-2 parameter finalize ===\n\n');
fprintf(fid, 'recommended_nx2_dwell_steps = %d\n', rec.nx2_dwell_steps);
fprintf(fid, 'recommended_nx2_guard_enable = %d\n', double(rec.nx2_guard_enable));
fprintf(fid, 'recommended_nx2_guard_ttl_steps = %d\n\n', rec.nx2_guard_ttl_steps);

for i = 1:numel(records)
    r = records(i);
    fprintf(fid, '--- %s ---\n', char(r.scene_preset));
    fprintf(fid, 'q_worst_window = %.6f\n', r.q_worst_window);
    fprintf(fid, 'q_worst_point = %.6f\n', r.q_worst_point);
    fprintf(fid, 'phi_mean = %.6f\n', r.phi_mean);
    fprintf(fid, 'outage_ratio = %.6f\n', r.outage_ratio);
    fprintf(fid, 'longest_outage_steps = %d\n', r.longest_outage_steps);
    fprintf(fid, 'mean_rmse = %.6f\n', r.mean_rmse);
    fprintf(fid, 'max_rmse = %.6f\n', r.max_rmse);
    fprintf(fid, 'switch_count = %d\n', r.switch_count);
    fprintf(fid, 'applied_switch_count = %.6f\n', r.applied_switch_count);
    fprintf(fid, 'mean_sat_count = %.6f\n\n', r.mean_sat_count);
end
end

function local_write_markdown(pathStr, records, rec)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open markdown file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# NX-2 参数定型收口\n\n');
fprintf(fid, '## 临时推荐参数\n\n');
fprintf(fid, '- `nx2_dwell_steps = %d`\n', rec.nx2_dwell_steps);
fprintf(fid, '- `nx2_guard_enable = %s`\n', string(rec.nx2_guard_enable));
fprintf(fid, '- `nx2_guard_ttl_steps = %d`\n\n', rec.nx2_guard_ttl_steps);

fprintf(fid, '## 定型依据\n\n');
fprintf(fid, '当前最小状态机扫描显示：`dwell` 已经能够压低切换，而当前 `guard_ttl_steps` 对结果几乎不敏感，因此本轮先固定 `dwell=16`，并暂时关闭 guard，等待后续将 guard 升级为更强的组合判据。\n\n');

fprintf(fid, '## 场景结果\n\n');
fprintf(fid, '| scene | q_worst_window | outage_ratio | longest_outage_steps | mean_rmse | switch_count | applied_switch_count |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|\n');
for i = 1:numel(records)
    r = records(i);
    fprintf(fid, '| %s | %.6f | %.6f | %d | %.6f | %d | %.6f |\n', ...
        char(r.scene_preset), ...
        r.q_worst_window, ...
        r.outage_ratio, ...
        r.longest_outage_steps, ...
        r.mean_rmse, ...
        r.switch_count, ...
        r.applied_switch_count);
end

fprintf(fid, '\n## 当前结论\n\n');
fprintf(fid, '1. `dwell` 已经证明有效，至少在 `ref128` 上能够压低切换且不损伤最坏窗口质量。\n');
fprintf(fid, '2. `guard_ttl_steps` 当前还没有形成明显灵敏度，不适合继续做精细调参。\n');
fprintf(fid, '3. 下一阶段重点不再是扫 TTL，而是将 guard 从单一 TTL 判据升级为更有任务语义的组合判据。\n');
end

function local_copy_latest_phase7a_fig(scene_preset, fig_dir)
src = fullfile(pwd, 'outputs', 'cpt5', 'phase7a', 'figs', ['phase7a_ck_vs_c_', scene_preset, '.png']);
if exist(src, 'file')
    dst = fullfile(fig_dir, ['phase7a_ck_vs_c_', scene_preset, '.png']);
    copyfile(src, dst);
end
end
