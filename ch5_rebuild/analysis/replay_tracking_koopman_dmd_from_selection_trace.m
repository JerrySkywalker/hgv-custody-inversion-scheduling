function out = replay_tracking_koopman_dmd_from_selection_trace(ch5case, selection_trace, tag)
%REPLAY_TRACKING_KOOPMAN_DMD_FROM_SELECTION_TRACE
% R8-D.1 replay with NIS computation added on top of the current repeatable mainline.
%
% Fixed truth source:
%   truth.X only

assert(isstruct(ch5case), 'ch5case must be struct.');
assert(iscell(selection_trace), 'selection_trace must be cell.');

Nt = numel(selection_trace);
assert(Nt >= 2, 'selection_trace too short.');

[x_truth, truth_source] = local_resolve_truth_fixed(ch5case);
if size(x_truth,1) ~= Nt
    error('Truth trajectory length does not match selection_trace.');
end

X_prev = x_truth(1:end-1,:).';
X_next = x_truth(2:end,:).';
model = fit_local_dmd_operator_reg(X_prev, X_next, 'lambda_reg', 1e-4);

Q = diag([1e-4 1e-4 1e-4 1e-5 1e-5 1e-5]);
H = [eye(3), zeros(3,3)];
Cr = build_requirement_projection_Cr(6, 'position');

x_pred = zeros(Nt, 6);
x_post = zeros(Nt, 6);
P_pred = zeros(6,6,Nt);
P_post = zeros(6,6,Nt);

pos_err_norm = zeros(Nt,1);
rmse_single = zeros(Nt,1);
key_abs_supp = zeros(Nt,1);
key_rel_supp = zeros(Nt,1);
lambda_max_pred = zeros(Nt,1);
lambda_key_post = zeros(Nt,1);

nis_series = NaN(Nt,1);
nis_ok_mask = false(Nt,1);

m_meas = 3;
alpha = 0.05;
nis_lower = chi2inv(alpha/2, m_meas);
nis_upper = chi2inv(1-alpha/2, m_meas);

x_post(1,:) = x_truth(1,:) + [0.05 -0.04 0.03 0.01 -0.01 0.02];
P_post(:,:,1) = diag([1e-2 1e-2 1e-2 1e-3 1e-3 1e-3]);

eps_reg = 1e-9;

for k = 2:Nt
    F = model.A;

    x_minus = (F * x_post(k-1,:).').';
    P_minus = F * P_post(:,:,k-1) * F.' + Q;
    P_minus = 0.5 * (P_minus + P_minus.');

    x_pred(k,:) = x_minus;
    P_pred(:,:,k) = P_minus;

    J_pair = zeros(3,3);
    if isstruct(selection_trace{k}) && isfield(selection_trace{k}, 'J_pair') && ~isempty(selection_trace{k}.J_pair)
        J_pair = selection_trace{k}.J_pair;
    end

    R_eq = inv(J_pair + eps_reg * eye(3));
    yk = x_truth(k,1:3).';

    innov = yk - H * x_minus.';
    S = H * P_minus * H.' + R_eq;

    nis_k = innov.' * (S \ innov);
    nis_series(k) = nis_k;
    nis_ok_mask(k) = (nis_k >= nis_lower) && (nis_k <= nis_upper);

    K = (P_minus * H.') / S;

    x_plus = x_minus.' + K * innov;
    I = eye(6);
    P_plus = (I - K*H) * P_minus * (I - K*H).' + K * R_eq * K.';
    P_plus = 0.5 * (P_plus + P_plus.');

    x_post(k,:) = x_plus.';
    P_post(:,:,k) = P_plus;

    e = x_plus(1:3) - yk;
    pos_err_norm(k) = norm(e, 2);
    rmse_single(k) = sqrt((e.' * e) / 3);

    PR_minus = compute_requirement_cov_PR(P_minus, Cr);
    PR_plus  = compute_requirement_cov_PR(P_plus, Cr);
    [V,D] = eig(0.5*(PR_minus+PR_minus.'));
    lam = real(diag(D));
    [lam_max, idx_max] = max(lam);
    u = V(:, idx_max);

    lambda_max_pred(k) = lam_max;
    lambda_key_post(k) = u.' * PR_plus * u;
    key_abs_supp(k) = lam_max - lambda_key_post(k);
    if lam_max > 0
        key_rel_supp(k) = 1 - lambda_key_post(k) / lam_max;
    else
        key_rel_supp(k) = 0;
    end
end

summary = struct();
summary.tag = tag;
summary.truth_source = truth_source;
summary.mean_pos_err_norm = mean(pos_err_norm(2:end), 'omitnan');
summary.mean_rmse_single = sqrt(mean(rmse_single(2:end).^2, 'omitnan'));
summary.mean_key_abs_supp = mean(key_abs_supp(2:end), 'omitnan');
summary.mean_key_rel_supp = mean(key_rel_supp(2:end), 'omitnan');

summary.nis_lower = nis_lower;
summary.nis_upper = nis_upper;
summary.mean_nis = mean(nis_series(2:end), 'omitnan');
summary.nis_ok_ratio = mean(nis_ok_mask(2:end), 'omitnan');
summary.nis_low_ratio = mean(nis_series(2:end) < nis_lower, 'omitnan');
summary.nis_high_ratio = mean(nis_series(2:end) > nis_upper, 'omitnan');

out = struct();
out.tag = tag;
out.x_truth = x_truth;
out.state_pred = x_pred;
out.state_post = x_post;
out.P_pred = P_pred;
out.P_post = P_post;
out.pos_err_norm = pos_err_norm;
out.rmse_single = rmse_single;
out.key_abs_supp = key_abs_supp;
out.key_rel_supp = key_rel_supp;
out.lambda_max_pred = lambda_max_pred;
out.lambda_key_post = lambda_key_post;
out.nis_series = nis_series;
out.nis_ok_mask = nis_ok_mask;
out.summary = summary;
end

function [x_truth, source_name] = local_resolve_truth_fixed(ch5case)
if isfield(ch5case, 'truth') && isfield(ch5case.truth, 'X') && ~isempty(ch5case.truth.X)
    X = ch5case.truth.X;
    assert(isnumeric(X) && size(X,2) >= 6, 'truth.X exists but is not a valid [Nt x >=6] state array.');
    x_truth = X(:,1:6);
    source_name = 'truth.X';
    return;
end

error(['Fixed truth source mode requires ch5case.truth.X. ', ...
       'No fallback to x_truth/x/r_eci_km is allowed in R8-D.1.']);
end
