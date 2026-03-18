function surface = build_mb_fixed_h_requirement_surface_iP(full_theta_table, h_km, family_name)
%BUILD_MB_FIXED_H_REQUIREMENT_SURFACE_IP Build a fixed-height minimum-requirement surface over (i, P).

if nargin < 3 || isempty(family_name)
    family_name = "nominal";
end

surface = build_mb_requirement_surface(full_theta_table, 'P', 'i_deg');
surface.h_km = h_km;
surface.family_name = string(family_name);
surface.surface_name = sprintf('fixedH_%g_requirement_iP', h_km);

if isfield(surface, 'surface_table') && ~isempty(surface.surface_table)
    surface.surface_table.h_km = repmat(h_km, height(surface.surface_table), 1);
    surface.surface_table.family_name = repmat(string(family_name), height(surface.surface_table), 1);
    surface.surface_table = movevars(surface.surface_table, {'h_km', 'family_name'}, 'Before', 1);
end
end
