function result = run_MB_heading_validation_stage06_singlecase(offset_deg)
if nargin < 1
    error('run_MB_heading_validation_stage06_singlecase:MissingInput', ...
        'offset_deg is required.');
end

startup;

profile = make_profile_MB_heading_validation_stage06();
profile.name = sprintf('MB_heading_validation_stage06_singlecase_%+03d', offset_deg);
profile.allowed_heading_offsets_deg = offset_deg;
profile.runtime.max_cases = 1;

mgr = create_static_evaluation_manager(profile);
result = mgr.run();

disp('[validation] MB heading single-case validation run completed.');
disp(result.truth_result.table(:, {'design_id','h_km','i_deg','P','T','Ns','gamma_eff_scalar','gamma_source','Tw_s','pass_ratio','is_feasible','joint_margin'}));
end
