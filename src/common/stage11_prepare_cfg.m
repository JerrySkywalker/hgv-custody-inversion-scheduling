function cfg = stage11_prepare_cfg(cfg)
%STAGE11_PREPARE_CFG Normalize / resolve Stage11 configuration fields.

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    cfg = stage10F_prepare_cfg(cfg);

    if ~isfield(cfg, 'stage11') || isempty(cfg.stage11)
        cfg.stage11 = struct();
    end

    if ~isfield(cfg.stage11, 'entry') || isempty(cfg.stage11.entry)
        cfg.stage11.entry = 'all';
    end
    if ~strcmpi(char(string(cfg.stage11.entry)), 'all')
        error('Unknown cfg.stage11.entry: %s', string(cfg.stage11.entry));
    end

    defaults = default_params();
    default_stage11 = defaults.stage11;
    field_names = fieldnames(default_stage11);
    for i = 1:numel(field_names)
        name = field_names{i};
        if ~isfield(cfg.stage11, name) || isempty(cfg.stage11.(name))
            cfg.stage11.(name) = default_stage11.(name);
        end
    end

    cfg.stage11.case_index = round(cfg.stage11.case_index);
    cfg.stage11.window_index = round(cfg.stage11.window_index);
    cfg.stage11.scan_log_every = max(1, round(cfg.stage11.scan_log_every));
    cfg.stage11.reference_case_index = round(cfg.stage11.reference_case_index);
    cfg.stage11.reference_window_index = round(cfg.stage11.reference_window_index);

    valid_rep_source = {'reference_library'};
    if ~ismember(char(string(cfg.stage11.rep_source)), valid_rep_source)
        error('Unsupported cfg.stage11.rep_source: %s', string(cfg.stage11.rep_source));
    end

    valid_ref_theta_source = {'manual'};
    if ~ismember(char(string(cfg.stage11.reference_theta_source)), valid_ref_theta_source)
        error('Unsupported cfg.stage11.reference_theta_source: %s', string(cfg.stage11.reference_theta_source));
    end

    valid_theta_source = {'stage10e1_grid', 'config_grid'};
    if ~ismember(lower(char(string(cfg.stage11.theta_source))), valid_theta_source)
        error('Unsupported cfg.stage11.theta_source: %s', string(cfg.stage11.theta_source));
    end

    valid_reference_fallback = {'leave_one_out', 'invalid'};
    if ~ismember(char(string(cfg.stage11.reference_fallback)), valid_reference_fallback)
        error('Unsupported cfg.stage11.reference_fallback: %s', string(cfg.stage11.reference_fallback));
    end

    if ~isfield(cfg.stage11, 'gamma_G') || isempty(cfg.stage11.gamma_G)
        cfg.stage11.gamma_G = cfg.stage11.threshold_truth;
    end
    if ~isscalar(cfg.stage11.gamma_G) || ~isfinite(cfg.stage11.gamma_G) || cfg.stage11.gamma_G <= 0
        error('cfg.stage11.gamma_G must be a positive finite scalar.');
    end
end
