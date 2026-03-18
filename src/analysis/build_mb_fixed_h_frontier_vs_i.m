function frontier_table = build_mb_fixed_h_frontier_vs_i(full_theta_table, h_km, family_name)
%BUILD_MB_FIXED_H_FRONTIER_VS_I Build the fixed-height inclination frontier of minimum feasible N_s.

if nargin < 3 || isempty(family_name)
    family_name = "nominal";
end

frontier_table = build_frontier_table_vs_i(full_theta_table, family_name);
if isempty(frontier_table)
    return;
end

frontier_table.h_km = repmat(h_km, height(frontier_table), 1);
frontier_table = movevars(frontier_table, 'h_km', 'Before', 1);
end
