function out = stage06_build_heading_family_demo()
    %STAGE06_BUILD_HEADING_FAMILY_DEMO
    % Stage06.2 standalone demo / self-check.
    %
    % Main tasks:
    %   1) load Stage06.1 scope cache
    %   2) load Stage02 nominal trajbank
    %   3) build heading-extended family
    %   4) save summary csv + cache
    %
    % This stage does not run Walker search yet.
    
        startup();
        cfg = default_params();
        cfg.project_stage = 'stage06_build_heading_family_demo';
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
    
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage06_build_heading_family_demo_%s.log', timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage06.2 demo started.');
    
        % ------------------------------------------------------------
        % Load latest Stage06.1 scope cache
        % ------------------------------------------------------------
        d6 = dir(fullfile(cfg.paths.cache, 'stage06_define_heading_scope_*.mat'));
        assert(~isempty(d6), ...
            'No Stage06.1 cache found. Please run stage06_define_heading_scope first.');
    
        [~, idx6] = max([d6.datenum]);
        stage06_scope_file = fullfile(d6(idx6).folder, d6(idx6).name);
        S6 = load(stage06_scope_file);
    
        assert(isfield(S6, 'out') && isfield(S6.out, 'spec'), ...
            'Invalid Stage06.1 cache: missing out.spec');
    
        spec = S6.out.spec;
        heading_offsets_deg = spec.heading_offsets_deg;
    
        % ------------------------------------------------------------
        % Load latest Stage02 cache
        % ------------------------------------------------------------
        d2 = dir(fullfile(cfg.paths.cache, 'stage02_hgv_nominal_*.mat'));
        assert(~isempty(d2), ...
            'No Stage02 cache found. Please run stage02_hgv_nominal first.');
    
        [~, idx2] = max([d2.datenum]);
        stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);
        S2 = load(stage02_file);
    
        assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
            'Invalid Stage02 cache: missing out.trajbank.nominal');
    
        trajs_nominal = S2.out.trajbank.nominal;
    
        % ------------------------------------------------------------
        % Build heading family
        % ------------------------------------------------------------
        family_out = stage06_build_heading_family( ...
            trajs_nominal, heading_offsets_deg, ...
            'HeadingMode', spec.heading_mode, ...
            'FamilyType', spec.family_type);
    
        n_nominal = numel(trajs_nominal);
        n_heading = numel(heading_offsets_deg);
        n_total = numel(family_out);
        expected_total = n_nominal * n_heading;
    
        assert(n_total == expected_total, ...
            'Family size mismatch: got %d, expected %d', n_total, expected_total);
    
        % ------------------------------------------------------------
        % Build summary table
        % ------------------------------------------------------------
        case_ids = strings(n_total,1);
        source_case_ids = strings(n_total,1);
        entry_ids = nan(n_total,1);
        heading_offsets = nan(n_total,1);
        heading_labels = strings(n_total,1);
        family_names = strings(n_total,1);
        subfamily_names = strings(n_total,1);
    
        for k = 1:n_total
            case_ids(k) = string(family_out(k).case.case_id);
            source_case_ids(k) = string(family_out(k).case.source_case_id);
            entry_ids(k) = family_out(k).case.entry_id;
            heading_offsets(k) = family_out(k).case.heading_offset_deg;
            heading_labels(k) = string(family_out(k).case.heading_label);
            family_names(k) = string(family_out(k).case.family);
            subfamily_names(k) = string(family_out(k).case.subfamily);
        end
    
        case_table = table(case_ids, source_case_ids, entry_ids, ...
            heading_offsets, heading_labels, family_names, subfamily_names);
    
        unique_offsets = unique(heading_offsets(:).', 'stable');
        offset_counts = zeros(numel(unique_offsets),1);
        for i = 1:numel(unique_offsets)
            offset_counts(i) = sum(heading_offsets == unique_offsets(i));
        end
        offset_summary = table(unique_offsets(:), offset_counts, ...
            'VariableNames', {'heading_offset_deg', 'N'});
    
        family_summary = table( ...
            string(spec.family_type), ...
            string(spec.heading_mode), ...
            n_nominal, ...
            n_heading, ...
            n_total, ...
            expected_total, ...
            n_total == expected_total, ...
            'VariableNames', { ...
            'family_type', ...
            'heading_mode', ...
            'nominal_case_count', ...
            'n_heading_offsets', ...
            'family_size', ...
            'expected_family_size', ...
            'size_ok'});
    
        % ------------------------------------------------------------
        % Save csv
        % ------------------------------------------------------------
        case_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_heading_family_cases_%s.csv', timestamp));
        offset_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_heading_family_offsets_%s.csv', timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_heading_family_summary_%s.csv', timestamp));
    
        writetable(case_table, case_csv);
        writetable(offset_summary, offset_csv);
        writetable(family_summary, summary_csv);
    
        % ------------------------------------------------------------
        % Save cache
        % ------------------------------------------------------------
        out = struct();
        out.cfg = cfg;
        out.spec = spec;
        out.family_out = family_out;
        out.case_table = case_table;
        out.offset_summary = offset_summary;
        out.family_summary = family_summary;
        out.files = struct();
        out.files.log_file = log_file;
        out.files.stage06_scope_file = stage06_scope_file;
        out.files.stage02_file = stage02_file;
        out.files.case_csv = case_csv;
        out.files.offset_csv = offset_csv;
        out.files.summary_csv = summary_csv;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage06_build_heading_family_%s.mat', timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        % ------------------------------------------------------------
        % Logging
        % ------------------------------------------------------------
        log_msg(log_fid, 'INFO', 'Loaded Stage06.1 scope: %s', stage06_scope_file);
        log_msg(log_fid, 'INFO', 'Loaded Stage02 cache: %s', stage02_file);
        log_msg(log_fid, 'INFO', 'Heading mode = %s', string(spec.heading_mode));
        log_msg(log_fid, 'INFO', 'Heading offsets = %s', mat2str(heading_offsets_deg));
        log_msg(log_fid, 'INFO', 'Nominal case count = %d', n_nominal);
        log_msg(log_fid, 'INFO', 'Family size = %d', n_total);
        log_msg(log_fid, 'INFO', 'Case CSV saved to: %s', case_csv);
        log_msg(log_fid, 'INFO', 'Offset CSV saved to: %s', offset_csv);
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage06.2 demo finished.');
    
        fprintf('\n');
        fprintf('========== Stage06.2 Summary ==========\n');
        fprintf('Stage06.1 scope   : %s\n', stage06_scope_file);
        fprintf('Stage02 cache     : %s\n', stage02_file);
        fprintf('Heading mode      : %s\n', string(spec.heading_mode));
        fprintf('Heading offsets   : %s\n', mat2str(heading_offsets_deg));
        fprintf('Nominal count     : %d\n', n_nominal);
        fprintf('Family size       : %d\n', n_total);
        fprintf('Case CSV          : %s\n', case_csv);
        fprintf('Offset CSV        : %s\n', offset_csv);
        fprintf('Summary CSV       : %s\n', summary_csv);
        fprintf('Cache file        : %s\n', cache_file);
        fprintf('=======================================\n');
    end