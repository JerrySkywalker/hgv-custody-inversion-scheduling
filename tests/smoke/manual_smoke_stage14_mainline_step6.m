function out = manual_smoke_stage14_mainline_step6(cfg, opts)
%MANUAL_SMOKE_STAGE14_MAINLINE_STEP6
% Minimal smoke test for Stage14.3 third step:
%   plot multi-Ns aggregate statistic curves.
%
% Default filter:
%   h=1000, i=40, F=1
%
% Default Ns_list:
%   inferred from latest Stage14.1 raw grid

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
    local.F = cfg.stage05.F_fixed;
    local.Ns_list = [];
    local.visible = "on";
    local.save_fig = true;
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    out = stage14_plot_multi_ns_stats(cfg, local);

    fprintf('\n=== Stage14.3 step3 smoke summary ===\n');
    disp(out.summary_table_all);
end
