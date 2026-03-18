function surface = build_dense_requirement_surface_iP(full_theta_table)
%BUILD_DENSE_REQUIREMENT_SURFACE_IP Build a dense local minimum-requirement surface over (i, P).

surface = build_mb_requirement_surface(full_theta_table, 'P', 'i_deg');
surface.surface_name = "dense_requirement_iP";
end
