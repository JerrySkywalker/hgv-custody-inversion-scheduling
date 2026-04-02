function out = run_ch5_phase7A_dualloop_ck(cfg, verbose)
%RUN_CH5_PHASE7A_DUALOOP_CK
% NX-2 patched compatible runner
%
% This version:
%   - explicitly calls policy_custody_dualloop_koopman(caseData, cfg)
%   - avoids depending on missing helper functions
%   - preserves the Phase7A output contract as much as possible

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('ref128');
end
if nargin < 2
    verbose = true;
end

if ischar(cfg) || isstring(cfg)
    cfg = default_ch5_params(char(cfg));
end

cfg = apply_nx2_state_machine_defaults(cfg);
scene_preset = cfg.ch5.scene_preset;

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase7a');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
log_dir = fullfile(out_root, 'logs');
mat_dir = fullfile(out_root, 'mats');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end

caseData = build_ch5_case(cfg);

trackingC = policy_custody_singleloop(caseData, cfg);
trackingCK = policy_custody_dualloop_koopman(caseData, cfg);

custodyC = local_evaluate_custody_metrics(trackingC, cfg);
custodyCK = local_evaluate_custody_metrics(trackingCK, cfg);

trackingStatsC = local_summarize_tracking_metrics(trackingC);
trackingStatsCK = local_summarize_tracking_metrics(trackingCK);

fig_path = fullfile(fig_dir, ['phase7a_ck_vs_c_', scene_preset, '.png']);
local_plot_phase7a_ck_vs_c(custodyC, custodyCK, scene_preset, fig_path);

txt_path = fullfile(tbl_dir, ['phase7a_summary_', scene_preset, '.txt']);
local_write_summary(txt_path, scene_preset, custodyC, custodyCK, trackingStatsC, trackingStatsCK, trackingCK);

log_path = fullfile(log_dir, ['phase7a_log_', scene_preset, '.txt']);
local_write_log(log_path, scene_preset, trackingCK);

mat_path = fullfile(mat_dir, ['phase7a_', scene_preset, '.mat']);
save(mat_path, 'scene_preset', 'trackingC', 'trackingCK', 'custodyC', 'custodyCK', 'trackingStatsC', 'trackingStatsCK');

if verbose
    disp('=== Chapter 5 Phase 7A CK Summary ===')
    disp(['scene_preset = ', scene_preset])
    disp('--- custody C ---')
    disp(custodyC)
    disp(' ')
    disp('--- custody CK ---')
    disp(custodyCK)
    disp(' ')
    disp(['[phase7a] fig  : ', fig_path])
    disp(['[phase7a] text : ', txt_path])
    disp(['[phase7a] log  : ', log_path])
    disp(['[phase7a] mat  : ', mat_path])
end

out = struct();
out.fig_file = fig_path;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
end

function custody = local_evaluate_custody_metrics(tracking, cfg)
phi_series = 1 ./ (1 + tracking.rmse_pos(:));
threshold = 0.45;

if isfield(cfg, 'ch5') && isfield(cfg.ch5, 'custody_threshold') && ~isempty(cfg.ch5.custody_threshold)
    threshold = cfg.ch5.custody_threshold;
end

q_worst_point = min(phi_series);

win = 8;
if isfield(cfg, 'ch5') && isfield(cfg.ch5, 'window_steps') && ~isempty(cfg.ch5.window_steps)
    win = cfg.ch5.window_steps;
end
win = max(1, min(win, numel(phi_series)));

q_window = inf(numel(phi_series)-win+1,1);
for i = 1:numel(q_window)
    q_window(i) = min(phi_series(i:i+win-1));
end
q_worst_window = min(q_window);

bad = phi_series < threshold;
outage_ratio = mean(bad);

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
custody.q_worst_point = q_worst_point;
custody.q_worst_window = q_worst_window;
custody.q_worst = q_worst_window;
custody.phi_mean = mean(phi_series);
custody.outage_ratio = outage_ratio;
custody.longest_outage_steps = longest;
custody.sc_ratio = mean(phi_series >= threshold);
custody.dc_ratio = mean(phi_series < threshold & phi_series >= 0.2);
custody.loc_ratio = mean(phi_series < 0.2);
end

