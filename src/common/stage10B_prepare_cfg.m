function cfg = stage10B_prepare_cfg(cfg)
%STAGE10B_PREPARE_CFG
% Prepare cfg for Stage10.B bcirc reference construction.
%
% Stage10.B builds a first workable truth-derived block-circulant baseline:
%   - reuse Stage10.A truth-side structural extraction
%   - use active-anchor mean lag blocks as first-column prototype
%   - reconstruct full bcirc matrix
%   - compare against a truth-side reduced reference matrix

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    cfg = stage10A_prepare_cfg(cfg);

    if ~isfield(cfg, 'stage10B') || isempty(cfg.stage10B)
        cfg.stage10B = struct();
    end

    if ~isfield(cfg.stage10B, 'run_tag') || isempty(cfg.stage10B.run_tag)
        cfg.stage10B.run_tag = 'bcircref';
    end

    if ~isfield(cfg.stage10B, 'case_source') || isempty(cfg.stage10B.case_source)
        cfg.stage10B.case_source = cfg.stage10A.case_source;
    end
    valid_case_source = {'inherit_stage09_casebank', 'custom'};
    if ~ismember(char(string(cfg.stage10B.case_source)), valid_case_source)
        error('Unknown cfg.stage10B.case_source: %s', string(cfg.stage10B.case_source));
    end

    if ~isfield(cfg.stage10B, 'theta_source') || isempty(cfg.stage10B.theta_source)
        cfg.stage10B.theta_source = cfg.stage10A.theta_source;
    end
    valid_theta_source = {'first_search_row', 'manual'};
    if ~ismember(char(string(cfg.stage10B.theta_source)), valid_theta_source)
        error('Unknown cfg.stage10B.theta_source: %s', string(cfg.stage10B.theta_source));
    end

    if ~isfield(cfg.stage10B, 'manual_theta') || isempty(cfg.stage10B.manual_theta)
        cfg.stage10B.manual_theta = cfg.stage10A.manual_theta;
    end

    if ~isfield(cfg.stage10B, 'case_index') || isempty(cfg.stage10B.case_index)
        cfg.stage10B.case_index = cfg.stage10A.case_index;
    end
    if ~isfield(cfg.stage10B, 'window_index') || isempty(cfg.stage10B.window_index)
        cfg.stage10B.window_index = cfg.stage10A.window_index;
    end
    if ~isfield(cfg.stage10B, 'clip_case_index') || isempty(cfg.stage10B.clip_case_index)
        cfg.stage10B.clip_case_index = true;
    end
    if ~isfield(cfg.stage10B, 'clip_window_index') || isempty(cfg.stage10B.clip_window_index)
        cfg.stage10B.clip_window_index = true;
    end

    cfg.stage10B.case_index = round(cfg.stage10B.case_index);
    cfg.stage10B.window_index = round(cfg.stage10B.window_index);

    if cfg.stage10B.case_index < 1
        error('cfg.stage10B.case_index must be >= 1.');
    end
    if cfg.stage10B.window_index < 1
        error('cfg.stage10B.window_index must be >= 1.');
    end

    if ~isfield(cfg.stage10B, 'anchor_mode') || isempty(cfg.stage10B.anchor_mode)
        cfg.stage10B.anchor_mode = cfg.stage10A.anchor_mode;
    end
    valid_anchor_mode = {'max_trace_active', 'first_active', 'manual'};
    if ~ismember(char(string(cfg.stage10B.anchor_mode)), valid_anchor_mode)
        error('Unknown cfg.stage10B.anchor_mode: %s', string(cfg.stage10B.anchor_mode));
    end

    if ~isfield(cfg.stage10B, 'manual_anchor_plane') || isempty(cfg.stage10B.manual_anchor_plane)
        cfg.stage10B.manual_anchor_plane = cfg.stage10A.manual_anchor_plane;
    end

    if ~isfield(cfg.stage10B, 'force_symmetric') || isempty(cfg.stage10B.force_symmetric)
        cfg.stage10B.force_symmetric = true;
    end

    if ~isfield(cfg.stage10B, 'bcirc_firstcol_source') || isempty(cfg.stage10B.bcirc_firstcol_source)
        cfg.stage10B.bcirc_firstcol_source = 'active_anchor_mean';
    end
    valid_firstcol_source = {'active_anchor_mean', 'anchor_relative'};
    if ~ismember(char(string(cfg.stage10B.bcirc_firstcol_source)), valid_firstcol_source)
        error('Unknown cfg.stage10B.bcirc_firstcol_source: %s', string(cfg.stage10B.bcirc_firstcol_source));
    end

    if ~isfield(cfg.stage10B, 'truth_reduced_source') || isempty(cfg.stage10B.truth_reduced_source)
        cfg.stage10B.truth_reduced_source = 'active_anchor_mean';
    end
    valid_truth_source = {'active_anchor_mean', 'anchor_relative'};
    if ~ismember(char(string(cfg.stage10B.truth_reduced_source)), valid_truth_source)
        error('Unknown cfg.stage10B.truth_reduced_source: %s', string(cfg.stage10B.truth_reduced_source));
    end

    if ~isfield(cfg.stage10B, 'make_plot') || isempty(cfg.stage10B.make_plot)
        cfg.stage10B.make_plot = true;
    end
    if ~isfield(cfg.stage10B, 'write_csv') || isempty(cfg.stage10B.write_csv)
        cfg.stage10B.write_csv = true;
    end
    if ~isfield(cfg.stage10B, 'save_mat_cache') || isempty(cfg.stage10B.save_mat_cache)
        cfg.stage10B.save_mat_cache = true;
    end

    if ~isfield(cfg.stage10B, 'scan_log_every') || isempty(cfg.stage10B.scan_log_every)
        cfg.stage10B.scan_log_every = 1;
    end
    if cfg.stage10B.scan_log_every < 1
        cfg.stage10B.scan_log_every = 1;
    end
end