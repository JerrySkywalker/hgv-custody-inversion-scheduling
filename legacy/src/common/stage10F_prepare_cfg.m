function cfg = stage10F_prepare_cfg(cfg)
%STAGE10F_PREPARE_CFG
% Prepare cfg for Stage10.F final report packaging.
%
% Stage10.F packages Stage10.A-E.1 into:
%   - one master summary row for the selected representative sample
%   - one screening benchmark summary for the small theta grid
%   - one compact master figure for thesis use

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    cfg = stage10E1_prepare_cfg(cfg);

    if ~isfield(cfg, 'stage10F') || isempty(cfg.stage10F)
        cfg.stage10F = struct();
    end

    if ~isfield(cfg.stage10F, 'run_tag') || isempty(cfg.stage10F.run_tag)
        cfg.stage10F.run_tag = 'finalpack';
    end

    if ~isfield(cfg.stage10F, 'case_index') || isempty(cfg.stage10F.case_index)
        cfg.stage10F.case_index = cfg.stage10E1.case_index;
    end
    if ~isfield(cfg.stage10F, 'window_index') || isempty(cfg.stage10F.window_index)
        cfg.stage10F.window_index = cfg.stage10E1.window_index;
    end
    if ~isfield(cfg.stage10F, 'anchor_mode') || isempty(cfg.stage10F.anchor_mode)
        cfg.stage10F.anchor_mode = cfg.stage10E1.anchor_mode;
    end
    if ~isfield(cfg.stage10F, 'manual_anchor_plane') || isempty(cfg.stage10F.manual_anchor_plane)
        cfg.stage10F.manual_anchor_plane = cfg.stage10E1.manual_anchor_plane;
    end
    if ~isfield(cfg.stage10F, 'prototype_source') || isempty(cfg.stage10F.prototype_source)
        cfg.stage10F.prototype_source = cfg.stage10E1.prototype_source;
    end

    % Representative theta
    if ~isfield(cfg.stage10F, 'manual_theta') || isempty(cfg.stage10F.manual_theta)
        if isfield(cfg.stage10E1, 'manual_theta') && ~isempty(cfg.stage10E1.manual_theta)
            cfg.stage10F.manual_theta = cfg.stage10E1.manual_theta;
        else
            cfg.stage10F.manual_theta = struct( ...
                'h_km', 1000, ...
                'i_deg', 70, ...
                'P', 8, ...
                'T', 12, ...
                'F', 1);
        end
    end

    % inherit grid from E.1
    if ~isfield(cfg.stage10F, 'grid_h_km') || isempty(cfg.stage10F.grid_h_km)
        cfg.stage10F.grid_h_km = cfg.stage10E1.grid_h_km;
    end
    if ~isfield(cfg.stage10F, 'grid_i_deg') || isempty(cfg.stage10F.grid_i_deg)
        cfg.stage10F.grid_i_deg = cfg.stage10E1.grid_i_deg;
    end
    if ~isfield(cfg.stage10F, 'grid_P') || isempty(cfg.stage10F.grid_P)
        cfg.stage10F.grid_P = cfg.stage10E1.grid_P;
    end
    if ~isfield(cfg.stage10F, 'grid_T') || isempty(cfg.stage10F.grid_T)
        cfg.stage10F.grid_T = cfg.stage10E1.grid_T;
    end
    if ~isfield(cfg.stage10F, 'grid_F') || isempty(cfg.stage10F.grid_F)
        cfg.stage10F.grid_F = cfg.stage10E1.grid_F;
    end

    if ~isfield(cfg.stage10F, 'threshold_truth') || isempty(cfg.stage10F.threshold_truth)
        cfg.stage10F.threshold_truth = cfg.stage10E1.threshold_truth;
    end
    if ~isfield(cfg.stage10F, 'threshold_zero') || isempty(cfg.stage10F.threshold_zero)
        cfg.stage10F.threshold_zero = cfg.stage10E1.threshold_zero;
    end
    if ~isfield(cfg.stage10F, 'threshold_bcirc') || isempty(cfg.stage10F.threshold_bcirc)
        cfg.stage10F.threshold_bcirc = cfg.stage10E1.threshold_bcirc;
    end

    if ~isfield(cfg.stage10F, 'make_plot') || isempty(cfg.stage10F.make_plot)
        cfg.stage10F.make_plot = true;
    end
    if ~isfield(cfg.stage10F, 'write_csv') || isempty(cfg.stage10F.write_csv)
        cfg.stage10F.write_csv = true;
    end
    if ~isfield(cfg.stage10F, 'save_mat_cache') || isempty(cfg.stage10F.save_mat_cache)
        cfg.stage10F.save_mat_cache = true;
    end
end