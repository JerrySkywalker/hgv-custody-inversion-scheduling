function out = manual_smoke_stage05_closedd_manual_raan_fullgrid()
startup;

artifact_root = fullfile('outputs','experiments','chapter4','stage05_closedd_manual_raan','fullgrid_smoke');

res = run_stage05_closedd_manual_raan_fullgrid_experiment( ...
    'i_grid_deg', [60], ...
    'P_grid', [8 10], ...
    'T_grid', [8 10 12], ...
    'raan_range_deg', [0 20], ...
    'raan_step_deg', 10, ...
    'plot_visible', 'off', ...
    'output_suffix', 'fullgrid_smoke', ...
    'artifact_root', artifact_root);

out = struct();
out.res = res;
out.grid_size = size(res.grid_table);
out.agg_table = res.outputs.agg_by_base_design;
out.env_min_joint_margin_plot = string(res.plot_outputs.env_min_joint_margin_plot.file_path);
out.env_min_pass_ratio_plot = string(res.plot_outputs.env_min_pass_ratio_plot.file_path);
out.agg_csv = string(res.table_exports.agg_by_base_design.csv_path);
out.env_min_pass_ratio_csv = string(res.table_exports.env_min_pass_ratio.csv_path);

disp('[manual] Stage05 ClosedD manual-RAAN full-grid smoke completed.');
disp(out.grid_size);
disp(out.agg_table(:, {'base_design_id','P','T','Ns','min_joint_margin','mean_joint_margin','min_pass_ratio','mean_pass_ratio'}));
disp(out.env_min_joint_margin_plot);
disp(out.env_min_pass_ratio_plot);
disp(out.agg_csv);
disp(out.env_min_pass_ratio_csv);
end
