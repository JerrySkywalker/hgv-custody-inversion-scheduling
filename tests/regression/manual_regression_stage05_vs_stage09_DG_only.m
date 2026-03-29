function out = manual_regression_stage05_vs_stage09_DG_only(cfg05, cfg09)
%MANUAL_REGRESSION_STAGE05_VS_STAGE09_DG_ONLY
% Run Stage05 baseline and Stage09 DG-only aligned regression, then compare.

    clear functions;
    rehash;
    evalc('startup();');

    if nargin < 1 || isempty(cfg05)
        cfg05 = default_params();
    end
    if nargin < 2 || isempty(cfg09)
        cfg09 = default_params();
    end

    % ---------------------------------------------------------
    % A. Stage05 baseline configuration
    % ---------------------------------------------------------
    cfg05.stage05.h_fixed_km = cfg05.stage05.h_fixed_km;
    cfg05.stage05.i_grid_deg = cfg05.stage05.i_grid_deg(:).';
    cfg05.stage05.P_grid = cfg05.stage05.P_grid(:).';
    cfg05.stage05.T_grid = cfg05.stage05.T_grid(:).';
    cfg05.stage05.F_fixed = cfg05.stage05.F_fixed;

    % ---------------------------------------------------------
    % B. Stage09 DG-only configuration
    % ---------------------------------------------------------
    cfg09.stage09.scheme_type = 'stage05_aligned';
    cfg09.stage09.run_tag = 'stage09_dg_only_regression';
    cfg09.stage09.search_domain.h_grid_km = cfg09.stage05.h_fixed_km;
    cfg09.stage09.search_domain.i_grid_deg = cfg09.stage05.i_grid_deg(:).';
    cfg09.stage09.search_domain.P_grid = cfg09.stage05.P_grid(:).';
    cfg09.stage09.search_domain.T_grid = cfg09.stage05.T_grid(:).';
    cfg09.stage09.search_domain.F_fixed = cfg09.stage05.F_fixed;
    cfg09.stage09.casebank_mode = 'nominal_only';
    cfg09.stage09.casebank_include_nominal = true;
    cfg09.stage09.casebank_include_heading = false;
    cfg09.stage09.casebank_include_critical = false;
    cfg09.stage09.scan_theta_limit = inf;
    cfg09.stage09.scan_case_limit = inf;
    cfg09.stage09.gamma_source = 'inherit_stage04';
    cfg09.stage09.plot_h_slice_km = cfg09.stage05.h_fixed_km;
    cfg09.stage09.require_DG_min = cfg09.stage05.require_D_G_min;
    cfg09.stage09.require_pass_ratio = cfg09.stage05.require_pass_ratio;
    cfg09.stage09.require_DA_min = 0.0;
    cfg09.stage09.require_DT_min = 0.0;

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('Stage05 vs Stage09 (DG-only) regression\n');
    fprintf('============================================================\n');
    fprintf('Stage05 search h_km      : %g\n', cfg05.stage05.h_fixed_km);
    fprintf('Stage05 search i_grid    : [%s]\n', num2str(cfg05.stage05.i_grid_deg));
    fprintf('Stage05 search P_grid    : [%s]\n', num2str(cfg05.stage05.P_grid));
    fprintf('Stage05 search T_grid    : [%s]\n', num2str(cfg05.stage05.T_grid));
    fprintf('Stage09 run_tag          : %s\n', char(string(cfg09.stage09.run_tag)));
    fprintf('Stage09 scheme_type      : %s\n', char(string(cfg09.stage09.scheme_type)));
    fprintf('Stage09 casebank_mode    : %s\n', char(string(cfg09.stage09.casebank_mode)));
    fprintf('Stage09 require_DG_min   : %g\n', cfg09.stage09.require_DG_min);
    fprintf('Stage09 require_pass     : %g\n', cfg09.stage09.require_pass_ratio);
    fprintf('Stage09 require_DA_min   : %g\n', cfg09.stage09.require_DA_min);
    fprintf('Stage09 require_DT_min   : %g\n', cfg09.stage09.require_DT_min);
    fprintf('============================================================\n');
    fprintf('\n');

    out = struct();

    fprintf('[REGRESSION] Stage05 main entry...\n');
    out.out05 = run_stage05_nominal_walker(cfg05, false);
    if isfield(out.out05, 'out1') && isfield(out.out05.out1, 'cfg')
        cfg05 = out.out05.out1.cfg;
    end

    fprintf('[REGRESSION] Stage09.1 prepare task spec...\n');
    out.out09 = struct();
    out.out09.s1 = stage09_prepare_task_spec(cfg09);
    if isfield(out.out09.s1, 'cfg')
        cfg09 = out.out09.s1.cfg;
    end

    fprintf('[REGRESSION] Stage09.4 build feasible domain...\n');
    out.out09.s4 = stage09_build_feasible_domain(cfg09);

    fprintf('[REGRESSION] Stage09.5 extract minimum boundary...\n');
    out.out09.s5 = stage09_extract_minimum_boundary(out.out09.s4, cfg09);

    fprintf('[REGRESSION] Stage09.6 plot inverse design results...\n');
    out.out09.s6 = stage09_plot_inverse_design_results(out.out09.s4, out.out09.s5, cfg09);

    fprintf('[REGRESSION] compare Stage05 vs Stage09 (DG-only)...\n');
    out.cmp = compare_stage05_stage09_dg_only(out.out05, out.out09, cfg05, cfg09);

    fprintf('[REGRESSION] export comparison figures...\n');
    out.fig_files = plot_stage09_stage05_style_comparison(out.cmp, out.out05, out.out09, cfg09);

    s = out.cmp.summary;
    fprintf('\n');
    fprintf('================ Regression Summary ================\n');
    fprintf('total rows      : Stage05=%d | Stage09=%d\n', s.n_rows_stage05, s.n_rows_stage09);
    fprintf('feasible rows   : Stage05=%d | Stage09=%d\n', s.n_feasible_stage05, s.n_feasible_stage09);
    fprintf('Ns_min          : Stage05=%g | Stage09=%g\n', s.Ns_min_stage05, s.Ns_min_stage09);
    fprintf('n mismatch      : feas=%d | frontier=%d | heatmap=%d\n', ...
        s.n_feas_label_mismatch, s.n_frontier_mismatch, s.n_heatmap_mismatch);
    fprintf('rows matched?   : %s\n', local_yesno(s.rows_matched_flag));
    fprintf('feasible matched?: %s\n', local_yesno(s.feasible_matched_flag));
    fprintf('Ns_min matched? : %s\n', local_yesno(s.Ns_min_matched_flag));
    fprintf('frontier matched?: %s\n', local_yesno(s.frontier_matched_flag));
    fprintf('overall         : %s\n', char(s.overall_status));
    fprintf('summary csv     : %s\n', out.cmp.files.summary_csv);
    fprintf('figure index csv: %s\n', out.fig_files.figure_index_csv);
    fprintf('====================================================\n');
end


function txt = local_yesno(tf)

    if tf
        txt = 'YES';
    else
        txt = 'NO';
    end
end
