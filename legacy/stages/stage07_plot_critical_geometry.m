function out = stage07_plot_critical_geometry(cfg)
    %STAGE07_PLOT_CRITICAL_GEOMETRY
    % Stage07.5:
    %   Plot critical-geometry mechanism figures from Stage07.3 + Stage07.4 results.
    %
    % Main tasks:
    %   1) load Stage07.1 reference Walker
    %   2) load Stage07.3 risk map
    %   3) load Stage07.4 selected examples
    %   4) generate three groups of figures:
    %       - grouped bar compare (nominal / C1 / C2)
    %       - representative heading-risk curves
    %       - coverage vs D_G scatter
    %   5) save figs and plot data tables
    %
    % Outputs:
    %   out.files
    %   out.summary_table
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg.project_stage = 'stage07_plot_critical_geometry';
        cfg = configure_stage_output_paths(cfg);
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
        ensure_dir(cfg.paths.figs);
    
        % Use existing path fields from default_params
        fig_dir = cfg.paths.figs;
        table_dir = cfg.paths.tables;
    
        run_tag = char(cfg.stage07.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage07_plot_critical_geometry_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage07.5 started.');
    
        % ============================================================
        % Load Stage07.1 reference
        % ============================================================
        d71 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_select_reference_walker_%s_*.mat', run_tag)));
        assert(~isempty(d71), 'No Stage07.1 cache found.');
    
        [~, idx71] = max([d71.datenum]);
        stage07_ref_file = fullfile(d71(idx71).folder, d71(idx71).name);
        S71 = load(stage07_ref_file);
        assert(isfield(S71, 'out') && isfield(S71.out, 'reference_walker'), ...
            'Invalid Stage07.1 cache.');
        reference_walker = S71.out.reference_walker;
    
        % ============================================================
        % Load Stage07.3 risk map
        % ============================================================
        d73 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_scan_heading_risk_map_%s_*.mat', run_tag)));
        assert(~isempty(d73), 'No Stage07.3 cache found.');
    
        [~, idx73] = max([d73.datenum]);
        stage07_risk_file = fullfile(d73(idx73).folder, d73(idx73).name);
        S73 = load(stage07_risk_file);
        assert(isfield(S73, 'out') && isfield(S73.out, 'risk_table') && isfield(S73.out, 'entry_summary'), ...
            'Invalid Stage07.3 cache.');
        risk_table = S73.out.risk_table;
        entry_summary = S73.out.entry_summary; %#ok<NASGU>
    
        % ============================================================
        % Load Stage07.4 selected examples
        % ============================================================
        d74 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_select_critical_examples_%s_*.mat', run_tag)));
        assert(~isempty(d74), 'No Stage07.4 cache found.');
    
        [~, idx74] = max([d74.datenum]);
        stage07_sel_file = fullfile(d74(idx74).folder, d74(idx74).name);
        S74 = load(stage07_sel_file);
        assert(isfield(S74, 'out') && isfield(S74.out, 'selection_table') && isfield(S74.out, 'entry_selection_table'), ...
            'Invalid Stage07.4 cache.');
        selection_table = S74.out.selection_table;
        entry_selection_table = S74.out.entry_selection_table;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage07.1 reference: %s', stage07_ref_file);
        log_msg(log_fid, 'INFO', 'Loaded Stage07.3 risk map : %s', stage07_risk_file);
        log_msg(log_fid, 'INFO', 'Loaded Stage07.4 selection: %s', stage07_sel_file);
    
        % ============================================================
        % Figure 1: grouped bar compare
        % ============================================================
        [fig1_files, fig1_tables] = local_plot_grouped_bar_compare( ...
            selection_table, fig_dir, table_dir, run_tag, timestamp, cfg);
    
        % ============================================================
        % Figure 2: representative heading-risk curves
        % ============================================================
        rep_entries = local_pick_representative_entries(entry_selection_table, cfg);
        [fig2_files, fig2_tables] = local_plot_heading_risk_curves( ...
            risk_table, selection_table, rep_entries, fig_dir, table_dir, run_tag, timestamp, cfg);
    
        % ============================================================
        % Figure 3: coverage vs D_G scatter
        % ============================================================
        [fig3_files, fig3_tables] = local_plot_scatter_cov_vs_DG( ...
            risk_table, selection_table, fig_dir, table_dir, run_tag, timestamp, cfg);
    
        % ============================================================
        % Save summary
        % ============================================================
        summary_table = table( ...
            reference_walker.h_km, ...
            reference_walker.i_deg, ...
            reference_walker.P, ...
            reference_walker.T, ...
            reference_walker.Ns, ...
            height(risk_table), ...
            height(selection_table), ...
            numel(rep_entries), ...
            'VariableNames', { ...
                'h_km', ...
                'i_deg', ...
                'P', ...
                'T', ...
                'Ns', ...
                'n_risk_row', ...
                'n_selected_row', ...
                'n_representative_entry'});
    
        summary_csv = fullfile(table_dir, ...
            sprintf('stage07_plot_summary_%s_%s.csv', run_tag, timestamp));
        writetable(summary_table, summary_csv);
    
        out = struct();
        out.reference_walker = reference_walker;
        out.summary_table = summary_table;
        out.representative_entries = rep_entries;
    
        out.files = struct();
        out.files.log_file = log_file;
        out.files.stage07_ref_file = stage07_ref_file;
        out.files.stage07_risk_file = stage07_risk_file;
        out.files.stage07_sel_file = stage07_sel_file;
        out.files.summary_csv = summary_csv;
    
        out.files.fig1 = fig1_files;
        out.files.fig2 = fig2_files;
        out.files.fig3 = fig3_files;
    
        out.files.fig1_tables = fig1_tables;
        out.files.fig2_tables = fig2_tables;
        out.files.fig3_tables = fig3_tables;
    
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage07_plot_critical_geometry_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage07.5 finished.');
    
        fprintf('\n');
        fprintf('========== Stage07.5 Summary ==========\n');
        fprintf('Stage07.1 ref         : %s\n', stage07_ref_file);
        fprintf('Stage07.3 risk        : %s\n', stage07_risk_file);
        fprintf('Stage07.4 selection   : %s\n', stage07_sel_file);
        fprintf('Representative entries: %d\n', numel(rep_entries));
        fprintf('Summary CSV           : %s\n', summary_csv);
        fprintf('Cache                 : %s\n', cache_file);
        fprintf('=======================================\n');
    end
    
    
    % ============================================================
    % Figure 1: grouped bar compare
    % ============================================================
    function [file_struct, table_struct] = local_plot_grouped_bar_compare(selection_table, fig_dir, table_dir, run_tag, timestamp, cfg)
    
        file_struct = struct();
        table_struct = struct();
    
        entries = unique(selection_table.entry_id);
        nEntry = numel(entries);
    
        sample_order = ["nominal", "C1", "C2"];
        metric_names = {'D_G_min', 'lambda_worst', 'mean_los_intersection_angle_deg'};
        metric_short = {'DG', 'lambda', 'angle'};
    
        for m = 1:numel(metric_names)
            metric = metric_names{m};
            shortname = metric_short{m};
    
            M = nan(nEntry, numel(sample_order));
    
            for i = 1:nEntry
                eid = entries(i);
                sub = selection_table(selection_table.entry_id == eid, :);
    
                for j = 1:numel(sample_order)
                    ss = sub(sub.sample_type == sample_order(j), :);
                    if ~isempty(ss)
                        M(i,j) = ss.(metric)(1);
                    end
                end
            end
    
            Tplot = array2table(M, 'VariableNames', cellstr(sample_order));
            Tplot = addvars(Tplot, entries, 'Before', 1, 'NewVariableNames', 'entry_id');
    
            fig = figure('Visible', cfg.stage07.plot.visible);
            bar(categorical(entries), M, 'grouped');
            xlabel('Entry ID');
            ylabel(metric, 'Interpreter', 'none');
            title(sprintf('Stage07 Selected Samples Compare: %s', metric), 'Interpreter', 'none');
            legend(cellstr(sample_order), 'Location', 'best');
            grid on;
    
            png_file = fullfile(fig_dir, ...
                sprintf('stage07_compare_%s_%s_%s.png', shortname, run_tag, timestamp));
            fig_file = fullfile(fig_dir, ...
                sprintf('stage07_compare_%s_%s_%s.fig', shortname, run_tag, timestamp));
            csv_file = fullfile(table_dir, ...
                sprintf('stage07_compare_%s_%s_%s.csv', shortname, run_tag, timestamp));
    
            if cfg.stage07.plot.save_png, saveas(fig, png_file); end
            if cfg.stage07.plot.save_fig, savefig(fig, fig_file); end
            if cfg.stage07.plot.export_plot_tables, writetable(Tplot, csv_file); end
            close(fig);
    
            file_struct.(shortname).png = png_file;
            file_struct.(shortname).fig = fig_file;
            file_struct.(shortname).csv = csv_file;
            table_struct.(shortname) = Tplot;
        end
    end
    
    
    % ============================================================
    % Figure 2: representative heading-risk curves
    % ============================================================
    function [file_struct, table_struct] = local_plot_heading_risk_curves(risk_table, selection_table, rep_entries, fig_dir, table_dir, run_tag, timestamp, cfg)
    
        file_struct = struct();
        table_struct = struct();
    
        metric_names = {'D_G_min', 'lambda_worst', 'mean_los_intersection_angle_deg'};
        metric_short = {'DG', 'lambda', 'angle'};
    
        for i = 1:numel(rep_entries)
            eid = rep_entries(i);
    
            sub = risk_table(risk_table.entry_id == eid, :);
            sel = selection_table(selection_table.entry_id == eid, :);
    
            sub = sortrows(sub, 'heading_offset_deg');
    
            for m = 1:numel(metric_names)
                metric = metric_names{m};
                shortname = metric_short{m};
    
                fig = figure('Visible', cfg.stage07.plot.visible);
                plot(sub.heading_offset_deg, sub.(metric), '-o');
                hold on;
    
                for j = 1:height(sel)
                    x = sel.heading_offset_deg(j);
                    y = sel.(metric)(j);
                    plot(x, y, 'o', 'MarkerSize', 8, 'LineWidth', 1.5);
                    text(x, y, char(sel.sample_type(j)), ...
                        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
                end
    
                xlabel('Heading Offset (deg)');
                ylabel(metric, 'Interpreter', 'none');
                title(sprintf('Entry %d Heading-Risk Curve: %s', eid, metric), 'Interpreter', 'none');
                grid on;
                hold off;
    
                png_file = fullfile(fig_dir, ...
                    sprintf('stage07_entry%02d_curve_%s_%s_%s.png', eid, shortname, run_tag, timestamp));
                fig_file = fullfile(fig_dir, ...
                    sprintf('stage07_entry%02d_curve_%s_%s_%s.fig', eid, shortname, run_tag, timestamp));
                csv_file = fullfile(table_dir, ...
                    sprintf('stage07_entry%02d_curve_%s_%s_%s.csv', eid, shortname, run_tag, timestamp));
    
                if cfg.stage07.plot.save_png, saveas(fig, png_file); end
                if cfg.stage07.plot.save_fig, savefig(fig, fig_file); end
                if cfg.stage07.plot.export_plot_tables, writetable(sub, csv_file); end
                close(fig);
    
                tag = sprintf('entry%02d_%s', eid, shortname);
                file_struct.(tag).png = png_file;
                file_struct.(tag).fig = fig_file;
                file_struct.(tag).csv = csv_file;
                table_struct.(tag) = sub;
            end
        end
    end
    
    
    % ============================================================
    % Figure 3: coverage vs D_G scatter
    % ============================================================
    function [file_struct, table_struct] = local_plot_scatter_cov_vs_DG(risk_table, selection_table, fig_dir, table_dir, run_tag, timestamp, cfg)
    
        file_struct = struct();
        table_struct = struct();
    
        fig = figure('Visible', cfg.stage07.plot.visible);
        scatter(risk_table.coverage_ratio_2sat, risk_table.D_G_min, 20, 'filled');
        hold on;
    
        for j = 1:height(selection_table)
            x = selection_table.coverage_ratio_2sat(j);
            y = selection_table.D_G_min(j);
            plot(x, y, 'o', 'MarkerSize', 8, 'LineWidth', 1.5);
            text(x, y, sprintf('%d-%s', selection_table.entry_id(j), char(selection_table.sample_type(j))), ...
                'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
        end
    
        xlabel('coverage_ratio_2sat', 'Interpreter', 'none');
        ylabel('D_G_min', 'Interpreter', 'none');
        title('Stage07 Coverage vs D_G Scatter', 'Interpreter', 'none');
        grid on;
        hold off;
    
        png_file = fullfile(fig_dir, ...
            sprintf('stage07_scatter_cov_vs_DG_%s_%s.png', run_tag, timestamp));
        fig_file = fullfile(fig_dir, ...
            sprintf('stage07_scatter_cov_vs_DG_%s_%s.fig', run_tag, timestamp));
        csv_file = fullfile(table_dir, ...
            sprintf('stage07_scatter_cov_vs_DG_%s_%s.csv', run_tag, timestamp));
    
        if cfg.stage07.plot.save_png, saveas(fig, png_file); end
        if cfg.stage07.plot.save_fig, savefig(fig, fig_file); end
        if cfg.stage07.plot.export_plot_tables, writetable(risk_table, csv_file); end
        close(fig);
    
        file_struct.png = png_file;
        file_struct.fig = fig_file;
        file_struct.csv = csv_file;
        table_struct = risk_table;
    end
    
    
    % ============================================================
    % Representative entries
    % ============================================================
    function rep_entries = local_pick_representative_entries(entry_selection_table, cfg)
    
        switch lower(char(cfg.stage07.plot.representative_entry_rule))
            case 'lowest_c2_dg'
                T = entry_selection_table(~isnan(entry_selection_table.C2_D_G_min), :);
                [~, ord] = sort(T.C2_D_G_min, 'ascend');
                T = T(ord, :);
                nKeep = min(cfg.stage07.plot.n_representative_entry, height(T));
                rep_entries = T.entry_id(1:nKeep);
    
            otherwise
                u = entry_selection_table.entry_id;
                nKeep = min(cfg.stage07.plot.n_representative_entry, numel(u));
                rep_entries = u(1:nKeep);
        end
    end
