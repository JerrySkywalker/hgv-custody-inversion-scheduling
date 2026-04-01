function [score, detail] = build_window_objective_dualloop(mode, selected_ids, prev_ids, ref_ids, caseData, k, cfg)
%BUILD_WINDOW_OBJECTIVE_DUALLOOP
% Custody-structure-constrained outerB scoring.
%
% Lower score is better.

if isempty(selected_ids)
    score = inf;
    detail = struct();
    return;
end

d = compute_support_window_proxy_dualloop(caseData, selected_ids, k, cfg);

if nargin < 4 || isempty(ref_ids)
    d_base = 0;
else
    d_base = numel(setxor(selected_ids(:).', ref_ids(:).')) / max(1, cfg.ch5.max_track_sats);
end

if nargin < 3 || isempty(prev_ids)
    c_switch = 0;
else
    c_switch = numel(setxor(selected_ids(:).', prev_ids(:).')) / max(1, cfg.ch5.max_track_sats);
end

long_single = d.longest_single_support_steps / max(1, cfg.ch5.window_steps);
long_zero = d.longest_zero_support_steps / max(1, cfg.ch5.window_steps);

switch mode
    case 'safe'
        w_dual = cfg.ch5.ck_safe_dual_weight;
        w_single = cfg.ch5.ck_safe_single_weight;
        w_zero = cfg.ch5.ck_safe_zero_weight;
        w_lsingle = cfg.ch5.ck_safe_longest_single_weight;
        w_lzero = cfg.ch5.ck_safe_longest_zero_weight;
        w_base = cfg.ch5.ck_safe_base_weight;
        w_sw = cfg.ch5.ck_safe_switch_weight;
    case 'warn'
        w_dual = cfg.ch5.ck_warn_dual_weight;
        w_single = cfg.ch5.ck_warn_single_weight;
        w_zero = cfg.ch5.ck_warn_zero_weight;
        w_lsingle = cfg.ch5.ck_warn_longest_single_weight;
        w_lzero = cfg.ch5.ck_warn_longest_zero_weight;
        w_base = cfg.ch5.ck_warn_base_weight;
        w_sw = cfg.ch5.ck_warn_switch_weight;
    otherwise
        w_dual = cfg.ch5.ck_trigger_dual_weight;
        w_single = cfg.ch5.ck_trigger_single_weight;
        w_zero = cfg.ch5.ck_trigger_zero_weight;
        w_lsingle = cfg.ch5.ck_trigger_longest_single_weight;
        w_lzero = cfg.ch5.ck_trigger_longest_zero_weight;
        w_base = cfg.ch5.ck_trigger_base_weight;
        w_sw = cfg.ch5.ck_trigger_switch_weight;
end

score = ...
    - w_dual * d.dual_support_ratio ...
    + w_single * d.single_support_ratio ...
    + w_zero * d.zero_support_ratio ...
    + w_lsingle * long_single ...
    + w_lzero * long_zero ...
    + w_base * d_base ...
    + w_sw * c_switch;

detail = d;
detail.d_base = d_base;
detail.c_switch = c_switch;
detail.mode = mode;
end
