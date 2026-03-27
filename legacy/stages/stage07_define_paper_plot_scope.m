function out = stage07_define_paper_plot_scope(cfg)
    %STAGE07_DEFINE_PAPER_PLOT_SCOPE
    % Stage07.6.1:
    %   Freeze paper-figure plotting scope for Stage07.
    %
    % Main tasks:
    %   1) load Stage07.1 reference Walker
    %   2) load Stage07.4 selected examples
    %   3) define representative entries for paper plots
    %   4) define standardized titles / labels / filenames
    %   5) save scope cache for Stage07.6.2 / Stage07.6.3
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg.project_stage = 'stage07_define_paper_plot_scope';
        cfg = configure_stage_output_paths(cfg);
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
        ensure_dir(cfg.paths.figs);
    
        run_tag = char(cfg.stage07.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage07_define_paper_plot_scope_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage07.6.1 started.');
    
        % ------------------------------------------------------------
        % Load Stage07.1 reference Walker
        % ------------------------------------------------------------
        d71 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_select_reference_walker_%s_*.mat', run_tag));
        assert(~isempty(d71), 'No Stage07.1 cache found.');
    
        [~, idx71] = max([d71.datenum]);
        stage07_ref_file = fullfile(d71(idx71).folder, d71(idx71).name);
        S71 = load(stage07_ref_file);
        assert(isfield(S71, 'out') && isfield(S71.out, 'reference_walker'), ...
            'Invalid Stage07.1 cache.');
        reference_walker = S71.out.reference_walker;
    
        % ------------------------------------------------------------
        % Load Stage07.4 selected examples
        % ------------------------------------------------------------
        d74 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_select_critical_examples_%s_*.mat', run_tag));
        assert(~isempty(d74), 'No Stage07.4 cache found.');
    
        [~, idx74] = max([d74.datenum]);
        stage07_sel_file = fullfile(d74(idx74).folder, d74(idx74).name);
        S74 = load(stage07_sel_file);
        assert(isfield(S74, 'out') && isfield(S74.out, 'entry_selection_table'), ...
            'Invalid Stage07.4 cache.');
        entry_selection_table = S74.out.entry_selection_table;
    
        % ------------------------------------------------------------
        % Representative entries:
        % pick two entries with smallest C2_D_G_min
        % ------------------------------------------------------------
        T = entry_selection_table(~isnan(entry_selection_table.C2_D_G_min), :);
        [~, ord] = sort(T.C2_D_G_min, 'ascend');
        T = T(ord, :);
    
        nRep = min(2, height(T));
        representative_entries = T.entry_id(1:nRep);
    
        % ------------------------------------------------------------
        % Paper plotting spec
        % ------------------------------------------------------------
        paper_scope = struct();
        paper_scope.run_tag = string(run_tag);
        paper_scope.reference_walker = reference_walker;
    
        paper_scope.representative_entries = representative_entries(:).';
        paper_scope.fig_dir = cfg.paths.figs;
        paper_scope.table_dir = cfg.paths.tables;
    
        paper_scope.file_prefix = "stage07_paper";
    
        paper_scope.title_DG_curve = "Representative heading-risk curve of normalized geometry margin";
        paper_scope.title_lambda_curve = "Representative heading-risk curve of worst-window observability eigenvalue";
        paper_scope.title_DG_compare = "Comparison of normalized geometry margin for nominal, track-plane-like and worst-geometry samples";
        paper_scope.title_lambda_compare = "Comparison of worst-window observability eigenvalue for nominal, track-plane-like and worst-geometry samples";
    
        paper_scope.xlabel_heading = "Heading offset (deg)";
        paper_scope.ylabel_DG = "D_G_min";
        paper_scope.ylabel_lambda = "lambda_worst";
        paper_scope.xlabel_entry = "Entry ID";
    
        paper_scope.sample_order = ["nominal", "C1", "C2"];
        paper_scope.sample_display = ["Nominal", "C1", "C2"];
    
        % ------------------------------------------------------------
        % Summary table
        % ------------------------------------------------------------
        summary_table = table( ...
            string(stage07_ref_file), ...
            reference_walker.h_km, ...
            reference_walker.i_deg, ...
            reference_walker.P, ...
            reference_walker.T, ...
            reference_walker.Ns, ...
            numel(representative_entries), ...
            'VariableNames', { ...
                'stage07_ref_file', ...
                'h_km', ...
                'i_deg', ...
                'P', ...
                'T', ...
                'Ns', ...
                'n_representative_entry'});
    
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage07_paper_scope_summary_%s_%s.csv', run_tag, timestamp));
        writetable(summary_table, summary_csv);
    
        out = struct();
        out.cfg = cfg;
        out.paper_scope = paper_scope;
        out.summary_table = summary_table;
    
        out.files = struct();
        out.files.log_file = log_file;
        out.files.stage07_ref_file = stage07_ref_file;
        out.files.stage07_sel_file = stage07_sel_file;
        out.files.summary_csv = summary_csv;
    
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage07_define_paper_plot_scope_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'Representative entries = [%s]', num2str(representative_entries.'));
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage07.6.1 finished.');
    
        fprintf('\n');
        fprintf('========== Stage07.6.1 Summary ==========\n');
        fprintf('Stage07.1 ref         : %s\n', stage07_ref_file);
        fprintf('Representative entries: [%s]\n', num2str(representative_entries.'));
        fprintf('Summary CSV           : %s\n', summary_csv);
        fprintf('Cache                 : %s\n', cache_file);
        fprintf('=========================================\n');
    end
