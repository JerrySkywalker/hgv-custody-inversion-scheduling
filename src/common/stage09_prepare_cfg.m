function cfg = stage09_prepare_cfg(cfg)
%STAGE09_PREPARE_CFG
% Normalize / resolve Stage09 configuration fields.
%
% Main responsibilities:
%   1) make sure cfg.stage09 exists
%   2) resolve C_A from CA_mode
%   3) normalize search-domain grids
%   4) normalize Tw source / run tag
%
% This function does NOT load Stage08.5 cache by itself.
% It only freezes Stage09-side configuration fields.

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    if ~isfield(cfg, 'stage09') || isempty(cfg.stage09)
        error('cfg.stage09 is missing.');
    end

    % ------------------------------------------------------------
    % run tag
    % ------------------------------------------------------------
    if ~isfield(cfg.stage09, 'run_tag') || isempty(cfg.stage09.run_tag)
        cfg.stage09.run_tag = 'inverse';
    end

    % ------------------------------------------------------------
    % Tw source
    % ------------------------------------------------------------
    if ~isfield(cfg.stage09, 'Tw_source') || isempty(cfg.stage09.Tw_source)
        cfg.stage09.Tw_source = 'inherit_stage08_5';
    end

    valid_tw_source = {'inherit_stage08_5', 'manual'};
    if ~ismember(char(string(cfg.stage09.Tw_source)), valid_tw_source)
        error('Unknown cfg.stage09.Tw_source: %s', string(cfg.stage09.Tw_source));
    end

    if ~isfield(cfg.stage09, 'Tw_manual_s') || isempty(cfg.stage09.Tw_manual_s)
        cfg.stage09.Tw_manual_s = cfg.stage04.Tw_s;
    end

    if ~isfield(cfg.stage09, 'stage08_5_run_tag_hint')
        cfg.stage09.stage08_5_run_tag_hint = '';
    end

    % ------------------------------------------------------------
    % sigma_A_req / dt_crit
    % ------------------------------------------------------------
    if ~isfield(cfg.stage09, 'sigma_A_req') || isempty(cfg.stage09.sigma_A_req)
        cfg.stage09.sigma_A_req = 1.0;
    end
    if ~isfield(cfg.stage09, 'sigma_A_req_unit') || isempty(cfg.stage09.sigma_A_req_unit)
        cfg.stage09.sigma_A_req_unit = 'normalized';
    end
    if ~isfield(cfg.stage09, 'dt_crit_s') || isempty(cfg.stage09.dt_crit_s)
        cfg.stage09.dt_crit_s = 60;
    end

    % ------------------------------------------------------------
    % CA_mode -> C_A
    % ------------------------------------------------------------
    if ~isfield(cfg.stage09, 'CA_mode') || isempty(cfg.stage09.CA_mode)
        cfg.stage09.CA_mode = 'position_xyz';
    end
    if ~isfield(cfg.stage09, 'CA_custom') || isempty(cfg.stage09.CA_custom)
        cfg.stage09.CA_custom = eye(3);
    end
    if ~isfield(cfg.stage09, 'CA_label') || isempty(cfg.stage09.CA_label)
        cfg.stage09.CA_label = 'task-position-projection';
    end

    switch lower(string(cfg.stage09.CA_mode))
        case "position_xyz"
            cfg.stage09.CA = eye(3);
        case "custom"
            cfg.stage09.CA = cfg.stage09.CA_custom;
        otherwise
            error('Unknown cfg.stage09.CA_mode: %s', string(cfg.stage09.CA_mode));
    end

    if ~ismatrix(cfg.stage09.CA) || isempty(cfg.stage09.CA)
        error('cfg.stage09.CA must be a non-empty matrix.');
    end

    % ------------------------------------------------------------
    % Stage09 scheme preset
    % ------------------------------------------------------------
    if ~isfield(cfg.stage09, 'scheme_type') || isempty(cfg.stage09.scheme_type)
        cfg.stage09.scheme_type = 'validation_small';
    end

    cfg.stage09 = local_apply_stage09_scheme(cfg.stage09, cfg);

    % ------------------------------------------------------------
    % Numeric kernel controls
    % ------------------------------------------------------------
    if ~isfield(cfg.stage09, 'wr_reg_eps') || isempty(cfg.stage09.wr_reg_eps)
        cfg.stage09.wr_reg_eps = 1e-9;
    end
    if ~isfield(cfg.stage09, 'wr_eig_floor') || isempty(cfg.stage09.wr_eig_floor)
        cfg.stage09.wr_eig_floor = 1e-10;
    end
    if ~isfield(cfg.stage09, 'wr_inv_mode') || isempty(cfg.stage09.wr_inv_mode)
        cfg.stage09.wr_inv_mode = 'eig_floor';
    end
    if ~isfield(cfg.stage09, 'A_metric_mode') || isempty(cfg.stage09.A_metric_mode)
        cfg.stage09.A_metric_mode = 'max_eig_rms';
    end
    if ~isfield(cfg.stage09, 'force_symmetric') || isempty(cfg.stage09.force_symmetric)
        cfg.stage09.force_symmetric = true;
    end

    valid_inv_mode = {'eig_floor', 'pinv'};
    if ~ismember(char(string(cfg.stage09.wr_inv_mode)), valid_inv_mode)
        error('Unknown cfg.stage09.wr_inv_mode: %s', string(cfg.stage09.wr_inv_mode));
    end

    valid_A_metric_mode = {'max_eig_rms', 'trace_rms'};
    if ~ismember(char(string(cfg.stage09.A_metric_mode)), valid_A_metric_mode)
        error('Unknown cfg.stage09.A_metric_mode: %s', string(cfg.stage09.A_metric_mode));
    end

    if cfg.stage09.wr_reg_eps < 0
        error('cfg.stage09.wr_reg_eps must be >= 0.');
    end
    if cfg.stage09.wr_eig_floor <= 0
        error('cfg.stage09.wr_eig_floor must be > 0.');
    end
    % ------------------------------------------------------------
    % Search domain
    % ------------------------------------------------------------
    if ~isfield(cfg.stage09, 'search_domain') || isempty(cfg.stage09.search_domain)
        cfg.stage09.search_domain = struct();
    end

    sd = cfg.stage09.search_domain;

    if ~isfield(sd, 'h_grid_km') || isempty(sd.h_grid_km)
        sd.h_grid_km = [800 1000 1200];
    end
    if ~isfield(sd, 'i_grid_deg') || isempty(sd.i_grid_deg)
        sd.i_grid_deg = cfg.stage06.i_grid_deg;
    end
    if ~isfield(sd, 'P_grid') || isempty(sd.P_grid)
        sd.P_grid = cfg.stage06.P_grid;
    end
    if ~isfield(sd, 'T_grid') || isempty(sd.T_grid)
        sd.T_grid = cfg.stage06.T_grid;
    end
    if ~isfield(sd, 'F_fixed') || isempty(sd.F_fixed)
        sd.F_fixed = 1;
    end
    if ~isfield(sd, 'round_to_integer') || isempty(sd.round_to_integer)
        sd.round_to_integer = true;
    end
    if ~isfield(sd, 'max_config_count') || isempty(sd.max_config_count)
        sd.max_config_count = inf;
    end

    sd.h_grid_km  = unique(sd.h_grid_km(:).', 'stable');
    sd.i_grid_deg = unique(sd.i_grid_deg(:).', 'stable');
    sd.P_grid     = unique(sd.P_grid(:).', 'stable');
    sd.T_grid     = unique(sd.T_grid(:).', 'stable');

    if sd.round_to_integer
        sd.h_grid_km  = round(sd.h_grid_km);
        sd.i_grid_deg = round(sd.i_grid_deg);
        sd.P_grid     = round(sd.P_grid);
        sd.T_grid     = round(sd.T_grid);
        sd.F_fixed    = round(sd.F_fixed);
    end

    sd.h_grid_km  = sort(sd.h_grid_km, 'ascend');
    sd.i_grid_deg = sort(sd.i_grid_deg, 'ascend');
    sd.P_grid     = sort(sd.P_grid, 'ascend');
    sd.T_grid     = sort(sd.T_grid, 'ascend');

    sd.h_grid_km  = sd.h_grid_km(sd.h_grid_km > 0);
    sd.i_grid_deg = sd.i_grid_deg(sd.i_grid_deg >= 0 & sd.i_grid_deg <= 180);
    sd.P_grid     = sd.P_grid(sd.P_grid >= 1);
    sd.T_grid     = sd.T_grid(sd.T_grid >= 1);

    if isempty(sd.h_grid_km) || isempty(sd.i_grid_deg) || isempty(sd.P_grid) || isempty(sd.T_grid)
        error('Stage09 search_domain has empty grid after normalization.');
    end

    cfg.stage09.search_domain = sd;

    % ------------------------------------------------------------
    % Casebank settings
    % ------------------------------------------------------------
    if ~isfield(cfg.stage09, 'casebank_mode') || isempty(cfg.stage09.casebank_mode)
        cfg.stage09.casebank_mode = 'validation_small';
    end

    valid_casebank_mode = {'validation_small', 'full74', 'custom'};
    if ~ismember(char(string(cfg.stage09.casebank_mode)), valid_casebank_mode)
        error('Unknown cfg.stage09.casebank_mode: %s', string(cfg.stage09.casebank_mode));
    end

    if ~isfield(cfg.stage09, 'casebank_include_nominal') || isempty(cfg.stage09.casebank_include_nominal)
        cfg.stage09.casebank_include_nominal = true;
    end
    if ~isfield(cfg.stage09, 'casebank_include_heading') || isempty(cfg.stage09.casebank_include_heading)
        cfg.stage09.casebank_include_heading = true;
    end
    if ~isfield(cfg.stage09, 'casebank_include_critical') || isempty(cfg.stage09.casebank_include_critical)
        cfg.stage09.casebank_include_critical = true;
    end
    if ~isfield(cfg.stage09, 'casebank_heading_subset_max') || isempty(cfg.stage09.casebank_heading_subset_max)
        cfg.stage09.casebank_heading_subset_max = 10;
    end
    if ~isfield(cfg.stage09, 'casebank_heading_subset_mode') || isempty(cfg.stage09.casebank_heading_subset_mode)
        cfg.stage09.casebank_heading_subset_mode = 'first';
    end

    % ------------------------------------------------------------
    % Rank rule
    % ------------------------------------------------------------
    if ~isfield(cfg.stage09, 'rank_rule') || isempty(cfg.stage09.rank_rule)
        cfg.stage09.rank_rule = 'min_Ns_then_max_joint_margin';
    end

    % ------------------------------------------------------------
    % Output controls
    % ------------------------------------------------------------
    if ~isfield(cfg.stage09, 'make_plot') || isempty(cfg.stage09.make_plot)
        cfg.stage09.make_plot = false;
    end
    if ~isfield(cfg.stage09, 'save_eval_bank') || isempty(cfg.stage09.save_eval_bank)
        cfg.stage09.save_eval_bank = false;
    end

    % ------------------------------------------------------------
    % Feasible-domain scan controls
    % ------------------------------------------------------------
    if ~isfield(cfg.stage09, 'scan_case_limit') || isempty(cfg.stage09.scan_case_limit)
        cfg.stage09.scan_case_limit = inf;
    end
    if ~isfield(cfg.stage09, 'scan_theta_limit') || isempty(cfg.stage09.scan_theta_limit)
        cfg.stage09.scan_theta_limit = inf;
    end
    if ~isfield(cfg.stage09, 'scan_log_every') || isempty(cfg.stage09.scan_log_every)
        cfg.stage09.scan_log_every = 10;
    end
    if ~isfield(cfg.stage09, 'sort_full_table') || isempty(cfg.stage09.sort_full_table)
        cfg.stage09.sort_full_table = true;
    end
    if ~isfield(cfg.stage09, 'write_csv') || isempty(cfg.stage09.write_csv)
        cfg.stage09.write_csv = true;
    end

    if cfg.stage09.scan_log_every < 1
        cfg.stage09.scan_log_every = 10;
    end


end

function s9 = local_apply_stage09_scheme(s9, cfg)
%LOCAL_APPLY_STAGE09_SCHEME
% Resolve preset search-domain and casebank settings for Stage09.

    scheme = lower(string(s9.scheme_type));

    % Resolve default run_tag automatically if user has not intentionally
    % customized it.
    if ~isfield(s9, 'run_tag') || isempty(s9.run_tag)
        s9.run_tag = local_default_stage09_run_tag(scheme);
    else
        rt = string(s9.run_tag);
        if any(rt == ["inverse","inverse_small","inverse_full","inverse_custom"])
            s9.run_tag = local_default_stage09_run_tag(scheme);
        end
    end

    switch scheme
        case "validation_small"
            % Keep the currently proven small-grid validation scheme
            s9.search_domain.h_grid_km = [800 1000];
            s9.search_domain.i_grid_deg = [30 60 80];
            s9.search_domain.P_grid = [4 6];
            s9.search_domain.T_grid = [4 6 8];
            s9.search_domain.F_fixed = 1;

            s9.casebank_mode = 'validation_small';
            s9.casebank_include_nominal = true;
            s9.casebank_include_heading = true;
            s9.casebank_include_critical = true;
            s9.casebank_heading_subset_max = 10;
            s9.casebank_heading_subset_mode = 'first';

        case "full_main"
            % Formal main scan:
            % inherit Stage05/06 granularity on i/P/T, add h = 500:100:1000
            s9.search_domain.h_grid_km = 500:100:1000;
            s9.search_domain.i_grid_deg = cfg.stage05.i_grid_deg;
            s9.search_domain.P_grid = cfg.stage05.P_grid;
            s9.search_domain.T_grid = cfg.stage05.T_grid;
            s9.search_domain.F_fixed = 1;

            s9.casebank_mode = 'full74';
            s9.casebank_include_nominal = true;
            s9.casebank_include_heading = true;
            s9.casebank_include_critical = true;
            s9.casebank_heading_subset_max = inf;
            s9.casebank_heading_subset_mode = 'first';

        case "custom"
            % Do not overwrite search_domain or casebank settings.
            % User is responsible for setting them manually.
            if ~isfield(s9, 'casebank_mode') || isempty(s9.casebank_mode)
                s9.casebank_mode = 'custom';
            end

        otherwise
            error('Unknown cfg.stage09.scheme_type: %s', string(s9.scheme_type));
    end
end


function run_tag = local_default_stage09_run_tag(scheme)

    switch lower(string(scheme))
        case "validation_small"
            run_tag = 'inverse_small';
        case "full_main"
            run_tag = 'inverse_full';
        case "custom"
            run_tag = 'inverse_custom';
        otherwise
            run_tag = 'inverse';
    end
end