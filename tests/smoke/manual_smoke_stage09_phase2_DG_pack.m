function out = manual_smoke_stage09_phase2_DG_pack(cfg)
%MANUAL_SMOKE_STAGE09_PHASE2_DG_PACK
% Phase2-A smoke:
%   run Phase1-B scan-only pipeline
%   then draw DG Stage05-style 9 figures

    clear functions;
    rehash;
    evalc('startup();');

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end

    if ~isfield(cfg, 'stage09') || ~isstruct(cfg.stage09)
        cfg.stage09 = struct();
    end

    cfg.stage09 = local_set_if_empty(cfg.stage09, 'scheme_type', 'stage05_aligned');
    cfg.stage09 = local_set_if_empty(cfg.stage09, 'run_tag', 'inverse_stage09_phase2_DG_pack');
    cfg.stage09 = local_set_if_empty(cfg.stage09, 'casebank_mode', 'nominal_only');
    cfg.stage09 = local_set_if_empty(cfg.stage09, 'scan_theta_limit', inf);
    cfg.stage09 = local_set_if_empty(cfg.stage09, 'scan_case_limit', inf);
    cfg.stage09 = local_set_if_empty(cfg.stage09, 'gamma_source', 'inherit_stage04');
    cfg.stage09 = local_set_if_empty(cfg.stage09, 'use_parallel', false);
    cfg.stage09 = local_set_if_empty(cfg.stage09, 'disable_progress', false);
    cfg.stage09 = local_set_if_empty(cfg.stage09, 'scan_log_every', 10);

    fprintf('\n[PHASE2-A] Running Phase1-B scan-only pipeline...\n');
    out = manual_smoke_stage09_phase1_metric_views(cfg);

    fprintf('[PHASE2-A] Drawing DG Stage05-style ninepack...\n');
    out.packDG = plot_stage09_DG_stage05_pack(out, 'phase2dg');

    fprintf('\n[PHASE2-A] DG pack figure index:\n');
    disp(out.packDG.figure_index)
end


function S = local_set_if_empty(S, field_name, default_value)

    if ~isfield(S, field_name) || isempty(S.(field_name))
        S.(field_name) = default_value;
    end
end
