function out = stage09_build_feasible_domain(cfg)
%STAGE09_BUILD_FEASIBLE_DOMAIN
% Stage09.4:
%   Scan the Walker parameter grid and build the feasible domain under
%   robust D-series constraints.
%
% Main outputs:
%   out.full_theta_table
%   out.feasible_theta_table
%   out.infeasible_theta_table
%   out.fail_partition_table
%   out.summary_table
%
% This stage is the first true "inverse-design domain" stage:
%   Theta  -->  {DG_rob, DA_rob, DT_rob}  -->  feasible domain

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage09_prepare_cfg(cfg);
    cfg.project_stage = 'stage09_build_feasible_domain';

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);

    run_tag = char(cfg.stage09.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage09_build_feasible_domain_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage09.4 started.');

    % ------------------------------------------------------------
    % Build casebank (validation/demo route for now)
    % ------------------------------------------------------------
    trajs_in = build_stage09_casebank(cfg);

    if isfinite(cfg.stage09.scan_case_limit)
        nKeep = min(numel(trajs_in), cfg.stage09.scan_case_limit);
        trajs_in = trajs_in(1:nKeep);
    end

    % ------------------------------------------------------------
    % Build search grid
    % ------------------------------------------------------------
    Tsearch = local_build_search_domain_table_stage09(cfg);

    if isfinite(cfg.stage09.scan_theta_limit)
        Tsearch = Tsearch(1:min(height(Tsearch), cfg.stage09.scan_theta_limit), :);
    end

    nTheta = height(Tsearch);
    if nTheta < 1
        error('Stage09 search domain is empty.');
    end

    gamma_eff_scalar = 1.0;  % placeholder; refined later in calibration stage

    % Use the first evaluated design as the struct template, so that
    % later indexed assignment is field-compatible.
    first_row = Tsearch(1,:);
    first_result = evaluate_single_layer_walker_stage09(first_row, trajs_in, gamma_eff_scalar, cfg);

    result_bank = repmat(first_result, nTheta, 1);
    result_bank(1) = first_result;

    t_scan = tic;
    for it = 2:nTheta
        row = Tsearch(it,:);
        result_bank(it) = evaluate_single_layer_walker_stage09(row, trajs_in, gamma_eff_scalar, cfg);

        if mod(it, cfg.stage09.scan_log_every) == 0 || it == 2 || it == nTheta
            log_msg(log_fid, 'INFO', ...
                'Scanned %d / %d designs (%.1f%%). Current: h=%.0f km, i=%.0f deg, P=%d, T=%d, feasible=%d', ...
                it, nTheta, 100*it/nTheta, ...
                row.h_km, row.i_deg, row.P, row.T, result_bank(it).feasible_flag);
        end
    end

    % Handle the one-design corner case explicitly
    if nTheta == 1
        log_msg(log_fid, 'INFO', ...
            'Scanned %d / %d designs (%.1f%%). Current: h=%.0f km, i=%.0f deg, P=%d, T=%d, feasible=%d', ...
            1, nTheta, 100, ...
            first_row.h_km, first_row.i_deg, first_row.P, first_row.T, first_result.feasible_flag);
    end
    elapsed_s = toc(t_scan);

    % ------------------------------------------------------------
    % Summarize
    % ------------------------------------------------------------
    S = summarize_stage09_grid(result_bank, cfg);

    if cfg.stage09.write_csv
        full_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage09_full_theta_table_%s_%s.csv', run_tag, timestamp));
        feasible_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage09_feasible_theta_table_%s_%s.csv', run_tag, timestamp));
        infeasible_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage09_infeasible_theta_table_%s_%s.csv', run_tag, timestamp));
        fail_partition_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage09_fail_partition_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage09_feasible_domain_summary_%s_%s.csv', run_tag, timestamp));

        writetable(S.full_theta_table, full_csv);
        writetable(S.feasible_theta_table, feasible_csv);
        writetable(S.infeasible_theta_table, infeasible_csv);
        writetable(S.fail_partition_table, fail_partition_csv);
        writetable(S.summary_table, summary_csv);
    else
        full_csv = "";
        feasible_csv = "";
        infeasible_csv = "";
        fail_partition_csv = "";
        summary_csv = "";
    end

    % ------------------------------------------------------------
    % Package outputs
    % ------------------------------------------------------------
    out = struct();
    out.cfg = cfg;
    out.full_theta_table = S.full_theta_table;
    out.feasible_theta_table = S.feasible_theta_table;
    out.infeasible_theta_table = S.infeasible_theta_table;
    out.fail_partition_table = S.fail_partition_table;
    out.summary_table = S.summary_table;
    out.result_bank = result_bank;

    out.files = struct();
    out.files.log_file = log_file;
    out.files.full_csv = full_csv;
    out.files.feasible_csv = feasible_csv;
    out.files.infeasible_csv = infeasible_csv;
    out.files.fail_partition_csv = fail_partition_csv;
    out.files.summary_csv = summary_csv;

    cache_file = fullfile(cfg.paths.cache, ...
        sprintf('stage09_build_feasible_domain_%s_%s.mat', run_tag, timestamp));
    save(cache_file, 'out', '-v7.3');
    out.files.cache_file = cache_file;

    log_msg(log_fid, 'INFO', 'Scan elapsed time = %.3f s', elapsed_s);
    log_msg(log_fid, 'INFO', 'Total theta      = %d', height(S.full_theta_table));
    log_msg(log_fid, 'INFO', 'Feasible theta   = %d', height(S.feasible_theta_table));
    log_msg(log_fid, 'INFO', 'Infeasible theta = %d', height(S.infeasible_theta_table));
    log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
    log_msg(log_fid, 'INFO', 'Stage09.4 finished.');

    fprintf('\n');
    fprintf('========== Stage09.4 Feasible-Domain Summary ==========\n');
    disp(S.summary_table);
    disp(S.fail_partition_table);
    fprintf('Cache          : %s\n', cache_file);
    if cfg.stage09.write_csv
        fprintf('Full table CSV : %s\n', full_csv);
        fprintf('Feasible CSV   : %s\n', feasible_csv);
        fprintf('Infeasible CSV : %s\n', infeasible_csv);
        fprintf('Fail-tag CSV   : %s\n', fail_partition_csv);
        fprintf('Summary CSV    : %s\n', summary_csv);
    end
    fprintf('=======================================================\n');
end


function trajs_in = local_build_demo_casebank_stage09(cfg)
% Reuse the Stage09.3 validation casebank builder logic:
%   - nominal all
%   - heading subset
%   - critical all
% and wrap each element into Stage02-family style.

    stage01_out = stage01_scenario_disk();
    casebank = stage01_out.casebank;

    nominal_cases = casebank.nominal(:);

    heading_cases = casebank.heading(:);
    if numel(heading_cases) > 10
        heading_cases = heading_cases(1:10);
    end

    critical_cases = casebank.critical(:);
    cases_all = [nominal_cases; heading_cases; critical_cases];
    nCase = numel(cases_all);

    if nCase < 1
        error('No cases selected for Stage09.4 scan.');
    end

    case_i = cases_all(1);
    traj_i = propagate_hgv_case_stage02(case_i, cfg);
    val_i  = validate_hgv_trajectory_stage02(traj_i, cfg);
    sum_i  = summarize_hgv_case_stage02(case_i, traj_i, val_i);

    first_item = struct();
    first_item.case = case_i;
    first_item.traj = traj_i;
    first_item.validation = val_i;
    first_item.summary = sum_i;

    trajs_in = repmat(first_item, nCase, 1);
    trajs_in(1) = first_item;

    for k = 2:nCase
        case_i = cases_all(k);
        traj_i = propagate_hgv_case_stage02(case_i, cfg);
        val_i  = validate_hgv_trajectory_stage02(traj_i, cfg);
        sum_i  = summarize_hgv_case_stage02(case_i, traj_i, val_i);

        trajs_in(k).case = case_i;
        trajs_in(k).traj = traj_i;
        trajs_in(k).validation = val_i;
        trajs_in(k).summary = sum_i;
    end
end


function T = local_build_search_domain_table_stage09(cfg)

    sd = cfg.stage09.search_domain;

    rows = {};
    idx = 0;
    for ih = 1:numel(sd.h_grid_km)
        for ii = 1:numel(sd.i_grid_deg)
            for ip = 1:numel(sd.P_grid)
                for it = 1:numel(sd.T_grid)
                    idx = idx + 1;
                    rows{idx,1} = struct( ... %#ok<AGROW>
                        'h_km', sd.h_grid_km(ih), ...
                        'i_deg', sd.i_grid_deg(ii), ...
                        'P', sd.P_grid(ip), ...
                        'T', sd.T_grid(it), ...
                        'F', sd.F_fixed, ...
                        'Ns', sd.P_grid(ip) * sd.T_grid(it));
                end
            end
        end
    end

    T = struct2table(vertcat(rows{:}));
    T = sortrows(T, {'Ns','h_km','i_deg','P','T'}, {'ascend','ascend','ascend','ascend','ascend'});
end