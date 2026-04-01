function [score, detail] = build_window_objective_dualloop(mode, selected_ids, prev_ids, ref_ids, caseData, k, cfg)
%BUILD_WINDOW_OBJECTIVE_DUALLOOP
% Custody-structure-constrained outerB scoring with formal geometry terms
% plus optional Phase08 continuous prior penalty.
%
% Lower score is better.

if isempty(selected_ids)
    score = inf;
    detail = struct();
    detail.mode = mode;
    detail.is_feasible = false;
    detail.gate_reason = "empty_selected_ids";
    detail.score_ck_base = inf;
    detail.score_total = inf;
    detail.prior_cost_used = 0.0;
    detail.prior_region_id = "";
    detail.prior_M_G_center = NaN;
    detail.baseline_km = NaN;
    detail.fragility_score = NaN;
    return;
end

d = compute_support_window_proxy_dualloop(caseData, selected_ids, k, cfg);
g = compute_geometry_tiebreak_dualloop(caseData, selected_ids, k, cfg);

if nargin < 4 || isempty(ref_ids)
    d_base = 0.0;
else
    d_base = compute_prior_deviation_cost(selected_ids, ref_ids, cfg);
end

if nargin < 3 || isempty(prev_ids)
    c_switch = 0.0;
else
    c_switch = numel(setxor(selected_ids(:).', prev_ids(:).')) / max(1, numel(union(selected_ids(:).', prev_ids(:).')));
end

[is_ok, gate_reason] = is_support_pattern_feasible_dualloop(mode, d, cfg);

long_single = d.longest_single_support_steps / max(1, cfg.ch5.window_steps);
long_zero   = d.longest_zero_support_steps   / max(1, cfg.ch5.window_steps);

switch mode
    case 'safe'
        w_dual = cfg.ch5.ck_safe_dual_weight;
        w_single = cfg.ch5.ck_safe_single_weight;
        w_zero = cfg.ch5.ck_safe_zero_weight;
        w_switch = cfg.ch5.ck_safe_switch_weight;
        w_base = cfg.ch5.ck_safe_base_weight;
        w_geom_lambda = 0.0;
        w_geom_angle = 0.0;

    case 'warn'
        w_dual = cfg.ch5.ck_warn_dual_weight;
        w_single = cfg.ch5.ck_warn_single_weight;
        w_zero = cfg.ch5.ck_warn_zero_weight;
        w_switch = cfg.ch5.ck_warn_switch_weight;
        w_base = cfg.ch5.ck_warn_base_weight;
        w_geom_lambda = cfg.ch5.ck_warn_geom_lambda_weight;
        w_geom_angle = cfg.ch5.ck_warn_geom_angle_weight;

    case 'trigger'
        w_dual = cfg.ch5.ck_trigger_dual_weight;
        w_single = cfg.ch5.ck_trigger_single_weight;
        w_zero = cfg.ch5.ck_trigger_zero_weight;
        w_switch = cfg.ch5.ck_trigger_switch_weight;
        w_base = cfg.ch5.ck_trigger_base_weight;
        w_geom_lambda = cfg.ch5.ck_trigger_geom_lambda_weight;
        w_geom_angle = cfg.ch5.ck_trigger_geom_angle_weight;

    otherwise
        error('Unknown mode: %s', char(mode));
end

score_ck_base = ...
    - w_dual   * d.dual_support_ratio ...
    + w_single * d.single_support_ratio ...
    + w_zero   * d.zero_support_ratio ...
    + w_switch * c_switch ...
    + w_base   * d_base ...
    + 0.5 * long_single ...
    + 1.0 * long_zero ...
    - w_geom_lambda * g.lambda_min_geom ...
    - w_geom_angle  * (g.min_crossing_angle_deg / 90.0);

if ~is_ok
    score_ck_base = score_ck_base + cfg.ch5.ck_gate_penalty;
end

prior_cost_used = 0.0;
prior_region_id = "";
prior_M_G_center = NaN;
prior_detail = struct();
baseline_km = NaN;
fragility_score = NaN;

