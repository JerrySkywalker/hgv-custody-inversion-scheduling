function plan = stage13_build_search_plan(cfg, mode)
%STAGE13_BUILD_SEARCH_PLAN Build a Stage13 candidate plan without evaluation.

cfg = stage13_default_config(cfg);
if nargin < 2 || isempty(mode)
    mode = cfg.stage13.mode;
end

families = string(cfg.stage13.search.families);
entries = local_empty_candidate_table();

for k = 1:numel(families)
    family_name = families(k);
    switch family_name
        case "dt_first_probe"
            family_table = stage13_build_family_dt_first_probe(cfg);
        case "dg_first_probe"
            family_table = stage13_build_family_dg_first_probe(cfg);
        otherwise
            family_table = local_empty_candidate_table();
    end
    if ~isempty(family_table)
        entries = [entries; family_table]; %#ok<AGROW>
    end
end

plan = struct();
plan.mode = string(mode);
plan.generated_at = string(datestr(now, 'yyyy-mm-dd HH:MM:SS'));
plan.baseline = cfg.stage13.baseline;
plan.families = families;
plan.candidate_table = entries;
end

function entries = local_empty_candidate_table()
entries = table('Size', [0 10], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'string', 'string'}, ...
    'VariableNames', {'candidate_tag', 'family', 'h_km', 'i_deg', 'P', 'T', 'F', 'Tw_s', 'case_mode', 'case_id'});
end
