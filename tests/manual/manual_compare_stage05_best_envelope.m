function out = manual_compare_stage05_best_envelope()
startup;

% ------------------------------------------------------------
% 1) Load legacy Stage05 grid cache
% ------------------------------------------------------------
cfg_legacy = default_params();
cfg_legacy = configure_stage_output_paths(cfg_legacy);

d5 = find_stage_cache_files(cfg_legacy.paths.cache, 'stage05_*walker_search*.mat');
assert(~isempty(d5), 'No Stage05 cache found.');

[~, idx5] = max([d5.datenum]);
stage05_file = fullfile(d5(idx5).folder, d5(idx5).name);
S5 = load(stage05_file);

assert(isfield(S5, 'out') && isfield(S5.out, 'grid'), ...
    'Invalid Stage05 cache: missing out.grid.');

legacy_grid = S5.out.grid;

% ------------------------------------------------------------
% 2) Build legacy best-pass envelope directly from grid
%    (replicates local_plot_passratio_profile logic)
% ------------------------------------------------------------
target_i_deg = 60;
legacy_sub = legacy_grid(legacy_grid.i_deg == target_i_deg, :);

Ns_u = unique(legacy_sub.Ns);
Ns_u = sort(Ns_u(:));

legacy_rows = repmat(struct(), numel(Ns_u), 1);
for j = 1:numel(Ns_u)
    ns = Ns_u(j);
    tmp = legacy_sub(legacy_sub.Ns == ns, :);

    legacy_rows(j).Ns = ns;
    legacy_rows(j).best_pass = max(tmp.pass_ratio);
end
legacy_env = struct2table(legacy_rows);

% ------------------------------------------------------------
% 3) Build framework best-pass envelope
%    Prefer framework derive path from current Stage05 replay source
% ------------------------------------------------------------
profile = make_profile_MB_nominal_validation_stage05();

cfg_engine = default_params();
cfg_engine = stage09_prepare_cfg(cfg_engine);
cfg_engine = configure_stage_output_paths(cfg_engine);

cfg_engine_profile = config_service(profile);
cfg_engine = local_merge_cfg_for_engine(cfg_engine, cfg_engine_profile);

% Reuse current design grid search result if available through framework search
search_result = run_design_grid_search_opend(profile);
grid_table = search_result.grid_table;

env_spec = struct();
env_spec.fixed_filters = struct('i_deg', target_i_deg);
env_spec.group_key = 'Ns';
env_spec.metric_name = 'pass_ratio';
env_spec.aggregate_mode = 'max';

framework_env = build_best_envelope(grid_table, env_spec);

% ------------------------------------------------------------
% 4) Compare
% ------------------------------------------------------------
legacy_env = renamevars(legacy_env, {'best_pass'}, {'legacy_best_pass'});
framework_env = renamevars(framework_env, {'best_pass'}, {'engine_best_pass'});

compare_tbl = innerjoin(legacy_env, framework_env, 'Keys', {'Ns'});
compare_tbl.best_pass_abs_diff = abs(compare_tbl.legacy_best_pass - compare_tbl.engine_best_pass);

out = struct();
out.stage05_file = string(stage05_file);
out.target_i_deg = target_i_deg;
out.legacy_env = legacy_env;
out.engine_env = framework_env;
out.compare_table = compare_tbl;

disp('[manual] Stage05 best-pass envelope comparison completed.');
disp(compare_tbl);
end

function cfg_out = local_merge_cfg_for_engine(cfg_base, cfg_overlay)
cfg_out = cfg_base;
overlay_fields = fieldnames(cfg_overlay);
for i = 1:numel(overlay_fields)
    f = overlay_fields{i};
    cfg_out.(f) = cfg_overlay.(f);
end
if isfield(cfg_overlay, 'runtime')
    cfg_out.runtime = cfg_overlay.runtime;
end
if isfield(cfg_overlay, 'stage03')
    cfg_out.stage03 = cfg_overlay.stage03;
end
end
