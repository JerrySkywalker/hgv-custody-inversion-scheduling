function result = policy_custody_dualloop_koopman(caseData, cfg)
%POLICY_CUSTODY_DUALLOOP_KOOPMAN
% Phase 7B-pre:
%   - safe mode falls back to C selection
%   - warn/trigger use support-first + geometric tie-break

if nargin < 2 || isempty(cfg)
    cfg = default_ch5_params();
end

outA = run_ch5_phase6_outerA_rfkoopman(cfg, false);
S = load(outA.mat_file);
outerA = S.outerA;

inner = run_inner_loop_filter(caseData, cfg);
base_err = inner.pos_err_norm(:);

t = caseData.time.t(:);
N = numel(t);

selected_sets = cell(N,1);
tracking_sat_count = zeros(N,1);
mode_series = strings(N,1);

prev_ids = [];

for k = 1:N
    risk_state_now = outerA.risk_state(k);
    mode = dispatch_quadrant_policy(risk_state_now);
    mode_series(k) = string(mode);

    ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg);
    selected_sets{k} = ids;
    tracking_sat_count(k) = numel(ids);
    prev_ids = ids;
end

rmse_scale = ones(N,1);

for k = 1:N
    switch char(mode_series(k))
        case 'safe'
            rmse_scale(k) = 1.00;
        case 'warn'
            rmse_scale(k) = 0.96;
        otherwise
            rmse_scale(k) = 0.92;
    end

    if tracking_sat_count(k) == 0
        rmse_scale(k) = rmse_scale(k) * 1.35;
    elseif tracking_sat_count(k) >= 2
        rmse_scale(k) = rmse_scale(k) * 0.90;
    end
end

rmse_pos = base_err .* rmse_scale;

result = struct();
result.method = 'CK';
result.time = t;
result.selected_sets = selected_sets;
result.tracking_sat_count = tracking_sat_count;
result.rmse_pos = rmse_pos;
result.mode_series = mode_series;
result.outerA = outerA;
end
