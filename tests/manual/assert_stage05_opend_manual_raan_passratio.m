function assert_stage05_opend_manual_raan_passratio()
startup;

out = manual_smoke_stage05_opend_manual_raan_passratio();

env_min = out.env_min_pass_ratio;
env_mean = out.env_mean_pass_ratio;

assert(ismember('pass_ratio', env_min.Properties.VariableNames), ...
    'env_min_pass_ratio missing pass_ratio column.');
assert(ismember('pass_ratio', env_mean.Properties.VariableNames), ...
    'env_mean_pass_ratio missing pass_ratio column.');

assert(isfield(out.hm_min_pass_ratio, 'value_matrix'), ...
    'hm_min_pass_ratio missing value_matrix.');
assert(isfield(out.hm_mean_pass_ratio, 'value_matrix'), ...
    'hm_mean_pass_ratio missing value_matrix.');

assert(isfile(char(out.env_min_pass_ratio_plot)), ...
    'env_min_pass_ratio plot file was not created.');
assert(isfile(char(out.hm_min_pass_ratio_plot)), ...
    'hm_min_pass_ratio plot file was not created.');

disp('assert_stage05_opend_manual_raan_passratio passed.');
end
