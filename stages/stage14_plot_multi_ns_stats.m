function out = stage14_plot_multi_ns_stats(cfg, opts)
%STAGE14_PLOT_MULTI_NS_STATS
% Aggregate and plot Stage14.3 multi-Ns statistics.
%
% New behavior:
%   - if fewer than 2 distinct valid Ns values remain after filtering,
%     DO NOT generate "vs Ns" curves.
%   - still export summary table and emit a clear warning.

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
    local.save_table = true;
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    agg_out = stage14_analyze_multi_ns_envelopes(cfg, struct( ...
        'h_km', local.h_km, ...
        'i_deg', local.i_deg, ...
        'F', local.F, ...
        'Ns_list', local.Ns_list, ...
        'save_table', local.save_table, ...
        'quiet', true));

    T = agg_out.summary_table_all;
    is_valid = false(height(T),1);
    if ismember('is_valid', T.Properties.VariableNames)
        is_valid = logical(T.is_valid);
    else
        is_valid(:) = true;
    end

    valid_T = T(is_valid, :);
    distinct_ns = [];
    if ~isempty(valid_T) && ismember('Ns', valid_T.Properties.VariableNames)
        distinct_ns = unique(valid_T.Ns(:))';
    end

    fig_dir = fullfile(cfg.paths.outputs, 'stage', 'stage14', 'figs');
    if ~exist(fig_dir, 'dir')
        mkdir(fig_dir);
    end

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    out = struct();
    out.summary_table_all = T;
    out.valid_table = valid_T;
    out.files = struct();
    out.files.fig_dir = fig_dir;
    out.files.multi_ns_table_file = agg_out.files.multi_ns_table_file;

    % Default empty outputs
    out.files.DG_mean_png   = "";
    out.files.DG_min_png    = "";
    out.files.DG_span_png   = "";
    out.files.pass_mean_png = "";
    out.files.pass_min_png  = "";
    out.files.pass_span_png = "";
    out.warning = "";

    if numel(distinct_ns) < 2
        out.warning = sprintf(['Stage14.3 skipped curve plotting: fewer than 2 distinct Ns values ' ...
            'after filtering (count=%d).'], numel(distinct_ns));

        warning('stage14_plot_multi_ns_stats:TooFewNs', '%s', out.warning);

        fprintf('\n=== Stage14.3 multi-Ns statistic plots ===\n');
        fprintf('filter          : h=%g, i=%g, F=%g\n', local.h_km, local.i_deg, local.F);
        fprintf('Ns list         : ');
        if isempty(local.Ns_list)
            fprintf('[empty]\n');
        else
            disp(local.Ns_list);
        end
        fprintf('valid rows      : %d\n', height(valid_T));
        fprintf('curve plots     : skipped (distinct valid Ns < 2)\n');
        fprintf('table file      : %s\n', agg_out.files.multi_ns_table_file);
        fprintf('warning         : %s\n\n', out.warning);

        return;
    end

    x = valid_T.Ns;

    % ---- DG mean ----
    fig = figure('Visible', local.visible);
    plot(x, valid_T.DG_env_mean, '-o', 'LineWidth', 1.5, 'MarkerSize', 8);
    grid on;
    xlabel('N_s');
    ylabel('DG env mean');
    title(sprintf('Stage14.3 multi-N_s stats: DG env mean vs N_s\\nh=%g km, i=%g deg, F=%g', ...
        local.h_km, local.i_deg, local.F));
    if local.save_fig
        out.files.DG_mean_png = fullfile(fig_dir, ...
            sprintf('stage14_DGenv_mean_vs_Ns_h%g_i%g_F%g_%s.png', ...
            local.h_km, local.i_deg, local.F, timestamp));
        saveas(fig, out.files.DG_mean_png);
    end

    % ---- DG min ----
    fig = figure('Visible', local.visible);
    plot(x, valid_T.DG_env_min, '-o', 'LineWidth', 1.5, 'MarkerSize', 8);
    hold on;
    yline(1, '--');
    grid on;
    xlabel('N_s');
    ylabel('DG env min');
    title(sprintf('Stage14.3 multi-N_s stats: DG env min vs N_s\\nh=%g km, i=%g deg, F=%g', ...
        local.h_km, local.i_deg, local.F));
    if local.save_fig
        out.files.DG_min_png = fullfile(fig_dir, ...
            sprintf('stage14_DGenv_min_vs_Ns_h%g_i%g_F%g_%s.png', ...
            local.h_km, local.i_deg, local.F, timestamp));
        saveas(fig, out.files.DG_min_png);
    end

    % ---- DG span ----
    fig = figure('Visible', local.visible);
    plot(x, valid_T.DG_env_span, '-o', 'LineWidth', 1.5, 'MarkerSize', 8);
    grid on;
    xlabel('N_s');
    ylabel('DG env span');
    title(sprintf('Stage14.3 multi-N_s stats: DG env span vs N_s\\nh=%g km, i=%g deg, F=%g', ...
        local.h_km, local.i_deg, local.F));
    if local.save_fig
        out.files.DG_span_png = fullfile(fig_dir, ...
            sprintf('stage14_DGenv_span_vs_Ns_h%g_i%g_F%g_%s.png', ...
            local.h_km, local.i_deg, local.F, timestamp));
        saveas(fig, out.files.DG_span_png);
    end

    % ---- pass mean ----
    fig = figure('Visible', local.visible);
    plot(x, valid_T.pass_env_mean, '-o', 'LineWidth', 1.5, 'MarkerSize', 8);
    grid on;
    xlabel('N_s');
    ylabel('pass env mean');
    title(sprintf('Stage14.3 multi-N_s stats: pass env mean vs N_s\\nh=%g km, i=%g deg, F=%g', ...
        local.h_km, local.i_deg, local.F));
    ylim([0 1]);
    if local.save_fig
        out.files.pass_mean_png = fullfile(fig_dir, ...
            sprintf('stage14_passenv_mean_vs_Ns_h%g_i%g_F%g_%s.png', ...
            local.h_km, local.i_deg, local.F, timestamp));
        saveas(fig, out.files.pass_mean_png);
    end

    % ---- pass min ----
    fig = figure('Visible', local.visible);
    plot(x, valid_T.pass_env_min, '-o', 'LineWidth', 1.5, 'MarkerSize', 8);
    grid on;
    xlabel('N_s');
    ylabel('pass env min');
    title(sprintf('Stage14.3 multi-N_s stats: pass env min vs N_s\\nh=%g km, i=%g deg, F=%g', ...
        local.h_km, local.i_deg, local.F));
    ylim([0 1]);
    if local.save_fig
        out.files.pass_min_png = fullfile(fig_dir, ...
            sprintf('stage14_passenv_min_vs_Ns_h%g_i%g_F%g_%s.png', ...
            local.h_km, local.i_deg, local.F, timestamp));
        saveas(fig, out.files.pass_min_png);
    end

    % ---- pass span ----
    fig = figure('Visible', local.visible);
    plot(x, valid_T.pass_env_span, '-o', 'LineWidth', 1.5, 'MarkerSize', 8);
    grid on;
    xlabel('N_s');
    ylabel('pass env span');
    title(sprintf('Stage14.3 multi-N_s stats: pass env span vs N_s\\nh=%g km, i=%g deg, F=%g', ...
        local.h_km, local.i_deg, local.F));
    ylim([0 1]);
    if local.save_fig
        out.files.pass_span_png = fullfile(fig_dir, ...
            sprintf('stage14_passenv_span_vs_Ns_h%g_i%g_F%g_%s.png', ...
            local.h_km, local.i_deg, local.F, timestamp));
        saveas(fig, out.files.pass_span_png);
    end

    fprintf('\n=== Stage14.3 multi-Ns statistic plots ===\n');
    fprintf('filter          : h=%g, i=%g, F=%g\n', local.h_km, local.i_deg, local.F);
    fprintf('Ns list         : ');
    disp(distinct_ns);
    fprintf('valid rows      : %d\n', height(valid_T));
    fprintf('DG mean plot    : %s\n', out.files.DG_mean_png);
    fprintf('DG min plot     : %s\n', out.files.DG_min_png);
    fprintf('DG span plot    : %s\n', out.files.DG_span_png);
    fprintf('pass mean plot  : %s\n', out.files.pass_mean_png);
    fprintf('pass min plot   : %s\n', out.files.pass_min_png);
    fprintf('pass span plot  : %s\n\n', out.files.pass_span_png);
end
