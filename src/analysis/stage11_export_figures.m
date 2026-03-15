function files = stage11_export_figures(out, cfg, timestamp)
%STAGE11_EXPORT_FIGURES Export Stage11 paper-friendly figures.

    if nargin < 3 || isempty(timestamp)
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    end

    files = struct();
    files.representative_png = local_plot_representative(out, cfg, timestamp);
    files.label_bar_png = local_plot_case_labels(out, cfg, timestamp);
    files.gap_box_png = local_plot_gap_box(out, cfg, timestamp);
    files.source_bar_png = local_plot_best_source(out, cfg, timestamp);
    files.coverage_png = local_plot_valid_ratio(out, cfg, timestamp);
    files.failure_reason_png = local_plot_failure_reason_counts(out, cfg, timestamp);
    files.match_ratio_png = local_plot_match_ratio_box(out, cfg, timestamp);
    files.subspace_diag_png = local_plot_subspace_diag_scatter(out, cfg, timestamp);
end


function out_png = local_plot_representative(out, cfg, timestamp)
    WT = out.window_table;
    theta_id = WT.theta_id(1);
    case_index = min(cfg.stage11.case_index, max(WT.case_index));
    mask = (WT.theta_id == theta_id) & (WT.case_index == case_index);
    T = sortrows(WT(mask, :), 't0_s', 'ascend');
    case_row = out.case_table(out.case_table.theta_id == theta_id & out.case_table.case_index == case_index, :);
    title_text = sprintf('Stage11 representative window bounds | case %s', char(string(T.case_id(1))));
    if ~isempty(case_row) && ismember('valid_ratio_new', case_row.Properties.VariableNames)
        title_text = sprintf('%s | valid ratio %.2f | all valid %d', ...
            title_text, case_row.valid_ratio_new(1), case_row.all_valid_new(1));
    end

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1180 720]);
    legend_entries = {};
    plot(T.t0_s, T.truth_lambda_min, 'k-', 'LineWidth', 1.8);
    legend_entries{end+1} = 'truth'; %#ok<AGROW>
    hold on;
    plot(T.t0_s, T.old_bound, '-', 'LineWidth', 1.2, 'Color', [0.3 0.45 0.85]);
    legend_entries{end+1} = 'old'; %#ok<AGROW>
    plot(T.t0_s, T.L_weak, '-', 'LineWidth', 1.2, 'Color', [0.2 0.6 0.25]);
    legend_entries{end+1} = 'weak'; %#ok<AGROW>
    if ismember('L_sub', T.Properties.VariableNames)
        plot(T.t0_s, T.L_sub, '-', 'LineWidth', 1.2, 'Color', [0.9 0.45 0.15]);
        legend_entries{end+1} = 'sub'; %#ok<AGROW>
    end
    if ismember('L_partblk', T.Properties.VariableNames) && any(isfinite(T.L_partblk))
        plot(T.t0_s, T.L_partblk, '-', 'LineWidth', 1.2, 'Color', [0.55 0.4 0.75]);
        legend_entries{end+1} = 'partblk'; %#ok<AGROW>
    end
    if ismember('L_new', T.Properties.VariableNames)
        plot(T.t0_s, T.L_new, '--', 'LineWidth', 1.6, 'Color', [0.85 0.1 0.1]);
        legend_entries{end+1} = 'new'; %#ok<AGROW>
    end
    yline(cfg.stage11.threshold_truth, ':', 'LineWidth', 1.2, 'Color', [0.35 0.35 0.35]);
    legend_entries{end+1} = 'truth threshold'; %#ok<AGROW>
    hold off;
    xlabel('t_0 [s]');
    ylabel('Lower-bound / truth value');
    title(title_text);
    legend(legend_entries, 'Location', 'best');
    grid on;

    out_png = fullfile(cfg.paths.figs, ...
        sprintf('stage11_representative_bounds_%s_%s.png', cfg.stage11.run_tag, timestamp));
    exportgraphics(fig, out_png, 'Resolution', 180);
    close(fig);
end


function out_png = local_plot_case_labels(out, cfg, timestamp)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1000 620]);
    labels = categorical({'reject', 'warn_pass', 'safe_pass'});
    old_counts = local_count_labels(out.case_table.old_case_label, labels);
    new_counts = local_count_labels(out.case_table.new_case_label, labels);

    bar(categorical(labels), [old_counts, new_counts], 'grouped');
    xlabel('Case label');
    ylabel('Count');
    title('Stage11 old/new case-label counts');
    legend({'old', 'new'}, 'Location', 'best');
    grid on;

    out_png = fullfile(cfg.paths.figs, ...
        sprintf('stage11_case_label_counts_%s_%s.png', cfg.stage11.run_tag, timestamp));
    exportgraphics(fig, out_png, 'Resolution', 180);
    close(fig);
end


