function cfg = stage10B1_prepare_cfg(cfg)
%STAGE10B1_PREPARE_CFG
% Prepare cfg for Stage10.B.1 legalizing a bcirc reference prototype.
%
% Stage10.B.1 performs:
%   1) mirror-compatibility enforcement on first-column blocks
%   2) PSD legalization in Fourier mode space
%
% Goal:
%   turn Stage10.B prototype into a legal bcirc baseline W_{r,0}.

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    cfg = stage10B_prepare_cfg(cfg);

    if ~isfield(cfg, 'stage10B1') || isempty(cfg.stage10B1)
        cfg.stage10B1 = struct();
    end

    if ~isfield(cfg.stage10B1, 'run_tag') || isempty(cfg.stage10B1.run_tag)
        cfg.stage10B1.run_tag = 'bcirclegal';
    end

    % inherit selection from Stage10.B by default
    if ~isfield(cfg.stage10B1, 'case_source') || isempty(cfg.stage10B1.case_source)
        cfg.stage10B1.case_source = cfg.stage10B.case_source;
    end
    if ~isfield(cfg.stage10B1, 'theta_source') || isempty(cfg.stage10B1.theta_source)
        cfg.stage10B1.theta_source = cfg.stage10B.theta_source;
    end
    if ~isfield(cfg.stage10B1, 'manual_theta') || isempty(cfg.stage10B1.manual_theta)
        cfg.stage10B1.manual_theta = cfg.stage10B.manual_theta;
    end
    if ~isfield(cfg.stage10B1, 'case_index') || isempty(cfg.stage10B1.case_index)
        cfg.stage10B1.case_index = cfg.stage10B.case_index;
    end
    if ~isfield(cfg.stage10B1, 'window_index') || isempty(cfg.stage10B1.window_index)
        cfg.stage10B1.window_index = cfg.stage10B.window_index;
    end
    if ~isfield(cfg.stage10B1, 'clip_case_index') || isempty(cfg.stage10B1.clip_case_index)
        cfg.stage10B1.clip_case_index = true;
    end
    if ~isfield(cfg.stage10B1, 'clip_window_index') || isempty(cfg.stage10B1.clip_window_index)
        cfg.stage10B1.clip_window_index = true;
    end
    if ~isfield(cfg.stage10B1, 'anchor_mode') || isempty(cfg.stage10B1.anchor_mode)
        cfg.stage10B1.anchor_mode = cfg.stage10B.anchor_mode;
    end
    if ~isfield(cfg.stage10B1, 'manual_anchor_plane') || isempty(cfg.stage10B1.manual_anchor_plane)
        cfg.stage10B1.manual_anchor_plane = cfg.stage10B.manual_anchor_plane;
    end

    cfg.stage10B1.case_index = round(cfg.stage10B1.case_index);
    cfg.stage10B1.window_index = round(cfg.stage10B1.window_index);

    if cfg.stage10B1.case_index < 1
        error('cfg.stage10B1.case_index must be >= 1.');
    end
    if cfg.stage10B1.window_index < 1
        error('cfg.stage10B1.window_index must be >= 1.');
    end

    if ~isfield(cfg.stage10B1, 'prototype_source') || isempty(cfg.stage10B1.prototype_source)
        cfg.stage10B1.prototype_source = 'active_anchor_mean';
    end
    valid_prototype_source = {'active_anchor_mean', 'anchor_relative'};
    if ~ismember(char(string(cfg.stage10B1.prototype_source)), valid_prototype_source)
        error('Unknown cfg.stage10B1.prototype_source: %s', string(cfg.stage10B1.prototype_source));
    end

    if ~isfield(cfg.stage10B1, 'force_block_symmetry') || isempty(cfg.stage10B1.force_block_symmetry)
        cfg.stage10B1.force_block_symmetry = true;
    end

    if ~isfield(cfg.stage10B1, 'do_mirror_symmetrization') || isempty(cfg.stage10B1.do_mirror_symmetrization)
        cfg.stage10B1.do_mirror_symmetrization = true;
    end

    if ~isfield(cfg.stage10B1, 'do_psd_projection') || isempty(cfg.stage10B1.do_psd_projection)
        cfg.stage10B1.do_psd_projection = true;
    end

    if ~isfield(cfg.stage10B1, 'psd_floor') || isempty(cfg.stage10B1.psd_floor)
        cfg.stage10B1.psd_floor = 0;
    end
    if ~isscalar(cfg.stage10B1.psd_floor) || cfg.stage10B1.psd_floor < 0
        error('cfg.stage10B1.psd_floor must be a nonnegative scalar.');
    end

    if ~isfield(cfg.stage10B1, 'make_plot') || isempty(cfg.stage10B1.make_plot)
        cfg.stage10B1.make_plot = true;
    end
    if ~isfield(cfg.stage10B1, 'write_csv') || isempty(cfg.stage10B1.write_csv)
        cfg.stage10B1.write_csv = true;
    end
    if ~isfield(cfg.stage10B1, 'save_mat_cache') || isempty(cfg.stage10B1.save_mat_cache)
        cfg.stage10B1.save_mat_cache = true;
    end

    if ~isfield(cfg.stage10B1, 'scan_log_every') || isempty(cfg.stage10B1.scan_log_every)
        cfg.stage10B1.scan_log_every = 1;
    end
    if cfg.stage10B1.scan_log_every < 1
        cfg.stage10B1.scan_log_every = 1;
    end
end