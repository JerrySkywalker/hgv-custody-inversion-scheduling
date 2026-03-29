function out = stage14_analyze_multi_ns_envelopes(cfg, opts)
%STAGE14_ANALYZE_MULTI_NS_ENVELOPES
% Stage14.3 second step:
%   aggregate Stage14 Ns-envelope statistics across multiple Ns values.

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    cfg.project_stage = 'stage14_analyze_multi_ns_envelopes';
    cfg = configure_stage_output_paths(cfg);

    local = struct();
    local.h_km = NaN;
    local.i_deg = NaN;
    local.F = NaN;
    local.Ns_list = [];
    local.save_table = true;
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    assert(~isempty(local.Ns_list), 'opts.Ns_list must be provided.');

    filter_opts = struct();
    filter_opts.h_km = local.h_km;
    filter_opts.i_deg = local.i_deg;
    filter_opts.F = local.F;
    filter_opts.visible = "off";
    filter_opts.save_fig = false;
    filter_opts.save_table = false;
    filter_opts.quiet = true;

    agg = aggregate_stage14_multi_ns_stats(cfg, filter_opts, local.Ns_list);

    files = struct();
    files.multi_ns_table_file = '';

    if local.save_table
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        tag = sprintf('h%d_i%.0f_F%d', round(local.h_km), local.i_deg, local.F);
        files.multi_ns_table_file = fullfile(cfg.paths.tables, ...
            sprintf('stage14_multi_ns_stats_%s_%s.csv', tag, timestamp));
        writetable(agg.summary_table_all, files.multi_ns_table_file);
    end

    out = struct();
    out.summary_table_all = agg.summary_table_all;
    out.per_ns_results = agg.per_ns_results;
    out.files = files;

    if ~local.quiet
        valid_rows = agg.summary_table_all(agg.summary_table_all.is_valid, :);
        fprintf('\n=== Stage14.3 multi-Ns aggregate stats ===\n');
        fprintf('filter             : h=%g, i=%g, F=%d\n', local.h_km, local.i_deg, local.F);
        fprintf('requested Ns list  : ');
        disp(local.Ns_list);
        fprintf('valid rows         : %d / %d\n', height(valid_rows), height(agg.summary_table_all));
        fprintf('table file         : %s\n\n', files.multi_ns_table_file);
        disp(agg.summary_table_all);
    end
end
