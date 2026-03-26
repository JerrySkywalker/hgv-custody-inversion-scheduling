function validate_cfg(cfg)
%VALIDATE_CFG Validate strict framework runtime configuration.
%   Unlike validate_profile, this function assumes defaults have already
%   been applied and therefore checks required fields explicitly.

    if nargin < 1 || ~isstruct(cfg)
        error('validate_cfg:TypeError', ...
            'cfg must be a struct.');
    end

    mustHaveStruct(cfg, 'meta');
    mustHaveStruct(cfg, 'scenario_def');
    mustHaveStruct(cfg, 'trajectory_registry_def');
    mustHaveStruct(cfg, 'task_family_def');
    mustHaveStruct(cfg, 'aggregation_def');
    mustHaveStruct(cfg, 'runtime_def');
    mustHaveStruct(cfg, 'output_def');

    mustHaveText(cfg.meta, 'framework_version');
    mustHaveText(cfg.meta, 'stage_id');
    mustHaveText(cfg.meta, 'run_name');
    mustHaveText(cfg.meta, 'mode');

    mustHaveText(cfg.scenario_def, 'kind');

    mustHaveText(cfg.trajectory_registry_def, 'build_mode');
    mustHaveText(cfg.trajectory_registry_def, 'registry_name');

    mustHaveText(cfg.task_family_def, 'family_name');
    mustHaveText(cfg.task_family_def, 'selection_mode');

    mustHaveText(cfg.aggregation_def, 'level');
    mustHaveText(cfg.aggregation_def, 'envelope_rule');

    if ~isfield(cfg.aggregation_def, 'group_keys') || ~iscell(cfg.aggregation_def.group_keys)
        error('validate_cfg:GroupKeysTypeError', ...
            'cfg.aggregation_def.group_keys must be a cell array.');
    end

    if ~isfield(cfg.runtime_def, 'max_cases')
        error('validate_cfg:MissingRuntimeMaxCases', ...
            'cfg.runtime_def.max_cases is required.');
    end

    if ~isfield(cfg.runtime_def, 'max_designs')
        error('validate_cfg:MissingRuntimeMaxDesigns', ...
            'cfg.runtime_def.max_designs is required.');
    end

    mustHaveText(cfg.output_def, 'root_dir');
    mustHaveText(cfg.output_def, 'chapter');
    mustHaveText(cfg.output_def, 'namespace');
end

function mustHaveStruct(s, fieldName)
    if ~isfield(s, fieldName) || ~isstruct(s.(fieldName))
        error('validate_cfg:MissingStructField', ...
            'cfg.%s must exist and be a struct.', fieldName);
    end
end

function mustHaveText(s, fieldName)
    if ~isfield(s, fieldName)
        error('validate_cfg:MissingTextField', ...
            'Required field missing: %s', fieldName);
    end

    value = s.(fieldName);
    if ~(ischar(value) || (isa(value, 'string') && isscalar(value)))
        error('validate_cfg:TextFieldTypeError', ...
            'Field %s must be char or string scalar.', fieldName);
    end
end
