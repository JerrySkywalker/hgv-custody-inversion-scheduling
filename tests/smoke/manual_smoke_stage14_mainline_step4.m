function out = manual_smoke_stage14_mainline_step4(cfg, opts)
%MANUAL_SMOKE_STAGE14_MAINLINE_STEP4
% Minimal smoke test for Stage14.3 first step:
%   aggregate Stage14.2 Ns-envelope table over RAAN_rel.
%
% Default target filter:
%   h=1000, i=40, Ns=48, F=1

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    local = struct();
    local.h_km = 1000;
    local.i_deg = 40;
    local.Ns = 48;
    local.F = cfg.stage05.F_fixed;
    local.visible = "off";
    local.save_fig = false;
    local.save_table = true;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    out = stage14_analyze_ns_envelopes(cfg, local);

    fprintf('\n=== Stage14.3 step1 smoke summary ===\n');
    disp(out.stats.summary_table);
end
