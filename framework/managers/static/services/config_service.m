function cfg = config_service(profile)
if nargin < 1
    profile = struct();
end

cfg = struct();
cfg.profile = profile;

cfg.runtime = struct();
cfg.runtime.max_cases = 1;
cfg.runtime.max_designs = 1;

cfg.design = struct();
cfg.design.default_P = 8;
cfg.design.default_T = 8;
cfg.design.default_h_km = 800;
cfg.design.default_i_deg = 60;
end
