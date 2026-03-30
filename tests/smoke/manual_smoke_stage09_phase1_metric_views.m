function out = manual_smoke_stage09_phase1_metric_views(cfg)
%MANUAL_SMOKE_STAGE09_PHASE1_METRIC_VIEWS
% Phase1 smoke:
%   scan only (Stage09.1 + 9.4 + 9.5)
%   then build metric views / frontiers
%   no Stage09.6 plotting

    clear functions;
    rehash;
    evalc('startup();');

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    if ~isfield(cfg, 'stage09') || ~isstruct(cfg.stage09)
        cfg.stage09 = struct();
    end

    % -------------------------------
    % Fast default for Phase1
    % -------------------------------
    cfg.stage09.scheme_type = local_set_if_empty(cfg.stage09, 'scheme_type', 'stage05_aligned');
    cfg.stage09.run_tag = local_set_if_empty(cfg.stage09, 'run_tag', 'inverse_stage09_phase1_metric_views');
    cfg.stage09.casebank_mode = local_set_if_empty(cfg.stage09, 'casebank_mode', 'nominal_only');
    cfg.stage09.scan_theta_limit = local_set_if_empty(cfg.stage09, 'scan_theta_limit', inf);
    cfg.stage09.scan_case_limit = local_set_if_empty(cfg.stage09, 'scan_case_limit', inf);
    cfg.stage09.gamma_source = local_set_if_empty(cfg.stage09, 'gamma_source', 'inherit_stage04');
    cfg.stage09.use_parallel = local_set_if_empty(cfg.stage09, 'use_parallel', false);
    cfg.stage09.disable_progress = local_set_if_empty(cfg.stage09, 'disable_progress', false);
    cfg.stage09.scan_log_every = local_set_if_empty(cfg.stage09, 'scan_log_every', 10);

    % Keep current thresholds; Phase1 is data-layer only
    cfg = stage09_prepare_cfg(cfg);

    fprintf('\n');
    fprintf('================ Phase1 Metric-View Smoke ================\n');
    fprintf('run_tag            : %s\n', string(cfg.stage09.run_tag));
    fprintf('scheme_type        : %s\n', string(cfg.stage09.scheme_type));
    fprintf('casebank_mode      : %s\n', string(cfg.stage09.casebank_mode));
    fprintf('gamma_source       : %s\n', string(cfg.stage09.gamma_source));
    fprintf('require_DG_min     : %g\n', cfg.stage09.require_DG_min);
    fprintf('require_DA_min     : %g\n', cfg.stage09.require_DA_min);
    fprintf('require_DT_min     : %g\n', cfg.stage09.require_DT_min);
    fprintf('require_pass_ratio : %g\n', cfg.stage09.require_pass_ratio);
    fprintf('==========================================================\n\n');

    out = struct();

    fprintf('[PHASE1] Stage09.1 prepare task spec...\n');
    out.s1 = stage09_prepare_task_spec(cfg);

    fprintf('[PHASE1] Stage09.4 build feasible domain...\n');
    out.s4 = stage09_build_feasible_domain(cfg);

    fprintf('[PHASE1] Stage09.5 extract minimum boundary...\n');
    out.s5 = stage09_extract_minimum_boundary(out.s4, cfg);

    fprintf('[PHASE1] Build metric views...\n');
    out.views = build_stage09_metric_views(out, 'phase1');

    fprintf('[PHASE1] Build metric frontiers...\n');
    out.frontiers = build_stage09_metric_frontiers(out.views, out.s4.cfg, 'phase1');

    fprintf('\n');
    fprintf('---------------- Phase1 Smoke Summary ----------------\n');
    disp(out.views.summary);

    fprintf('\nDG transition summary:\n');
    disp(out.frontiers.DG.transition_summary);

    fprintf('\nDA transition summary:\n');
    disp(out.frontiers.DA.transition_summary);

    fprintf('\nDT transition summary:\n');
    disp(out.frontiers.DT.transition_summary);

    fprintf('\nJoint transition summary:\n');
    disp(out.frontiers.joint.transition_summary);

    fprintf('------------------------------------------------------\n\n');
end


function S = local_set_if_empty(S, field_name, default_value)

    if ~isfield(S, field_name) || isempty(S.(field_name))
        S.(field_name) = default_value;
    end
end
