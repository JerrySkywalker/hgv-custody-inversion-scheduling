function fig = plot_mb_dense_requirement_heatmap_hi(surface, minimum_design_table, style)
%PLOT_MB_DENSE_REQUIREMENT_HEATMAP_HI Plot refined dense local minimum requirement over (h, i).

fig = plot_mb_requirement_heatmap_hi(surface, minimum_design_table, style);
ax = findobj(fig, 'Type', 'Axes');
ax = ax(1);
title(ax, sprintf('Dense Local Requirement Surface over (h, i)\nDiscrete truth evaluation without interpolation'));
end
