function out = run_ch5r_phase8_C_outerB_bubble_correction()
%RUN_CH5R_PHASE8_C_OUTERB_BUBBLE_CORRECTION
% R8-C.2 aligned version:
%   align outerB bubble correction with R5-real experimental conditions.
%
% Key changes:
%   - use real ch5case built from the same pipeline as R5-real
%   - use real time-varying pair candidates
%   - use real time-varying satellite positions
%   - preserve requirement-induced Xi_B / tau_B / A_B lexicographic correction logic

cfg = default_ch5r_params(true);
ch5case = build_ch5r_case(cfg);

% basic time axis
if isfield(ch5case, 't_s')
    t_s = ch5case.t_s(:);
else
    error('ch5case.t_s missing.');
end
n_steps = numel(t_s);

% obtain truth state if available
if isfield(ch5case, 'truth')
    truth = ch5case.truth;
else
    truth = struct();
end

% use same requirement bound if available, else fallback
Gamma_req = 1.0e-2;
if isfield(cfg, 'ch5r') && isfield(cfg.ch5r, 'Gamma_req')
    Gamma_req = cfg.ch5r.Gamma_req;
elseif isfield(cfg, 'requirement') && isfield(cfg.requirement, 'Gamma_req')
    Gamma_req = cfg.requirement.Gamma_req;
end

% fallback dynamics/filter constants for now; these are only used as inner-loop placeholders
dt = median(diff(t_s));
if ~isfinite(dt) || dt <= 0
    dt = 1.0;
end
window_len = 8;
lambda_reg = 1e-4;
r_meas = 1.0e-2;
q_pos = 1.0e-4;
q_vel = 1.0e-5;
Cr_mode = 'position';

nx = 6;
ny = 3;

% build a simple aligned truth source:
% prefer case truth if present; otherwise reuse the old synthetic placeholder
use_case_truth = false;
x_truth = [];

if isfield(truth, 'x_truth')
    xt = truth.x_truth;
    if isnumeric(xt) && size(xt,1) == n_steps
        x_truth = xt;
        use_case_truth = true;
    end
elseif isfield(truth, 'x')
    xt = truth.x;
    if isnumeric(xt) && size(xt,1) == n_steps
        x_truth = xt;
        use_case_truth = true;
    end
elseif isfield(ch5case, 'x_truth')
    xt = ch5case.x_truth;
    if isnumeric(xt) && size(xt,1) == n_steps
        x_truth = xt;
        use_case_truth = true;
    end
end

if ~use_case_truth
    x_truth = zeros(n_steps, nx);
    x_truth(1,:) = [0 0 0 1.2 -0.4 0.3];
    for k = 2:n_steps
        ax = 0.02 * sin(0.09 * (k-1));
        ay = 0.016 * cos(0.06 * (k-1));
        az = 0.012 * sin(0.05 * (k-1));
        x_truth(k,4) = x_truth(k-1,4) + dt * ax;
        x_truth(k,5) = x_truth(k-1,5) + dt * ay;
        x_truth(k,6) = x_truth(k-1,6) + dt * az;
        x_truth(k,1:3) = x_truth(k-1,1:3) + dt * x_truth(k,4:6);
    end
end

X_prev = x_truth(1:end-1,:).';
X_next = x_truth(2:end,:).';
model = fit_local_dmd_operator_reg(X_prev, X_next, 'lambda_reg', lambda_reg);

Q = diag([q_pos q_pos q_pos q_vel q_vel q_vel]);
R_single = r_meas * eye(ny);
h_fun = @(x) x(1:3);
H_fun = @(x) [eye(3), zeros(3,3)];
Cr = build_requirement_projection_Cr(nx, Cr_mode);

x0_est = x_truth(1,:).' + [0.05; -0.04; 0.03; 0.01; -0.01; 0.02];
P0 = diag([1e-2 1e-2 1e-2 1e-3 1e-3 1e-3]);
fs = package_filter_state(x0_est, P0);

n_eval = n_steps - 1;
trace_data = struct();
trace_data.selected_pair = zeros(n_eval, 2);
trace_data.Xi_B = zeros(n_eval, 1);
trace_data.R_B = zeros(n_eval, 1);
trace_data.tau_B_time_s = inf(n_eval, 1);
trace_data.A_B = zeros(n_eval, 1);
trace_data.is_bubble = false(n_eval, 1);
trace_data.switch_cost = zeros(n_eval, 1);
trace_data.M_G = zeros(n_eval, 1);
trace_data.nPairs = zeros(n_eval, 1);

prev_pair = [];

