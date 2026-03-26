function assert_stage05_opend_manual_raan_wrapper()
startup;

out = manual_smoke_stage05_opend_manual_raan_wrapper();

agg = out.agg_table;

assert(height(agg) == 3, 'Expected 3 aggregated base designs.');
assert(all(ismember({'min_DG_rob','max_DG_rob','mean_DG_rob'}, agg.Properties.VariableNames)), ...
    'Missing DG aggregate columns.');
assert(all(ismember({'min_pass_ratio','max_pass_ratio','mean_pass_ratio'}, agg.Properties.VariableNames)), ...
    'Missing pass-ratio aggregate columns.');
assert(all(agg.n_region_phase == 3), 'Expected n_region_phase == 3 for all rows.');

assert(isfile(char(out.env_min_plot_path)), 'env_min_DG plot file was not created.');
assert(isfile(char(out.hm_min_plot_path)), 'hm_min_DG plot file was not created.');

disp('assert_stage05_opend_manual_raan_wrapper passed.');
end
