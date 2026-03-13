function cfg = stage10_prepare_cfg(cfg)
%STAGE10_PREPARE_CFG
% Normalize / resolve Stage10 configuration fields.
%
% Stage10.1 responsibility:
%   - ensure cfg.stage10 exists
%   - normalize run_tag / mode / source switches
%   - normalize single-window debug selectors
%   - provide Stage10-specific defaults in one place
%   - keep Stage09 numeric kernel compatible

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    if ~isfield(cfg, 'stage10') || isempty(cfg.stage10)
        cfg.stage10 = struct();
    end

    % ------------------------------------------------------------
    % Reuse Stage09 kernel defaults if needed
    % ------------------------------------------------------------
    if ~isfield(cfg, 'stage09') || isempty(cfg.stage09)
        cfg = stage09_prepare_cfg(cfg);
    else
        cfg = stage09_prepare_cfg(cfg);
    end

    % ------------------------------------------------------------
    % Basic tags
    % ------------------------------------------------------------
    if ~isfield(cfg.stage10, 'run_tag') || isempty(cfg.stage10.run_tag)
        cfg.stage10.run_tag = 'fftcheck';
    end

    if ~isfield(cfg.stage10, 'mode') || isempty(cfg.stage10.mode)
        cfg.stage10.mode = 'single_window_debug';
    end

    valid_mode = {'single_window_debug', 'full'};
    if ~ismember(char(string(cfg.stage10.mode)), valid_mode)
        error('Unknown cfg.stage10.mode: %s', string(cfg.stage10.mode));
    end

    % ------------------------------------------------------------
    % Source modes
    % ------------------------------------------------------------
    if ~isfield(cfg.stage10, 'case_source') || isempty(cfg.stage10.case_source)
        cfg.stage10.case_source = 'inherit_stage09_casebank';
    end
    valid_case_source = {'inherit_stage09_casebank', 'custom'};
    if ~ismember(char(string(cfg.stage10.case_source)), valid_case_source)
        error('Unknown cfg.stage10.case_source: %s', string(cfg.stage10.case_source));
    end

    if ~isfield(cfg.stage10, 'theta_source') || isempty(cfg.stage10.theta_source)
        cfg.stage10.theta_source = 'first_search_row';
    end
    valid_theta_source = {'first_search_row', 'manual'};
    if ~ismember(char(string(cfg.stage10.theta_source)), valid_theta_source)
        error('Unknown cfg.stage10.theta_source: %s', string(cfg.stage10.theta_source));
    end

    % ------------------------------------------------------------
    % Manual theta
    % ------------------------------------------------------------
    if ~isfield(cfg.stage10, 'manual_theta') || isempty(cfg.stage10.manual_theta)
        cfg.stage10.manual_theta = struct();
    end
    mt = cfg.stage10.manual_theta;

    if ~isfield(mt, 'h_km') || isempty(mt.h_km)
        mt.h_km = 1000;
    end
    if ~isfield(mt, 'i_deg') || isempty(mt.i_deg)
        mt.i_deg = 60;
    end
    if ~isfield(mt, 'P') || isempty(mt.P)
        mt.P = 8;
    end
    if ~isfield(mt, 'T') || isempty(mt.T)
        mt.T = 4;
    end
    if ~isfield(mt, 'F') || isempty(mt.F)
        mt.F = 1;
    end

    mt.h_km = round(mt.h_km);
    mt.i_deg = round(mt.i_deg);
    mt.P = round(mt.P);
    mt.T = round(mt.T);
    mt.F = round(mt.F);

    if mt.h_km <= 0
        error('cfg.stage10.manual_theta.h_km must be > 0.');
    end
    if mt.i_deg < 0 || mt.i_deg > 180
        error('cfg.stage10.manual_theta.i_deg must be in [0, 180].');
    end
    if mt.P < 1 || mt.T < 1
        error('cfg.stage10.manual_theta.P/T must be >= 1.');
    end

    cfg.stage10.manual_theta = mt;

    % ------------------------------------------------------------
    % Single-case / single-window selectors
    % ------------------------------------------------------------
    if ~isfield(cfg.stage10, 'case_index') || isempty(cfg.stage10.case_index)
        cfg.stage10.case_index = 1;
    end
    if ~isfield(cfg.stage10, 'window_index') || isempty(cfg.stage10.window_index)
        cfg.stage10.window_index = 1;
    end
    if ~isfield(cfg.stage10, 'clip_case_index') || isempty(cfg.stage10.clip_case_index)
        cfg.stage10.clip_case_index = true;
    end
    if ~isfield(cfg.stage10, 'clip_window_index') || isempty(cfg.stage10.clip_window_index)
        cfg.stage10.clip_window_index = true;
    end

    cfg.stage10.case_index = round(cfg.stage10.case_index);
    cfg.stage10.window_index = round(cfg.stage10.window_index);

    if cfg.stage10.case_index < 1
        error('cfg.stage10.case_index must be >= 1.');
    end
    if cfg.stage10.window_index < 1
        error('cfg.stage10.window_index must be >= 1.');
    end

    % ------------------------------------------------------------
    % Stage10.1 structured-spectrum defaults
    % ------------------------------------------------------------
    if ~isfield(cfg.stage10, 'force_symmetric') || isempty(cfg.stage10.force_symmetric)
        cfg.stage10.force_symmetric = true;
    end

    if ~isfield(cfg.stage10, 'active_plane_min_trace') || isempty(cfg.stage10.active_plane_min_trace)
        cfg.stage10.active_plane_min_trace = 0;
    end

    if ~isfield(cfg.stage10, 'shape_norm_mode') || isempty(cfg.stage10.shape_norm_mode)
        cfg.stage10.shape_norm_mode = 'trace';
    end
    valid_shape_norm_mode = {'trace', 'fro'};
    if ~ismember(char(string(cfg.stage10.shape_norm_mode)), valid_shape_norm_mode)
        error('Unknown cfg.stage10.shape_norm_mode: %s', string(cfg.stage10.shape_norm_mode));
    end

    if ~isfield(cfg.stage10, 'fft_proxy_mode') || isempty(cfg.stage10.fft_proxy_mode)
        cfg.stage10.fft_proxy_mode = 'lag0_mean_block';
    end
    valid_fft_proxy_mode = {'lag0_mean_block'};
    if ~ismember(char(string(cfg.stage10.fft_proxy_mode)), valid_fft_proxy_mode)
        error('Unknown cfg.stage10.fft_proxy_mode: %s', string(cfg.stage10.fft_proxy_mode));
    end

    if ~isfield(cfg.stage10, 'eps_sb_norm') || isempty(cfg.stage10.eps_sb_norm)
        cfg.stage10.eps_sb_norm = 'fro';
    end
    valid_eps_norm = {'fro', 2};
    is_ok_eps = false;
    if ischar(cfg.stage10.eps_sb_norm) || isstring(cfg.stage10.eps_sb_norm)
        is_ok_eps = any(strcmpi(char(string(cfg.stage10.eps_sb_norm)), {'fro'}));
    elseif isnumeric(cfg.stage10.eps_sb_norm) && isscalar(cfg.stage10.eps_sb_norm)
        is_ok_eps = any(cfg.stage10.eps_sb_norm == [2]);
    end
    if ~is_ok_eps
        error('Unknown cfg.stage10.eps_sb_norm. Allowed: ''fro'' or 2.');
    end

    if ~isfield(cfg.stage10, 'compute_bounds') || isempty(cfg.stage10.compute_bounds)
        cfg.stage10.compute_bounds = true;
    end

    % ------------------------------------------------------------
    % Outputs
    % ------------------------------------------------------------
    if ~isfield(cfg.stage10, 'write_csv') || isempty(cfg.stage10.write_csv)
        cfg.stage10.write_csv = true;
    end
    if ~isfield(cfg.stage10, 'save_mat_cache') || isempty(cfg.stage10.save_mat_cache)
        cfg.stage10.save_mat_cache = true;
    end
    if ~isfield(cfg.stage10, 'make_plot') || isempty(cfg.stage10.make_plot)
        cfg.stage10.make_plot = false;
    end
    if ~isfield(cfg.stage10, 'scan_log_every') || isempty(cfg.stage10.scan_log_every)
        cfg.stage10.scan_log_every = 1;
    end
    if cfg.stage10.scan_log_every < 1
        cfg.stage10.scan_log_every = 1;
    end
end