function stats = local_summarize_tracking_metrics(tracking)
rmse = tracking.rmse_pos(:);
stats = struct();
stats.mean_rmse = mean(rmse);
stats.max_rmse = max(rmse);
stats.min_rmse = min(rmse);
stats.mean_sat_count = mean(tracking.tracking_sat_count(:));
end

function local_plot_phase7a_ck_vs_c(custodyC, custodyCK, scene_preset, fig_path)
f = figure('Visible', 'off');
tiledlayout(2,2);

nexttile
plot(custodyC.time, custodyC.phi_series, 'LineWidth', 1.2); hold on
plot(custodyCK.time, custodyCK.phi_series, 'LineWidth', 1.2);
yline(custodyC.threshold, '--', 'Interpreter', 'none');
title('phi series', 'Interpreter', 'none');
legend({'C','CK','threshold'}, 'Interpreter', 'none', 'Location', 'best');
grid on

nexttile
bar([custodyC.q_worst_window, custodyCK.q_worst_window]);
set(gca, 'XTickLabel', {'q_worst_window'});
legend({'C','CK'}, 'Interpreter', 'none', 'Location', 'best');
title('worst-window quality', 'Interpreter', 'none');
grid on

nexttile
bar([custodyC.outage_ratio, custodyCK.outage_ratio]);
set(gca, 'XTickLabel', {'outage_ratio'});
legend({'C','CK'}, 'Interpreter', 'none', 'Location', 'best');
title('outage ratio', 'Interpreter', 'none');
grid on

nexttile
bar([custodyC.longest_outage_steps, custodyCK.longest_outage_steps]);
set(gca, 'XTickLabel', {'longest_outage_steps'});
legend({'C','CK'}, 'Interpreter', 'none', 'Location', 'best');
title('longest outage steps', 'Interpreter', 'none');
grid on

sgtitle(['Phase7A CK vs C - ', scene_preset], 'Interpreter', 'none');
saveas(f, fig_path);
close(f);
end

function local_write_summary(pathStr, scene_preset, custodyC, custodyCK, trackingStatsC, trackingStatsCK, trackingCK)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open summary file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Chapter 5 Phase 7A CK Summary ===\n');
fprintf(fid, 'scene_preset = %s\n', scene_preset);

fprintf(fid, '--- custody C ---\n');
local_dump_struct(fid, custodyC);

fprintf(fid, '\n--- custody CK ---\n');
local_dump_struct(fid, custodyCK);

fprintf(fid, '\n--- trackingStatsC ---\n');
local_dump_struct(fid, trackingStatsC);

fprintf(fid, '\n--- trackingStatsCK ---\n');
local_dump_struct(fid, trackingStatsCK);

fprintf(fid, '\n--- trackingCK fields ---\n');
fn = fieldnames(trackingCK);
for i = 1:numel(fn)
    fprintf(fid, '%s\n', fn{i});
end
end

function local_write_log(pathStr, scene_preset, trackingCK)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open log file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '[INFO] phase7a ck\n');
fprintf(fid, '[INFO] scene_preset = %s\n', scene_preset);
fprintf(fid, '[INFO] trackingCK fields:\n');
fn = fieldnames(trackingCK);
for i = 1:numel(fn)
    fprintf(fid, '[INFO]   %s\n', fn{i});
end
end

function local_dump_struct(fid, S)
fn = fieldnames(S);
for i = 1:numel(fn)
    v = S.(fn{i});
    if isnumeric(v) && isscalar(v)
        fprintf(fid, '%s = %.6f\n', fn{i}, v);
    elseif isstring(v) && isscalar(v)
        fprintf(fid, '%s = %s\n', fn{i}, char(v));
    elseif ischar(v)
        fprintf(fid, '%s = %s\n', fn{i}, v);
    else
        sz = size(v);
        sz_txt = sprintf('%dx', sz);
        sz_txt = sz_txt(1:end-1);
        fprintf(fid, '%s : [%s %s]\n', fn{i}, sz_txt, class(v));
    end
end
end
