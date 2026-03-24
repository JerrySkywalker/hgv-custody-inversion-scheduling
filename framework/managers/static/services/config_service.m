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

cfg.design = struct();
cfg.design.default_P = 8;
cfg.design.default_T = 8;
cfg.design.default_h_km = 800;
cfg.design.default_i_deg = 60;
end
