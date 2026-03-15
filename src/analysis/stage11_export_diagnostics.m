function files = stage11_export_diagnostics(out, cfg, timestamp)
%STAGE11_EXPORT_DIAGNOSTICS Export Stage11 window/case diagnosis tables.

    if nargin < 3 || isempty(timestamp)
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    end

    files = struct();

    if cfg.stage11.export_window_diagnostics
        window_diag = local_build_window_diagnostics(out.window_table);
        window_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage11_window_diagnostics_%s_%s.csv', cfg.stage11.run_tag, timestamp));
        writetable(window_diag, window_csv);
        files.window_diagnostics_csv = window_csv;
    end

    if cfg.stage11.export_case_diagnostics
        case_diag = local_build_case_diagnostics(out.case_table);
        case_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage11_case_diagnostics_%s_%s.csv', cfg.stage11.run_tag, timestamp));
        writetable(case_diag, case_csv);
        files.case_diagnostics_csv = case_csv;
    end
end


function T = local_build_window_diagnostics(window_table)
    keep = { ...
        'case_id', 'window_id', 't0_s', 'new_valid', 'new_failure_reason', ...
        'has_reference_match', 'n_groups_total', 'n_groups_matched', 'n_groups_fallback', ...
        'match_ratio', 'reference_match_ratio', 'supported_ratio', 'fully_supported', ...
        'weak_valid', 'sub_valid', 'truth_lambda_min', 'old_bound', ...
        'L_weak', 'L_sub', 'L_new', ...
        'alpha', 'beta', 'eig_gap', 'e_scalar', 'g_norm', 'Eperp_norm', 'mu_bar', ...
        'eps_pi', 'rho_pi', 'rho_g', 'group_status_list', 'template_residual_min_list'};
    T = local_select_columns(window_table, keep);
    if ismember('template_residual_min_list', T.Properties.VariableNames)
        T.group_status_summary = T.group_status_list;
        T.template_residual_min_mean = cellfun(@local_mean_residual, T.template_residual_min_list);
        T.template_residual_min_max = cellfun(@local_max_residual, T.template_residual_min_list);
        T.template_residual_min_list = [];
    end
end


function T = local_build_case_diagnostics(case_table)
    keep = { ...
        'case_id', 'n_window_total', 'n_window_valid_new', 'valid_ratio_new', 'all_valid_new', ...
        'old_case_label', 'new_case_label', 'mean_reference_match_ratio', 'mean_supported_ratio', ...
        'n_groups_fallback_total', ...
        'n_failure_no_reference', 'n_failure_partial_reference', ...
        'n_failure_reference_gap', ...
        'n_failure_weak_invalid', 'n_failure_sub_invalid', ...
        'n_failure_all_bounds_invalid', 'n_failure_numerical'};
    T = local_select_columns(case_table, keep);
end


function T = local_select_columns(source_table, names)
    present = names(ismember(names, source_table.Properties.VariableNames));
    T = source_table(:, present);
end


function value = local_mean_residual(x)
    x = x(isfinite(x));
    if isempty(x)
        value = NaN;
    else
        value = mean(x);
    end
end


function value = local_max_residual(x)
    x = x(isfinite(x));
    if isempty(x)
        value = NaN;
    else
        value = max(x);
    end
end
