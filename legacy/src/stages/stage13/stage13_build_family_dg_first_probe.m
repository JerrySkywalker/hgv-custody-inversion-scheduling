function candidate_table = stage13_build_family_dg_first_probe(cfg)
%STAGE13_BUILD_FAMILY_DG_FIRST_PROBE Build directed DG-first geometry probe family.

cfg = stage13_default_config(cfg);
b = cfg.stage13.baseline;
stage01_out = stage01_scenario_disk(cfg);
casebank = stage01_out.casebank;

candidate_ids = local_collect_case_ids(casebank, string(b.case_id));
n = numel(candidate_ids);
candidate_table = table('Size', [n 10], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'string', 'string'}, ...
    'VariableNames', {'candidate_tag', 'family', 'h_km', 'i_deg', 'P', 'T', 'F', 'Tw_s', 'case_mode', 'case_id'});

for k = 1:n
    candidate_table.candidate_tag(k) = "dg_first_probe_" + string(k);
    candidate_table.family(k) = "dg_first_probe";
    candidate_table.h_km(k) = b.theta.h_km;
    candidate_table.i_deg(k) = b.theta.i_deg;
    candidate_table.P(k) = b.theta.P;
    candidate_table.T(k) = b.theta.T;
    candidate_table.F(k) = b.theta.F;
    candidate_table.Tw_s(k) = b.Tw_s;
    candidate_table.case_mode(k) = "exact";
    candidate_table.case_id(k) = candidate_ids(k);
end
end

function ids = local_collect_case_ids(casebank, baseline_id)
ids = strings(0, 1);
ids(end + 1, 1) = baseline_id; %#ok<AGROW>

heading_ids = string({casebank.heading.case_id});
critical_ids = string({casebank.critical.case_id});

preferred_heading = ["H01_+00", "H01_+20", "H01_-20", "H01_+30", "H01_-30"];
for k = 1:numel(preferred_heading)
    hit = heading_ids(strcmpi(heading_ids, preferred_heading(k)));
    if ~isempty(hit)
        ids(end + 1, 1) = hit(1); %#ok<AGROW>
    end
end

if isempty(critical_ids)
    return;
end
ids = [ids; critical_ids(:)]; %#ok<AGROW>
ids = unique(ids, 'stable');
end
