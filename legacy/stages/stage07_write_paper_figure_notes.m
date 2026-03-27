function out = stage07_write_paper_figure_notes(cfg)
    %STAGE07_WRITE_PAPER_FIGURE_NOTES
    % Stage07.6.3:
    %   Generate paper-ready figure notes for Stage07 simplified paper figures.
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg.project_stage = 'stage07_write_paper_figure_notes';
        cfg = configure_stage_output_paths(cfg);
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
    
        run_tag = char(cfg.stage07.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage07_write_paper_figure_notes_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage07.6.3 started.');
    
        % ------------------------------------------------------------
        % Load Stage07.6.1 paper scope
        % ------------------------------------------------------------
        d76 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_define_paper_plot_scope_%s_*.mat', run_tag));
        assert(~isempty(d76), 'No Stage07.6.1 cache found.');
    
        [~, idx76] = max([d76.datenum]);
        stage0761_file = fullfile(d76(idx76).folder, d76(idx76).name);
        S76 = load(stage0761_file);
        assert(isfield(S76, 'out') && isfield(S76.out, 'paper_scope'), ...
            'Invalid Stage07.6.1 cache.');
        paper_scope = S76.out.paper_scope;
    
        % ------------------------------------------------------------
        % Load Stage07.4 selection
        % ------------------------------------------------------------
        d74 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_select_critical_examples_%s_*.mat', run_tag));
        assert(~isempty(d74), 'No Stage07.4 cache found.');
    
        [~, idx74] = max([d74.datenum]);
        stage07_sel_file = fullfile(d74(idx74).folder, d74(idx74).name);
        S74 = load(stage07_sel_file);
        assert(isfield(S74, 'out') && isfield(S74.out, 'selection_table') && ...
               isfield(S74.out, 'entry_selection_table'), ...
            'Invalid Stage07.4 cache.');
    
        selection_table = S74.out.selection_table;
        entry_selection_table = S74.out.entry_selection_table;
    
        rep_entries = paper_scope.representative_entries(:).';
    
        % ------------------------------------------------------------
        % Compose notes
        % ------------------------------------------------------------
        lines = {};
        lines{end+1} = 'Stage07 Paper Figure Notes';
        lines{end+1} = '==========================';
        lines{end+1} = '';
        lines{end+1} = sprintf('Reference Walker: h=%.1f km, i=%.1f deg, P=%d, T=%d, Ns=%d.', ...
            paper_scope.reference_walker.h_km, ...
            paper_scope.reference_walker.i_deg, ...
            paper_scope.reference_walker.P, ...
            paper_scope.reference_walker.T, ...
            paper_scope.reference_walker.Ns);
        lines{end+1} = sprintf('Representative entries: [%s].', num2str(rep_entries));
        lines{end+1} = '';
    
        lines{end+1} = 'Figure A/B: representative heading-risk curves';
        lines{end+1} = 'These curves show that the nominal heading remains feasible under the selected reference Walker, while specific heading deviations can significantly reduce the worst-window observability eigenvalue and the normalized geometry margin.';
        lines{end+1} = 'The C2 sample corresponds to a high-coverage but low-margin geometry, directly supporting the statement that persistent dual-satellite visibility does not guarantee persistent custody.';
        lines{end+1} = '';
    
        lines{end+1} = 'Figure C/D: global compare of nominal, C1 and C2 samples';
        lines{end+1} = 'The global comparison across all entries shows that C2 samples generally have smaller lambda_worst and lower D_G_min than nominal samples.';
        lines{end+1} = 'The C1 sample should be interpreted as a track-plane-like mechanism sample rather than a universally worst sample.';
        lines{end+1} = '';
    
        lines{end+1} = 'Suggested thesis wording';
        lines{end+1} = 'Under the fixed reference Walker, the nominal heading remains feasible for all selected entries, whereas certain heading deviations lead to substantial degradation of worst-window observability. Although dual-satellite coverage remains high, the normalized geometry margin may still fall below the design threshold, indicating that visibility continuity is not equivalent to custody robustness.';
        lines{end+1} = '';
    
        txt_file = fullfile(cfg.paths.tables, ...
            sprintf('stage07_paper_figure_notes_%s_%s.txt', run_tag, timestamp));
        fid = fopen(txt_file, 'w');
        assert(fid >= 0, 'Failed to open txt file: %s', txt_file);
        cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
        for i = 1:numel(lines)
            fprintf(fid, '%s\n', lines{i});
        end
    
        summary_table = table( ...
            numel(rep_entries), ...
            height(selection_table), ...
            sum(entry_selection_table.is_complete_triplet), ...
            'VariableNames', { ...
                'n_representative_entry', ...
                'n_selected_row', ...
                'n_complete_triplet'});
    
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage07_paper_figure_notes_summary_%s_%s.csv', run_tag, timestamp));
        writetable(summary_table, summary_csv);
    
        out = struct();
        out.summary_table = summary_table;
        out.lines = string(lines(:));
        out.files = struct();
        out.files.log_file = log_file;
        out.files.stage0761_file = stage0761_file;
        out.files.stage07_sel_file = stage07_sel_file;
        out.files.txt_file = txt_file;
        out.files.summary_csv = summary_csv;
    
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage07_write_paper_figure_notes_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'TXT saved to: %s', txt_file);
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage07.6.3 finished.');
    
        fprintf('\n');
        fprintf('========== Stage07.6.3 Summary ==========\n');
        fprintf('Stage07.6.1 scope     : %s\n', stage0761_file);
        fprintf('Stage07.4 selection   : %s\n', stage07_sel_file);
        fprintf('TXT file              : %s\n', txt_file);
        fprintf('Summary CSV           : %s\n', summary_csv);
        fprintf('Cache                 : %s\n', cache_file);
        fprintf('=========================================\n');
    end
