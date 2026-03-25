function out = manual_compare_stage01_casebank()
cfg = default_params();

legacy_casebank = stage01_build_casebank(cfg);
engine_casebank = build_casebank(cfg);

out = struct();
out.legacy_nominal_count = numel(legacy_casebank.nominal);
out.engine_nominal_count = numel(engine_casebank.nominal);
out.nominal_count_match = (out.legacy_nominal_count == out.engine_nominal_count);

if out.nominal_count_match && ~isempty(legacy_casebank.nominal) && ~isempty(engine_casebank.nominal)
    out.first_case_id_legacy = string(legacy_casebank.nominal(1).case_id);
    out.first_case_id_engine = string(engine_casebank.nominal(1).case_id);
    out.first_case_match = strcmp(out.first_case_id_legacy, out.first_case_id_engine);
else
    out.first_case_id_legacy = "";
    out.first_case_id_engine = "";
    out.first_case_match = false;
end
end
