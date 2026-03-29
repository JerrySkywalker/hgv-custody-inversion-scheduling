function out = manual_smoke_stage09_stage05_aligned_fullscan(cfg)
%MANUAL_SMOKE_STAGE09_STAGE05_ALIGNED_FULLSCAN
% Full-scan Stage09 smoke under Stage05-aligned domain.
% This version respects externally provided cfg fields and only fills
% missing defaults, so wrapper diagnose scripts can override DA / DT
% thresholds and run tags safely.

    clear functions;
    rehash;
    evalc('startup();');

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    if ~isfield(cfg, 'stage09') || ~isstruct(cfg.stage09)
        cfg.stage09 = struct();
    end

    % ---------------------------------------------------------
    % A. Default Stage09-aligned domain (only fill missing fields)
    % ---------------------------------------------------------
    cfg.stage09 = local_set_default(cfg.stage09, 'scheme_type', 'stage05_aligned');
    cfg.stage09 = local_set_default(cfg.stage09, 'run_tag', 'inverse_stage05_aligned_fullscan_smoke');

    if ~isfield(cfg.stage09, 'search_domain') || ~isstruct(cfg.stage09.search_domain)
        cfg.stage09.search_domain = struct();
    end
    cfg.stage09.search_domain = local_set_default(cfg.stage09.search_domain, 'h_grid_km', cfg.stage05.h_fixed_km);
    cfg.stage09.search_domain = local_set_default(cfg.stage09.search_domain, 'i_grid_deg', cfg.stage05.i_grid_deg(:).');
    cfg.stage09.search_domain = local_set_default(cfg.stage09.search_domain, 'P_grid', cfg.stage05.P_grid(:).');
    cfg.stage09.search_domain = local_set_default(cfg.stage09.search_domain, 'T_grid', cfg.stage05.T_grid(:).');
    cfg.stage09.search_domain = local_set_default(cfg.stage09.search_domain, 'F_fixed', cfg.stage05.F_fixed);

    cfg.stage09 = local_set_default(cfg.stage09, 'casebank_mode', 'nominal_only');
    cfg.stage09 = local_set_default(cfg.stage09, 'casebank_include_nominal', true);
    cfg.stage09 = local_set_default(cfg.stage09, 'casebank_include_heading', false);
    cfg.stage09 = local_set_default(cfg.stage09, 'casebank_include_critical', false);
    cfg.stage09 = local_set_default(cfg.stage09, 'casebank_heading_subset_max', 0);

    cfg.stage09 = local_set_default(cfg.stage09, 'scan_theta_limit', inf);
    cfg.stage09 = local_set_default(cfg.stage09, 'scan_case_limit', inf);
    cfg.stage09 = local_set_default(cfg.stage09, 'gamma_source', 'inherit_stage04');
    cfg.stage09 = local_set_default(cfg.stage09, 'plot_h_slice_km', cfg.stage05.h_fixed_km);

    cfg.stage09 = local_set_default(cfg.stage09, 'require_DG_min', cfg.stage05.require_D_G_min);
    cfg.stage09 = local_set_default(cfg.stage09, 'require_pass_ratio', cfg.stage05.require_pass_ratio);
    cfg.stage09 = local_set_default(cfg.stage09, 'require_DA_min', 0.0);
    cfg.stage09 = local_set_default(cfg.stage09, 'require_DT_min', 0.0);

    cfg.stage09 = local_set_default(cfg.stage09, 'enable_stage05_compatible_feasible', true);
    cfg.stage09 = local_set_default(cfg.stage09, 'enable_joint_feasible', true);
    cfg.stage09 = local_set_default(cfg.stage09, 'refPT_mode', 'all_theta_min_pairs');
    cfg.stage09 = local_set_default(cfg.stage09, 'use_parallel', false);
    cfg.stage09 = local_set_default(cfg.stage09, 'disable_progress', false);
    cfg.stage09 = local_set_default(cfg.stage09, 'scan_log_every', 1);

    if isfield(cfg, 'parallel') && isstruct(cfg.parallel) && isfield(cfg.parallel, 'enable')
        cfg.parallel.enable = false;
    end

    % ---------------------------------------------------------
    % B. Console summary
    % ---------------------------------------------------------
    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('Stage09 aligned full-scan smoke\n');
    fprintf('============================================================\n');
    fprintf('scheme_type           : %s\n', string(cfg.stage09.scheme_type));
    fprintf('run_tag               : %s\n', string(cfg.stage09.run_tag));
    fprintf('h_grid_km             : [%s]\n', num2str(cfg.stage09.search_domain.h_grid_km));
    fprintf('i_grid_deg            : [%s]\n', num2str(cfg.stage09.search_domain.i_grid_deg));
    fprintf('P_grid                : [%s]\n', num2str(cfg.stage09.search_domain.P_grid));
    fprintf('T_grid                : [%s]\n', num2str(cfg.stage09.search_domain.T_grid));
    fprintf('F_fixed               : %g\n', cfg.stage09.search_domain.F_fixed);
    fprintf('casebank_mode         : %s\n', string(cfg.stage09.casebank_mode));
    fprintf('scan_theta_limit      : %s\n', local_num_to_text(cfg.stage09.scan_theta_limit));
    fprintf('scan_case_limit       : %s\n', local_num_to_text(cfg.stage09.scan_case_limit));
    fprintf('gamma_source          : %s\n', string(cfg.stage09.gamma_source));
    fprintf('plot_h_slice_km       : %g\n', cfg.stage09.plot_h_slice_km);
    fprintf('require_DG_min        : %g\n', cfg.stage09.require_DG_min);
    fprintf('require_pass_ratio    : %g\n', cfg.stage09.require_pass_ratio);
    fprintf('require_DA_min        : %g\n', cfg.stage09.require_DA_min);
    fprintf('require_DT_min        : %g\n', cfg.stage09.require_DT_min);
    fprintf('use_parallel          : %d\n', logical(cfg.stage09.use_parallel));
    fprintf('scan_log_every        : %d\n', cfg.stage09.scan_log_every);
    fprintf('============================================================\n');
    fprintf('\n');

    % ---------------------------------------------------------
    % C. Run Stage09 pipeline
    % ---------------------------------------------------------
    out = struct();

    fprintf('[SMOKE] Stage09.1 prepare task spec...\n');
    out.s1 = stage09_prepare_task_spec(cfg);

    fprintf('[SMOKE] Stage09.4 build feasible domain...\n');
    out.s4 = stage09_build_feasible_domain(cfg);

    fprintf('[SMOKE] Stage09.5 extract minimum boundary...\n');
    out.s5 = stage09_extract_minimum_boundary(out.s4, cfg);

    fprintf('[SMOKE] Stage09.6 plot inverse design results...\n');
    out.s6 = stage09_plot_inverse_design_results(out.s4, out.s5, cfg);

    % ---------------------------------------------------------
    % D. Quick summary
    % ---------------------------------------------------------
    try
        Tfull = out.s4.full_theta_table;
        fprintf('\n');
        fprintf('---------------- Stage09 smoke summary ----------------\n');
        fprintf('Total theta rows                  : %d\n', height(Tfull));

        if ismember('feasible_stage05_compat', Tfull.Properties.VariableNames)
            fprintf('Stage05-compatible feasible rows  : %d\n', sum(Tfull.feasible_stage05_compat));
        end
        if ismember('joint_feasible', Tfull.Properties.VariableNames)
            fprintf('Joint-feasible rows               : %d\n', sum(Tfull.joint_feasible));
        end
        if ismember('Ns', Tfull.Properties.VariableNames)
            fprintf('Ns unique                         : [%s]\n', num2str(unique(Tfull.Ns(:)).'));
        end
        if ismember('P', Tfull.Properties.VariableNames) && ismember('T', Tfull.Properties.VariableNames)
            PT = unique(Tfull(:, {'P','T'}), 'rows');
            fprintf('Unique (P,T) count                : %d\n', height(PT));
        end

        fprintf('full csv                          : %s\n', string(out.s4.files.full_csv));
        fprintf('summary csv                       : %s\n', string(out.s4.files.summary_csv));
        fprintf('-------------------------------------------------------\n');
        fprintf('\n');
    catch ME
        warning('Post-run summary failed: %s', ME.message);
    end
end


function S = local_set_default(S, field_name, default_value)

    if ~isfield(S, field_name) || isempty(S.(field_name))
        S.(field_name) = default_value;
    end
end


function txt = local_num_to_text(x)

    if isinf(x)
        txt = 'inf';
    else
        txt = num2str(x);
    end
end
