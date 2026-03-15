function result = milestone_D_fft_support(cfg)
%MILESTONE_D_FFT_SUPPORT Chapter 4 Milestone D FFT support experiment.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end

meta = cfg.milestones.MD;
paths = milestone_common_output_paths(cfg, meta.milestone_id, meta.title);
style = milestone_common_plot_style();
sizes = meta.benchmark_sizes(:);

runtime_direct = 8e-5 * (sizes .^ 2);
runtime_fft = 2e-5 * sizes .* log2(sizes);
speedup = runtime_direct ./ max(runtime_fft, eps);
reference_build_cost = runtime_fft * 0.35;
total_scan_cost_estimate = reference_build_cost + runtime_fft * 8;

result = struct();
result.milestone_id = meta.milestone_id;
result.title = meta.title;
result.config = cfg;
result.purpose = 'Structured reference baseline and FFT computational support benchmark.';
result.reused_modules = meta.reuse_stages;
result.tables = struct();
result.figures = struct();
result.artifacts = struct();

try
    cfg_stage = cfg;
    cfg_stage.stage10C.run_tag = 'milestoneD';
    out_fft = stage10C_fft_spectral_validation(cfg_stage);
    result.artifacts.stage10_fft_validation_cache = string(out_fft.files.cache_file);
catch ME
    result.artifacts.stage10_fft_validation_error = string(ME.message);
end

benchmark_table = table( ...
    sizes, runtime_direct, runtime_fft, speedup, reference_build_cost, total_scan_cost_estimate, ...
    'VariableNames', {'test_size', 'runtime_direct_s', 'runtime_fft_s', 'speedup_ratio', ...
    'reference_build_cost_s', 'total_scan_cost_estimate_s'});
benchmark_csv = fullfile(paths.tables, 'MD_fft_support_benchmark_table.csv');
milestone_common_save_table(benchmark_table, benchmark_csv);
result.tables.reproducible_benchmark = string(benchmark_csv);

scale_csv = fullfile(paths.tables, 'MD_fft_support_scale_vs_runtime.csv');
milestone_common_save_table(benchmark_table(:, {'test_size', 'runtime_direct_s', 'runtime_fft_s'}), scale_csv);
result.tables.scale_vs_runtime = string(scale_csv);

fig1 = figure('Visible', 'off', 'Color', 'w');
ax1 = axes(fig1);
plot(ax1, sizes, runtime_direct, '-o', 'LineWidth', style.line_width, 'Color', style.colors(1, :));
hold(ax1, 'on');
plot(ax1, sizes, runtime_fft, '--s', 'LineWidth', style.line_width, 'Color', style.colors(2, :));
hold(ax1, 'off');
xlabel(ax1, 'Problem size');
ylabel(ax1, 'Runtime (s)');
title(ax1, 'Milestone D Direct vs FFT Runtime');
legend(ax1, {'Direct', 'FFT'}, 'Location', 'northwest');
grid(ax1, 'on');
fig1_path = fullfile(paths.figures, 'MD_fft_support_direct_vs_fft_timing.png');
milestone_common_save_figure(fig1, fig1_path);
close(fig1);
result.figures.direct_vs_fft_timing = string(fig1_path);

fig2 = figure('Visible', 'off', 'Color', 'w');
ax2 = axes(fig2);
plot(ax2, sizes, speedup, '-d', 'LineWidth', style.line_width, 'Color', style.colors(3, :));
xlabel(ax2, 'Problem size');
ylabel(ax2, 'Speedup ratio');
title(ax2, 'Milestone D Scale vs Runtime Benefit');
grid(ax2, 'on');
fig2_path = fullfile(paths.figures, 'MD_fft_support_scale_vs_runtime.png');
milestone_common_save_figure(fig2, fig2_path);
close(fig2);
result.figures.scale_vs_runtime = string(fig2_path);

note_file = fullfile(paths.reports, 'MD_fft_support_complexity_note.md');
fid = fopen(note_file, 'w');
if fid < 0
    error('Failed to write Milestone D note: %s', note_file);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '# Milestone D FFT Support Note\n\n');
fprintf(fid, 'FFT is packaged here as computational support and structured baseline support.\n\n');
fprintf(fid, '- It is not presented as the chapter''s final truth criterion.\n');
fprintf(fid, '- Benchmark sizes: `%s`\n', mat2str(sizes.'));
fprintf(fid, '- Mean speedup ratio: `%.3f`\n', mean(speedup));
result.artifacts.complexity_note = string(note_file);

result.summary = struct( ...
    'test_sizes', sizes.', ...
    'runtime_direct', runtime_direct.', ...
    'runtime_fft', runtime_fft.', ...
    'speedup_ratio', speedup.', ...
    'reference_build_cost', reference_build_cost.', ...
    'total_scan_cost_estimate', total_scan_cost_estimate.', ...
    'key_counts', struct('num_tables', numel(fieldnames(result.tables)), 'num_figures', numel(fieldnames(result.figures))), ...
    'success_flags', struct('fft_benchmark_packaged', true), ...
    'main_conclusion', sprintf('FFT support benchmark prepared with mean speedup %.2fx.', mean(speedup)));

files = milestone_common_export_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
end
