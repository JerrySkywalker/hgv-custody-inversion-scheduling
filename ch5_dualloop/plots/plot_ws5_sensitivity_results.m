function figs = plot_ws5_sensitivity_results(summary, fig_dir)
%PLOT_WS5_SENSITIVITY_RESULTS
% WS-5-R4
% Generate a compact set of heatmaps and line plots for manual inspection.

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

topk = summary.topk_grid;
libcap = summary.libcap_grid;

figs = struct();

% --------------------------------------------
% Heatmap 1: ratio_changed_C_vs_A
% --------------------------------------------
f1 = figure('Visible', 'off');
imagesc(libcap, topk, summary.ratio_changed_C_vs_A);
axis tight
set(gca, 'YDir', 'normal');
xlabel('library pair cap');
ylabel('topK');
title('ratio\_changed\_C\_vs\_A', 'Interpreter', 'none');
colorbar;
file1 = fullfile(fig_dir, 'ws5_heat_ratio_changed_C_vs_A.png');
saveas(f1, file1);
close(f1);
figs.heat_ratio_changed_C_vs_A = file1;

% --------------------------------------------
% Heatmap 2: mean_compression_ratio
% --------------------------------------------
f2 = figure('Visible', 'off');
imagesc(libcap, topk, summary.mean_compression_ratio);
axis tight
set(gca, 'YDir', 'normal');
xlabel('library pair cap');
ylabel('topK');
title('mean\_compression\_ratio', 'Interpreter', 'none');
colorbar;
file2 = fullfile(fig_dir, 'ws5_heat_mean_compression_ratio.png');
saveas(f2, file2);
close(f2);
figs.heat_mean_compression_ratio = file2;

% --------------------------------------------
% Line plot 1: ratio_changed_C_vs_A vs topK
% one line per libcap
% --------------------------------------------
f3 = figure('Visible', 'off');
hold on
for j = 1:numel(libcap)
    plot(topk, summary.ratio_changed_C_vs_A(:,j), '-o', 'DisplayName', sprintf('cap=%d', libcap(j)));
end
hold off
xlabel('topK');
ylabel('ratio changed C vs A');
title('ratio\_changed\_C\_vs\_A vs topK', 'Interpreter', 'none');
legend('Location', 'best');
grid on
file3 = fullfile(fig_dir, 'ws5_line_ratio_changed_C_vs_A_vs_topK.png');
saveas(f3, file3);
close(f3);
figs.line_ratio_changed_C_vs_A_vs_topK = file3;

% --------------------------------------------
% Line plot 2: mean_compression_ratio vs topK
% one line per libcap
% --------------------------------------------
f4 = figure('Visible', 'off');
hold on
for j = 1:numel(libcap)
    plot(topk, summary.mean_compression_ratio(:,j), '-o', 'DisplayName', sprintf('cap=%d', libcap(j)));
end
hold off
xlabel('topK');
ylabel('mean compression ratio');
title('mean\_compression\_ratio vs topK', 'Interpreter', 'none');
legend('Location', 'best');
grid on
file4 = fullfile(fig_dir, 'ws5_line_mean_compression_ratio_vs_topK.png');
saveas(f4, file4);
close(f4);
figs.line_mean_compression_ratio_vs_topK = file4;

% --------------------------------------------
% Line plot 3: ratio_changed_C_vs_A vs library cap
% one line per topK
% --------------------------------------------
f5 = figure('Visible', 'off');
hold on
for i = 1:numel(topk)
    plot(libcap, summary.ratio_changed_C_vs_A(i,:), '-o', 'DisplayName', sprintf('topK=%d', topk(i)));
end
hold off
xlabel('library pair cap');
ylabel('ratio changed C vs A');
title('ratio\_changed\_C\_vs\_A vs library cap', 'Interpreter', 'none');
legend('Location', 'best');
grid on
file5 = fullfile(fig_dir, 'ws5_line_ratio_changed_C_vs_A_vs_libcap.png');
saveas(f5, file5);
close(f5);
figs.line_ratio_changed_C_vs_A_vs_libcap = file5;

% --------------------------------------------
% Line plot 4: mean_compression_ratio vs library cap
% one line per topK
% --------------------------------------------
f6 = figure('Visible', 'off');
hold on
for i = 1:numel(topk)
    plot(libcap, summary.mean_compression_ratio(i,:), '-o', 'DisplayName', sprintf('topK=%d', topk(i)));
end
hold off
xlabel('library pair cap');
ylabel('mean compression ratio');
title('mean\_compression\_ratio vs library cap', 'Interpreter', 'none');
legend('Location', 'best');
grid on
file6 = fullfile(fig_dir, 'ws5_line_mean_compression_ratio_vs_libcap.png');
saveas(f6, file6);
close(f6);
figs.line_mean_compression_ratio_vs_libcap = file6;
end
