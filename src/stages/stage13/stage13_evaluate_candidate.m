function out = stage13_evaluate_candidate(cfg, candidate, paths)
%STAGE13_EVALUATE_CANDIDATE Evaluate one Stage13 candidate via MA truth kernel.

cfg = stage13_default_config(cfg);
overrides = local_build_overrides(candidate);
scan_out = stage12B_truth_case_window_scan(cfg, overrides);
signature = stage13_extract_case_signature(scan_out, candidate);

curve_csv = fullfile(paths.cache, sprintf('stage13_curve_%s.csv', signature.case_tag));
writetable(scan_out.window_table, curve_csv);
signature.curve_data_path = string(curve_csv);

out = struct();
out.candidate = candidate;
out.scan_out = scan_out;
out.signature = signature;
end

function overrides = local_build_overrides(candidate)
overrides = struct();
overrides.case_mode = char(candidate.case_mode);
overrides.case_id = char(candidate.case_id);
overrides.Tw_s = candidate.Tw_s;
overrides.theta = struct( ...
    'h_km', candidate.h_km, ...
    'i_deg', candidate.i_deg, ...
    'P', candidate.P, ...
    'T', candidate.T, ...
    'F', candidate.F);
end
