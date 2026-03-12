function trajs_in = build_stage09_casebank(cfg)
%BUILD_STAGE09_CASEBANK
% Build Stage09 casebank according to cfg.stage09.casebank_mode.
%
% Supported modes:
%   'validation_small' : nominal all + heading subset + critical all
%   'full74'           : nominal all + heading all + critical all
%   'custom'           : manual include flags + heading subset controls

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage09_prepare_cfg(cfg);

    stage01_out = stage01_scenario_disk();
    casebank = stage01_out.casebank;

    nominal_cases = repmat(struct(), 0, 1);
    heading_cases = repmat(struct(), 0, 1);
    critical_cases = repmat(struct(), 0, 1);

    switch lower(string(cfg.stage09.casebank_mode))
        case "validation_small"
            if cfg.stage09.casebank_include_nominal
                nominal_cases = casebank.nominal(:);
            end
            if cfg.stage09.casebank_include_heading
                heading_cases = casebank.heading(:);
                if isfinite(cfg.stage09.casebank_heading_subset_max)
                    nKeep = min(numel(heading_cases), cfg.stage09.casebank_heading_subset_max);
                    heading_cases = heading_cases(1:nKeep);
                end
            end
            if cfg.stage09.casebank_include_critical
                critical_cases = casebank.critical(:);
            end

        case "full74"
            if cfg.stage09.casebank_include_nominal
                nominal_cases = casebank.nominal(:);
            end
            if cfg.stage09.casebank_include_heading
                heading_cases = casebank.heading(:);
            end
            if cfg.stage09.casebank_include_critical
                critical_cases = casebank.critical(:);
            end

        case "custom"
            if cfg.stage09.casebank_include_nominal
                nominal_cases = casebank.nominal(:);
            end
            if cfg.stage09.casebank_include_heading
                heading_cases = casebank.heading(:);
                if isfinite(cfg.stage09.casebank_heading_subset_max)
                    nKeep = min(numel(heading_cases), cfg.stage09.casebank_heading_subset_max);
                    heading_cases = heading_cases(1:nKeep);
                end
            end
            if cfg.stage09.casebank_include_critical
                critical_cases = casebank.critical(:);
            end

        otherwise
            error('Unknown cfg.stage09.casebank_mode: %s', string(cfg.stage09.casebank_mode));
    end

    cases_all = [nominal_cases; heading_cases; critical_cases];
    nCase = numel(cases_all);

    if nCase < 1
        error('No cases selected for Stage09 casebank.');
    end

    % Build first element as template
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