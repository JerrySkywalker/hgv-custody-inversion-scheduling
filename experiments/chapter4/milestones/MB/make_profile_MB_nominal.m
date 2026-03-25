function profile = make_profile_MB_nominal()
task_profile = make_ch4_task_profile();
grid_profile = make_ch4_design_grid_profile();

profile = struct();
profile.name = 'MB_nominal';
profile.mode = 'static';
profile.task_family = task_profile.nominal.family_name;

profile.runtime = struct();
profile.runtime.max_cases = task_profile.nominal.max_cases;
profile.runtime.max_designs = numel(grid_profile.bootstrap.rows);

profile.allowed_heading_offsets_deg = task_profile.nominal.allowed_heading_offsets_deg;
profile.design_pool = struct();
profile.design_pool.rows = grid_profile.bootstrap.rows;
end
