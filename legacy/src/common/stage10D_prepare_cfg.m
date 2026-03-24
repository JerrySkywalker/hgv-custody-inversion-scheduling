function cfg = stage10D_prepare_cfg(cfg)
%STAGE10D_PREPARE_CFG
% Prepare cfg for Stage10.D symmetry-breaking and margin analysis.
%
% Stage10.D compares three spectral quantities:
%   1) lambda_min(W_r)         : truth full
%   2) lambda_min(A_0)         : zero-mode reference
%   3) lambda_min(W_{r,0})     : legal bcirc full minimum
%
% It also defines a dimension-consistent symmetry-breaking norm
% using the embedded zero-mode baseline:
%   eps_sb_zero = ||W_r - A_0||_2

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    cfg = stage10C_prepare_cfg(cfg);

    if ~isfield(cfg, 'stage10D') || isempty(cfg.stage10D)
        cfg.stage10D = struct();
    end

    if ~isfield(cfg.stage10D, 'run_tag') || isempty(cfg.stage10D.run_tag)
        cfg.stage10D.run_tag = 'margin';
    end

    if ~isfield(cfg.stage10D, 'case_source') || isempty(cfg.stage10D.case_source)
        cfg.stage10D.case_source = cfg.stage10C.case_source;
    end
    if ~isfield(cfg.stage10D, 'theta_source') || isempty(cfg.stage10D.theta_source)
        cfg.stage10D.theta_source = cfg.stage10C.theta_source;
    end
    if ~isfield(cfg.stage10D, 'manual_theta') || isempty(cfg.stage10D.manual_theta)
        cfg.stage10D.manual_theta = cfg.stage10C.manual_theta;
    end
    if ~isfield(cfg.stage10D, 'case_index') || isempty(cfg.stage10D.case_index)
        cfg.stage10D.case_index = cfg.stage10C.case_index;
    end
    if ~isfield(cfg.stage10D, 'window_index') || isempty(cfg.stage10D.window_index)
        cfg.stage10D.window_index = cfg.stage10C.window_index;
    end
    if ~isfield(cfg.stage10D, 'clip_case_index') || isempty(cfg.stage10D.clip_case_index)
        cfg.stage10D.clip_case_index = true;
    end
    if ~isfield(cfg.stage10D, 'clip_window_index') || isempty(cfg.stage10D.clip_window_index)
        cfg.stage10D.clip_window_index = true;
    end
    if ~isfield(cfg.stage10D, 'anchor_mode') || isempty(cfg.stage10D.anchor_mode)
        cfg.stage10D.anchor_mode = cfg.stage10C.anchor_mode;
    end
    if ~isfield(cfg.stage10D, 'manual_anchor_plane') || isempty(cfg.stage10D.manual_anchor_plane)
        cfg.stage10D.manual_anchor_plane = cfg.stage10C.manual_anchor_plane;
    end
    if ~isfield(cfg.stage10D, 'prototype_source') || isempty(cfg.stage10D.prototype_source)
        cfg.stage10D.prototype_source = cfg.stage10C.prototype_source;
    end

    cfg.stage10D.case_index = round(cfg.stage10D.case_index);
    cfg.stage10D.window_index = round(cfg.stage10D.window_index);

    if cfg.stage10D.case_index < 1
        error('cfg.stage10D.case_index must be >= 1.');
    end
    if cfg.stage10D.window_index < 1
        error('cfg.stage10D.window_index must be >= 1.');
    end

    if ~isfield(cfg.stage10D, 'eps_norm_mode') || isempty(cfg.stage10D.eps_norm_mode)
        cfg.stage10D.eps_norm_mode = 2;
    end
    valid_eps_norm = {'fro', 2};
    is_ok = false;
    if ischar(cfg.stage10D.eps_norm_mode) || isstring(cfg.stage10D.eps_norm_mode)
        is_ok = strcmpi(char(string(cfg.stage10D.eps_norm_mode)), 'fro');
    elseif isnumeric(cfg.stage10D.eps_norm_mode) && isscalar(cfg.stage10D.eps_norm_mode)
        is_ok = (cfg.stage10D.eps_norm_mode == 2);
    end
    if ~is_ok
        error('cfg.stage10D.eps_norm_mode must be ''fro'' or 2.');
    end

    if ~isfield(cfg.stage10D, 'make_plot') || isempty(cfg.stage10D.make_plot)
        cfg.stage10D.make_plot = true;
    end
    if ~isfield(cfg.stage10D, 'write_csv') || isempty(cfg.stage10D.write_csv)
        cfg.stage10D.write_csv = true;
    end
    if ~isfield(cfg.stage10D, 'save_mat_cache') || isempty(cfg.stage10D.save_mat_cache)
        cfg.stage10D.save_mat_cache = true;
    end

    if ~isfield(cfg.stage10D, 'scan_log_every') || isempty(cfg.stage10D.scan_log_every)
        cfg.stage10D.scan_log_every = 1;
    end
    if cfg.stage10D.scan_log_every < 1
        cfg.stage10D.scan_log_every = 1;
    end
end