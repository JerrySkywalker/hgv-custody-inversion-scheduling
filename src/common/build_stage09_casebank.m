function trajs_in = build_stage09_casebank(cfg)
%BUILD_STAGE09_CASEBANK
% Build Stage09 casebank according to cfg.stage09.casebank_mode.
%
% Supported modes:
%   'nominal_only'     : nominal all only
%   'validation_small' : nominal all + heading subset + critical all
%   'full74'           : nominal all + heading all + critical all
%   'custom'           : manual include flags + heading subset controls

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage09_prepare_cfg(cfg);

    persistent last_signature last_casebank
    signature = local_stage09_casebank_signature(cfg);
    if ~isempty(last_signature) && isequal(last_signature, signature)
        trajs_in = last_casebank;
        return;
    end

    stage01_out = stage01_scenario_disk(cfg);
    casebank = stage01_out.casebank;

    nominal_cases = repmat(struct(), 0, 1);
    heading_cases = repmat(struct(), 0, 1);
    critical_cases = repmat(struct(), 0, 1);

    switch lower(string(cfg.stage09.casebank_mode))
        case "nominal_only"
            nominal_cases = casebank.nominal(:);
            heading_cases = repmat(struct(), 0, 1);
            critical_cases = repmat(struct(), 0, 1);

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

    parts = cell(0,1);
    if ~isempty(nominal_cases)
        parts{end+1,1} = nominal_cases(:); %#ok<AGROW>
    end
    if ~isempty(heading_cases)
        parts{end+1,1} = heading_cases(:); %#ok<AGROW>
    end
    if ~isempty(critical_cases)
        parts{end+1,1} = critical_cases(:); %#ok<AGROW>
    end

    if isempty(parts)
        error('No cases selected for Stage09 casebank.');
    end

    cases_all = vertcat(parts{:});
    nCase = numel(cases_all);

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

    last_signature = signature;
    last_casebank = trajs_in;
end

function signature = local_stage09_casebank_signature(cfg)
    signature_data = struct();
    signature_data.casebank_mode = string(cfg.stage09.casebank_mode);
    signature_data.include_nominal = logical(cfg.stage09.casebank_include_nominal);
    signature_data.include_heading = logical(cfg.stage09.casebank_include_heading);
    signature_data.include_critical = logical(cfg.stage09.casebank_include_critical);
    signature_data.heading_subset_max = cfg.stage09.casebank_heading_subset_max;
    signature_data.heading_subset_mode = string(cfg.stage09.casebank_heading_subset_mode);
    signature_data.R_D_km = cfg.stage01.R_D_km;
    signature_data.R_in_km = cfg.stage01.R_in_km;
    signature_data.num_nominal_entry_points = cfg.stage01.num_nominal_entry_points;
    signature_data.heading_offsets_deg = cfg.stage01.heading_offsets_deg;
    signature_data.critical_C1_y_offset_km = cfg.stage01.critical_C1_y_offset_km;
    signature_data.critical_C2_start_angle_deg = cfg.stage01.critical_C2_start_angle_deg;
    signature_data.critical_C2_heading_offset_deg = cfg.stage01.critical_C2_heading_offset_deg;
    signature_data.Ts_s = cfg.stage02.Ts_s;
    signature_data.Tmax_s = cfg.stage02.Tmax_s;
    signature_data.alpha_nominal_deg = cfg.stage02.alpha_nominal_deg;
    signature_data.bank_nominal_deg = cfg.stage02.bank_nominal_deg;
    signature_data.alpha_heading_deg = cfg.stage02.alpha_heading_deg;
    signature_data.bank_heading_deg = cfg.stage02.bank_heading_deg;
    signature_data.alpha_c1_deg = cfg.stage02.alpha_c1_deg;
    signature_data.bank_c1_deg = cfg.stage02.bank_c1_deg;
    signature_data.alpha_c2_deg = cfg.stage02.alpha_c2_deg;
    signature_data.bank_c2_deg = cfg.stage02.bank_c2_deg;
    signature = jsonencode(signature_data);
end
