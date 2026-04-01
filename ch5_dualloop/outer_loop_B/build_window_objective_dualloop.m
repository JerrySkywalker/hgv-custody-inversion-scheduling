function [score, detail] = build_window_objective_dualloop(mode, selected_ids, prev_ids, ref_ids, caseData, k, cfg)
%BUILD_WINDOW_OBJECTIVE_DUALLOOP
% Worst-window-oriented outerB scoring.
%
% Lower score is better.

if isempty(selected_ids)
    score = inf;
    detail = struct();
    return;
end

d = compute_phi_window_proxy_dualloop(caseData, selected_ids, k, cfg);

% Reference deviation
if nargin < 4 || isempty(ref_ids)
    d_base = 0;
else
    d_base = numel(setxor(selected_ids(:).', ref_ids(:).')) / max(1, cfg.ch5.max_track_sats);
end

% Switching cost
if nargin < 3 || isempty(prev_ids)
    c_switch = 0;
else
    c_switch = numel(setxor(selected_ids(:).', prev_ids(:).')) / max(1, cfg.ch5.max_track_sats);
end

switch mode
    case 'safe'
        w_min = cfg.ch5.ck_safe_phi_min_weight;
        w_avg = cfg.ch5.ck_safe_phi_avg_weight;
        w_out = cfg.ch5.ck_safe_outage_weight;
        w_long = cfg.ch5.ck_safe_longest_weight;
        w_base = cfg.ch5.ck_safe_base_weight;
        w_sw = cfg.ch5.ck_safe_switch_weight;
    case 'warn'
        w_min = cfg.ch5.ck_warn_phi_min_weight;
        w_avg = cfg.ch5.ck_warn_phi_avg_weight;
        w_out = cfg.ch5.ck_warn_outage_weight;
        w_long = cfg.ch5.ck_warn_longest_weight;
        w_base = cfg.ch5.ck_warn_base_weight;
        w_sw = cfg.ch5.ck_warn_switch_weight;
    otherwise
        w_min = cfg.ch5.ck_trigger_phi_min_weight;
        w_avg = cfg.ch5.ck_trigger_phi_avg_weight;
        w_out = cfg.ch5.ck_trigger_outage_weight;
        w_long = cfg.ch5.ck_trigger_longest_weight;
        w_base = cfg.ch5.ck_trigger_base_weight;
        w_sw = cfg.ch5.ck_trigger_switch_weight;
end

long_norm = d.longest_outage_steps / max(1, cfg.ch5.window_steps);

score = ...
    - w_min * d.phi_min ...
    - w_avg * d.phi_avg ...
    + w_out * d.outage_ratio ...
    + w_long * long_norm ...
    + w_base * d_base ...
    + w_sw * c_switch;

detail = d;
detail.d_base = d_base;
detail.c_switch = c_switch;
detail.mode = mode;
end
