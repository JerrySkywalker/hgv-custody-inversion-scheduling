function fig = plot_compare_nis_histogram(nisA, nisB, lower, upper, nameA, nameB, visible)
%PLOT_COMPARE_NIS_HISTOGRAM Overlay histograms of NIS for two policies.

if nargin < 7
    visible = 'off';
end

nisA = nisA(:);
nisB = nisB(:);
nisA = nisA(isfinite(nisA));
nisB = nisB(isfinite(nisB));

fig = figure('Visible', visible);
histogram(nisA, 30, 'Normalization', 'pdf');
hold on;
histogram(nisB, 30, 'Normalization', 'pdf');
xline(lower, '--');
xline(upper, '--');
grid on;
xlabel('NIS');
ylabel('pdf');
title('NIS histogram comparison');
legend({char(nameA), char(nameB), 'lower bound', 'upper bound'}, 'Location', 'best');
end
