function out = manual_smoke_stage14_mainline_step3(cfg, opts)
%MANUAL_SMOKE_STAGE14_MAINLINE_STEP3
% Minimal smoke test for Stage14.2 second step:
%   fixed-(h,i,Ns,F) PT-envelope RAAN curves from latest Stage14.1 raw grid.
%
% Default target filter:
%   h=1000, i=40, Ns=48, F=1

    if nargin < 1 || isempty(cfg)
        evalc('startup();');
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
    local.visible = "on";
    local.save_fig = true;
    local.save_table = true;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    out = stage14_plot_ns_envelopes(cfg, local);

    fprintf('\n=== Stage14.2 step2 smoke summary ===\n');
    fprintf('rows           : %d\n', height(out.envelope_table));
    fprintf('DG_env span    : %.6f\n', out.summary.DG_env_span);
    fprintf('pass_env span  : %.6f\n', out.summary.pass_env_span);
    fprintf('DG plot        : %s\n', out.files.DG_env_png);
    fprintf('pass plot      : %s\n', out.files.pass_env_png);
    fprintf('table file     : %s\n\n', out.files.table_file);

    disp(out.envelope_table);
end
