function refine_out = stage13_refine_dg_first_probe(cfg, stage13_out)
%STAGE13_REFINE_DG_FIRST_PROBE Optional Stage13.6 refined-search entry.

cfg = stage13_default_config(cfg);

refine_out = struct();
refine_out.enabled = logical(cfg.stage13.dg_refine.enable);
refine_out.seed_case = string(cfg.stage13.dg_refine.seed_case);
refine_out.status = "disabled";
refine_out.plan = table();
refine_out.summary = table();
refine_out.recommended_case = "";
refine_out.figures = struct();
refine_out.evaluations = struct([]);
refine_out.micro = struct();

if ~refine_out.enabled
    return;
end

refine_out.status = "pending";
if nargin >= 2 && isstruct(stage13_out)
    refine_out.source_summary = stage13_out.summary;
end

refine_plan = stage13_build_family_dg_first_refine(cfg, stage13_out, cfg.stage13.dg_refine.seed_case);
refine_out.plan = refine_plan.candidate_table;
refine_out.candidates = refine_plan.candidates;
refine_out.seed_case_id = refine_plan.seed_case_id;
refine_out.status = "plan_ready";

if isfield(stage13_out, 'paths') && isfield(stage13_out.paths, 'dg_refined_plan_csv')
    writetable(refine_out.plan, stage13_out.paths.dg_refined_plan_csv);
end

