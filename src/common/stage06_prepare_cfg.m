function cfg = stage06_prepare_cfg(cfg)
    %STAGE06_PREPARE_CFG
    % Normalize / resolve Stage06 configuration fields.
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
    
        % resolve active heading offsets
        if ~isfield(cfg, 'stage06') || isempty(cfg.stage06)
            error('cfg.stage06 is missing.');
        end
    
        if ~isfield(cfg.stage06, 'active_heading_set_name')
            cfg.stage06.active_heading_set_name = 'small';
        end
    
        switch lower(string(cfg.stage06.active_heading_set_name))
            case "small"
                cfg.stage06.active_heading_offsets_deg = cfg.stage06.heading_offsets_small_deg;
            case "full"
                cfg.stage06.active_heading_offsets_deg = cfg.stage06.heading_offsets_full_deg;
            case "custom"
                cfg.stage06.active_heading_offsets_deg = cfg.stage06.active_heading_offsets_custom_deg;
            otherwise
                error('Unknown cfg.stage06.active_heading_set_name: %s', cfg.stage06.active_heading_set_name);
        end
    
        cfg.stage06.active_heading_offsets_deg = cfg.stage06.active_heading_offsets_deg(:).';
    
        % default run tag
        if ~isfield(cfg.stage06, 'run_tag') || isempty(cfg.stage06.run_tag)
            cfg.stage06.run_tag = char(cfg.stage06.active_heading_set_name);
        end
    
        % expected family size
        if isfield(cfg.stage06, 'expected_nominal_case_count')
            cfg.stage06.expected_family_size = ...
                cfg.stage06.expected_nominal_case_count * numel(cfg.stage06.active_heading_offsets_deg);
        end
    end