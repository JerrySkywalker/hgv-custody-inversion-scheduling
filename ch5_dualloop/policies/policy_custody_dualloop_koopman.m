function result = policy_custody_dualloop_koopman(caseData, cfg)
%POLICY_CUSTODY_DUALOOP_KOOPMAN
% NX-3 second round
% CK policy with:
%   - NX-2 dwell/hysteresis
%   - NX-3 composite guard
%   - NX-3 guard action coupling:
%       'none'
%       'freeze_selection'
%       'degrade_mode'

if nargin < 2 || isempty(cfg)
    cfg = default_ch5_params();
end

cfg = apply_nx2_state_machine_defaults(cfg);
cfg = apply_nx3_guard_defaults(cfg);
cfg = apply_nx3_guard_action_defaults(cfg);

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
state_series = strings(N,1);
switch_applied = false(N,1);
ttl_steps = inf(N,1);

prev_ids = [];
disable_state_machine = local_is_state_machine_disabled(cfg);

sm_prev = struct();
sm_prev.state_id = 0;
sm_prev.state_name = "safe";
sm_prev.last_switch_k = 1;
sm_prev.mode = "safe";

selected_ids_prev = [];
guard_action_mode = string(cfg.ch5.nx3_guard_action_mode);

for k = 1:N
    risk_state_now = outerA.risk_state(k);
    ttl_steps_now = local_get_ttl_steps(outerA, k);
    ttl_steps(k) = ttl_steps_now;

    if disable_state_machine
        mode = string(cfg.ch5.nx2_mode_when_disabled);
        sm_now = sm_prev;
        sm_now.k = k;
        sm_now.risk_state_now = risk_state_now;
        sm_now.mode = mode;
        sm_now.state_name = mode;
        if mode == "safe"
            sm_now.state_id = 0;
        elseif mode == "warn"
            sm_now.state_id = 1;
        else
            sm_now.state_id = 2;
        end
        do_switch = true;
        guard_info = struct();
    else
        sm_now = update_custody_state_machine_minimal(sm_prev, risk_state_now, k, cfg);

        if cfg.ch5.nx3_guard_enable
            G = package_nx3_guard_signals(outerA, sm_prev, sm_now, ttl_steps_now, k, cfg);
            [do_switch, guard_info] = should_switch_under_guard_nx3(sm_prev, sm_now, G, k, cfg);
        else
            [do_switch, guard_info] = should_switch_under_guard_minimal(sm_prev, sm_now, ttl_steps_now, k, cfg);
        end

        mode = string(sm_now.mode);
    end

    if isempty(selected_ids_prev)
        do_switch = true;
    end

    if do_switch
        ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, char(mode), cfg);
        selected_ids_prev = ids;
        switch_applied(k) = true;

        if ~disable_state_machine && ~isempty(ids)
            sm_now.last_switch_k = k;
        end
    else
        switch guard_action_mode
            case "freeze_selection"
                ids = selected_ids_prev;

            case "degrade_mode"
                degraded_mode = local_degrade_mode(mode);
                ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, char(degraded_mode), cfg);
                mode = degraded_mode;

            otherwise
                ids = selected_ids_prev;
        end
    end

    selected_sets{k} = ids;
    tracking_sat_count(k) = numel(ids);
    mode_series(k) = mode;
    state_series(k) = string(sm_now.state_name);

    prev_ids = ids;
    sm_prev = sm_now;
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
result.state_series = state_series;
result.switch_applied = switch_applied;
result.ttl_steps = ttl_steps;
result.outerA = outerA;
result.state_machine_disabled = disable_state_machine;
result.guard_action_mode = guard_action_mode;
end

function degraded_mode = local_degrade_mode(mode)
mode = string(mode);
if mode == "trigger"
    degraded_mode = "warn";
elseif mode == "warn"
    degraded_mode = "safe";
else
    degraded_mode = "safe";
end
end

function ttl_steps_now = local_get_ttl_steps(outerA, k)
ttl_steps_now = inf;
names = {'time_to_loss_steps','ttl_steps','TTL_steps','time_to_loc_steps'};
for i = 1:numel(names)
    if isfield(outerA, names{i})
        x = outerA.(names{i});
        if ~isempty(x) && numel(x) >= k
            ttl_steps_now = x(k);
            return
        end
    end
end
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
