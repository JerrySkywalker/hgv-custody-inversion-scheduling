function assert_stage05_opend_manual_raan_fullgrid()
startup;

out = manual_smoke_stage05_opend_manual_raan_fullgrid();

assert(isequal(out.grid_size, [18 32]), 'Expected grid_table size [18 32].');

agg = out.agg_table;
assert(height(agg) == 6, 'Expected 6 aggregated base designs.');
assert(all(ismember({'min_DG_rob','mean_DG_rob','min_pass_ratio','mean_pass_ratio'}, agg.Properties.VariableNames)), ...
    'Missing expected aggregate columns.');

assert(isfile(char(out.env_min_DG_plot)), 'env_min_DG plot file was not created.');
assert(isfile(char(out.hm_min_pass_ratio_plot)), 'hm_min_pass_ratio plot file was not created.');
assert(isfile(char(out.agg_csv)), 'agg_by_base_design CSV was not created.');
assert(isfile(char(out.env_min_pass_ratio_csv)), 'env_min_pass_ratio CSV was not created.');

disp('assert_stage05_opend_manual_raan_fullgrid passed.');
end