signature_rows = table('Size', [0 14], ...
    'VariableTypes', {'string', 'string', 'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'logical', 'string', 'string'}, ...
    'VariableNames', {'case_tag', 'case_id', 'family', 'case_family', 'D_G_worst', 'D_A_worst', 'D_T_worst', 'D_T_bar_worst', ...
    't0G_star', 't0A_star', 't0T_star', 'feasible_truth', 'active_constraint', 'summary_tag'});
refine_evals = repmat(struct('candidate', struct(), 'scan_out', struct(), 'signature', struct()), numel(refine_plan.candidates), 1);

for k = 1:numel(refine_plan.candidates)
    refine_evals(k) = stage13_evaluate_candidate(cfg, refine_plan.candidates(k), stage13_out.paths);
    sig = refine_evals(k).signature;
    signature_rows = [signature_rows; {sig.case_tag, sig.case_id, sig.family, sig.case_family, sig.D_G_worst, sig.D_A_worst, ... %#ok<AGROW>
        sig.D_T_worst, sig.D_T_bar_worst, sig.t0G_star, sig.t0A_star, sig.t0T_star, ...
        sig.feasible_truth, sig.active_constraint, sig.summary_tag}];
end

[ranked_summary, recommended_case] = stage13_rank_dg_refined_candidates(signature_rows);
refine_out.evaluations = refine_evals;
refine_out.summary = ranked_summary;
refine_out.coarse_recommended_case = string(recommended_case);
refine_out.recommended_case = string(recommended_case);
refine_out.status = "ranked";

if isfield(stage13_out, 'paths') && isfield(stage13_out.paths, 'dg_refined_summary_csv')
    writetable(ranked_summary, stage13_out.paths.dg_refined_summary_csv);
end

if isfield(cfg.stage13.dg_refine, 'micro') && isfield(cfg.stage13.dg_refine.micro, 'enable') && cfg.stage13.dg_refine.micro.enable
    micro_seed_tag = local_pick_micro_seed(ranked_summary);
    micro_plan = stage13_build_family_dg_clean_micro(cfg, refine_evals, micro_seed_tag);
    [micro_rows, micro_evals] = local_evaluate_micro_candidates(cfg, micro_plan.candidates, stage13_out.paths);
    micro_summary = local_rank_micro_candidates(micro_rows);

    refine_out.micro.seed_case = string(micro_seed_tag);
    refine_out.micro.summary = micro_summary;
    refine_out.micro.evaluations = micro_evals;
    if isfield(stage13_out, 'paths') && isfield(stage13_out.paths, 'dg_micro_summary_csv')
        writetable(micro_summary, stage13_out.paths.dg_micro_summary_csv);
    end
    micro_pick = micro_summary(micro_summary.recommendation_flag, :);
    if ~isempty(micro_pick)
        refine_out.recommended_case = string(micro_pick.case_tag(1));
        refine_out.micro.recommended_case = string(micro_pick.case_tag(1));
    end
end

if strlength(refine_out.recommended_case) > 0
    baseline_eval = local_find_baseline_eval(stage13_out.evaluations);
    recommended_eval = local_find_eval_by_tag([refine_evals; local_get_micro_evals(refine_out)], refine_out.recommended_case);
    plot_files = stage13_plot_case_vs_baseline( ...
        baseline_eval, recommended_eval, 'dg_refined_probe', stage13_out.paths, 'dg_refined_recommended');
    refine_out.figures.curve_compare = plot_files.curve_compare;
    refine_out.figures.worst_window_compare = plot_files.worst_window_compare;
end

refine_out.figures.family_overview = stage13_plot_dg_refined_overview(ranked_summary, stage13_out.paths);
end

function [micro_rows, micro_evals] = local_evaluate_micro_candidates(cfg, candidates, paths)
micro_rows = table('Size', [0 14], ...
    'VariableTypes', {'string', 'string', 'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'logical', 'string', 'string'}, ...
    'VariableNames', {'case_tag', 'case_id', 'family', 'case_family', 'D_G_worst', 'D_A_worst', 'D_T_worst', 'D_T_bar_worst', ...
    't0G_star', 't0A_star', 't0T_star', 'feasible_truth', 'active_constraint', 'summary_tag'});
micro_evals = repmat(struct('candidate', struct(), 'scan_out', struct(), 'signature', struct()), numel(candidates), 1);
for k = 1:numel(candidates)
    micro_evals(k) = stage13_evaluate_candidate(cfg, candidates(k), paths);
    sig = micro_evals(k).signature;
    micro_rows = [micro_rows; {sig.case_tag, sig.case_id, sig.family, sig.case_family, sig.D_G_worst, sig.D_A_worst, ... %#ok<AGROW>
        sig.D_T_worst, sig.D_T_bar_worst, sig.t0G_star, sig.t0A_star, sig.t0T_star, ...
        sig.feasible_truth, sig.active_constraint, sig.summary_tag}];
end
end

function rows = local_rank_micro_candidates(rows)
if isempty(rows)
    rows.clean_dg_score = [];
    rows.recommendation_flag = [];
    return;
end

n = height(rows);
scores = nan(n, 1);
for k = 1:n
    DG = rows.D_G_worst(k);
    DA = rows.D_A_worst(k);
    DT = rows.D_T_worst(k);
    is_dg_min = DG <= (DA + 0.02) && DG <= (DT + 0.02);

    score = 0;
    if is_dg_min
        score = score + 2.5;
    else
        score = score - 4.0;
    end
    if DG < 1
        score = score + 2.0;
    else
        score = score - 1.5;
    end
    if DT >= 1
        score = score + 2.0;
    else
        score = score - 5.0;
    end
    score = score + 3.0 * DA;
    score = score + 1.5 * min(DT - DG, 1.0);
    score = score - 1.2 * max(0.0, 1.0 - DA);
    score = score - 0.8 * abs(DG - 0.90);
    scores(k) = score;
end

rows.clean_dg_score = scores;
rows = sortrows(rows, {'clean_dg_score', 'D_A_worst', 'D_G_worst'}, {'descend', 'descend', 'descend'});
rows.recommendation_flag = false(height(rows), 1);
if ~isempty(rows)
    rows.recommendation_flag(1) = true;
end
end

function seed_tag = local_pick_micro_seed(ranked_summary)
eligible = ranked_summary(ranked_summary.is_dg_min & ranked_summary.D_G_worst < 1 & ranked_summary.D_T_worst >= 1, :);
if isempty(eligible)
    seed_tag = string(ranked_summary.case_tag(1));
    return;
end

eligible = sortrows(eligible, {'D_A_worst', 'D_G_worst'}, {'descend', 'descend'});
seed_tag = string(eligible.case_tag(1));
end

function evals = local_get_micro_evals(refine_out)
if isfield(refine_out, 'micro') && isfield(refine_out.micro, 'evaluations')
    evals = refine_out.micro.evaluations;
else
    evals = struct([]);
end
end

function eval_out = local_find_eval_by_tag(evaluations, case_tag)
eval_out = struct();
for k = 1:numel(evaluations)
    if strcmp(string(evaluations(k).signature.case_tag), string(case_tag))
        eval_out = evaluations(k);
        return;
    end
end
error('Stage13 refined evaluation not found for tag: %s', case_tag);
end

function baseline_eval = local_find_baseline_eval(evaluations)
baseline_eval = struct();
for k = 1:numel(evaluations)
    if strcmp(string(evaluations(k).signature.case_id), "N01")
        baseline_eval = evaluations(k);
        return;
    end
end
error('Stage13 refined search cannot find baseline evaluation with case_id N01.');
end
