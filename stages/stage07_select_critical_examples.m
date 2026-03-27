function out = stage07_select_critical_examples(cfg)
    %STAGE07_SELECT_CRITICAL_EXAMPLES
    % Stage07.4:
    %   Select nominal / C1 / C2 representative samples from Stage07.3 risk map.
    %
    % Main tasks:
    %   1) load latest Stage07.1 reference Walker
    %   2) load latest Stage07.2 scope
    %   3) load latest Stage07.3 risk map
    %   4) select nominal / C1 / C2 for each entry
    %   5) save selection tables and cache
    %
    % Outputs:
    %   out.selection_table
    %   out.entry_selection_table
    %   out.summary_table
    %   out.files
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg.project_stage = 'stage07_select_critical_examples';
        cfg = configure_stage_output_paths(cfg);
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
    
        run_tag = char(cfg.stage07.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage07_select_critical_examples_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage07.4 started.');
    
        % ============================================================
        % Load Stage07.1 reference Walker
        % ============================================================
        d71 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_select_reference_walker_%s_*.mat', run_tag));
        assert(~isempty(d71), 'No Stage07.1 cache found.');
    
        [~, idx71] = max([d71.datenum]);
        stage07_ref_file = fullfile(d71(idx71).folder, d71(idx71).name);
        S71 = load(stage07_ref_file);
    
        assert(isfield(S71, 'out') && isfield(S71.out, 'reference_walker'), ...
            'Invalid Stage07.1 cache.');
        reference_walker = S71.out.reference_walker;
    
        % ============================================================
        % Load Stage07.2 scope
        % ============================================================
        d72 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_define_critical_scope_refwalker_%s_*.mat', run_tag));
        assert(~isempty(d72), 'No Stage07.2 cache found.');
    
        [~, idx72] = max([d72.datenum]);
        stage07_scope_file = fullfile(d72(idx72).folder, d72(idx72).name);
        S72 = load(stage07_scope_file);
    
        assert(isfield(S72, 'out') && isfield(S72.out, 'spec'), ...
            'Invalid Stage07.2 cache.');
        scope_spec = S72.out.spec;
    
        % ============================================================
        % Load Stage07.3 risk map
        % ============================================================
        d73 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_scan_heading_risk_map_%s_*.mat', run_tag));
        assert(~isempty(d73), 'No Stage07.3 cache found.');
    
        [~, idx73] = max([d73.datenum]);
        stage07_risk_file = fullfile(d73(idx73).folder, d73(idx73).name);
        S73 = load(stage07_risk_file);
    
        assert(isfield(S73, 'out') && isfield(S73.out, 'risk_table'), ...
            'Invalid Stage07.3 cache.');
        risk_table = S73.out.risk_table;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage07.1 reference: %s', stage07_ref_file);
        log_msg(log_fid, 'INFO', 'Loaded Stage07.2 scope    : %s', stage07_scope_file);
        log_msg(log_fid, 'INFO', 'Loaded Stage07.3 risk map : %s', stage07_risk_file);
    
        % ============================================================
        % Per-entry selection
        % ============================================================
        uEntry = unique(risk_table.entry_id);
        nEntry = numel(uEntry);
    
        selection_rows = cell(0,1);
        entry_rows = cell(nEntry,1);
    
        for i = 1:nEntry
            eid = uEntry(i);
            sub = risk_table(risk_table.entry_id == eid, :);
    
            nominal_row = local_select_nominal(sub, cfg);
            c1_row = local_select_C1(sub, cfg);
            c2_row = local_select_C2(sub, c1_row, cfg);
    
            entry_summary = struct();
            entry_summary.entry_id = eid;
            entry_summary.has_nominal = ~isempty(nominal_row);
            entry_summary.has_C1 = ~isempty(c1_row);
            entry_summary.has_C2 = ~isempty(c2_row);
            entry_summary.is_complete_triplet = entry_summary.has_nominal && ...
                                               entry_summary.has_C1 && ...
                                               entry_summary.has_C2;
    
            if entry_summary.has_nominal
                entry_summary.nominal_heading_deg = nominal_row.heading_deg;
                entry_summary.nominal_D_G_min = nominal_row.D_G_min;
            else
                entry_summary.nominal_heading_deg = NaN;
                entry_summary.nominal_D_G_min = NaN;
            end
    
            if entry_summary.has_C1
                entry_summary.C1_heading_deg = c1_row.heading_deg;
                entry_summary.C1_D_G_min = c1_row.D_G_min;
                entry_summary.C1_distance_to_trackplane_deg = c1_row.C1_distance_to_nearest_deg;
            else
                entry_summary.C1_heading_deg = NaN;
                entry_summary.C1_D_G_min = NaN;
                entry_summary.C1_distance_to_trackplane_deg = NaN;
            end
    
            if entry_summary.has_C2
                entry_summary.C2_heading_deg = c2_row.heading_deg;
                entry_summary.C2_D_G_min = c2_row.D_G_min;
                entry_summary.C2_lambda_worst = c2_row.lambda_worst;
            else
                entry_summary.C2_heading_deg = NaN;
                entry_summary.C2_D_G_min = NaN;
                entry_summary.C2_lambda_worst = NaN;
            end
    
            if entry_summary.has_nominal
                selection_rows{end+1,1} = local_tag_row(nominal_row, "nominal"); %#ok<AGROW>
            end
            if entry_summary.has_C1
                selection_rows{end+1,1} = local_tag_row(c1_row, "C1"); %#ok<AGROW>
            end
            if entry_summary.has_C2
                selection_rows{end+1,1} = local_tag_row(c2_row, "C2"); %#ok<AGROW>
            end
    
            entry_rows{i} = entry_summary;
    
            log_msg(log_fid, 'INFO', ...
                'entry=%d | nominal=%d | C1=%d | C2=%d | complete=%d', ...
                eid, ...
                entry_summary.has_nominal, ...
                entry_summary.has_C1, ...
                entry_summary.has_C2, ...
                entry_summary.is_complete_triplet);
        end
    
        selection_table = struct2table(vertcat(selection_rows{:}));
        entry_selection_table = struct2table(vertcat(entry_rows{:}));
    
        % optionally keep only complete triplets
        if cfg.stage07.selection.require_complete_triplet
            keep_entry = entry_selection_table.entry_id(entry_selection_table.is_complete_triplet);
            selection_table = selection_table(ismember(selection_table.entry_id, keep_entry), :);
            entry_selection_table = entry_selection_table(entry_selection_table.is_complete_triplet, :);
        end
    
        % ============================================================
        % Build summary
        % ============================================================
        summary_table = table( ...
            string(scope_spec.family_type), ...
            reference_walker.h_km, ...
            reference_walker.i_deg, ...
            reference_walker.P, ...
            reference_walker.T, ...
            reference_walker.Ns, ...
            height(selection_table), ...
            height(entry_selection_table), ...
            sum(entry_selection_table.is_complete_triplet), ...
            'VariableNames', { ...
                'family_type', ...
                'h_km', ...
                'i_deg', ...
                'P', ...
                'T', ...
                'Ns', ...
                'n_selected_row', ...
                'n_entry', ...
                'n_complete_triplet'});
    
        % ============================================================
        % Save outputs
        % ============================================================
        selection_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage07_selected_examples_%s_%s.csv', run_tag, timestamp));
        entry_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage07_selected_examples_entry_summary_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage07_selected_examples_summary_%s_%s.csv', run_tag, timestamp));
    
        writetable(selection_table, selection_csv);
        writetable(entry_selection_table, entry_csv);
        writetable(summary_table, summary_csv);
    
        out = struct();
        out.cfg = cfg;
        out.reference_walker = reference_walker;
        out.scope_spec = scope_spec;
        out.selection_table = selection_table;
        out.entry_selection_table = entry_selection_table;
        out.summary_table = summary_table;
    
        out.files = struct();
        out.files.log_file = log_file;
        out.files.stage07_ref_file = stage07_ref_file;
        out.files.stage07_scope_file = stage07_scope_file;
        out.files.stage07_risk_file = stage07_risk_file;
        out.files.selection_csv = selection_csv;
        out.files.entry_csv = entry_csv;
        out.files.summary_csv = summary_csv;
    
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage07_select_critical_examples_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'Selection CSV saved to: %s', selection_csv);
        log_msg(log_fid, 'INFO', 'Entry summary CSV saved to: %s', entry_csv);
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage07.4 finished.');
    
        fprintf('\n');
        fprintf('========== Stage07.4 Summary ==========\n');
        fprintf('Stage07.1 ref         : %s\n', stage07_ref_file);
        fprintf('Stage07.2 scope       : %s\n', stage07_scope_file);
        fprintf('Stage07.3 risk        : %s\n', stage07_risk_file);
        fprintf('Selected rows         : %d\n', height(selection_table));
        fprintf('Entry rows            : %d\n', height(entry_selection_table));
        fprintf('Complete triplets     : %d\n', sum(entry_selection_table.is_complete_triplet));
        fprintf('Selection CSV         : %s\n', selection_csv);
        fprintf('Entry summary CSV     : %s\n', entry_csv);
        fprintf('Cache                 : %s\n', cache_file);
        fprintf('=======================================\n');
    end
    
    
    % ============================================================
    % local helpers
    % ============================================================
    function row_out = local_tag_row(row_in, sample_type)
        row_out = table2struct(row_in);
        row_out.sample_type = string(sample_type);
    end
    
    
    function row = local_select_nominal(sub, cfg)
    
        row = [];
        target_offset = cfg.stage07.selection.nominal_heading_offset_deg;
    
        hit = sub(sub.heading_offset_deg == target_offset, :);
        if isempty(hit)
            return;
        end
    
        row = hit(1, :);
    end
    
    
    function row = local_select_C1(sub, cfg)
    
        row = [];
    
        % exclude nominal first
        sub1 = sub(sub.heading_offset_deg ~= cfg.stage07.selection.nominal_heading_offset_deg, :);
        if isempty(sub1), return; end
    
        % keep close-to-trackplane candidates
        keep = abs(sub1.C1_distance_to_nearest_deg) <= cfg.stage07.selection.C1_max_distance_deg;
        sub1 = sub1(keep, :);
        if isempty(sub1), return; end
    
        % primary: nearest to trackplane
        % secondary: smaller D_G_min
        score_dist = abs(sub1.C1_distance_to_nearest_deg);
        score_DG = sub1.D_G_min;
    
        [~, ord] = sortrows([score_dist, score_DG], [1 2]);
        row = sub1(ord(1), :);
    end
    
    
    function row = local_select_C2(sub, c1_row, cfg)
    
        row = [];
    
        sub2 = sub;
    
        % must have high coverage
        keep = sub2.coverage_ratio_2sat >= cfg.stage07.selection.C2_require_high_coverage;
        sub2 = sub2(keep, :);
        if isempty(sub2), return; end
    
        % exclude nominal
        sub2 = sub2(sub2.heading_offset_deg ~= cfg.stage07.selection.nominal_heading_offset_deg, :);
        if isempty(sub2), return; end
    
        % exclude C1 neighborhood if C1 exists
        if ~isempty(c1_row)
            c1_heading = c1_row.heading_deg(1);
            d = abs(wrapTo180(sub2.heading_deg - c1_heading));
            keep = d > cfg.stage07.selection.C2_exclude_C1_neighborhood_deg;
            sub2 = sub2(keep, :);
            if isempty(sub2), return; end
        end
    
        % primary: min D_G_min
        % secondary: min lambda_worst
        % tertiary: min mean angle
        score_DG = sub2.D_G_min;
        score_lambda = sub2.lambda_worst;
        score_angle = sub2.mean_los_intersection_angle_deg;
    
        [~, ord] = sortrows([score_DG, score_lambda, score_angle], [1 2 3]);
        row = sub2(ord(1), :);
    end
