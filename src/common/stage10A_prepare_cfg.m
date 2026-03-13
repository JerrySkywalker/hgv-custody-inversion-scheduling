function cfg = stage10A_prepare_cfg(cfg)
%STAGE10A_PREPARE_CFG
% Prepare cfg for Stage10.A truth-structure diagnostics.
%
% This stage is intentionally truth-side only:
%   - no FFT proxy
%   - no template fitting
%   - no screening
%
% It answers:
%   1) what does the per-plane window information structure look like?
%   2) how sparse / concentrated is the active-plane support?
%   3) is this window structurally suitable for later bcirc/FFT approximation?

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    % Reuse Stage09 / Stage10 common defaults first.
    cfg = stage10_prepare_cfg(cfg);

    if ~isfield(cfg, 'stage10A') || isempty(cfg.stage10A)
        cfg.stage10A = struct();
    end

    if ~isfield(cfg.stage10A, 'run_tag') || isempty(cfg.stage10A.run_tag)
        cfg.stage10A.run_tag = 'truthdiag';
    end

    if ~isfield(cfg.stage10A, 'case_source') || isempty(cfg.stage10A.case_source)
        cfg.stage10A.case_source = 'inherit_stage09_casebank';
    end
    valid_case_source = {'inherit_stage09_casebank', 'custom'};
    if ~ismember(char(string(cfg.stage10A.case_source)), valid_case_source)
        error('Unknown cfg.stage10A.case_source: %s', string(cfg.stage10A.case_source));
    end

    if ~isfield(cfg.stage10A, 'theta_source') || isempty(cfg.stage10A.theta_source)
        % Follow Stage10 default unless explicitly overridden.
        cfg.stage10A.theta_source = cfg.stage10.theta_source;
    end
    valid_theta_source = {'first_search_row', 'manual'};
    if ~ismember(char(string(cfg.stage10A.theta_source)), valid_theta_source)
        error('Unknown cfg.stage10A.theta_source: %s', string(cfg.stage10A.theta_source));
    end

    if ~isfield(cfg.stage10A, 'manual_theta') || isempty(cfg.stage10A.manual_theta)
        cfg.stage10A.manual_theta = cfg.stage10.manual_theta;
    end

    if ~isfield(cfg.stage10A, 'case_index') || isempty(cfg.stage10A.case_index)
        cfg.stage10A.case_index = cfg.stage10.case_index;
    end
    if ~isfield(cfg.stage10A, 'window_index') || isempty(cfg.stage10A.window_index)
        cfg.stage10A.window_index = cfg.stage10.window_index;
    end
    if ~isfield(cfg.stage10A, 'clip_case_index') || isempty(cfg.stage10A.clip_case_index)
        cfg.stage10A.clip_case_index = true;
    end
    if ~isfield(cfg.stage10A, 'clip_window_index') || isempty(cfg.stage10A.clip_window_index)
        cfg.stage10A.clip_window_index = true;
    end

    cfg.stage10A.case_index = round(cfg.stage10A.case_index);
    cfg.stage10A.window_index = round(cfg.stage10A.window_index);

    if cfg.stage10A.case_index < 1
        error('cfg.stage10A.case_index must be >= 1.');
    end
    if cfg.stage10A.window_index < 1
        error('cfg.stage10A.window_index must be >= 1.');
    end

    if ~isfield(cfg.stage10A, 'anchor_mode') || isempty(cfg.stage10A.anchor_mode)
        % reference plane for relative-lag truth view
        cfg.stage10A.anchor_mode = 'max_trace_active';
    end
    valid_anchor_mode = {'max_trace_active', 'first_active', 'manual'};
    if ~ismember(char(string(cfg.stage10A.anchor_mode)), valid_anchor_mode)
        error('Unknown cfg.stage10A.anchor_mode: %s', string(cfg.stage10A.anchor_mode));
    end

    if ~isfield(cfg.stage10A, 'manual_anchor_plane') || isempty(cfg.stage10A.manual_anchor_plane)
        cfg.stage10A.manual_anchor_plane = 1;
    end
    cfg.stage10A.manual_anchor_plane = round(cfg.stage10A.manual_anchor_plane);

    if ~isfield(cfg.stage10A, 'active_plane_min_trace') || isempty(cfg.stage10A.active_plane_min_trace)
        cfg.stage10A.active_plane_min_trace = cfg.stage10.active_plane_min_trace;
    end

    if ~isfield(cfg.stage10A, 'force_symmetric') || isempty(cfg.stage10A.force_symmetric)
        cfg.stage10A.force_symmetric = true;
    end

    if ~isfield(cfg.stage10A, 'make_plot') || isempty(cfg.stage10A.make_plot)
        cfg.stage10A.make_plot = true;
    end
    if ~isfield(cfg.stage10A, 'write_csv') || isempty(cfg.stage10A.write_csv)
        cfg.stage10A.write_csv = true;
    end
    if ~isfield(cfg.stage10A, 'save_mat_cache') || isempty(cfg.stage10A.save_mat_cache)
        cfg.stage10A.save_mat_cache = true;
    end

    if ~isfield(cfg.stage10A, 'plot_visible') || isempty(cfg.stage10A.plot_visible)
        cfg.stage10A.plot_visible = false;
    end

    if ~isfield(cfg.stage10A, 'entropy_eps') || isempty(cfg.stage10A.entropy_eps)
        cfg.stage10A.entropy_eps = 1e-12;
    end

    if ~isfield(cfg.stage10A, 'scan_log_every') || isempty(cfg.stage10A.scan_log_every)
        cfg.stage10A.scan_log_every = 1;
    end
    if cfg.stage10A.scan_log_every < 1
        cfg.stage10A.scan_log_every = 1;
    end
end