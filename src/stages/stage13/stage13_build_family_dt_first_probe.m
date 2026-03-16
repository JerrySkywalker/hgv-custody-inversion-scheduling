function candidate_table = stage13_build_family_dt_first_probe(cfg)
%STAGE13_BUILD_FAMILY_DT_FIRST_PROBE Build directed DT-first probe family.

cfg = stage13_default_config(cfg);
b = cfg.stage13.baseline;

theta_list = [ ...
    struct('tag', "dt_first_probe_baseline", 'h_km', b.theta.h_km, 'i_deg', b.theta.i_deg, 'P', b.theta.P, 'T', b.theta.T, 'F', b.theta.F); ...
    struct('tag', "dt_first_probe_T3F0", 'h_km', b.theta.h_km, 'i_deg', b.theta.i_deg, 'P', b.theta.P, 'T', max(b.theta.T - 1, 2), 'F', 0); ...
    struct('tag', "dt_first_probe_T3F1", 'h_km', b.theta.h_km, 'i_deg', b.theta.i_deg, 'P', b.theta.P, 'T', max(b.theta.T - 1, 2), 'F', 1); ...
    struct('tag', "dt_first_probe_T2F0", 'h_km', b.theta.h_km, 'i_deg', b.theta.i_deg, 'P', b.theta.P, 'T', max(b.theta.T - 2, 2), 'F', 0); ...
    struct('tag', "dt_first_probe_P6T4F0", 'h_km', b.theta.h_km, 'i_deg', b.theta.i_deg, 'P', max(b.theta.P - 2, 4), 'T', b.theta.T, 'F', 0); ...
    struct('tag', "dt_first_probe_P6T4F1", 'h_km', b.theta.h_km, 'i_deg', b.theta.i_deg, 'P', max(b.theta.P - 2, 4), 'T', b.theta.T, 'F', 1)];

candidate_table = local_structs_to_table(theta_list, b);
end

function T = local_structs_to_table(theta_list, baseline)
n = numel(theta_list);
T = table('Size', [n 10], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'string', 'string'}, ...
    'VariableNames', {'candidate_tag', 'family', 'h_km', 'i_deg', 'P', 'T', 'F', 'Tw_s', 'case_mode', 'case_id'});
for k = 1:n
    item = theta_list(k);
    T.candidate_tag(k) = string(item.tag);
    T.family(k) = "dt_first_probe";
    T.h_km(k) = item.h_km;
    T.i_deg(k) = item.i_deg;
    T.P(k) = item.P;
    T.T(k) = item.T;
    T.F(k) = item.F;
    T.Tw_s(k) = baseline.Tw_s;
    T.case_mode(k) = string(baseline.case_mode);
    T.case_id(k) = string(baseline.case_id);
end
end
