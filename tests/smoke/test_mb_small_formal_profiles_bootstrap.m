function test_mb_small_formal_profiles_bootstrap()
startup;

grid_profile = make_ch4_design_grid_profile();
rows = expand_ch4_design_grid_profile(grid_profile.small_formal, 'X');

assert(numel(rows) == 16, 'Expected 16 expanded small-formal design rows.');

p_nom = make_profile_MB_nominal_small_formal();
p_head = make_profile_MB_heading_small_formal();

assert(numel(p_nom.design_pool.rows) == 16, 'Expected 16 nominal small-formal rows.');
assert(numel(p_head.design_pool.rows) == 16, 'Expected 16 heading small-formal rows.');

assert(strcmp(p_nom.task_family, 'nominal'), 'Expected nominal small-formal task family.');
assert(strcmp(p_head.task_family, 'heading'), 'Expected heading small-formal task family.');

disp('test_mb_small_formal_profiles_bootstrap passed.');
end
