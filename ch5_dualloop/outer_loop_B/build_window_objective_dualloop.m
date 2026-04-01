function score = build_window_objective_dualloop(mode, selected_ids, prev_ids, caseData, k, cfg)
%BUILD_WINDOW_OBJECTIVE_DUALLOOP  Mode-dependent CK scoring for one candidate set.

cand_mask = caseData.candidates.visible_mask;
N = size(cand_mask, 1);
H = cfg.ch5.window_steps;

num_sel = numel(selected_ids);
if num_sel == 0
    score = inf;
    return;
end

% RMSE proxy: more selected sats => lower proxy
rmse_proxy = 1 / num_sel;

% Future phi proxy: encourage selected sats that remain visible in near future
future_end = min(N, k + H - 1);
future_vis = cand_mask(k:future_end, selected_ids);
phi_proxy = 1 - mean(future_vis(:));

% Switch penalty
if nargin < 3 || isempty(prev_ids)
    switch_penalty = 0;
else
    switch_penalty = numel(setxor(selected_ids(:).', prev_ids(:).')) / max(1, cfg.ch5.max_track_sats);
end

switch mode
    case 'safe'
        w_sw = cfg.ch5.ck_safe_switch_weight;
        w_rm = cfg.ch5.ck_safe_rmse_weight;
        w_ph = cfg.ch5.ck_safe_phi_weight;
    case 'warn'
        w_sw = cfg.ch5.ck_warn_switch_weight;
        w_rm = cfg.ch5.ck_warn_rmse_weight;
        w_ph = cfg.ch5.ck_warn_phi_weight;
    otherwise
        w_sw = cfg.ch5.ck_trigger_switch_weight;
        w_rm = cfg.ch5.ck_trigger_rmse_weight;
        w_ph = cfg.ch5.ck_trigger_phi_weight;
end

score = w_rm * rmse_proxy + w_ph * phi_proxy + w_sw * switch_penalty;
end
