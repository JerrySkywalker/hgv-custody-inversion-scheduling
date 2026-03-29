function out = manual_smoke_stage09_stage05_aligned_fullscan()
%MANUAL_SMOKE_STAGE09_STAGE05_ALIGNED_FULLSCAN
% Stage09 smoke test rewritten to fully replicate Stage05 search scope.
%
% Goals:
%   1) No theta sampling, no case sampling
%   2) Search domain exactly matches Stage05
%   3) Casebank mode = nominal_only
%   4) Gamma inherits from Stage04
%   5) First verify Stage05-compatible behavior before joint-feasible behavior
%
% This script is intended for regression/debug use, not for paper-scale full_main scans.

    clear functions;
    rehash;
    startup;

    cfg = default_params();

    % =========================================================
    % A. Force Stage09 into Stage05-aligned full-scan mode
    % =========================================================
    cfg.stage09.scheme_type = 'stage05_aligned';
    cfg.stage09.run_tag = 'inverse_stage05_aligned_fullscan_smoke';

    % Exact Stage05 search scope
    cfg.stage09.search_domain.h_grid_km = cfg.stage05.h_fixed_km;
    cfg.stage09.search_domain.i_grid_deg = cfg.stage05.i_grid_deg(:).';
    cfg.stage09.search_domain.P_grid = cfg.stage05.P_grid(:).';
    cfg.stage09.search_domain.T_grid = cfg.stage05.T_grid(:).';
    cfg.stage09.search_domain.F_fixed = cfg.stage05.F_fixed;

    % Exact Stage05-like casebank scope
    cfg.stage09.casebank_mode = 'nominal_only';
    cfg.stage09.casebank_include_nominal = true;
    cfg.stage09.casebank_include_heading = false;
    cfg.stage09.casebank_include_critical = false;
    cfg.stage09.casebank_heading_subset_max = 0;

    % =========================================================
    % B. Disable all sampling / truncation
    % =========================================================
    cfg.stage09.scan_theta_limit = inf;
    cfg.stage09.scan_case_limit = inf;

    % =========================================================
    % C. Gamma inheritance must match Stage04 / Stage05
    % =========================================================
    cfg.stage09.gamma_source = 'inherit_stage04';

    % =========================================================
    % D. Plot h-slice exactly at Stage05 fixed altitude
    % =========================================================
    cfg.stage09.plot_h_slice_km = cfg.stage05.h_fixed_km;

    % =========================================================
    % E. Threshold strategy:
    %    First smoke goal = Stage05-compatible comparison
    %    So DG + pass_ratio are the primary gates.
    %
    %    Keep joint metrics computed, but do not let DA / DT kill
    %    the aligned smoke result at this stage.
    % =========================================================
    cfg.stage09.require_DG_min = cfg.stage05.require_D_G_min;
    cfg.stage09.require_pass_ratio = cfg.stage05.require_pass_ratio;

    % Relax joint-only thresholds for the aligned smoke.
    % These are not the final paper settings; this is only to verify
    % Stage09 can degenerate consistently back to Stage05 behavior.
    cfg.stage09.require_DA_min = 0.0;
    cfg.stage09.require_DT_min = 0.0;

    % =========================================================
    % F. Keep diagnostic / plotting enabled
    % =========================================================
    cfg.stage09.enable_stage05_compatible_feasible = true;
    cfg.stage09.enable_joint_feasible = true;
    cfg.stage09.refPT_mode = 'all_theta_min_pairs';

    % Optional: reduce noise in smoke execution
    if isfield(cfg, 'parallel') && isstruct(cfg.parallel)
        if isfield(cfg.parallel, 'enable')
            cfg.parallel.enable = false;
        end
    end

    % =========================================================
    % G. Console summary
    % =========================================================
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
    fprintf('scan_theta_limit      : inf\n');
    fprintf('scan_case_limit       : inf\n');
    fprintf('gamma_source          : %s\n', string(cfg.stage09.gamma_source));
    fprintf('plot_h_slice_km       : %g\n', cfg.stage09.plot_h_slice_km);
    fprintf('require_DG_min        : %g\n', cfg.stage09.require_DG_min);
    fprintf('require_pass_ratio    : %g\n', cfg.stage09.require_pass_ratio);
    fprintf('require_DA_min        : %g (relaxed for aligned smoke)\n', cfg.stage09.require_DA_min);
    fprintf('require_DT_min        : %g (relaxed for aligned smoke)\n', cfg.stage09.require_DT_min);
    fprintf('============================================================\n');
    fprintf('\n');

    % =========================================================
    % H. Run Stage09 pipeline
    % =========================================================
    out = struct();

    fprintf('[SMOKE] Stage09.1 prepare task spec...\n');
    out.s1 = stage09_prepare_task_spec(cfg);

    fprintf('[SMOKE] Stage09.4 build feasible domain...\n');
    out.s4 = stage09_build_feasible_domain(cfg);

    fprintf('[SMOKE] Stage09.5 extract minimum boundary...\n');
    out.s5 = stage09_extract_minimum_boundary(out.s4, cfg);

    fprintf('[SMOKE] Stage09.6 plot inverse design results...\n');
    out.s6 = stage09_plot_inverse_design_results(out.s4, out.s5, cfg);

    % =========================================================
    % I. Post-run quick summary
    % =========================================================
    try
        Tfull = out.s4.full_theta_table;
        fprintf('\n');
        fprintf('---------------- Stage09 smoke summary ----------------\n');
        fprintf('Total theta rows                  : %d\n', height(Tfull));

        if ismember('feasible_stage05_compat', Tfull.Properties.VariableNames)
            n_stage05_feas = sum(Tfull.feasible_stage05_compat);
            fprintf('Stage05-compatible feasible rows  : %d\n', n_stage05_feas);
        end

        if ismember('joint_feasible', Tfull.Properties.VariableNames)
            n_joint_feas = sum(Tfull.joint_feasible);
            fprintf('Joint-feasible rows               : %d\n', n_joint_feas);
        end

        if ismember('Ns', Tfull.Properties.VariableNames)
            fprintf('Ns unique                         : [%s]\n', num2str(unique(Tfull.Ns(:)).'));
        end

        if ismember('P', Tfull.Properties.VariableNames) && ismember('T', Tfull.Properties.VariableNames)
            PT = unique(Tfull(:, {'P','T'}), 'rows');
            fprintf('Unique (P,T) count                : %d\n', height(PT));
        end

        fprintf('-------------------------------------------------------\n');
        fprintf('\n');
    catch ME
        warning('Post-run summary failed: %s', ME.message);
    end
end