prior_enable = false;
if isfield(cfg, 'ch5') && isfield(cfg.ch5, 'continuous_prior_enable') && cfg.ch5.continuous_prior_enable
    prior_enable = true;
end

if prior_enable
    prior_cfg = default_phase8_continuous_prior_config();

    if isfield(cfg.ch5, 'continuous_prior_mode')
        prior_cfg.mode = cfg.ch5.continuous_prior_mode;
    else
        prior_cfg.mode = prior_cfg.default_mode;
    end

    if isfield(cfg.ch5, 'continuous_prior_w_prior')
        prior_cfg.w_prior = cfg.ch5.continuous_prior_w_prior;
    end
    if isfield(cfg.ch5, 'continuous_prior_wf')
        prior_cfg.weights.wf = cfg.ch5.continuous_prior_wf;
    end
    if isfield(cfg.ch5, 'continuous_prior_wb')
        prior_cfg.weights.wb = cfg.ch5.continuous_prior_wb;
    end
    if isfield(cfg.ch5, 'continuous_prior_wr')
        prior_cfg.weights.wr = cfg.ch5.continuous_prior_wr;
    end

    cand_prior = build_phase8_continuous_prior_candidate(caseData, selected_ids, k, cfg, g);
    out_prior = score_candidate_with_continuous_prior(0.0, cand_prior, prior_cfg);

    prior_cost_used = out_prior.prior_cost_used;
    prior_region_id = string(out_prior.prior.region_id);
    prior_M_G_center = out_prior.prior.M_G_center;
    prior_detail = out_prior.detail;

    if isfield(cand_prior, 'baseline_km')
        baseline_km = cand_prior.baseline_km;
    end
    if isfield(out_prior.prior, 'fragility_score')
        fragility_score = out_prior.prior.fragility_score;
    end

    score = score_ck_base + prior_cfg.w_prior * prior_cost_used;
else
    score = score_ck_base;
end

detail = struct();
detail.mode = mode;
detail.is_feasible = is_ok;
detail.gate_reason = gate_reason;

detail.dual_support_ratio = d.dual_support_ratio;
detail.single_support_ratio = d.single_support_ratio;
detail.zero_support_ratio = d.zero_support_ratio;
detail.longest_single_support_steps = d.longest_single_support_steps;
detail.longest_zero_support_steps = d.longest_zero_support_steps;

detail.lambda_min_geom = g.lambda_min_geom;
detail.mean_trace_geom = g.mean_trace_geom;
detail.min_crossing_angle_deg = g.min_crossing_angle_deg;

detail.base_deviation = d_base;
detail.switch_cost = c_switch;

detail.score_ck_base = score_ck_base;
detail.prior_cost_used = prior_cost_used;
detail.prior_region_id = prior_region_id;
detail.prior_M_G_center = prior_M_G_center;
detail.prior_detail = prior_detail;
detail.baseline_km = baseline_km;
detail.fragility_score = fragility_score;

detail.score_total = score;

% candidate-level diff logging
if isfield(cfg, 'ch5') && isfield(cfg.ch5, 'continuous_prior_debug_enable') && cfg.ch5.continuous_prior_debug_enable
    rec = struct();
    rec.k = k;
    rec.mode = mode;
    rec.selected_ids = selected_ids;
    rec.score_ck_base = score_ck_base;
    rec.prior_cost_used = prior_cost_used;
    rec.score_total = score;
    rec.prior_region_id = prior_region_id;
    rec.prior_M_G_center = prior_M_G_center;
    rec.lambda_min_geom = g.lambda_min_geom;
    rec.min_crossing_angle_deg = g.min_crossing_angle_deg;
    rec.baseline_km = baseline_km;
    rec.fragility_score = fragility_score;
    rec.gate_reason = gate_reason;
    rec.is_feasible = is_ok;
    append_phase8_candidate_diff_log(cfg, rec);
end
end