function out_png = local_plot_gap_box(out, cfg, timestamp)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 980 620]);
    gap_old = out.window_table.truth_lambda_min - out.window_table.old_bound;
    gap_new = out.window_table.truth_lambda_min - out.window_table.L_new;
    boxplot([gap_old, gap_new], 'Labels', {'gap old', 'gap new'});
    ylabel('truth - lower bound');
    title('Stage11 gap distribution');
    grid on;

    out_png = fullfile(cfg.paths.figs, ...
        sprintf('stage11_gap_box_%s_%s.png', cfg.stage11.run_tag, timestamp));
    exportgraphics(fig, out_png, 'Resolution', 180);
    close(fig);
end


function out_png = local_plot_best_source(out, cfg, timestamp)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 980 620]);
    valid_mask = true(height(out.window_table), 1);
    if ismember('new_valid', out.window_table.Properties.VariableNames)
        valid_mask = logical(out.window_table.new_valid);
    end
    source_order = {'weak', 'sub'};
    if ismember('L_partblk', out.window_table.Properties.VariableNames) && any(isfinite(out.window_table.L_partblk))
        source_order{end+1} = 'partblk'; %#ok<AGROW>
    end
    labels = categorical(out.window_table.best_bound_source(valid_mask), source_order);
    counts = zeros(numel(source_order), 1);
    for i = 1:numel(source_order)
        counts(i) = sum(labels == source_order{i});
    end
    bar(categorical(source_order), counts, 'FaceColor', [0.2 0.55 0.85]);
    xlabel('Winning bound');
    ylabel('Valid window count');
    title('Stage11 best-bound source ratio (valid windows only)');
    grid on;

    out_png = fullfile(cfg.paths.figs, ...
        sprintf('stage11_best_source_%s_%s.png', cfg.stage11.run_tag, timestamp));
    exportgraphics(fig, out_png, 'Resolution', 180);
    close(fig);
end


function out_png = local_plot_valid_ratio(out, cfg, timestamp)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1080 620]);
    case_ids = categorical(cellstr(string(out.case_table.case_id)));
    bar(case_ids, out.case_table.valid_ratio_new, 'FaceColor', [0.2 0.6 0.4]);
    ylim([0 1.05]);
    xlabel('Case');
    ylabel('valid ratio (new)');
    title('Stage11 case-level valid-window coverage');
    grid on;

    out_png = fullfile(cfg.paths.figs, ...
        sprintf('stage11_valid_ratio_%s_%s.png', cfg.stage11.run_tag, timestamp));
    exportgraphics(fig, out_png, 'Resolution', 180);
    close(fig);
end


function out_png = local_plot_failure_reason_counts(out, cfg, timestamp)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1100 620]);
    reason_order = {'no_reference_match', 'partial_reference_match', 'weak_invalid', ...
        'sub_invalid', 'all_bounds_invalid', 'numerical_issue'};
    counts = zeros(numel(reason_order), 1);
    reasons = string(out.window_table.new_failure_reason);
    for i = 1:numel(reason_order)
        counts(i) = sum(reasons == reason_order{i});
    end
    bar(categorical(reason_order), counts, 'FaceColor', [0.8 0.35 0.25]);
    xlabel('Failure reason');
    ylabel('Window count');
    title('Stage11 window failure reason counts');
    grid on;

    out_png = fullfile(cfg.paths.figs, ...
        sprintf('stage11_window_failure_reason_counts_%s_%s.png', cfg.stage11.run_tag, timestamp));
    exportgraphics(fig, out_png, 'Resolution', 180);
    close(fig);
end


function out_png = local_plot_match_ratio_box(out, cfg, timestamp)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 620]);
    boxplot(out.window_table.match_ratio, 'Labels', {'match ratio'});
    ylabel('Reference group match ratio');
    title('Stage11 reference match ratio distribution');
    grid on;

    out_png = fullfile(cfg.paths.figs, ...
        sprintf('stage11_match_ratio_box_%s_%s.png', cfg.stage11.run_tag, timestamp));
    exportgraphics(fig, out_png, 'Resolution', 180);
    close(fig);
end


function out_png = local_plot_subspace_diag_scatter(out, cfg, timestamp)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 980 680]);
    valid_mask = logical(out.window_table.sub_valid);
    scatter(out.window_table.eig_gap(valid_mask), out.window_table.g_norm(valid_mask), ...
        42, [0.2 0.6 0.35], 'filled');
    hold on;
    scatter(out.window_table.eig_gap(~valid_mask), out.window_table.g_norm(~valid_mask), ...
        42, [0.85 0.25 0.2], 'filled');
    hold off;
    xlabel('eig gap = beta - alpha');
    ylabel('g norm');
    title('Stage11 subspace diagnostic scatter');
    legend({'sub valid', 'sub invalid'}, 'Location', 'best');
    grid on;

    out_png = fullfile(cfg.paths.figs, ...
        sprintf('stage11_subspace_diag_scatter_%s_%s.png', cfg.stage11.run_tag, timestamp));
    exportgraphics(fig, out_png, 'Resolution', 180);
    close(fig);
end


function counts = local_count_labels(label_values, labels)
    counts = zeros(numel(labels), 1);
    values = categorical(label_values, cellstr(string(labels)));
    for i = 1:numel(labels)
        counts(i) = sum(values == labels(i));
    end
end
