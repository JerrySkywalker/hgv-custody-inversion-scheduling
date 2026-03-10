function out = stage08_scan_smallgrid_search(cfg)
    %STAGE08_SCAN_SMALLGRID_SEARCH
    % Stage08.4:
    %   Run reduced-grid inversion sensitivity analysis over Tw grid.
    %
    % Main tasks:
    %   1) load latest Stage08.1 scope cache
    %   2) load latest Stage02 nominal trajbank
    %   3) rebuild Stage08 casebank
    %   4) evaluate every small-grid Walker config over all casebank cases and Tw grid
    %   5) summarize N_min(Tw), feasible ratio, and best configuration stability
    %
    % Outputs:
    %   out.scope
    %   out.smallgrid_table
    %   out.raw_config_table
    %   out.Tw_summary_table
    %   out.best_config_table
    %   out.figures
    %   out.files
    %
    % Notes:
    %   - This is a reduced-grid sensitivity analysis only
    %   - It does NOT replace Stage05/06 global search
    %   - It uses pass_geom_ratio over the full casebank as feasibility criterion
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg = stage08_prepare_cfg(cfg);
        cfg = local_prepare_stage08_smallgrid_cfg(cfg);
        cfg.project_stage = 'stage08_scan_smallgrid_search';
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
        ensure_dir(cfg.paths.figs);
    
        run_tag = char(cfg.stage08.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage08_scan_smallgrid_search_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage08.4 started.');
    
        % ============================================================
        % Load latest Stage08.1 scope
        % ============================================================
        d81 = dir(fullfile(cfg.paths.cache, ...
            sprintf('stage08_define_window_scope_%s_*.mat', run_tag)));
        assert(~isempty(d81), ...
            'No Stage08.1 scope cache found for run_tag=%s.', run_tag);
    
        [~, idx81] = max([d81.datenum]);
        stage08_scope_file = fullfile(d81(idx81).folder, d81(idx81).name);
        S81 = load(stage08_scope_file);
    
        assert(isfield(S81, 'out') && isfield(S81.out, 'scope'), ...
            'Invalid Stage08.1 cache: missing out.scope');
        scope = S81.out.scope;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage08.1 scope: %s', stage08_scope_file);
    
        % ============================================================
        % Load latest Stage02 nominal bank
        % ============================================================
        d2 = dir(fullfile(cfg.paths.cache, 'stage02_hgv_nominal_*.mat'));
        assert(~isempty(d2), 'No Stage02 nominal cache found.');
    
        [~, idx2] = max([d2.datenum]);
        stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);
        S2 = load(stage02_file);
    
        assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
            'Invalid Stage02 cache: missing out.trajbank.nominal');
        nominal_bank = S2.out.trajbank.nominal;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage02 nominal cache: %s', stage02_file);
        log_msg(log_fid, 'INFO', 'Nominal family size = %d', numel(nominal_bank));
    
        % ============================================================
        % Resolve casebank / Tw / smallgrid
        % ============================================================
        casebank_table = local_build_casebank_master_table(scope);
        assert(~isempty(casebank_table), 'Stage08.1 casebank is empty.');
    
        assert(isfield(scope, 'smallgrid_table') && istable(scope.smallgrid_table) && ...
            ~isempty(scope.smallgrid_table), 'Stage08.1 smallgrid_table is missing or empty.');
        smallgrid_table = scope.smallgrid_table;
    
        Tw_grid_s = scope.Tw_grid_s(:).';
    
        nCase = height(casebank_table);
        nCfg = height(smallgrid_table);
        nTw = numel(Tw_grid_s);
    
        log_msg(log_fid, 'INFO', ...
            'Casebank cases = %d | small-grid configs = %d | Tw count = %d', ...
            nCase, nCfg, nTw);
    
        % ============================================================
        % Prebuild all case items once
        % ============================================================
        case_items = cell(nCase, 1);
        for iCase = 1:nCase
            case_items{iCase} = local_build_casebank_case_item(casebank_table(iCase, :), nominal_bank, cfg);
        end
    
        % ============================================================
        % Main loop: config x Tw x casebank
        % ============================================================
        raw_rows = cell(nCfg * nTw, 1);
        row_ptr = 0;
    
        for iCfg = 1:nCfg
            walker_cfg = smallgrid_table(iCfg, :);
            ref_walker = local_make_ref_from_smallgrid_row(walker_cfg, iCfg, cfg);
            gamma_req = local_resolve_gamma_req(ref_walker, cfg);
    
            cfg_label = local_make_smallgrid_label(ref_walker, iCfg);
    
            log_msg(log_fid, 'INFO', ...
                'Config[%d/%d] %s | h=%.0f i=%.0f P=%d T=%d Ns=%d', ...
                iCfg, nCfg, cfg_label, ...
                ref_walker.h_km, ref_walker.i_deg, ref_walker.P, ref_walker.T, ref_walker.Ns);
    
            for iTw = 1:nTw
                Tw_s = Tw_grid_s(iTw);
    
                cfg_eval = cfg;
                cfg_eval.stage04.Tw_s = Tw_s;
    
                metric = local_evaluate_smallgrid_config_over_casebank( ...
                    case_items, casebank_table, ref_walker, gamma_req, cfg_eval);
    
                row_ptr = row_ptr + 1;
                raw_rows{row_ptr} = local_build_smallgrid_raw_row( ...
                    walker_cfg, ref_walker, iCfg, cfg_label, Tw_s, metric, cfg);
    
                log_msg(log_fid, 'INFO', ...
                    '  -> Tw=%6.1f s | feasible=%d | pass_ratio=%.3f | DG_median=%.3f | DG_min=%.3f', ...
                    Tw_s, metric.is_feasible, metric.pass_geom_ratio, metric.D_G_median, metric.D_G_min);
            end
        end
    
        raw_config_table = struct2table(vertcat(raw_rows{1:row_ptr}));
    
        % ============================================================
        % Summaries
        % ============================================================
        Tw_summary_table = local_build_Tw_summary_table(raw_config_table);
        best_config_table = local_build_best_config_table(raw_config_table);
    
        % ============================================================
        % Plots
        % ============================================================
        figures = struct();
        figures.Nmin_vs_Tw = '';
        figures.feasible_ratio_vs_Tw = '';
        figures.num_feasible_vs_Tw = '';
        figures.best_DG_vs_Tw = '';
    
        if ~isfield(cfg.stage08, 'smallgrid') || ~isfield(cfg.stage08.smallgrid, 'make_plot') || cfg.stage08.smallgrid.make_plot
            fig1 = local_plot_Tw_summary(Tw_summary_table, 'N_min', 'N_{min}');
            figures.Nmin_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_smallgrid_Nmin_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig1, figures.Nmin_vs_Tw, 'Resolution', 180);
            close(fig1);
    
            fig2 = local_plot_Tw_summary(Tw_summary_table, 'feasible_ratio', 'feasible ratio');
            figures.feasible_ratio_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_smallgrid_feasible_ratio_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig2, figures.feasible_ratio_vs_Tw, 'Resolution', 180);
            close(fig2);
    
            fig3 = local_plot_Tw_summary(Tw_summary_table, 'num_feasible', 'num feasible');
            figures.num_feasible_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_smallgrid_num_feasible_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig3, figures.num_feasible_vs_Tw, 'Resolution', 180);
            close(fig3);
    
            fig4 = local_plot_best_config_metric(best_config_table, 'D_G_median', 'best D_G_median');
            figures.best_DG_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_smallgrid_best_DG_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig4, figures.best_DG_vs_Tw, 'Resolution', 180);
            close(fig4);
        end
    
        % ============================================================
        % Save CSV
        % ============================================================
        raw_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_smallgrid_raw_%s_%s.csv', run_tag, timestamp));
        Tw_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_smallgrid_Tw_summary_%s_%s.csv', run_tag, timestamp));
        best_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_smallgrid_best_config_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_smallgrid_summary_%s_%s.csv', run_tag, timestamp));
    
        writetable(raw_config_table, raw_csv);
        writetable(Tw_summary_table, Tw_csv);
        writetable(best_config_table, best_csv);
    
        summary_table = table( ...
            string(stage08_scope_file), ...
            string(stage02_file), ...
            nCase, ...
            nCfg, ...
            nTw, ...
            height(raw_config_table), ...
            height(Tw_summary_table), ...
            height(best_config_table), ...
            'VariableNames', { ...
                'stage08_scope_file', ...
                'stage02_file', ...
                'n_casebank_case', ...
                'n_smallgrid_config', ...
                'n_Tw', ...
                'n_raw_row', ...
                'n_Tw_summary_row', ...
                'n_best_config_row'});
    
        writetable(summary_table, summary_csv);
    
        % ============================================================
        % Save outputs
        % ============================================================
        out = struct();
        out.cfg = cfg;
        out.scope = scope;
        out.casebank_table = casebank_table;
        out.smallgrid_table = smallgrid_table;
        out.raw_config_table = raw_config_table;
        out.Tw_summary_table = Tw_summary_table;
        out.best_config_table = best_config_table;
        out.figures = figures;
        out.summary_table = summary_table;
    
        out.files = struct();
        out.files.log_file = log_file;
        out.files.stage08_scope_file = stage08_scope_file;
        out.files.stage02_file = stage02_file;
        out.files.raw_csv = raw_csv;
        out.files.Tw_csv = Tw_csv;
        out.files.best_csv = best_csv;
        out.files.summary_csv = summary_csv;
    
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage08_scan_smallgrid_search_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'Raw CSV saved to: %s', raw_csv);
        log_msg(log_fid, 'INFO', 'Tw summary CSV saved to: %s', Tw_csv);
        log_msg(log_fid, 'INFO', 'Best config CSV saved to: %s', best_csv);
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage08.4 finished.');
    
        fprintf('\n');
        fprintf('========== Stage08.4 Summary ==========\n');
        fprintf('Stage08.1 scope      : %s\n', stage08_scope_file);
        fprintf('Stage02 nominal      : %s\n', stage02_file);
        fprintf('Casebank cases       : %d\n', nCase);
        fprintf('Small-grid configs   : %d\n', nCfg);
        fprintf('Tw count             : %d\n', nTw);
        fprintf('Raw row count        : %d\n', height(raw_config_table));
        fprintf('Tw summary rows      : %d\n', height(Tw_summary_table));
        fprintf('Best config rows     : %d\n', height(best_config_table));
        fprintf('Raw CSV              : %s\n', raw_csv);
        fprintf('Tw summary CSV       : %s\n', Tw_csv);
        fprintf('Best config CSV      : %s\n', best_csv);
        fprintf('Cache                : %s\n', cache_file);
        fprintf('=======================================\n');
    end
    
    
    % ============================================================
    % local helpers
    % ============================================================
    
    function casebank_table = local_build_casebank_master_table(scope)
    
        casebank_table = table();
    
        assert(isfield(scope, 'casebank') && isstruct(scope.casebank), ...
            'Stage08.1 scope missing casebank.');
    
        tables = {};
        family_names = {};
    
        if isfield(scope.casebank, 'nominal_table') && istable(scope.casebank.nominal_table)
            tables{end+1} = scope.casebank.nominal_table; %#ok<AGROW>
            family_names{end+1} = 'nominal'; %#ok<AGROW>
        end
        if isfield(scope.casebank, 'C1_table') && istable(scope.casebank.C1_table)
            tables{end+1} = scope.casebank.C1_table; %#ok<AGROW>
            family_names{end+1} = 'C1'; %#ok<AGROW>
        end
        if isfield(scope.casebank, 'C2_table') && istable(scope.casebank.C2_table)
            tables{end+1} = scope.casebank.C2_table; %#ok<AGROW>
            family_names{end+1} = 'C2'; %#ok<AGROW>
        end
    
        assert(~isempty(tables), 'No valid family tables found in scope.casebank.');
    
        for i = 1:numel(tables)
            T = tables{i};
            fam = string(family_names{i});
    
            if ~any(strcmp(T.Properties.VariableNames, 'family_name'))
                T.family_name = repmat(fam, height(T), 1);
            else
                T.family_name = string(T.family_name);
            end
    
            if ~any(strcmp(T.Properties.VariableNames, 'sample_type'))
                T.sample_type = repmat(fam, height(T), 1);
            else
                T.sample_type = string(T.sample_type);
            end
    
            if isempty(casebank_table)
                casebank_table = T;
            else
                casebank_table = outerjoin(casebank_table, T, 'MergeKeys', true); %#ok<NASGU>
                casebank_table = [casebank_table; T]; %#ok<AGROW>
            end
        end
    
        if any(strcmp(casebank_table.Properties.VariableNames, 'entry_id')) && ...
                any(strcmp(casebank_table.Properties.VariableNames, 'heading_deg'))
            casebank_table = sortrows(casebank_table, {'sample_type','entry_id','heading_deg'}, ...
                {'ascend','ascend','ascend'});
        end
    end
    
    
    function case_item = local_build_casebank_case_item(case_row, nominal_bank, cfg)
    
        entry_id = local_get_table_value(case_row, 'entry_id', NaN);
        heading_deg = local_get_table_value(case_row, 'heading_deg', NaN);
        sample_type = string(local_get_table_value(case_row, 'sample_type', "unknown"));
        family_name = string(local_get_table_value(case_row, 'family_name', sample_type));
    
        assert(isfinite(entry_id), 'Case row missing entry_id.');
        assert(isfinite(heading_deg), 'Case row missing heading_deg.');
    
        base_item = local_find_nominal_item_by_entry_id(nominal_bank, entry_id);
        assert(~isempty(base_item), 'Failed to find nominal Stage02 item for entry_id=%g.', entry_id);
    
        base_case = base_item.case;
        nominal_heading_deg = local_extract_numeric(base_case, 'heading_deg', NaN);
        assert(isfinite(nominal_heading_deg), 'Base nominal case missing heading_deg.');
    
        case_new = base_case;
        case_new.heading_deg = heading_deg;
        case_new.heading_offset_deg = wrapTo180(heading_deg - nominal_heading_deg);
        case_new.nominal_heading_deg = nominal_heading_deg;
        case_new.entry_id = entry_id;
        case_new.entry_point_id = entry_id;
        case_new.family = 'stage08_casebank';
        case_new.subfamily = char(sample_type);
        case_new.source_case_id = char(string(base_case.case_id));
        case_new.sample_type = char(sample_type);
        case_new.family_name = char(family_name);
        case_new.case_id = sprintf('S08S_E%02d_%s_H%03d', round(entry_id), char(sample_type), round(heading_deg));
    
        traj_new = propagate_hgv_case_stage02(case_new, cfg);
        val_new = validate_hgv_trajectory_stage02(traj_new, cfg);
        sum_new = summarize_hgv_case_stage02(case_new, traj_new, val_new);
    
        case_item = struct();
        case_item.case = case_new;
        case_item.traj = traj_new;
        case_item.validation = val_new;
        case_item.summary = sum_new;
    end
    
    
    function base_item = local_find_nominal_item_by_entry_id(nominal_bank, entry_id)
    
        base_item = [];
    
        for k = 1:numel(nominal_bank)
            item_k = nominal_bank(k);
    
            eid = local_extract_numeric(item_k.case, 'entry_id', NaN);
            if ~isfinite(eid)
                eid = local_parse_entry_id_from_case_id(item_k.case);
            end
    
            if isequaln(eid, entry_id)
                base_item = item_k;
                return;
            end
        end
    end
    
    
    function ref_walker = local_make_ref_from_smallgrid_row(walker_cfg, iCfg, cfg)
    
        ref_walker = struct();
        ref_walker.ref_id = iCfg;
        ref_walker.source_stage = 'stage08_smallgrid';
        ref_walker.selection_rule = 'smallgrid_scan';
    
        ref_walker.h_km = local_get_table_value(walker_cfg, 'h_km', NaN);
        ref_walker.i_deg = local_get_table_value(walker_cfg, 'i_deg', NaN);
        ref_walker.P = local_get_table_value(walker_cfg, 'P', NaN);
        ref_walker.T = local_get_table_value(walker_cfg, 'T', NaN);
        ref_walker.F = local_get_table_value(walker_cfg, 'F', 1);
        ref_walker.Ns = local_get_table_value(walker_cfg, 'Ns', ref_walker.P * ref_walker.T);
    
        if isstruct(cfg) && isfield(cfg, 'stage05') && isfield(cfg.stage05, 'require_D_G_min')
            ref_walker.gamma_req = cfg.stage05.require_D_G_min;
        else
            ref_walker.gamma_req = 1.0;
        end
    end
    
    
    function label = local_make_smallgrid_label(ref_walker, iCfg)
    
        label = sprintf('G%d_h%.0f_i%.0f_P%dT%d', ...
            iCfg, ref_walker.h_km, ref_walker.i_deg, round(ref_walker.P), round(ref_walker.T));
    end
    
    
    function metric = local_evaluate_smallgrid_config_over_casebank(case_items, casebank_table, ref_walker, gamma_req, cfg_eval)
    
        nCase = numel(case_items);
    
        lambda_worst = nan(nCase, 1);
        D_G_min = nan(nCase, 1);
        t0_worst = nan(nCase, 1);
        coverage_ratio = nan(nCase, 1);
        mean_angle = nan(nCase, 1);
        pass_geom = false(nCase, 1);
    
        sample_type = strings(nCase, 1);
    
        for iCase = 1:nCase
            eval_out = evaluate_critical_case_geometry_stage07( ...
                case_items{iCase}, ref_walker, gamma_req, cfg_eval);
    
            diag_row = eval_out.diag_row;
    
            lambda_worst(iCase) = local_get_diag_value(diag_row, 'lambda_worst', NaN);
            D_G_min(iCase) = local_get_diag_value(diag_row, 'D_G_min', NaN);
            t0_worst(iCase) = local_get_diag_value(diag_row, 't0_worst', NaN);
            coverage_ratio(iCase) = local_get_diag_value(diag_row, 'coverage_ratio_2sat', NaN);
            mean_angle(iCase) = local_get_diag_value(diag_row, 'mean_los_intersection_angle_deg', NaN);
    
            pass_geom(iCase) = isfinite(D_G_min(iCase)) && D_G_min(iCase) >= 1;
            sample_type(iCase) = string(local_get_table_value(casebank_table(iCase, :), 'sample_type', "unknown"));
        end
    
        metric = struct();
        metric.N_case = nCase;
    
        metric.lambda_worst_mean = mean(lambda_worst, 'omitnan');
        metric.lambda_worst_median = median(lambda_worst, 'omitnan');
        metric.lambda_worst_min = min(lambda_worst, [], 'omitnan');
    
        metric.D_G_mean = mean(D_G_min, 'omitnan');
        metric.D_G_median = median(D_G_min, 'omitnan');
        metric.D_G_min = min(D_G_min, [], 'omitnan');
    
        metric.t0_worst_mean = mean(t0_worst, 'omitnan');
        metric.coverage_ratio_mean = mean(coverage_ratio, 'omitnan');
        metric.mean_angle_mean = mean(mean_angle, 'omitnan');
    
        metric.pass_geom_ratio = mean(double(pass_geom), 'omitnan');
    
        metric.pass_nominal_ratio = local_family_pass_ratio(pass_geom, sample_type, "nominal");
        metric.pass_C1_ratio = local_family_pass_ratio(pass_geom, sample_type, "C1");
        metric.pass_C2_ratio = local_family_pass_ratio(pass_geom, sample_type, "C2");
    
        % reduced-grid feasibility criterion
        req = local_resolve_smallgrid_requirements(cfg_eval);

        metric.is_feasible = (metric.D_G_min >= req.require_DG_min) && ...
                            (metric.pass_geom_ratio >= req.require_pass_geom_ratio) && ...
                            (metric.pass_C2_ratio >= req.require_C2_pass_ratio);
    
        metric.score = [ ...
            -double(metric.is_feasible), ...
            local_safe_numeric(metric.N_case * 0 + ref_walker.Ns), ...
            -local_safe_numeric(metric.pass_geom_ratio), ...
            -local_safe_numeric(metric.D_G_median), ...
            -local_safe_numeric(metric.D_G_min)];
    end
    
    
    function x = local_family_pass_ratio(pass_geom, sample_type, fam_name)
    
        idx = sample_type == fam_name;
        if ~any(idx)
            x = NaN;
            return;
        end
        x = mean(double(pass_geom(idx)), 'omitnan');
    end
    
    
    function row = local_build_smallgrid_raw_row(walker_cfg, ref_walker, iCfg, cfg_label, Tw_s, metric, ~)
    
        row = struct();
    
        row.cfg_id = iCfg;
        row.cfg_label = string(cfg_label);
    
        row.h_km = local_get_table_value(walker_cfg, 'h_km', ref_walker.h_km);
        row.i_deg = local_get_table_value(walker_cfg, 'i_deg', ref_walker.i_deg);
        row.P = local_get_table_value(walker_cfg, 'P', ref_walker.P);
        row.T = local_get_table_value(walker_cfg, 'T', ref_walker.T);
        row.F = local_get_table_value(walker_cfg, 'F', ref_walker.F);
        row.Ns = local_get_table_value(walker_cfg, 'Ns', ref_walker.Ns);
    
        row.Tw_s = Tw_s;
    
        row.N_case = metric.N_case;
        row.lambda_worst_mean = metric.lambda_worst_mean;
        row.lambda_worst_median = metric.lambda_worst_median;
        row.lambda_worst_min = metric.lambda_worst_min;
    
        row.D_G_mean = metric.D_G_mean;
        row.D_G_median = metric.D_G_median;
        row.D_G_min = metric.D_G_min;
    
        row.t0_worst_mean = metric.t0_worst_mean;
        row.coverage_ratio_mean = metric.coverage_ratio_mean;
        row.mean_angle_mean = metric.mean_angle_mean;
    
        row.pass_geom_ratio = metric.pass_geom_ratio;
        row.pass_nominal_ratio = metric.pass_nominal_ratio;
        row.pass_C1_ratio = metric.pass_C1_ratio;
        row.pass_C2_ratio = metric.pass_C2_ratio;
    
        row.is_feasible = metric.is_feasible;
    end
    
    
    function T = local_build_Tw_summary_table(raw_config_table)
    
        Tw_vals = unique(raw_config_table.Tw_s);
        rows = cell(numel(Tw_vals), 1);
    
        for i = 1:numel(Tw_vals)
            Tw = Tw_vals(i);
            sub = raw_config_table(raw_config_table.Tw_s == Tw, :);
    
            feasible_sub = sub(sub.is_feasible == true, :);
            num_feasible = height(feasible_sub);
    
            r = struct();
            r.Tw_s = Tw;
            r.num_config = height(sub);
            r.num_feasible = num_feasible;
            r.feasible_ratio = num_feasible / max(1, height(sub));
    
            if num_feasible >= 1
                Ns_feasible = feasible_sub.Ns;
                r.N_min = min(Ns_feasible, [], 'omitnan');
    
                best_mask = feasible_sub.Ns == r.N_min;
                best_sub = feasible_sub(best_mask, :);
                [~, idx_best] = max(best_sub.D_G_median);
                best_row = best_sub(idx_best, :);
    
                r.best_cfg_id = best_row.cfg_id;
                r.best_cfg_label = best_row.cfg_label;
                r.best_h_km = best_row.h_km;
                r.best_i_deg = best_row.i_deg;
                r.best_P = best_row.P;
                r.best_T = best_row.T;
                r.best_Ns = best_row.Ns;
    
                r.best_D_G_median = best_row.D_G_median;
                r.best_D_G_min = best_row.D_G_min;
                r.best_pass_geom_ratio = best_row.pass_geom_ratio;
                r.best_pass_C2_ratio = best_row.pass_C2_ratio;
            else
                r.N_min = NaN;
                r.best_cfg_id = NaN;
                r.best_cfg_label = "";
                r.best_h_km = NaN;
                r.best_i_deg = NaN;
                r.best_P = NaN;
                r.best_T = NaN;
                r.best_Ns = NaN;
                r.best_D_G_median = NaN;
                r.best_D_G_min = NaN;
                r.best_pass_geom_ratio = NaN;
                r.best_pass_C2_ratio = NaN;
            end
    
            rows{i} = r;
        end
    
        T = struct2table(vertcat(rows{:}));
        T = sortrows(T, 'Tw_s', 'ascend');
    end
    
    
    function T = local_build_best_config_table(raw_config_table)
    
        Tw_vals = unique(raw_config_table.Tw_s);
        rows = cell(numel(Tw_vals), 1);
    
        for i = 1:numel(Tw_vals)
            Tw = Tw_vals(i);
            sub = raw_config_table(raw_config_table.Tw_s == Tw, :);
    
            feasible_sub = sub(sub.is_feasible == true, :);
    
            if isempty(feasible_sub)
                feasible_sub = sortrows(sub, {'Ns','D_G_median'}, {'ascend','descend'});
                best_row = feasible_sub(1, :);
                feasible_flag = false;
            else
                feasible_sub = sortrows(feasible_sub, {'Ns','D_G_median'}, {'ascend','descend'});
                best_row = feasible_sub(1, :);
                feasible_flag = true;
            end
    
            r = struct();
            r.Tw_s = Tw;
            r.best_is_feasible = feasible_flag;
            r.cfg_id = best_row.cfg_id;
            r.cfg_label = best_row.cfg_label;
            r.h_km = best_row.h_km;
            r.i_deg = best_row.i_deg;
            r.P = best_row.P;
            r.T = best_row.T;
            r.F = best_row.F;
            r.Ns = best_row.Ns;
            r.D_G_median = best_row.D_G_median;
            r.D_G_min = best_row.D_G_min;
            r.pass_geom_ratio = best_row.pass_geom_ratio;
            r.pass_nominal_ratio = best_row.pass_nominal_ratio;
            r.pass_C1_ratio = best_row.pass_C1_ratio;
            r.pass_C2_ratio = best_row.pass_C2_ratio;
    
            rows{i} = r;
        end
    
        T = struct2table(vertcat(rows{:}));
        T = sortrows(T, 'Tw_s', 'ascend');
    end
    
    
    function fig = local_plot_Tw_summary(Tw_summary_table, metric_name, y_label_str)
    
        fig = figure('Color', 'w', 'Position', [120 120 900 520]);
        hold on; grid on; box on;
    
        plot(Tw_summary_table.Tw_s, Tw_summary_table.(metric_name), '-o', ...
            'LineWidth', 1.8, 'MarkerSize', 6);
    
        xlabel('Tw (s)');
        ylabel(y_label_str);
        title(sprintf('Stage08.4 summary: %s', metric_name), 'Interpreter', 'none');
    end
    
    
    function fig = local_plot_best_config_metric(best_config_table, metric_name, y_label_str)
    
        fig = figure('Color', 'w', 'Position', [120 120 900 520]);
        hold on; grid on; box on;
    
        plot(best_config_table.Tw_s, best_config_table.(metric_name), '-o', ...
            'LineWidth', 1.8, 'MarkerSize', 6);
    
        xlabel('Tw (s)');
        ylabel(y_label_str);
        title(sprintf('Stage08.4 best-config curve: %s', metric_name), 'Interpreter', 'none');
    end
    
    
    function gamma_req = local_resolve_gamma_req(ref_walker, cfg)
    
        gamma_req = local_get_struct_value(ref_walker, 'gamma_req', NaN);
        if isfinite(gamma_req)
            return;
        end
    
        if isstruct(cfg) && isfield(cfg, 'stage04') && isstruct(cfg.stage04) && ...
                isfield(cfg.stage04, 'gamma_req') && ~isempty(cfg.stage04.gamma_req)
            gamma_req = cfg.stage04.gamma_req;
            if isfinite(gamma_req)
                return;
            end
        end
    
        if isstruct(cfg) && isfield(cfg, 'stage05') && isstruct(cfg.stage05) && ...
                isfield(cfg.stage05, 'require_D_G_min') && ~isempty(cfg.stage05.require_D_G_min)
            gamma_req = cfg.stage05.require_D_G_min;
            if isfinite(gamma_req)
                return;
            end
        end
    
        gamma_req = 1.0;
    end
    
    
    function value = local_get_table_value(Trow, field_name, default_value)
    
        if nargin < 3
            default_value = NaN;
        end
    
        value = default_value;
    
        if istable(Trow) && height(Trow) >= 1 && any(strcmp(Trow.Properties.VariableNames, field_name))
            tmp = Trow.(field_name)(1);
            if ~isempty(tmp)
                value = tmp;
            end
        end
    end
    
    
    function value = local_get_struct_value(S, field_name, default_value)
    
        if nargin < 3
            default_value = NaN;
        end
    
        value = default_value;
    
        if isstruct(S) && isfield(S, field_name)
            tmp = S.(field_name);
            if ~isempty(tmp)
                value = tmp;
            end
        end
    end
    
    
    function value = local_get_diag_value(diag_row, field_name, default_value)
    
        if nargin < 3
            default_value = NaN;
        end
    
        value = default_value;
    
        if isstruct(diag_row)
            value = local_get_struct_value(diag_row, field_name, default_value);
            return;
        end
    
        if istable(diag_row) && height(diag_row) >= 1 && any(strcmp(diag_row.Properties.VariableNames, field_name))
            tmp = diag_row.(field_name)(1);
            if ~isempty(tmp)
                value = tmp;
            end
        end
    end
    
    
    function x = local_extract_numeric(S, field_name, fallback)
        x = fallback;
        if isstruct(S) && isfield(S, field_name)
            val = S.(field_name);
            if isnumeric(val) && ~isempty(val) && isfinite(val(1))
                x = double(val(1));
            end
        end
    end
    
    
    function entry_id = local_parse_entry_id_from_case_id(base_case)
        entry_id = NaN;
        if isstruct(base_case) && isfield(base_case, 'case_id') && ~isempty(base_case.case_id)
            cid = char(string(base_case.case_id));
            tok = regexp(cid, '^N(\d+)$', 'tokens', 'once');
            if ~isempty(tok)
                entry_id = str2double(tok{1});
            end
        end
    end
    
    
    function x = local_safe_numeric(x)
        if ~isfinite(x)
            x = -inf;
        end
    end

    function cfg = local_prepare_stage08_smallgrid_cfg(cfg)

        if ~isfield(cfg, 'stage08') || ~isstruct(cfg.stage08)
            cfg.stage08 = struct();
        end
    
        if ~isfield(cfg.stage08, 'smallgrid') || ~isstruct(cfg.stage08.smallgrid)
            cfg.stage08.smallgrid = struct();
        end
    
        if ~isfield(cfg.stage08.smallgrid, 'make_plot') || isempty(cfg.stage08.smallgrid.make_plot)
            cfg.stage08.smallgrid.make_plot = true;
        end
    
        if ~isfield(cfg.stage08.smallgrid, 'require_DG_min') || isempty(cfg.stage08.smallgrid.require_DG_min)
            cfg.stage08.smallgrid.require_DG_min = 1.0;
        end
    
        if ~isfield(cfg.stage08.smallgrid, 'require_pass_geom_ratio') || isempty(cfg.stage08.smallgrid.require_pass_geom_ratio)
            cfg.stage08.smallgrid.require_pass_geom_ratio = 0.90;
        end
    
        if ~isfield(cfg.stage08.smallgrid, 'require_C2_pass_ratio') || isempty(cfg.stage08.smallgrid.require_C2_pass_ratio)
            cfg.stage08.smallgrid.require_C2_pass_ratio = 0.50;
        end
    end

    function req = local_resolve_smallgrid_requirements(cfg)

        req = struct();
        req.require_DG_min = 1.0;
        req.require_pass_geom_ratio = 0.90;
        req.require_C2_pass_ratio = 0.50;
    
        if ~isstruct(cfg)
            return;
        end
    
        if ~isfield(cfg, 'stage08') || ~isstruct(cfg.stage08)
            return;
        end
    
        if ~isfield(cfg.stage08, 'smallgrid') || ~isstruct(cfg.stage08.smallgrid)
            return;
        end
    
        sg = cfg.stage08.smallgrid;
    
        if isfield(sg, 'require_DG_min') && ~isempty(sg.require_DG_min) && isfinite(sg.require_DG_min)
            req.require_DG_min = sg.require_DG_min;
        end
    
        if isfield(sg, 'require_pass_geom_ratio') && ~isempty(sg.require_pass_geom_ratio) && isfinite(sg.require_pass_geom_ratio)
            req.require_pass_geom_ratio = sg.require_pass_geom_ratio;
        end
    
        if isfield(sg, 'require_C2_pass_ratio') && ~isempty(sg.require_C2_pass_ratio) && isfinite(sg.require_C2_pass_ratio)
            req.require_C2_pass_ratio = sg.require_C2_pass_ratio;
        end
    end