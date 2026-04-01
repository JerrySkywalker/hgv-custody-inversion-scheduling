function out = run_ch5_phase9_window_sweep(cfg, verbose)
%RUN_CH5_PHASE9_WINDOW_SWEEP
% Sweep T_w over T / C / CK for one scene preset.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('stress96');
end
if nargin < 2
    verbose = true;
end

phase_name = 'phase9';
out_root = fullfile(pwd, 'outputs', 'cpt5', phase_name);
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

if ~isfield(cfg.ch5, 'phase9_window_grid') || isempty(cfg.ch5.phase9_window_grid)
    cfg.ch5.phase9_window_grid = [10 20 30 40 60 80];
end

Tw_grid = cfg.ch5.phase9_window_grid(:).';

rows = struct( ...
    'method', {}, ...
    'T_w', {}, ...
    'q_worst_window', {}, ...
    'phi_mean', {}, ...
    'outage_ratio', {}, ...
    'longest_outage_steps', {}, ...
    'mean_rmse', {}, ...
    'coverage_ratio_ge2', {});

for itw = 1:numel(Tw_grid)
    cfg_i = cfg;
    cfg_i.ch5.window_steps = Tw_grid(itw);

    caseData = build_ch5_case(cfg_i);

    trackingT = policy_tracking_dynamic(caseData, cfg_i);
    resultT = local_attach_custody_fields(trackingT, caseData, cfg_i);
    custodyT = eval_custody_metrics(resultT);
    trackT = eval_tracking_metrics(trackingT);

    trackingC = policy_custody_singleloop(caseData, cfg_i);
    resultC = local_attach_custody_fields(trackingC, caseData, cfg_i);
    custodyC = eval_custody_metrics(resultC);
    trackC = eval_tracking_metrics(trackingC);

    trackingCK = policy_custody_dualloop_koopman(caseData, cfg_i);
    resultCK = local_attach_custody_fields(trackingCK, caseData, cfg_i);
    custodyCK = eval_custody_metrics(resultCK);
    trackCK = eval_tracking_metrics(trackingCK);

    rows(end+1) = local_make_row('T',  Tw_grid(itw), custodyT,  trackT); %#ok<AGROW>
    rows(end+1) = local_make_row('C',  Tw_grid(itw), custodyC,  trackC); %#ok<AGROW>
    rows(end+1) = local_make_row('CK', Tw_grid(itw), custodyCK, trackCK); %#ok<AGROW>
end

scene_name = cfg.ch5.scene_preset;
scene_fig_dir = fullfile(fig_dir, scene_name);
figs = plot_window_sweep_curves(scene_name, rows, scene_fig_dir);

txt_path = fullfile(tbl_dir, ['phase9_window_sweep_', scene_name, '.txt']);
local_write_summary(txt_path, rows, scene_name);

csv_path = fullfile(tbl_dir, ['phase9_window_sweep_', scene_name, '.csv']);
local_write_csv(csv_path, rows);

log_path = fullfile(log_dir, ['phase9_window_sweep_log_', scene_name, '.txt']);
log_lines = {
    '=== Chapter 5 Phase 9 Window Sweep ==='
    ['scene_preset = ', scene_name]
    ['Tw_grid      = ', mat2str(Tw_grid)]
    ['rows         = ', num2str(numel(rows))]
    };
local_write_txt(log_path, log_lines);

mat_path = fullfile(mat_dir, ['phase9_window_sweep_', scene_name, '.mat']);
save(mat_path, 'cfg', 'Tw_grid', 'rows', 'figs');

if verbose
    disp('=== Chapter 5 Phase 9 Window Sweep Summary ===')
    disp(['scene_preset = ', scene_name])
    disp(struct2table(rows))
    disp(['[phase9] text : ', txt_path]);
    disp(['[phase9] csv  : ', csv_path]);
    disp(['[phase9] log  : ', log_path]);
    disp(['[phase9] mat  : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.text_file = txt_path;
out.csv_file = csv_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.figs = figs;
out.rows = rows;
end

function row = local_make_row(method_name, T_w, custody, tracking)
row = struct();
row.method = method_name;
row.T_w = T_w;
row.q_worst_window = custody.q_worst_window;
row.phi_mean = custody.phi_mean;
row.outage_ratio = custody.outage_ratio;
row.longest_outage_steps = custody.longest_outage_steps;
row.mean_rmse = tracking.mean_rmse;
row.coverage_ratio_ge2 = tracking.coverage_ratio_ge2;
end

function result = local_attach_custody_fields(tracking, caseData, cfg)
result = tracking;

mg = compute_mg_series(tracking, caseData, cfg);
ttl = compute_ttl_series(tracking, caseData, cfg);

switch_series = zeros(size(tracking.time(:)));
for k = 2:numel(tracking.selected_sets)
    switch_series(k) = ~isequal(tracking.selected_sets{k-1}, tracking.selected_sets{k});
end

phi_series = compute_phi_window(mg, ttl, switch_series, cfg);

result.mg_series = mg(:);
result.ttl_series = ttl(:);
result.switch_series = switch_series(:);
result.phi_series = phi_series(:);
result.threshold = cfg.ch5.custody_phi_threshold;
end

function local_write_summary(pathStr, rows, scene_name)
lines = {'=== Chapter 5 Phase 9 Window Sweep Summary ===', ...
         ['scene_preset = ', scene_name], ...
         'method,T_w,q_worst_window,phi_mean,outage_ratio,longest_outage_steps,mean_rmse,coverage_ratio_ge2'};
for i = 1:numel(rows)
    r = rows(i);
    lines{end+1} = sprintf('%s,%d,%.6f,%.6f,%.6f,%d,%.6f,%.6f', ...
        r.method, r.T_w, r.q_worst_window, r.phi_mean, r.outage_ratio, ...
        r.longest_outage_steps, r.mean_rmse, r.coverage_ratio_ge2); %#ok<AGROW>
end
local_write_txt(pathStr, lines);
end

function local_write_csv(pathStr, rows)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'method,T_w,q_worst_window,phi_mean,outage_ratio,longest_outage_steps,mean_rmse,coverage_ratio_ge2\n');
for i = 1:numel(rows)
    r = rows(i);
    fprintf(fid, '%s,%d,%.6f,%.6f,%.6f,%d,%.6f,%.6f\n', ...
        r.method, r.T_w, r.q_worst_window, r.phi_mean, r.outage_ratio, ...
        r.longest_outage_steps, r.mean_rmse, r.coverage_ratio_ge2);
end
end

function local_write_txt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
