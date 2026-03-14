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
end
