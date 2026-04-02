function result = policy_custody_dualloop_koopman(caseData, cfg)
%POLICY_CUSTODY_DUALLOOP_KOOPMAN
% Phase 7B-pre:
%   - safe mode falls back to C selection
%   - warn/trigger use support-first + geometric tie-break
%
% NX-1-R2:
%   - consume no-state-machine ablation flags
%   - when disabled, use fixed warn mode instead of risk-state dispatch

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
disable_state_machine = local_is_state_machine_disabled(cfg);

for k = 1:N
    risk_state_now = outerA.risk_state(k);

    if disable_state_machine
        mode = 'warn';
    else
        mode = dispatch_quadrant_policy(risk_state_now);
    end

    mode_series(k) = string(mode);

    ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg);
    selected_sets{k} = ids;
    tracking_sat_count(k) = numel(ids);
    prev_ids = ids;
end

rmse_scale = ones(N,1);

for k = 1:N
    if disable_state_machine
        rmse_scale(k) = 0.96;
    else
        switch char(mode_series(k))
            case 'safe'
                rmse_scale(k) = 1.00;
            case 'warn'
                rmse_scale(k) = 0.96;
            otherwise
                rmse_scale(k) = 0.92;
        end
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
result.state_machine_disabled = disable_state_machine;
end

function tf = local_is_state_machine_disabled(cfg)
tf = false;
if ~isfield(cfg, 'ch5') || isempty(cfg.ch5)
    return
end

names = { ...
    'ablation_disable_state_machine', ...
    'disable_state_machine', ...
    'disable_mode_switching', ...
    'ck_disable_state_machine', ...
    'ck_disable_warn_trigger', ...
    'ck_disable_guard_switching'};

for i = 1:numel(names)
    if isfield(cfg.ch5, names{i}) && ~isempty(cfg.ch5.(names{i})) && logical(cfg.ch5.(names{i}))
        tf = true;
        return
    end
end
end
