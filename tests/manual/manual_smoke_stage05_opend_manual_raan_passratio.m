function out = manual_smoke_stage05_opend_manual_raan_passratio()
startup;

base_rows = manual_make_stage05_representative_grid();
base_rows = base_rows(1:3);

res = run_stage05_opend_manual_raan_experiment( ...
    'base_rows', base_rows, ...
    'raan_range_deg', [0 20], ...
    'raan_step_deg', 10, ...
    'plot_visible', 'off', ...
    'output_suffix', 'passratio_smoke');

out = struct();
out.res = res;
out.env_min_pass_ratio = res.outputs.env_min_pass_ratio;
out.env_mean_pass_ratio = res.outputs.env_mean_pass_ratio;
out.hm_min_pass_ratio = res.outputs.hm_min_pass_ratio;
out.hm_mean_pass_ratio = res.outputs.hm_mean_pass_ratio;
out.env_min_pass_ratio_plot = string(res.plot_outputs.env_min_pass_ratio_plot.file_path);
out.hm_min_pass_ratio_plot = string(res.plot_outputs.hm_min_pass_ratio_plot.file_path);

disp('[manual] Stage05 OpenD manual-RAAN pass-ratio smoke completed.');
disp(out.env_min_pass_ratio);
disp(out.env_mean_pass_ratio);
disp(out.hm_min_pass_ratio.value_matrix);
disp(out.hm_mean_pass_ratio.value_matrix);
disp(out.env_min_pass_ratio_plot);
disp(out.hm_min_pass_ratio_plot);
end
