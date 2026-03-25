function info = load_stage04_nominal_gamma_req()
startup;

repo_root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
stage04_cache_dir = fullfile(repo_root, 'legacy', 'outputs', 'stage', 'stage04', 'cache');

assert(exist(stage04_cache_dir, 'dir') == 7, ...
    'Stage04 cache directory not found: %s', stage04_cache_dir);

d4 = dir(fullfile(stage04_cache_dir, 'stage04_window_worstcase*.mat'));
assert(~isempty(d4), 'No Stage04 worst-case cache found in %s', stage04_cache_dir);

[~, idx4] = max([d4.datenum]);
stage04_file = fullfile(d4(idx4).folder, d4(idx4).name);

S4 = load(stage04_file);
assert(isfield(S4, 'out'), 'Invalid Stage04 cache: missing out field.');
assert(isfield(S4.out, 'gamma_meta') && isstruct(S4.out.gamma_meta), ...
    'Invalid Stage04 cache: missing out.gamma_meta.');
assert(isfield(S4.out, 'cfg') && isstruct(S4.out.cfg), ...
    'Invalid Stage04 cache: missing out.cfg.');
assert(isfield(S4.out.cfg, 'stage04') && isstruct(S4.out.cfg.stage04), ...
    'Invalid Stage04 cache: missing out.cfg.stage04.');

gamma_meta = S4.out.gamma_meta;
stage04_cfg = S4.out.cfg.stage04;

assert(isfield(gamma_meta, 'gamma_req'), ...
    'Invalid Stage04 gamma_meta: missing gamma_req.');
assert(isfield(stage04_cfg, 'Tw_s'), ...
    'Invalid Stage04 cfg.stage04: missing Tw_s.');

info = struct();
info.gamma_req = gamma_meta.gamma_req;

if isfield(gamma_meta, 'mode') && isfield(gamma_meta, 'quantile')
    info.gamma_source = sprintf('stage04:%s:q%.3f', gamma_meta.mode, gamma_meta.quantile);
elseif isfield(gamma_meta, 'mode')
    info.gamma_source = sprintf('stage04:%s', gamma_meta.mode);
else
    info.gamma_source = 'stage04_nominal_quantile';
end

info.Tw_s = stage04_cfg.Tw_s;
info.cache_file = stage04_file;
info.gamma_meta = gamma_meta;
info.stage04_cfg = stage04_cfg;
end
