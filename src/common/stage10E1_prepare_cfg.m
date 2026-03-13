function cfg = stage10E1_prepare_cfg(cfg)
%STAGE10E1_PREPARE_CFG
% Prepare cfg for Stage10.E.1 refined screening rule benchmark.
%
% Rule design:
%   - zero-mode is the primary pass/fail gate
%   - bcirc-min is a warning / refine trigger, not a hard reject gate
%
% Labels:
%   reject      : zero_pass = false
%   safe_pass   : zero_pass = true  and bcirc_pass = true
%   warn_pass   : zero_pass = true  and bcirc_pass = false

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    cfg = stage10E_prepare_cfg(cfg);

    if ~isfield(cfg, 'stage10E1') || isempty(cfg.stage10E1)
        cfg.stage10E1 = struct();
    end

    if ~isfield(cfg.stage10E1, 'run_tag') || isempty(cfg.stage10E1.run_tag)
        cfg.stage10E1.run_tag = 'screen_refine';
    end

    if ~isfield(cfg.stage10E1, 'case_index') || isempty(cfg.stage10E1.case_index)
        cfg.stage10E1.case_index = cfg.stage10E.case_index;
    end
    if ~isfield(cfg.stage10E1, 'window_index') || isempty(cfg.stage10E1.window_index)
        cfg.stage10E1.window_index = cfg.stage10E.window_index;
    end
    if ~isfield(cfg.stage10E1, 'anchor_mode') || isempty(cfg.stage10E1.anchor_mode)
        cfg.stage10E1.anchor_mode = cfg.stage10E.anchor_mode;
    end
    if ~isfield(cfg.stage10E1, 'manual_anchor_plane') || isempty(cfg.stage10E1.manual_anchor_plane)
        cfg.stage10E1.manual_anchor_plane = cfg.stage10E.manual_anchor_plane;
    end
    if ~isfield(cfg.stage10E1, 'prototype_source') || isempty(cfg.stage10E1.prototype_source)
        cfg.stage10E1.prototype_source = cfg.stage10E.prototype_source;
    end

    % inherit small grid and thresholds from Stage10.E
    if ~isfield(cfg.stage10E1, 'grid_h_km') || isempty(cfg.stage10E1.grid_h_km)
        cfg.stage10E1.grid_h_km = cfg.stage10E.grid_h_km;
    end
    if ~isfield(cfg.stage10E1, 'grid_i_deg') || isempty(cfg.stage10E1.grid_i_deg)
        cfg.stage10E1.grid_i_deg = cfg.stage10E.grid_i_deg;
    end
    if ~isfield(cfg.stage10E1, 'grid_P') || isempty(cfg.stage10E1.grid_P)
        cfg.stage10E1.grid_P = cfg.stage10E.grid_P;
    end
    if ~isfield(cfg.stage10E1, 'grid_T') || isempty(cfg.stage10E1.grid_T)
        cfg.stage10E1.grid_T = cfg.stage10E.grid_T;
    end
    if ~isfield(cfg.stage10E1, 'grid_F') || isempty(cfg.stage10E1.grid_F)
        cfg.stage10E1.grid_F = cfg.stage10E.grid_F;
    end

    if ~isfield(cfg.stage10E1, 'threshold_truth') || isempty(cfg.stage10E1.threshold_truth)
        cfg.stage10E1.threshold_truth = cfg.stage10E.threshold_truth;
    end
    if ~isfield(cfg.stage10E1, 'threshold_zero') || isempty(cfg.stage10E1.threshold_zero)
        cfg.stage10E1.threshold_zero = cfg.stage10E.threshold_zero;
    end
    if ~isfield(cfg.stage10E1, 'threshold_bcirc') || isempty(cfg.stage10E1.threshold_bcirc)
        cfg.stage10E1.threshold_bcirc = cfg.stage10E.threshold_bcirc;
    end

    if ~isfield(cfg.stage10E1, 'make_plot') || isempty(cfg.stage10E1.make_plot)
        cfg.stage10E1.make_plot = true;
    end
    if ~isfield(cfg.stage10E1, 'write_csv') || isempty(cfg.stage10E1.write_csv)
        cfg.stage10E1.write_csv = true;
    end
    if ~isfield(cfg.stage10E1, 'save_mat_cache') || isempty(cfg.stage10E1.save_mat_cache)
        cfg.stage10E1.save_mat_cache = true;
    end
end