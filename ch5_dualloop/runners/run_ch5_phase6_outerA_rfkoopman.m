function out = run_ch5_phase6_outerA_rfkoopman(cfg, verbose)
%RUN_CH5_PHASE6_OUTERA_RFKOOPMAN  Standalone outerA RF-Koopman evidence runner.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('stress96');
end
if nargin < 2
    verbose = true;
end

cfg.phase_name = 'phase6a';

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase6a');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

caseData = build_ch5_case(cfg);

% Use tracking baseline as observation shell for phi and candidate richness
resultT = policy_tracking_dynamic(caseData, cfg);
mgT = compute_mg_series(resultT, caseData, cfg);
ttlT = compute_ttl_series(resultT, caseData, cfg);

switchT = zeros(size(resultT.time));
for k = 2:numel(resultT.selected_sets)
    switchT(k) = ~isequal(resultT.selected_sets{k-1}, resultT.selected_sets{k});
end

phiT = compute_phi_window(mgT, ttlT, switchT, cfg);

inner = run_inner_loop_filter(caseData, cfg);
nis_series = compute_nis_series(inner);
time = caseData.time.t(:);

cand_count = caseData.candidates.count(:);
cand_norm = cand_count / max(cand_count);

fitW = cfg.ch5.outerA_fit_window_steps;
H = cfg.ch5.outerA_horizon_steps;
N = numel(time);
d = cfg.ch5.outerA_state_dim;

std_eps = cfg.ch5.outerA_std_eps;
clip_phi = cfg.ch5.outerA_pred_clip_phi;
clip_nis = cfg.ch5.outerA_pred_clip_nis;
clip_cand = cfg.ch5.outerA_pred_clip_cand;

mr_hat_series = zeros(N,1);
mr_tilde_series = zeros(N,1);
omega_series = zeros(N,1);
risk_state = zeros(N,1);
risk_quadrant = ones(N,1);
lead_time_steps = zeros(N,1);

for k = 1:N
    i1 = max(1, k-fitW+1);

    Xi_raw = [phiT(i1:k), nis_series(i1:k), cand_norm(i1:k)];

    mu = mean(Xi_raw, 1);
    sigma = std(Xi_raw, 0, 1);
    sigma = max(sigma, std_eps);

    Xi = (Xi_raw - mu) ./ sigma;

    if size(Xi,1) < 2
        A = eye(d);
    else
        A = rfkoopman_fit_local_operator(Xi, cfg);
    end

    x0_raw = [phiT(k), nis_series(k), cand_norm(k)];
    x0 = ((x0_raw - mu) ./ sigma).';

    Xpred_n = propagate_rfkoopman_window(x0, A, H);
    Xpred = Xpred_n .* sigma + mu;

    phi_pred = Xpred(:,1);
    nis_pred = Xpred(:,2);
    cand_pred = Xpred(:,3);

    phi_pred = min(max(phi_pred, clip_phi(1)), clip_phi(2));
    nis_pred = min(max(nis_pred, clip_nis(1)), clip_nis(2));
    cand_pred = min(max(cand_pred, clip_cand(1)), clip_cand(2));

    mr_hat = compute_mr_hat(phi_pred, nis_pred, cand_pred, cfg);
    mr_tilde = conservative_mr_from_nis(mr_hat, nis_series(k), cfg);
    omega_now = compute_omega_max(mr_hat);

    mr_hat_series(k) = mr_hat(1);
    mr_tilde_series(k) = mr_tilde(1);
    omega_series(k) = omega_now;

    [risk_state(k), risk_quadrant(k)] = classify_outerA_risk_state(mr_tilde_series(k), omega_now, cfg);

    % lead time estimate to next bad phi event under current threshold
    future_bad = find(phiT(k:min(N, k+H-1)) < cfg.ch5.custody_phi_threshold, 1, 'first');
    if ~isempty(future_bad)
        lead_time_steps(k) = future_bad - 1;
    else
        lead_time_steps(k) = 0;
    end
end

outerA = package_outerA_result(time, mr_hat_series, mr_tilde_series, omega_series, risk_state, risk_quadrant, lead_time_steps);
stats = eval_dualloop_metrics(outerA);

fig_evidence = fullfile(fig_dir, ['phase6a_evidence_timeline_', cfg.ch5.scene_preset, '.png']);
fig_quad = fullfile(fig_dir, ['phase6a_quadrant_stats_', cfg.ch5.scene_preset, '.png']);

f1 = plot_dualloop_evidence_timeline(time, phiT, outerA, fig_evidence); %#ok<NASGU>
f2 = plot_outerA_quadrant_stats(stats, fig_quad); %#ok<NASGU>
close all

txt_path = fullfile(tbl_dir, ['phase6a_outerA_summary_', cfg.ch5.scene_preset, '.txt']);
txt_lines = {
    '=== Chapter 5 Phase 6A OuterA Summary ==='
    ['scene_preset           = ', cfg.ch5.scene_preset]
    ['fit_window_steps       = ', num2str(cfg.ch5.outerA_fit_window_steps)]
    ['horizon_steps          = ', num2str(cfg.ch5.outerA_horizon_steps)]
    ['safe_ratio             = ', num2str(stats.safe_ratio, '%.6f')]
    ['warn_ratio             = ', num2str(stats.warn_ratio, '%.6f')]
    ['trigger_ratio          = ', num2str(stats.trigger_ratio, '%.6f')]
    ['trigger_count          = ', num2str(stats.trigger_count)]
    ['mean_lead_time_steps   = ', num2str(stats.mean_lead_time_steps, '%.6f')]
    ['max_lead_time_steps    = ', num2str(stats.max_lead_time_steps, '%.6f')]
    };
SetTxt(txt_path, txt_lines);

log_path = fullfile(log_dir, ['phase6a_outerA_log_', cfg.ch5.scene_preset, '.txt']);
log_lines = {
    '[INFO] run_ch5_phase6_outerA_rfkoopman started'
    ['[INFO] output_root = ', out_root]
    ['[INFO] scene_preset = ', cfg.ch5.scene_preset]
    ['[INFO] safe_ratio = ', num2str(stats.safe_ratio, '%.6f')]
    ['[INFO] warn_ratio = ', num2str(stats.warn_ratio, '%.6f')]
    ['[INFO] trigger_ratio = ', num2str(stats.trigger_ratio, '%.6f')]
    ['[INFO] trigger_count = ', num2str(stats.trigger_count)]
    ['[INFO] mean_lead_time_steps = ', num2str(stats.mean_lead_time_steps, '%.6f')]
    '[INFO] run_ch5_phase6_outerA_rfkoopman finished'
    };
SetTxt(log_path, log_lines);

mat_path = fullfile(mat_dir, ['phase6a_outerA_', cfg.ch5.scene_preset, '.mat']);
save(mat_path, 'cfg', 'caseData', 'inner', 'resultT', 'phiT', 'outerA', 'stats');

if verbose
    disp('=== Chapter 5 Phase 6A OuterA Summary ===')
    disp(['scene_preset = ', cfg.ch5.scene_preset])
    disp(stats)
    disp(['[phase6a] evidence fig : ', fig_evidence]);
    disp(['[phase6a] quad fig     : ', fig_quad]);
    disp(['[phase6a] text         : ', txt_path]);
    disp(['[phase6a] log          : ', log_path]);
    disp(['[phase6a] mat          : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.evidence_fig = fig_evidence;
out.quadrant_fig = fig_quad;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.outerA = outerA;
out.stats = stats;
end

function SetTxt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
