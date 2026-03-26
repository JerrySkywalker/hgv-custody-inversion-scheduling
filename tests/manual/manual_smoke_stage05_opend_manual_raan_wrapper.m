function out = manual_smoke_stage05_opend_manual_raan_wrapper()
startup;

base_rows = manual_make_stage05_representative_grid();
base_rows = base_rows(1:3);

res = run_stage05_opend_manual_raan_experiment( ...
    'base_rows', base_rows, ...
    'raan_range_deg', [0 20], ...
    'raan_step_deg', 10, ...
    'plot_visible', 'off', ...
    'output_suffix', 'wrapper_smoke');

out = struct();
out.res = res;
out.agg_table = res.outputs.agg_by_base_design;
out.env_min_plot_path = string(res.plot_outputs.env_min_DG_plot.file_path);
out.hm_min_plot_path = string(res.plot_outputs.hm_min_DG_plot.file_path);

disp('[manual] Stage05 OpenD manual-RAAN wrapper smoke completed.');
disp(out.agg_table);
disp(out.env_min_plot_path);
disp(out.hm_min_plot_path);
end
