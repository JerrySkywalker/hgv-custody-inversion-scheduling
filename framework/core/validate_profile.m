function validate_profile(profile)
%VALIDATE_PROFILE Validate user-facing experiment profile.
%   This function performs lightweight validation only. The profile is
%   allowed to be partial because defaults will be applied later.

    if nargin < 1 || isempty(profile)
        return;
    end

    if ~isstruct(profile)
        error('validate_profile:TypeError', ...
            'Profile must be a struct.');
    end

    if isfield(profile, 'meta')
        if ~isstruct(profile.meta)
            error('validate_profile:MetaTypeError', ...
                'profile.meta must be a struct.');
        end

        if isfield(profile.meta, 'run_name')
            if ~(ischar(profile.meta.run_name) || isStringScalar(profile.meta.run_name))
                error('validate_profile:RunNameTypeError', ...
                    'profile.meta.run_name must be char or string scalar.');
            end
        end

        if isfield(profile.meta, 'mode')
            if ~(ischar(profile.meta.mode) || isStringScalar(profile.meta.mode))
                error('validate_profile:ModeTypeError', ...
                    'profile.meta.mode must be char or string scalar.');
            end
        end
    end

    if isfield(profile, 'runtime_def') && ~isstruct(profile.runtime_def)
        error('validate_profile:RuntimeTypeError', ...
            'profile.runtime_def must be a struct.');
    end

    if isfield(profile, 'scenario_def') && ~isstruct(profile.scenario_def)
        error('validate_profile:ScenarioTypeError', ...
            'profile.scenario_def must be a struct.');
    end

    if isfield(profile, 'trajectory_registry_def') && ~isstruct(profile.trajectory_registry_def)
        error('validate_profile:TrajectoryRegistryTypeError', ...
            'profile.trajectory_registry_def must be a struct.');
    end

    if isfield(profile, 'task_family_def') && ~isstruct(profile.task_family_def)
        error('validate_profile:TaskFamilyTypeError', ...
            'profile.task_family_def must be a struct.');
    end

    if isfield(profile, 'aggregation_def') && ~isstruct(profile.aggregation_def)
        error('validate_profile:AggregationTypeError', ...
            'profile.aggregation_def must be a struct.');
    end

    if isfield(profile, 'output_def') && ~isstruct(profile.output_def)
        error('validate_profile:OutputTypeError', ...
            'profile.output_def must be a struct.');
    end
end

function tf = isStringScalar(x)
    tf = isa(x, 'string') && isscalar(x);
end
