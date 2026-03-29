function cmp = compare_stage05_stage09_dg_only(out05, out09, cfg05, cfg09)
%COMPARE_STAGE05_STAGE09_DG_ONLY
% Compare Stage05 baseline against Stage09 stage05-aligned DG-only results.

    if nargin < 3 || isempty(cfg05)
        cfg05 = default_params();
    end
    if nargin < 4 || isempty(cfg09)
        cfg09 = default_params();
    end

    cfg09 = stage09_prepare_cfg(cfg09);
    cfg09.project_stage = 'stage09_compare_stage05_dg_only';
    cfg09 = configure_stage_output_paths(cfg09);
    ensure_dir(cfg09.paths.tables);

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    cmp = build_stage05_stage09_comparison_tables(out05, out09, cfg05, cfg09, timestamp);

    summary = local_build_summary(cmp);
    summary_table = struct2table(summary);

    summary_csv = fullfile(cfg09.paths.tables, ...
        sprintf('stage09_stage05_dg_only_regression_summary_%s_%s.csv', ...
        char(cmp.run_tag), cmp.timestamp));
    writetable(summary_table, summary_csv);

    cmp.summary = summary;
    cmp.summary_table = summary_table;
    cmp.files.summary_csv = summary_csv;
end


function summary = local_build_summary(cmp)

    Tmain = cmp.main_compare_table;
    Tfront = cmp.frontier_compare_table;
    Theat = cmp.heatmap_compare_table;
    Tprof = cmp.passratio_profile_compare_table;
    T05 = cmp.stage05_table;
    T09 = cmp.stage09_table;

    rows_matched_flag = height(T05) == height(T09) && ...
        all(Tmain.present_stage05 == Tmain.present_stage09) && ...
        all(Tmain.Ns_match(Tmain.row_match));

    gamma_req_abs_diff = local_abs_diff(cmp.gamma_req_stage05, cmp.gamma_req_stage09);
    gamma_req_match_flag = local_equal_numeric(cmp.gamma_req_stage05, cmp.gamma_req_stage09);

    Ns_min_stage05 = local_min_feasible_or_nan(T05);
    Ns_min_stage09 = local_min_feasible_or_nan(T09);

    feasible_matched_flag = all(Tmain.feas_match(Tmain.row_match));
    frontier_matched_flag = all(Tfront.frontier_match_flag);
    heatmap_matched_flag = all(Theat.heatmap_match_flag);
    Ns_min_matched_flag = local_equal_or_both_nan(Ns_min_stage05, Ns_min_stage09);

    summary = struct();
    summary.n_rows_stage05 = height(T05);
    summary.n_rows_stage09 = height(T09);
    summary.n_feasible_stage05 = sum(T05.feasible_flag);
    summary.n_feasible_stage09 = sum(T09.feasible_flag);
    summary.n_stage05_only_rows = sum(Tmain.present_stage05 & ~Tmain.present_stage09);
    summary.n_stage09_only_rows = sum(Tmain.present_stage09 & ~Tmain.present_stage05);
    summary.n_row_Ns_mismatch = sum(Tmain.row_match & ~Tmain.Ns_match);
    summary.gamma_req_stage05 = cmp.gamma_req_stage05;
    summary.gamma_req_stage09 = cmp.gamma_req_stage09;
    summary.gamma_req_abs_diff = gamma_req_abs_diff;
    summary.gamma_req_match_flag = gamma_req_match_flag;
    summary.Ns_min_stage05 = Ns_min_stage05;
    summary.Ns_min_stage09 = Ns_min_stage09;
    summary.n_feas_label_mismatch = sum(Tmain.row_match & ~Tmain.feas_match);
    summary.n_frontier_mismatch = sum(~Tfront.frontier_match_flag);
    summary.n_frontier_equivalent_alt = sum(Tfront.frontier_equivalent_alt_flag);
    summary.n_heatmap_mismatch = sum(~Theat.heatmap_match_flag);
    summary.max_abs_DG_diff = local_max_or_nan(Tmain.DG_abs_diff);
    summary.max_abs_pass_diff = local_max_or_nan(Tmain.pass_abs_diff);
    summary.max_abs_pass_profile_diff = local_max_or_nan(Tprof.pass_abs_diff);
    summary.rows_matched_flag = rows_matched_flag;
    summary.feasible_matched_flag = feasible_matched_flag;
    summary.Ns_min_matched_flag = Ns_min_matched_flag;
    summary.frontier_matched_flag = frontier_matched_flag;
    summary.heatmap_matched_flag = heatmap_matched_flag;
    summary.overall_status = local_pick_overall_status(summary);
end


function status = local_pick_overall_status(summary)

    tol_float = 1e-10;

    fail_flag = ~summary.rows_matched_flag || ...
        ~summary.gamma_req_match_flag || ...
        ~summary.feasible_matched_flag || ...
        ~summary.Ns_min_matched_flag || ...
        ~summary.frontier_matched_flag || ...
        ~summary.heatmap_matched_flag;

    warn_flag = summary.n_frontier_equivalent_alt > 0 || ...
        local_exceeds_tol(summary.max_abs_DG_diff, tol_float) || ...
        local_exceeds_tol(summary.max_abs_pass_diff, tol_float) || ...
        local_exceeds_tol(summary.max_abs_pass_profile_diff, tol_float);

    if fail_flag
        status = "FAIL";
    elseif warn_flag
        status = "WARN";
    else
        status = "PASS";
    end
end


function tf = local_exceeds_tol(val, tol)

    tf = isfinite(val) && (val > tol);
end


function tf = local_equal_numeric(a, b)

    tf = isfinite(a) && isfinite(b) && abs(a - b) <= 1e-12;
end


function tf = local_equal_or_both_nan(a, b)

    if isnan(a) && isnan(b)
        tf = true;
    else
        tf = local_equal_numeric(a, b);
    end
end


function val = local_min_feasible_or_nan(T)

    T = T(T.feasible_flag, :);
    if isempty(T)
        val = NaN;
    else
        val = min(T.Ns);
    end
end


function val = local_max_or_nan(x)

    x = x(isfinite(x));
    if isempty(x)
        val = NaN;
    else
        val = max(x);
    end
end


function d = local_abs_diff(a, b)

    if isfinite(a) && isfinite(b)
        d = abs(a - b);
    else
        d = NaN;
    end
end