rng(1);
for k = 2:n_steps
    pred = predict_filter_state(fs, model, Q);

    yk = x_truth(k,1:3).' + chol(R_single, 'lower') * randn(ny,1);
    upd = update_filter_state_ekf(pred, yk, h_fun, H_fun, R_single);

    pair_bank_k = resolve_ch5case_pair_bank(ch5case, k);
    sat_pos_k = resolve_ch5case_sat_positions(ch5case, k);

    sel = select_pair_bubble_correction( ...
        upd.x_plus, upd.P_plus, pair_bank_k, sat_pos_k, model, Q, H_fun, R_single, Cr, ...
        Gamma_req, dt, window_len, prev_pair);

    idx = k - 1;
    trace_data.selected_pair(idx,:) = sel.best_pair;
    trace_data.Xi_B(idx) = sel.best_eval.Xi_B;
    trace_data.R_B(idx) = sel.best_eval.R_B;
    trace_data.tau_B_time_s(idx) = sel.best_eval.tau_B_time_s;
    trace_data.A_B(idx) = sel.best_eval.A_B;
    trace_data.is_bubble(idx) = sel.best_eval.is_bubble;
    trace_data.switch_cost(idx) = sel.best_eval.switch_cost;
    trace_data.M_G(idx) = sel.best_eval.M_G;
    trace_data.nPairs(idx) = size(pair_bank_k, 1);

    prev_pair = sel.best_pair;
    fs = package_filter_state(upd.x_plus, upd.P_plus);

    if mod(k, 20) == 0 || k == 2 || k == n_steps
        fprintf('[R8-C.2][k=%d/%d] nPairs=%d pair=[%d %d] Xi_B=%.6g tau_B=%s A_B=%.6g\n', ...
            idx, n_eval, trace_data.nPairs(idx), ...
            trace_data.selected_pair(idx,1), trace_data.selected_pair(idx,2), ...
            trace_data.Xi_B(idx), local_num_or_inf(trace_data.tau_B_time_s(idx)), trace_data.A_B(idx));
    end
end

summary = struct();
summary.n_steps = n_steps;
summary.mean_Xi_B = mean(trace_data.Xi_B);
summary.mean_R_B = mean(trace_data.R_B);
summary.mean_tau_B_time_s = mean(trace_data.tau_B_time_s(isfinite(trace_data.tau_B_time_s)));
summary.has_failure_fraction = mean(isfinite(trace_data.tau_B_time_s));
summary.mean_A_B = mean(trace_data.A_B);
summary.bubble_steps = sum(trace_data.is_bubble);
summary.bubble_fraction = mean(trace_data.is_bubble);
summary.switch_count = sum(trace_data.switch_cost > 0);
summary.mean_M_G = mean(trace_data.M_G);
summary.mean_nPairs = mean(trace_data.nPairs);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_C_outerB_bubble_correction_aligned');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_C_outerB_bubble_correction_aligned_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR8_C_outerB_bubble_correction_aligned_' stamp '.md']);
fig1_file = fullfile(out_dir, ['plot_phaseR8_C2_XiB_' stamp '.png']);
fig2_file = fullfile(out_dir, ['plot_phaseR8_C2_tauB_' stamp '.png']);
fig3_file = fullfile(out_dir, ['plot_phaseR8_C2_pairs_' stamp '.png']);

k_idx = (1:n_eval).';
fig1 = plot_requirement_margin_forecast(k_idx, trace_data.Xi_B, 'off');
saveas(fig1, fig1_file);
close(fig1);

fig2 = plot_tauB_timeline(k_idx, trace_data.tau_B_time_s, 'off');
saveas(fig2, fig2_file);
close(fig2);

fig3 = plot_pair_selection_timeline(k_idx, trace_data.selected_pair, 'off');
saveas(fig3, fig3_file);
close(fig3);

save(mat_file, 'cfg', 'ch5case', 'x_truth', 'trace_data', 'summary');

md = local_build_md(summary, mat_file, fig1_file, fig2_file, fig3_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8-C.2] outerB bubble correction aligned-to-R5 summary ===')
disp(summary)
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])
disp(['fig1 file            : ' fig1_file])
disp(['fig2 file            : ' fig2_file])
disp(['fig3 file            : ' fig3_file])

out = struct();
out.cfg = cfg;
out.case = ch5case;
out.trace_data = trace_data;
out.summary = summary;
out.paths = struct( ...
    'mat_file', mat_file, ...
    'md_file', md_file, ...
    'fig1_file', fig1_file, ...
    'fig2_file', fig2_file, ...
    'fig3_file', fig3_file, ...
    'output_dir', out_dir);
out.ok = true;
end

function s = local_num_or_inf(v)
if isfinite(v)
    s = num2str(v, '%.6g');
else
    s = 'inf';
end
end

function md = local_build_md(summary, mat_file, fig1_file, fig2_file, fig3_file)
lines = {};
lines{end+1} = '# Phase R8-C.2 outerB bubble correction aligned to R5 conditions';
lines{end+1} = '';
fns = fieldnames(summary);
for i = 1:numel(fns)
    v = summary.(fns{i});
    if isnumeric(v) && isscalar(v)
        if isfinite(v)
            lines{end+1} = ['- ', fns{i}, ' = ', num2str(v, '%.12g')];
        else
            lines{end+1} = ['- ', fns{i}, ' = inf'];
        end
    end
end
lines{end+1} = '';
lines{end+1} = ['- mat file: `', mat_file, '`'];
lines{end+1} = ['- fig1 file: `', fig1_file, '`'];
lines{end+1} = ['- fig2 file: `', fig2_file, '`'];
lines{end+1} = ['- fig3 file: `', fig3_file, '`'];
md = strjoin(lines, newline);
end
