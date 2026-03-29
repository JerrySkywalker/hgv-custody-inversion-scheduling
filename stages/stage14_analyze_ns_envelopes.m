function out = stage14_analyze_ns_envelopes(cfg, opts)
%STAGE14_ANALYZE_NS_ENVELOPES
% Stage14.3 first step:
%   aggregate one fixed-(h,i,Ns,F) envelope table over RAAN_rel.
%
% Current scope:
%   - read/rebuild one Stage14.2 envelope table
%   - output one summary table
%   - no B2 / B2-dual yet

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    cfg.project_stage = 'stage14_analyze_ns_envelopes';
    cfg = configure_stage_output_paths(cfg);

    local = struct();
    local.h_km = NaN;
    local.i_deg = NaN;
    local.Ns = NaN;
    local.F = NaN;
    local.visible = "off";
    local.save_fig = false;
    local.save_table = true;
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    env_opts = local;
    env_opts.quiet = true;
    env_out = stage14_plot_ns_envelopes(cfg, env_opts);
    envelope_table = env_out.envelope_table;

    stats = aggregate_stage14_ns_envelope_stats(envelope_table);

    files = struct();
    files.summary_table_file = '';

    if local.save_table
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        tag = sprintf('h%d_i%.0f_Ns%d_F%d', ...
            round(stats.summary_table.h_km(1)), ...
            stats.summary_table.i_deg(1), ...
            stats.summary_table.Ns(1), ...
            stats.summary_table.F(1));
        files.summary_table_file = fullfile(cfg.paths.tables, ...
            sprintf('stage14_ns_envelope_stats_%s_%s.csv', tag, timestamp));
        writetable(stats.summary_table, files.summary_table_file);
    end

    out = struct();
    out.envelope_table = envelope_table;
    out.stats = stats;
    out.files = files;

    if ~local.quiet
        S = stats.summary_table;
        fprintf('\n=== Stage14.3 Ns-envelope aggregate stats ===\n');
        fprintf('filter                : h=%g, i=%g, F=%d, Ns=%d\n', ...
            S.h_km(1), S.i_deg(1), S.F(1), S.Ns(1));
        fprintf('DG mean/min/max/span  : %.6f / %.6f / %.6f / %.6f\n', ...
            S.DG_env_mean(1), S.DG_env_min(1), S.DG_env_max(1), S.DG_env_span(1));
        fprintf('pass mean/min/max/span: %.6f / %.6f / %.6f / %.6f\n', ...
            S.pass_env_mean(1), S.pass_env_min(1), S.pass_env_max(1), S.pass_env_span(1));
        fprintf('best mean DG PT       : (%d,%d)\n', ...
            S.best_P_of_raan_mean_DG(1), S.best_T_of_raan_mean_DG(1));
        fprintf('best worst DG PT      : (%d,%d) at RAAN=%g deg\n', ...
            S.best_P_of_raan_min_DG(1), S.best_T_of_raan_min_DG(1), S.RAAN_of_raan_min_DG(1));
        fprintf('best mean pass PT     : (%d,%d)\n', ...
            S.best_P_of_raan_mean_pass(1), S.best_T_of_raan_mean_pass(1));
        fprintf('best worst pass PT    : (%d,%d) at RAAN=%g deg\n', ...
            S.best_P_of_raan_min_pass(1), S.best_T_of_raan_min_pass(1), S.RAAN_of_raan_min_pass(1));
        fprintf('summary table file    : %s\n\n', files.summary_table_file);
    end
end
