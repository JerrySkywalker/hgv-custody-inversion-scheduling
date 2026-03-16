function plan = stage13_build_search_plan(cfg, mode)
%STAGE13_BUILD_SEARCH_PLAN Build a Stage13 candidate plan without evaluation.

cfg = stage13_default_config(cfg);
if nargin < 2 || isempty(mode)
    mode = cfg.stage13.mode;
end

families = string(cfg.stage13.search.families);
entries = table('Size', [0 10], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'string', 'string'}, ...
    'VariableNames', {'candidate_tag', 'family', 'h_km', 'i_deg', 'P', 'T', 'F', 'Tw_s', 'case_mode', 'case_id'});

baseline = cfg.stage13.baseline;
for k = 1:numel(families)
    entries = [entries; {sprintf('%s_baseline', families(k)), families(k), ...
        baseline.theta.h_km, baseline.theta.i_deg, baseline.theta.P, baseline.theta.T, baseline.theta.F, ...
        baseline.Tw_s, string(baseline.case_mode), string(baseline.case_id)}]; %#ok<AGROW>
end

plan = struct();
plan.mode = string(mode);
plan.generated_at = string(datestr(now, 'yyyy-mm-dd HH:MM:SS'));
plan.baseline = baseline;
plan.families = families;
plan.candidate_table = entries;
end
