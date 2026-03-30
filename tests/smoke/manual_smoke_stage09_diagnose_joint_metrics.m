function out = manual_smoke_stage09_diagnose_joint_metrics(cfg)
%MANUAL_SMOKE_STAGE09_DIAGNOSE_JOINT_METRICS
% Stage09 diagnosis smoke:
%   DG + DA + DT + pass_ratio all active
% Purpose:
%   identify which Stage05-compatible points are killed in final joint mode.

    clear functions;
    rehash;
    evalc('startup();');

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    cfg.stage09.run_tag = 'inverse_stage09_diagnose_joint_metrics';
    cfg.stage09.scheme_type = 'stage05_aligned';
    cfg.stage09.casebank_mode = 'nominal_only';
    cfg.stage09.casebank_include_nominal = true;
    cfg.stage09.casebank_include_heading = false;
    cfg.stage09.casebank_include_critical = false;

    cfg.stage09.scan_theta_limit = inf;
    cfg.stage09.scan_case_limit = inf;
    cfg.stage09.gamma_source = 'inherit_stage04';
    cfg.stage09.plot_h_slice_km = cfg.stage05.h_fixed_km;

    cfg.stage09.require_DG_min = cfg.stage05.require_D_G_min;
    cfg.stage09.require_pass_ratio = cfg.stage05.require_pass_ratio;
    cfg.stage09.require_DA_min = 1.0;
    cfg.stage09.require_DT_min = 1.0;

    cfg.stage09.use_parallel = true;
    cfg.stage09.disable_progress = false;
    cfg.stage09.scan_log_every = 1;

    fprintf('\n[JOINT] Running Stage09 diagnose smoke...\n');
    out = manual_smoke_stage09_stage05_aligned_fullscan(cfg);
    out.diag = stage09_dump_metric_diagnosis(out, 'joint_metrics', 15);

    fprintf('\n[JOINT] Recommended CSVs:\n');
    fprintf('diag table    : %s\n', string(out.diag.files.diag_csv));
    fprintf('killed joint  : %s\n', string(out.diag.files.killed_joint_csv));
    fprintf('summary table : %s\n', string(out.diag.files.summary_csv));
    fprintf('\n');
end
