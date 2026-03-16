function out = stage09_validate_single_design(cfg)
%STAGE09_VALIDATE_SINGLE_DESIGN
% Stage09.3 validation script:
%   evaluate one candidate Walker design on the full casebank and print
%   DG_rob / DA_rob / DT_rob.
%
% Default behavior:
%   1) prepare cfg by stage09_prepare_cfg
%   2) build nominal+heading+critical casebank via existing stage outputs if available
%   3) evaluate the first search-domain row
%
% NOTE:
%   This is a validation / debug script, not the full domain scan.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage09_prepare_cfg(cfg);
    cfg.project_stage = 'stage09_validate_single_design';

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);

    run_tag = char(cfg.stage09.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage09_validate_single_design_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage09.3 validation started.');

    % ------------------------------------------------------------
    % Build / load a trajectory family from current workspace pipeline
    % ------------------------------------------------------------
    trajs_in = build_stage09_casebank(cfg);
    Tsearch = local_build_search_domain_table(cfg);

    if height(Tsearch) < 1
        error('Stage09 search domain is empty.');
    end

    row = Tsearch(1,:);
    gamma_eff_scalar = 1.0;
    eval_ctx = build_stage09_eval_context(trajs_in, cfg, gamma_eff_scalar);

    result = evaluate_single_layer_walker_stage09(row, trajs_in, gamma_eff_scalar, cfg, eval_ctx);

    summary_table = table( ...
        row.h_km, row.i_deg, row.P, row.T, row.F, row.Ns, ...
        result.DG_rob, result.DA_rob, result.DT_bar_rob, result.DT_rob, ...
        result.joint_margin, result.pass_ratio, result.feasible_flag, ...
        string(result.dominant_fail_tag), ...
        string(result.worst_case_id_DG), ...
        string(result.worst_case_id_DA), ...
        string(result.worst_case_id_DT), ...
        'VariableNames', { ...
            'h_km','i_deg','P','T','F','Ns', ...
            'DG_rob','DA_rob','DT_bar_rob','DT_rob', ...
            'joint_margin','pass_ratio','feasible_flag', ...
            'dominant_fail_tag', ...
            'worst_case_id_DG', ...
            'worst_case_id_DA', ...
            'worst_case_id_DT'});

    summary_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_validate_single_design_summary_%s_%s.csv', run_tag, timestamp));
    case_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage09_validate_single_design_cases_%s_%s.csv', run_tag, timestamp));

    writetable(summary_table, summary_csv);
    writetable(result.case_table, case_csv);

    out = struct();
    out.summary_table = summary_table;
    out.case_table = result.case_table;
    out.result = result;
    out.files = struct();
    out.files.summary_csv = summary_csv;
    out.files.case_csv = case_csv;
    out.files.log_file = log_file;

    cache_file = fullfile(cfg.paths.cache, ...
        sprintf('stage09_validate_single_design_%s_%s.mat', run_tag, timestamp));
    save(cache_file, 'out', '-v7.3');
    out.files.cache_file = cache_file;

    log_msg(log_fid, 'INFO', 'Validation summary CSV saved to: %s', summary_csv);
    log_msg(log_fid, 'INFO', 'Validation case CSV saved to: %s', case_csv);
    log_msg(log_fid, 'INFO', 'Stage09.3 validation finished.');

    fprintf('\n');
    fprintf('========== Stage09.3 Single-Design Validation ==========\n');
    disp(summary_table);
    disp(result.case_table(1:min(10,height(result.case_table)), :));
    fprintf('Summary CSV : %s\n', summary_csv);
    fprintf('Cases CSV   : %s\n', case_csv);
    fprintf('Cache       : %s\n', cache_file);
    fprintf('========================================================\n');
end


function trajs_in = local_build_demo_casebank(cfg)
% Build a lightweight validation trajbank directly from Stage01 casebank.
%
% IMPORTANT:
%   Stage09 evaluator follows the Stage02/Stage03 convention:
%       trajs_in(k).case
%       trajs_in(k).traj
%       trajs_in(k).validation
%       trajs_in(k).summary
%
% Therefore we must wrap propagated trajectories into the same
% Stage02-style family struct, instead of returning raw traj structs.

    stage01_out = stage01_scenario_disk(cfg);
    casebank = stage01_out.casebank;

    % Keep validation lightweight:
    %   - all nominal cases
    %   - a small heading subset
    %   - all critical cases
    nominal_cases = casebank.nominal(:);

    heading_cases = casebank.heading(:);
    if numel(heading_cases) > 10
        heading_cases = heading_cases(1:10);
    end

    critical_cases = casebank.critical(:);

    cases_all = [nominal_cases; heading_cases; critical_cases];
    nCase = numel(cases_all);

    if nCase < 1
        error('No cases selected for Stage09.3 validation.');
    end

    % Build first element as template so struct-array assignment is safe
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


function T = local_build_search_domain_table(cfg)

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
