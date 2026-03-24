function cfg = stage10C_prepare_cfg(cfg)
%STAGE10C_PREPARE_CFG
% Prepare cfg for Stage10.C FFT spectral validation.
%
% Stage10.C validates:
%   1) mode-wise FFT decomposition of legal bcirc baseline
%   2) consistency between full bcirc eig and mode-min eig
%   3) preliminary truth-vs-bcirc spectral comparison

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    cfg = stage10B1_prepare_cfg(cfg);

    if ~isfield(cfg, 'stage10C') || isempty(cfg.stage10C)
        cfg.stage10C = struct();
    end

    if ~isfield(cfg.stage10C, 'run_tag') || isempty(cfg.stage10C.run_tag)
        cfg.stage10C.run_tag = 'fftspec';
    end

    if ~isfield(cfg.stage10C, 'case_source') || isempty(cfg.stage10C.case_source)
        cfg.stage10C.case_source = cfg.stage10B1.case_source;
    end
    if ~isfield(cfg.stage10C, 'theta_source') || isempty(cfg.stage10C.theta_source)
        cfg.stage10C.theta_source = cfg.stage10B1.theta_source;
    end
    if ~isfield(cfg.stage10C, 'manual_theta') || isempty(cfg.stage10C.manual_theta)
        cfg.stage10C.manual_theta = cfg.stage10B1.manual_theta;
    end
    if ~isfield(cfg.stage10C, 'case_index') || isempty(cfg.stage10C.case_index)
        cfg.stage10C.case_index = cfg.stage10B1.case_index;
    end
    if ~isfield(cfg.stage10C, 'window_index') || isempty(cfg.stage10C.window_index)
        cfg.stage10C.window_index = cfg.stage10B1.window_index;
    end
    if ~isfield(cfg.stage10C, 'clip_case_index') || isempty(cfg.stage10C.clip_case_index)
        cfg.stage10C.clip_case_index = true;
    end
    if ~isfield(cfg.stage10C, 'clip_window_index') || isempty(cfg.stage10C.clip_window_index)
        cfg.stage10C.clip_window_index = true;
    end
    if ~isfield(cfg.stage10C, 'anchor_mode') || isempty(cfg.stage10C.anchor_mode)
        cfg.stage10C.anchor_mode = cfg.stage10B1.anchor_mode;
    end
    if ~isfield(cfg.stage10C, 'manual_anchor_plane') || isempty(cfg.stage10C.manual_anchor_plane)
        cfg.stage10C.manual_anchor_plane = cfg.stage10B1.manual_anchor_plane;
    end
    if ~isfield(cfg.stage10C, 'prototype_source') || isempty(cfg.stage10C.prototype_source)
        cfg.stage10C.prototype_source = cfg.stage10B1.prototype_source;
    end

    cfg.stage10C.case_index = round(cfg.stage10C.case_index);
    cfg.stage10C.window_index = round(cfg.stage10C.window_index);

    if cfg.stage10C.case_index < 1
        error('cfg.stage10C.case_index must be >= 1.');
    end
    if cfg.stage10C.window_index < 1
        error('cfg.stage10C.window_index must be >= 1.');
    end

    if ~isfield(cfg.stage10C, 'mode_order') || isempty(cfg.stage10C.mode_order)
        cfg.stage10C.mode_order = 'natural';
    end
    valid_mode_order = {'natural', 'sorted_by_lambda_min'};
    if ~ismember(char(string(cfg.stage10C.mode_order)), valid_mode_order)
        error('Unknown cfg.stage10C.mode_order: %s', string(cfg.stage10C.mode_order));
    end

    if ~isfield(cfg.stage10C, 'make_plot') || isempty(cfg.stage10C.make_plot)
        cfg.stage10C.make_plot = true;
    end
    if ~isfield(cfg.stage10C, 'write_csv') || isempty(cfg.stage10C.write_csv)
        cfg.stage10C.write_csv = true;
    end
    if ~isfield(cfg.stage10C, 'save_mat_cache') || isempty(cfg.stage10C.save_mat_cache)
        cfg.stage10C.save_mat_cache = true;
    end

    if ~isfield(cfg.stage10C, 'scan_log_every') || isempty(cfg.stage10C.scan_log_every)
        cfg.stage10C.scan_log_every = 1;
    end
    if cfg.stage10C.scan_log_every < 1
        cfg.stage10C.scan_log_every = 1;
    end
end