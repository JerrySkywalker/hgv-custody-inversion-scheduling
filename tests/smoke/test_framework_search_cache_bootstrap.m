function test_framework_search_cache_bootstrap()
startup;

ctx = build_engine_test_context();
grid_profile = make_ch4_design_grid_profile();
rows = grid_profile.validation_stage05.rows;

task_family = build_task_family(struct('family_name', 'nominal', 'max_cases', 1), ctx.cfg);
search_result = run_design_grid_search_opend(rows, task_family, ctx.cfg, struct( ...
    'gamma_eff_scalar', ctx.gamma_info.gamma_req, ...
    'run_tag', 'test_framework_search_cache_bootstrap', ...
    'source_profile', struct('name', 'test_framework_search_cache_bootstrap')));

assert(height(search_result.grid_table) == numel(rows), 'Search returned unexpected row count.');
assert(isfield(search_result, 'cache_path') && isfile(search_result.cache_path), 'Missing truth cache MAT.');
assert(isfile(search_result.manifest_paths.manifest_txt_path), 'Missing truth cache manifest TXT.');

payload = load_truth_table_cache(search_result.cache_path);
assert(height(payload.grid_table) == height(search_result.grid_table), 'Loaded cache row count mismatch.');
assert(strcmp(payload.meta.engine_mode, 'opend'), 'Expected opend engine_mode in cache meta.');

disp('test_framework_search_cache_bootstrap passed.');
end
