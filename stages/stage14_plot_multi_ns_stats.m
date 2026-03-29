function out = stage14_plot_multi_ns_stats(cfg, opts)
%STAGE14_PLOT_MULTI_NS_STATS
% Stage14.3 third step:
%   generate multi-Ns statistic plots from Stage14.3 step2 summary_table_all.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    cfg.project_stage = 'stage14_plot_multi_ns_stats';
    cfg = configure_stage_output_paths(cfg);

    local = struct();
    local.h_km = NaN;
    local.i_deg = NaN;
    local.F = NaN;
    local.Ns_list = [];
    local.visible = "on";
    local.save_fig = true;
    local.save_table = false;
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    analyze_opts = local;
    analyze_opts.quiet = true;
    analyze_opts.save_table = false;

    agg_out = stage14_analyze_multi_ns_envelopes(cfg, analyze_opts);
    summary_table_all = agg_out.summary_table_all;

    tag = sprintf('h%d_i%.0f_F%d', round(local.h_km), local.i_deg, local.F);

    files = plot_stage14_multi_ns_stats(summary_table_all, cfg, ...
        'visible', local.visible, ...
        'save_fig', local.save_fig, ...
        'tag', tag);

    out = struct();
    out.summary_table_all = summary_table_all;
    out.files = files;

    if ~local.quiet
        T = summary_table_all(summary_table_all.is_valid, :);
        fprintf('\n=== Stage14.3 multi-Ns statistic plots ===\n');
        fprintf('filter          : h=%g, i=%g, F=%d\n', local.h_km, local.i_deg, local.F);
        fprintf('valid rows      : %d\n', height(T));
        fprintf('DG mean plot    : %s\n', files.DG_mean_png);
        fprintf('DG min plot     : %s\n', files.DG_min_png);
        fprintf('DG span plot    : %s\n', files.DG_span_png);
        fprintf('pass mean plot  : %s\n', files.pass_mean_png);
        fprintf('pass min plot   : %s\n', files.pass_min_png);
        fprintf('pass span plot  : %s\n\n', files.pass_span_png);
    end
end
