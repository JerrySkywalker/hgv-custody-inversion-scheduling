function out = stage07_plot_paper_subset(cfg)
    %STAGE07_PLOT_PAPER_SUBSET
    % Stage07.6.2:
    %   Generate paper-ready simplified figures for Stage07.
    %
    % Outputs:
    %   - 2 representative D_G curves
    %   - 2 representative lambda curves
    %   - 1 D_G compare bar chart
    %   - 1 lambda compare bar chart
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg.project_stage = 'stage07_plot_paper_subset';
        cfg = configure_stage_output_paths(cfg);
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
        ensure_dir(cfg.paths.figs);
    
        run_tag = char(cfg.stage07.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage07_plot_paper_subset_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage07.6.2 started.');
    
        % ------------------------------------------------------------
        % Load Stage07.6.1 paper scope
        % ------------------------------------------------------------
        d76 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_define_paper_plot_scope_%s_*.mat', run_tag)));
        assert(~isempty(d76), 'No Stage07.6.1 cache found.');
    
        [~, idx76] = max([d76.datenum]);
        stage0761_file = fullfile(d76(idx76).folder, d76(idx76).name);
        S76 = load(stage0761_file);
        assert(isfield(S76, 'out') && isfield(S76.out, 'paper_scope'), ...
            'Invalid Stage07.6.1 cache.');
        paper_scope = S76.out.paper_scope;
    
        % ------------------------------------------------------------
        % Load Stage07.3 risk map
        % ------------------------------------------------------------
        d73 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_scan_heading_risk_map_%s_*.mat', run_tag)));
        assert(~isempty(d73), 'No Stage07.3 cache found.');
    
        [~, idx73] = max([d73.datenum]);
        stage07_risk_file = fullfile(d73(idx73).folder, d73(idx73).name);
        S73 = load(stage07_risk_file);
        assert(isfield(S73, 'out') && isfield(S73.out, 'risk_table'), ...
            'Invalid Stage07.3 cache.');
        risk_table = S73.out.risk_table;
    
        % ------------------------------------------------------------
        % Load Stage07.4 selected examples
        % ------------------------------------------------------------
        d74 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_select_critical_examples_%s_*.mat', run_tag)));
        assert(~isempty(d74), 'No Stage07.4 cache found.');
    
        [~, idx74] = max([d74.datenum]);
        stage07_sel_file = fullfile(d74(idx74).folder, d74(idx74).name);
        S74 = load(stage07_sel_file);
        assert(isfield(S74, 'out') && isfield(S74.out, 'selection_table'), ...
            'Invalid Stage07.4 cache.');
        selection_table = S74.out.selection_table;
    
        rep_entries = paper_scope.representative_entries(:).';
        fig_dir = char(paper_scope.fig_dir);
        table_dir = char(paper_scope.table_dir);
        file_prefix = char(paper_scope.file_prefix);
    
        files = struct();
        tables = struct();
    
        % ------------------------------------------------------------
        % Representative curves: D_G and lambda
        % ------------------------------------------------------------
        for k = 1:numel(rep_entries)
            eid = rep_entries(k);
    
            sub = risk_table(risk_table.entry_id == eid, :);
            sel = selection_table(selection_table.entry_id == eid, :);
            sub = sortrows(sub, 'heading_offset_deg');
    
            % D_G
            [f_png, f_fig, t_csv] = local_plot_single_curve( ...
                sub, sel, 'D_G_min', ...
                paper_scope.title_DG_curve, ...
                paper_scope.xlabel_heading, ...
                paper_scope.ylabel_DG, ...
                fig_dir, table_dir, ...
                sprintf('%s_entry%02d_DG_%s_%s', file_prefix, eid, run_tag, timestamp), ...
                cfg);
            files.(sprintf('entry%02d_DG', eid)) = struct('png', f_png, 'fig', f_fig, 'csv', t_csv);
            tables.(sprintf('entry%02d_DG', eid)) = sub;
    
            % lambda
            [f_png, f_fig, t_csv] = local_plot_single_curve( ...
                sub, sel, 'lambda_worst', ...
                paper_scope.title_lambda_curve, ...
                paper_scope.xlabel_heading, ...
                paper_scope.ylabel_lambda, ...
                fig_dir, table_dir, ...
                sprintf('%s_entry%02d_lambda_%s_%s', file_prefix, eid, run_tag, timestamp), ...
                cfg);
            files.(sprintf('entry%02d_lambda', eid)) = struct('png', f_png, 'fig', f_fig, 'csv', t_csv);
            tables.(sprintf('entry%02d_lambda', eid)) = sub;
        end
    
        % ------------------------------------------------------------
        % Global compare: D_G and lambda
        % ------------------------------------------------------------
        [f_png, f_fig, t_csv, Tplot] = local_plot_global_compare( ...
            selection_table, 'D_G_min', ...
            paper_scope.title_DG_compare, ...
            paper_scope.xlabel_entry, ...
            paper_scope.ylabel_DG, ...
            paper_scope.sample_order, ...
            paper_scope.sample_display, ...
            fig_dir, table_dir, ...
            sprintf('%s_compare_DG_%s_%s', file_prefix, run_tag, timestamp), ...
            cfg);
        files.compare_DG = struct('png', f_png, 'fig', f_fig, 'csv', t_csv);
        tables.compare_DG = Tplot;
    
        [f_png, f_fig, t_csv, Tplot] = local_plot_global_compare( ...
            selection_table, 'lambda_worst', ...
            paper_scope.title_lambda_compare, ...
            paper_scope.xlabel_entry, ...
            paper_scope.ylabel_lambda, ...
            paper_scope.sample_order, ...
            paper_scope.sample_display, ...
            fig_dir, table_dir, ...
            sprintf('%s_compare_lambda_%s_%s', file_prefix, run_tag, timestamp), ...
            cfg);
        files.compare_lambda = struct('png', f_png, 'fig', f_fig, 'csv', t_csv);
        tables.compare_lambda = Tplot;
    
        % ------------------------------------------------------------
        % Summary
        % ------------------------------------------------------------
        summary_table = table( ...
            string(stage0761_file), ...
            string(stage07_risk_file), ...
            string(stage07_sel_file), ...
            numel(rep_entries), ...
            2*numel(rep_entries) + 2, ...
            'VariableNames', { ...
                'stage0761_file', ...
                'stage07_risk_file', ...
                'stage07_sel_file', ...
                'n_representative_entry', ...
                'n_paper_figure'});
    
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage07_paper_plot_summary_%s_%s.csv', run_tag, timestamp));
        writetable(summary_table, summary_csv);
    
        out = struct();
        out.paper_scope = paper_scope;
        out.summary_table = summary_table;
        out.files = files;
        out.tables = tables;
    
        out.meta = struct();
        out.meta.log_file = log_file;
        out.meta.summary_csv = summary_csv;
        out.meta.stage0761_file = stage0761_file;
        out.meta.stage07_risk_file = stage07_risk_file;
        out.meta.stage07_sel_file = stage07_sel_file;
    
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage07_plot_paper_subset_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.meta.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage07.6.2 finished.');
    
        fprintf('\n');
        fprintf('========== Stage07.6.2 Summary ==========\n');
        fprintf('Stage07.6.1 scope     : %s\n', stage0761_file);
        fprintf('Stage07.3 risk        : %s\n', stage07_risk_file);
        fprintf('Stage07.4 selection   : %s\n', stage07_sel_file);
        fprintf('Representative entries: [%s]\n', num2str(rep_entries));
        fprintf('Summary CSV           : %s\n', summary_csv);
        fprintf('Cache                 : %s\n', cache_file);
        fprintf('=========================================\n');
    end
    
    
    % ============================================================
    % local helpers
    % ============================================================
    function [png_file, fig_file, csv_file] = local_plot_single_curve( ...
        sub, sel, metric_name, title_str, xlabel_str, ylabel_str, ...
        fig_dir, table_dir, file_stub, cfg)
    
        fig = figure('Visible', cfg.stage07.plot.visible);
        plot(sub.heading_offset_deg, sub.(metric_name), '-o');
        hold on;
    
        for j = 1:height(sel)
            x = sel.heading_offset_deg(j);
            y = sel.(metric_name)(j);
            plot(x, y, 'o', 'MarkerSize', 9, 'LineWidth', 1.8);
            text(x, y, char(sel.sample_type(j)), ...
                'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
        end
    
        xlabel(xlabel_str, 'Interpreter', 'none');
        ylabel(ylabel_str, 'Interpreter', 'none');
        title(title_str, 'Interpreter', 'none');
        grid on;
        hold off;
    
        png_file = fullfile(fig_dir, [file_stub '.png']);
        fig_file = fullfile(fig_dir, [file_stub '.fig']);
        csv_file = fullfile(table_dir, [file_stub '.csv']);
    
        if cfg.stage07.plot.save_png, saveas(fig, png_file); end
        if cfg.stage07.plot.save_fig, savefig(fig, fig_file); end
        if cfg.stage07.plot.export_plot_tables, writetable(sub, csv_file); end
        close(fig);
    end
    
    
    function [png_file, fig_file, csv_file, Tplot] = local_plot_global_compare( ...
        selection_table, metric_name, title_str, xlabel_str, ylabel_str, ...
        sample_order, sample_display, fig_dir, table_dir, file_stub, cfg)
    
        entries = unique(selection_table.entry_id);
        nEntry = numel(entries);
        M = nan(nEntry, numel(sample_order));
    
        for i = 1:nEntry
            eid = entries(i);
            sub = selection_table(selection_table.entry_id == eid, :);
    
            for j = 1:numel(sample_order)
                ss = sub(sub.sample_type == sample_order(j), :);
                if ~isempty(ss)
                    M(i,j) = ss.(metric_name)(1);
                end
            end
        end
    
        Tplot = array2table(M, 'VariableNames', cellstr(sample_order));
        Tplot = addvars(Tplot, entries, 'Before', 1, 'NewVariableNames', 'entry_id');
    
        fig = figure('Visible', cfg.stage07.plot.visible);
        bar(categorical(entries), M, 'grouped');
        xlabel(xlabel_str, 'Interpreter', 'none');
        ylabel(ylabel_str, 'Interpreter', 'none');
        title(title_str, 'Interpreter', 'none');
        legend(cellstr(sample_display), 'Location', 'best');
        grid on;
    
        png_file = fullfile(fig_dir, [file_stub '.png']);
        fig_file = fullfile(fig_dir, [file_stub '.fig']);
        csv_file = fullfile(table_dir, [file_stub '.csv']);
    
        if cfg.stage07.plot.save_png, saveas(fig, png_file); end
        if cfg.stage07.plot.save_fig, savefig(fig, fig_file); end
        if cfg.stage07.plot.export_plot_tables, writetable(Tplot, csv_file); end
        close(fig);
    end
