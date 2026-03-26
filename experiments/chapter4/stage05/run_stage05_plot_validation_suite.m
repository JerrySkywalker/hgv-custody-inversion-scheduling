function out = run_stage05_plot_validation_suite(varargin)
%RUN_STAGE05_PLOT_VALIDATION_SUITE Run plotting-API validation suite for Stage05 legacy reproduction.

suite = make_stage05_plot_validation_suite_spec(varargin{:});

setenv('HGV_STARTUP_LOG_REPEATED_INIT', 'false');

out = struct();
out.suite_spec = suite;
out.started_at = string(datetime('now'));

common_args = { ...
    'profile', suite.profile, ...
    'i_grid_deg', suite.i_grid_deg, ...
    'P_grid', suite.P_grid, ...
    'T_grid', suite.T_grid, ...
    'h_fixed_km', suite.h_fixed_km, ...
    'F_fixed', suite.F_fixed, ...
    'plot_visible', suite.plot_visible, ...
    'artifact_root', suite.reproduction_artifact_root, ...
    'output_suffix', 'plot_validation', ...
    'save_cache', suite.save_cache, ...
    'use_parallel', suite.use_parallel, ...
    'show_progress', suite.show_progress};

out.reproduction = run_stage05_opend_legacy_reproduction_framework(common_args{:});

plot_dir = fullfile(suite.plot_artifact_root, 'figures');
if exist(plot_dir, 'dir') ~= 7
    mkdir(plot_dir);
end

env_tbl = out.reproduction.outputs.best_pass_by_Ns;
hm = out.reproduction.outputs.geometry_heatmap_i60;

fig1 = plot_envelope_curve(env_tbl.Ns, env_tbl.pass_ratio, struct( ...
    'title', 'Stage05 legacy reproduction: best pass ratio by Ns', ...
    'x_label', 'Ns', ...
    'y_label', 'best pass ratio', ...
    'visible', suite.plot_visible));
fig2 = plot_heatmap_matrix(hm.row_values, hm.col_values, hm.value_matrix, struct( ...
    'title', 'Stage05 legacy reproduction: DG heatmap at i=60', ...
    'x_label', 'T', ...
    'y_label', 'P', ...
    'visible', suite.plot_visible));

out.plot_outputs = struct();
out.plot_outputs.best_pass_plot = struct();
out.plot_outputs.best_pass_plot.file_path = string(save_figure_artifact(fig1, struct( ...
    'output_dir', plot_dir, ...
    'file_name', 'stage05_plot_validation_best_pass.png')));

out.plot_outputs.heatmap_i60_plot = struct();
out.plot_outputs.heatmap_i60_plot.file_path = string(save_figure_artifact(fig2, struct( ...
    'output_dir', plot_dir, ...
    'file_name', 'stage05_plot_validation_heatmap_i60.png')));

out.compare = manual_compare_stage05_plot_validation_sources(out);

manifest_dir = fullfile(suite.plot_artifact_root, 'manifest');
if exist(manifest_dir, 'dir') ~= 7
    mkdir(manifest_dir);
end

plot_manifest = struct();
plot_manifest.generated_at = string(datetime('now'));
plot_manifest.started_at = out.started_at;
plot_manifest.finished_at = string(datetime('now'));
plot_manifest.best_pass_plot = out.plot_outputs.best_pass_plot.file_path;
plot_manifest.heatmap_i60_plot = out.plot_outputs.heatmap_i60_plot.file_path;
plot_manifest.reproduction_grid_size = size(out.reproduction.grid_table);
plot_manifest.best_pass_height = height(out.reproduction.outputs.best_pass_by_Ns);
plot_manifest.heatmap_size = size(out.reproduction.outputs.geometry_heatmap_i60.value_matrix);
plot_manifest.best_pass_compare_height = height(out.compare.best_pass_compare);
plot_manifest.heatmap_compare_height = height(out.compare.heatmap_compare);
plot_manifest.best_pass_max_abs_diff = max(out.compare.best_pass_compare.pass_abs_diff, [], 'omitnan');
plot_manifest.heatmap_max_abs_diff = max(out.compare.heatmap_compare.abs_diff, [], 'omitnan');

plot_manifest_mat = fullfile(manifest_dir, 'plot_validation_manifest.mat');
save(plot_manifest_mat, 'plot_manifest');

plot_manifest_txt = fullfile(manifest_dir, 'plot_validation_manifest.txt');
fid = fopen(plot_manifest_txt, 'w');
if fid ~= -1
    fprintf(fid, 'Stage05 plot validation suite manifest\n');
    fprintf(fid, 'generated_at: %s\n', plot_manifest.generated_at);
    fprintf(fid, 'started_at:   %s\n', plot_manifest.started_at);
    fprintf(fid, 'finished_at:  %s\n', plot_manifest.finished_at);
    fprintf(fid, '\n');
    fprintf(fid, 'reproduction_grid_size: [%d %d]\n', ...
        plot_manifest.reproduction_grid_size(1), plot_manifest.reproduction_grid_size(2));
    fprintf(fid, 'best_pass_height: %d\n', plot_manifest.best_pass_height);
    fprintf(fid, 'heatmap_size:    [%d %d]\n', ...
        plot_manifest.heatmap_size(1), plot_manifest.heatmap_size(2));
    fprintf(fid, 'best_pass_compare_height: %d\n', plot_manifest.best_pass_compare_height);
    fprintf(fid, 'heatmap_compare_height:   %d\n', plot_manifest.heatmap_compare_height);
    fprintf(fid, 'best_pass_max_abs_diff:   %.16g\n', plot_manifest.best_pass_max_abs_diff);
    fprintf(fid, 'heatmap_max_abs_diff:     %.16g\n', plot_manifest.heatmap_max_abs_diff);
    fprintf(fid, '\n');
    fprintf(fid, 'best_pass_plot:   %s\n', plot_manifest.best_pass_plot);
    fprintf(fid, 'heatmap_i60_plot: %s\n', plot_manifest.heatmap_i60_plot);
    fclose(fid);
end

out.plot_manifest = plot_manifest;
out.plot_manifest.manifest_mat = string(plot_manifest_mat);
out.plot_manifest.manifest_txt = string(plot_manifest_txt);
out.finished_at = string(datetime('now'));
end
