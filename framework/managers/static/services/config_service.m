function cfg = config_service(profile)
if nargin < 1
    profile = struct();
end

cfg = struct();
cfg.profile = profile;

cfg.runtime = struct();
cfg.runtime.max_designs = 3;

task_family = 'nominal';
if isfield(profile, 'task_family') && ~isempty(profile.task_family)
    task_family = lower(string(profile.task_family));
end

switch char(task_family)
    case 'nominal'
        cfg.runtime.max_cases = 1;
    case 'heading'
        cfg.runtime.max_cases = 3;
    otherwise
        cfg.runtime.max_cases = 1;
end

% Allow profile runtime overrides
if isfield(profile, 'runtime') && isstruct(profile.runtime)
    if isfield(profile.runtime, 'max_cases') && ~isempty(profile.runtime.max_cases)
        cfg.runtime.max_cases = profile.runtime.max_cases;
    end
    if isfield(profile.runtime, 'max_designs') && ~isempty(profile.runtime.max_designs)
        cfg.runtime.max_designs = profile.runtime.max_designs;
    end
end

cfg.design = struct();
cfg.design.default_P = 8;
cfg.design.default_T = 8;
cfg.design.default_h_km = 800;
cfg.design.default_i_deg = 60;

cfg.threshold = struct();
cfg.threshold.gamma_eff_scalar = 1.0;
cfg.threshold.gamma_source = 'default_unit_threshold';
cfg.threshold.Tw_s = [];

if isfield(profile, 'gamma_eff_scalar') && ~isempty(profile.gamma_eff_scalar)
    cfg.threshold.gamma_eff_scalar = profile.gamma_eff_scalar;
end

if isfield(profile, 'gamma_source') && ~isempty(profile.gamma_source)
    cfg.threshold.gamma_source = char(profile.gamma_source);
end

if isfield(profile, 'Tw_s') && ~isempty(profile.Tw_s)
    cfg.threshold.Tw_s = profile.Tw_s;
end

cfg.evaluator_mode = 'closedd';
if isfield(profile, 'evaluator_mode') && ~isempty(profile.evaluator_mode)
    cfg.evaluator_mode = char(lower(string(profile.evaluator_mode)));
end

cfg.engine_cfg = default_params();
if ~isempty(cfg.threshold.Tw_s)
    cfg.engine_cfg.stage04.Tw_s = cfg.threshold.Tw_s;
end
cfg.engine_cfg.stage04.gamma_req = cfg.threshold.gamma_eff_scalar;
end
