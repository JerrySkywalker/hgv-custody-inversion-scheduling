function scatter_result = ch4_design_point_scatter_service(grid_table)
%CH4_DESIGN_POINT_SCATTER_SERVICE Build a design-point scatter table from grid results.

scatter_table = build_design_point_scatter( ...
    grid_table, 'Ns', 'pass_ratio', struct(), {'P', 'T'});

scatter_result = struct();
scatter_result.scatter_table = scatter_table;
scatter_result.point_count = height(scatter_table);
end
