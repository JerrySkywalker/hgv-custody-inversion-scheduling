function fig = plot_mb_dense_requirement_heatmap_iP(surface, minimum_design_table, style)
%PLOT_MB_DENSE_REQUIREMENT_HEATMAP_IP Plot local zoom minimum requirement over (i, P).

fig = plot_mb_requirement_heatmap_iP(surface, minimum_design_table, style);
ax = findobj(fig, 'Type', 'Axes');
ax = ax(1);
title(ax, 'Local Zoom Minimum Feasible Constellation Requirement over (i, P)');
end
