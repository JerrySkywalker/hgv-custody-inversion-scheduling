function scenario_cases = build_shared_scenario_case_trajectories(cfg)
%BUILD_SHARED_SCENARIO_CASE_TRAJECTORIES Build representative cases for shared figures.

cfg_stage = cfg;
cfg_stage = stage09_prepare_cfg(cfg_stage);
cfg_stage.stage09.casebank_mode = 'custom';
cfg_stage.stage09.casebank_include_nominal = cfg.shared_scenarios.show_nominal_family;
cfg_stage.stage09.casebank_include_heading = cfg.shared_scenarios.show_heading_family;
cfg_stage.stage09.casebank_include_critical = cfg.shared_scenarios.show_critical_family;
cfg_stage.stage09.casebank_heading_subset_max = 5;

trajs_in = build_stage09_casebank(cfg_stage);

scenario_cases = struct();
scenario_cases.nominal = local_pick_family_case(trajs_in, "nominal");
scenario_cases.heading = local_pick_family_case(trajs_in, "heading");
scenario_cases.critical = local_pick_family_case(trajs_in, "critical");
scenario_cases.all = trajs_in;
end

function item = local_pick_family_case(trajs_in, family_name)
item = struct([]);
for k = 1:numel(trajs_in)
    case_i = trajs_in(k).case;
    if isfield(case_i, 'family') && strcmpi(string(case_i.family), family_name)
        item = trajs_in(k);
        return;
    end
end
end
