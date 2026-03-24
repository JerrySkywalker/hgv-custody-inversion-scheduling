function signature = stage13_extract_case_signature(scan_out, candidate)
%STAGE13_EXTRACT_CASE_SIGNATURE Convert Stage12 scan output to Stage13 signature.

summary_row = scan_out.summary_table(1, :);
selection = scan_out.case_selection;

DG = summary_row.DG_worst_truth;
DA = summary_row.DA_worst_truth;
DT = summary_row.DT_worst_truth;
DT_bar = summary_row.DT_bar_worst;
metric_values = [DG, DA, DT];
metric_names = ["DG", "DA", "DT"];
feasible_truth = all(metric_values >= 1);
if feasible_truth
    metric_gap = metric_values - 1;
    [~, idx] = min(metric_gap);
    joint_idx = find(abs(metric_gap - metric_gap(idx)) <= 0.02);
else
    metric_gap = metric_values - 1;
    [~, idx] = min(metric_gap);
    joint_idx = find(abs(metric_values - metric_values(idx)) <= 0.02);
end

if numel(joint_idx) > 1
    active_constraint = "joint";
else
    active_constraint = metric_names(idx);
end

if feasible_truth
    summary_tag = "feasible_neighbor";
else
    summary_tag = active_constraint + "_first_failure";
end

signature = struct();
signature.case_tag = string(candidate.candidate_tag);
signature.case_id = string(selection.case_id);
signature.family = string(candidate.family);
signature.case_family = string(selection.case_family);
signature.theta = struct('h_km', candidate.h_km, 'i_deg', candidate.i_deg, 'P', candidate.P, 'T', candidate.T, 'F', candidate.F);
signature.Tw = candidate.Tw_s;
signature.D_G_worst = DG;
signature.D_A_worst = DA;
signature.D_T_worst = DT;
signature.D_T_bar_worst = DT_bar;
signature.t0G_star = summary_row.t0G_star_s;
signature.t0A_star = summary_row.t0A_star_s;
signature.t0T_star = summary_row.t0T_star_s;
signature.feasible_truth = feasible_truth;
signature.active_constraint = active_constraint;
signature.curve_data_path = "";
signature.summary_tag = summary_tag;
end
