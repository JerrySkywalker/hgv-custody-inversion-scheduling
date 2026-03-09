function out = stage06_batch_heading_runs()
    %STAGE06_BATCH_HEADING_RUNS
    % Stage06.6 batch runner.
    %
    % Reads heading families from cfg.stage06.batch and runs:
    %   Stage06.1 -> Stage06.2b -> Stage06.3 -> Stage06.4 -> Stage06.5
    % for each heading-offset set.
    
        startup();
        cfg0 = default_params();
        cfg0 = stage06_prepare_cfg(cfg0);
    
        assert(isfield(cfg0.stage06, 'batch') && cfg0.stage06.batch.enable, ...
            'cfg.stage06.batch.enable must be true.');
    
        run_tags = cfg0.stage06.batch.run_tags;
        heading_sets = cfg0.stage06.batch.heading_offset_sets;
    
        assert(numel(run_tags) == numel(heading_sets), ...
            'run_tags and heading_offset_sets must have the same length.');
    
        ensure_dir(cfg0.paths.logs);
        ensure_dir(cfg0.paths.cache);
        ensure_dir(cfg0.paths.tables);
        ensure_dir(cfg0.paths.figs);
    
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(cfg0.paths.logs, ...
            sprintf('stage06_batch_heading_runs_%s.log', timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open batch log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage06.6 batch started.');
    
        nRun = numel(run_tags);
        runs = cell(nRun,1);
    
        summary_rows = {};
    
        for k = 1:nRun
            cfg = default_params();
    
            cfg.stage06.active_heading_set_name = 'custom';
            cfg.stage06.active_heading_offsets_custom_deg = heading_sets{k};
            cfg.stage06.run_tag = char(run_tags{k});
    
            cfg = stage06_prepare_cfg(cfg);
    
            log_msg(log_fid, 'INFO', ...
                'Run %d/%d | run_tag=%s | heading_offsets=%s', ...
                k, nRun, cfg.stage06.run_tag, mat2str(cfg.stage06.active_heading_offsets_deg));
    
            run_out = struct();
            run_out.run_tag = cfg.stage06.run_tag;
            run_out.heading_offsets_deg = cfg.stage06.active_heading_offsets_deg;
    
            if cfg.stage06.batch.run_scope
                run_out.scope = stage06_define_heading_scope(cfg);
            end
    
            if cfg.stage06.batch.run_family
                run_out.family_demo = stage06_build_heading_family_physical_demo(cfg);
            end
    
            if cfg.stage06.batch.run_search
                run_out.search = stage06_heading_walker_search(cfg);
            end
    
            if cfg.stage06.batch.run_compare
                run_out.compare = stage06_compare_with_stage05(cfg);
            end
    
            if cfg.stage06.batch.run_plot
                run_out.plot = stage06_plot_heading_results(cfg);
            end
    
            runs{k} = run_out;
    
            if isfield(run_out, 'compare')
                cmp = run_out.compare;
                gs = cmp.global_summary;
                as = cmp.auto_summary;
    
                summary_rows(end+1,:) = { ...
                    string(cfg.stage06.run_tag), ...
                    mat2str(cfg.stage06.active_heading_offsets_deg), ...
                    numel(cfg.stage06.active_heading_offsets_deg), ...
                    cfg.stage06.expected_family_size, ...
                    gs.n_stage06_feasible(1), ...
                    as.n_feasible_mismatch, ...
                    as.n_frontier_shift, ...
                    as.feasible_same_ratio, ...
                    as.frontier_same_ratio ...
                    }; %#ok<AGROW>
            else
                summary_rows(end+1,:) = { ...
                    string(cfg.stage06.run_tag), ...
                    mat2str(cfg.stage06.active_heading_offsets_deg), ...
                    numel(cfg.stage06.active_heading_offsets_deg), ...
                    cfg.stage06.expected_family_size, ...
                    NaN, NaN, NaN, NaN, NaN ...
                    }; %#ok<AGROW>
            end
        end
    
        batch_summary = cell2table(summary_rows, 'VariableNames', { ...
            'run_tag', ...
            'heading_offsets_deg', ...
            'n_heading_offsets', ...
            'expected_family_size', ...
            'n_stage06_feasible', ...
            'n_feasible_mismatch', ...
            'n_frontier_shift', ...
            'feasible_same_ratio', ...
            'frontier_same_ratio'});
    
        summary_csv = fullfile(cfg0.paths.tables, ...
            sprintf('stage06_batch_summary_%s.csv', timestamp));
        writetable(batch_summary, summary_csv);
    
        out = struct();
        out.runs = runs;
        out.batch_summary = batch_summary;
        out.log_file = log_file;
        out.summary_csv = summary_csv;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg0.paths.cache, ...
            sprintf('stage06_batch_heading_runs_%s.mat', timestamp));
        save(cache_file, 'out', '-v7.3');
        out.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'Batch summary saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Stage06.6 batch finished.');
    
        fprintf('\n');
        fprintf('========== Stage06.6 Batch Summary ==========\n');
        disp(batch_summary);
        fprintf('Summary CSV : %s\n', summary_csv);
        fprintf('Cache       : %s\n', cache_file);
        fprintf('=============================================\n');
    end