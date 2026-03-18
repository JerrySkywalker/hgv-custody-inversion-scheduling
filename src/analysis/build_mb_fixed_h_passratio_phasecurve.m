function phasecurve_table = build_mb_fixed_h_passratio_phasecurve(full_theta_table, h_km, i_list, family_name)
%BUILD_MB_FIXED_H_PASSRATIO_PHASECURVE Build fixed-height pass-ratio envelopes versus N_s.

if nargin < 3 || isempty(i_list)
    if isempty(full_theta_table)
        i_list = [];
    else
        i_list = unique(full_theta_table.i_deg, 'sorted');
    end
end
if nargin < 4 || isempty(family_name)
    family_name = "nominal";
end

phasecurve_table = build_dense_passratio_phasecurve(full_theta_table, i_list);
if isempty(phasecurve_table)
    return;
end

phasecurve_table.h_km = repmat(h_km, height(phasecurve_table), 1);
phasecurve_table.family_name = repmat(string(family_name), height(phasecurve_table), 1);
phasecurve_table = movevars(phasecurve_table, {'h_km', 'family_name'}, 'Before', 1);
end
