function cfg = stage10E_prepare_cfg(cfg)
%STAGE10E_PREPARE_CFG
% Prepare cfg for Stage10.E screening benchmark.
%
% Stage10.E benchmarks three decision layers on a small theta grid:
%   1) truth full lambda_min(W_r)
%   2) zero-mode lambda_min(A_0)
%   3) two-stage screening:
%        zero-mode pass  +  bcirc-min conservative check

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    cfg = stage10D_prepare_cfg(cfg);

    if ~isfield(cfg, 'stage10E') || isempty(cfg.stage10E)
        cfg.stage10E = struct();
    end

    if ~isfield(cfg.stage10E, 'run_tag') || isempty(cfg.stage10E.run_tag)
        cfg.stage10E.run_tag = 'screen';
    end

    if ~isfield(cfg.stage10E, 'case_source') || isempty(cfg.stage10E.case_source)
        cfg.stage10E.case_source = cfg.stage10D.case_source;
    end
    if ~isfield(cfg.stage10E, 'theta_source') || isempty(cfg.stage10E.theta_source)
        cfg.stage10E.theta_source = 'grid_manual';
    end
    valid_theta_source = {'grid_manual'};
    if ~ismember(char(string(cfg.stage10E.theta_source)), valid_theta_source)
        error('Unknown cfg.stage10E.theta_source: %s', string(cfg.stage10E.theta_source));
    end

    if ~isfield(cfg.stage10E, 'case_index') || isempty(cfg.stage10E.case_index)
        cfg.stage10E.case_index = cfg.stage10D.case_index;
    end
    if ~isfield(cfg.stage10E, 'window_index') || isempty(cfg.stage10E.window_index)
        cfg.stage10E.window_index = cfg.stage10D.window_index;
    end
    if ~isfield(cfg.stage10E, 'clip_case_index') || isempty(cfg.stage10E.clip_case_index)
        cfg.stage10E.clip_case_index = true;
    end
    if ~isfield(cfg.stage10E, 'clip_window_index') || isempty(cfg.stage10E.clip_window_index)
        cfg.stage10E.clip_window_index = true;
    end
    if ~isfield(cfg.stage10E, 'anchor_mode') || isempty(cfg.stage10E.anchor_mode)
        cfg.stage10E.anchor_mode = cfg.stage10D.anchor_mode;
    end
    if ~isfield(cfg.stage10E, 'manual_anchor_plane') || isempty(cfg.stage10E.manual_anchor_plane)
        cfg.stage10E.manual_anchor_plane = cfg.stage10D.manual_anchor_plane;
    end
    if ~isfield(cfg.stage10E, 'prototype_source') || isempty(cfg.stage10E.prototype_source)
        cfg.stage10E.prototype_source = cfg.stage10D.prototype_source;
    end

    cfg.stage10E.case_index = round(cfg.stage10E.case_index);
    cfg.stage10E.window_index = round(cfg.stage10E.window_index);

    if cfg.stage10E.case_index < 1
        error('cfg.stage10E.case_index must be >= 1.');
    end
    if cfg.stage10E.window_index < 1
        error('cfg.stage10E.window_index must be >= 1.');
    end

    % Small benchmark grid
    if ~isfield(cfg.stage10E, 'grid_h_km') || isempty(cfg.stage10E.grid_h_km)
        cfg.stage10E.grid_h_km = [900, 1000, 1100];
    end
    if ~isfield(cfg.stage10E, 'grid_i_deg') || isempty(cfg.stage10E.grid_i_deg)
        cfg.stage10E.grid_i_deg = [60, 70, 80];
    end
    if ~isfield(cfg.stage10E, 'grid_P') || isempty(cfg.stage10E.grid_P)
        cfg.stage10E.grid_P = [6, 8];
    end
    if ~isfield(cfg.stage10E, 'grid_T') || isempty(cfg.stage10E.grid_T)
        cfg.stage10E.grid_T = [10, 12];
    end
    if ~isfield(cfg.stage10E, 'grid_F') || isempty(cfg.stage10E.grid_F)
        cfg.stage10E.grid_F = 1;
    end

    % Screening thresholds
    if ~isfield(cfg.stage10E, 'threshold_truth') || isempty(cfg.stage10E.threshold_truth)
        cfg.stage10E.threshold_truth = 2.0e4;
    end
    if ~isfield(cfg.stage10E, 'threshold_zero') || isempty(cfg.stage10E.threshold_zero)
        cfg.stage10E.threshold_zero = cfg.stage10E.threshold_truth;
    end
    if ~isfield(cfg.stage10E, 'threshold_bcirc') || isempty(cfg.stage10E.threshold_bcirc)
        cfg.stage10E.threshold_bcirc = 1.0;
    end

    % Whether two-stage requires both zero and bcirc pass
    if ~isfield(cfg.stage10E, 'two_stage_rule') || isempty(cfg.stage10E.two_stage_rule)
        cfg.stage10E.two_stage_rule = 'zero_pass_and_bcirc_nonnegative';
    end
    valid_rule = {'zero_pass_and_bcirc_nonnegative', 'zero_pass_only'};
    if ~ismember(char(string(cfg.stage10E.two_stage_rule)), valid_rule)
        error('Unknown cfg.stage10E.two_stage_rule: %s', string(cfg.stage10E.two_stage_rule));
    end

    if ~isfield(cfg.stage10E, 'make_plot') || isempty(cfg.stage10E.make_plot)
        cfg.stage10E.make_plot = true;
    end
    if ~isfield(cfg.stage10E, 'write_csv') || isempty(cfg.stage10E.write_csv)
        cfg.stage10E.write_csv = true;
    end
    if ~isfield(cfg.stage10E, 'save_mat_cache') || isempty(cfg.stage10E.save_mat_cache)
        cfg.stage10E.save_mat_cache = true;
    end
end