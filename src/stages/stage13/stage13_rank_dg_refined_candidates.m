function [ranked_rows, recommended_case] = stage13_rank_dg_refined_candidates(signature_rows)
%STAGE13_RANK_DG_REFINED_CANDIDATES Rank refined DG candidates by mechanism clarity.

rows = signature_rows(strcmp(string(signature_rows.family), "dg_refined_probe"), :);
if isempty(rows)
    ranked_rows = table();
    recommended_case = "";
    return;
end

n = height(rows);
is_dg_min = false(n, 1);
dg_margin_gap_to_dt = nan(n, 1);
dg_margin_gap_to_da = nan(n, 1);
collapse_penalty = nan(n, 1);
dg_refined_rank_score = nan(n, 1);
recommendation_flag = false(n, 1);

for k = 1:n
    DG = rows.D_G_worst(k);
    DA = rows.D_A_worst(k);
    DT = rows.D_T_worst(k);

    is_dg_min(k) = DG <= (DA + 0.02) && DG <= (DT + 0.02);
    dg_margin_gap_to_dt(k) = DT - DG;
    dg_margin_gap_to_da(k) = DA - DG;
    collapse_penalty(k) = local_collapse_penalty(DG, DA, DT);
    dg_refined_rank_score(k) = local_rank_score(DG, DA, DT, is_dg_min(k), dg_margin_gap_to_dt(k), dg_margin_gap_to_da(k), collapse_penalty(k));
end

rows.is_dg_min = is_dg_min;
rows.dg_margin_gap_to_dt = dg_margin_gap_to_dt;
rows.dg_margin_gap_to_da = dg_margin_gap_to_da;
rows.collapse_penalty = collapse_penalty;
rows.dg_refined_rank_score = dg_refined_rank_score;

rows = sortrows(rows, {'dg_refined_rank_score', 'D_G_worst'}, {'descend', 'ascend'});
if ~isempty(rows)
    recommendation_flag(1) = true;
    rows.recommendation_flag = false(height(rows), 1);
    rows.recommendation_flag(1) = true;
    recommended_case = string(rows.case_tag(1));
else
    rows.recommendation_flag = recommendation_flag;
    recommended_case = "";
end

ranked_rows = rows;
end

function score = local_rank_score(DG, DA, DT, is_dg_min, gap_dt, gap_da, collapse_penalty)
score = 0.0;

if is_dg_min
    score = score + 4.0;
else
    score = score - 4.0;
end

if DG < 1
    score = score + 4.0 + min(0.6, 1 - DG);
else
    score = score + max(0.0, 2.0 - 3.0 * abs(DG - 1.0));
end

score = score + 1.8 * max(gap_dt, 0.0);
score = score + 1.2 * max(gap_da, 0.0);

if DT <= 1
    score = score - 3.0;
    if abs(DT - DG) <= 0.10
        score = score - 2.0;
    end
end

if DA <= 1 && abs(DA - DG) <= 0.10
    score = score - 1.8;
end

if max([DG, DA, DT]) < 0.85
    score = score - 3.0;
end

score = score - 2.5 * collapse_penalty;
end

function penalty = local_collapse_penalty(DG, DA, DT)
penalty = 0.0;

if DG < 0.95 && DA < 0.95 && DT < 0.95
    penalty = penalty + 1.2;
end

if DA < 1.0
    penalty = penalty + 0.6 * max(0.0, 1.0 - DA);
end

if DT < 1.0
    penalty = penalty + 0.8 * max(0.0, 1.0 - DT);
end

if abs(DA - DG) <= 0.08
    penalty = penalty + 0.4;
end

if abs(DT - DG) <= 0.08
    penalty = penalty + 0.5;
end
end
