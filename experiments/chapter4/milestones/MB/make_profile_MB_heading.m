function profile = make_profile_MB_heading()
task_profile = make_ch4_task_profile();
grid_profile = make_ch4_design_grid_profile();

profile = struct();
profile.name = 'MB_heading';
profile.mode = 'static';
profile.task_family = task_profile.heading_minimal.family_name;

profile.runtime = struct();
profile.runtime.max_cases = task_profile.heading_minimal.max_cases;
profile.runtime.max_designs = numel(grid_profile.bootstrap.rows);

profile.allowed_heading_offsets_deg = task_profile.heading_minimal.allowed_heading_offsets_deg;
profile.design_pool = struct();
profile.design_pool.rows = grid_profile.bootstrap.rows;
end
