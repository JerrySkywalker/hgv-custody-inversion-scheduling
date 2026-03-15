function out = stage11_entry(cfg)
%STAGE11_ENTRY Stage11 orchestrator for tightened geometric certificates.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);
    cfg.project_stage = 'stage11_entry';

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage11.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage11_entry_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage11 started.');
    log_msg(log_fid, 'INFO', 'Stage11 mode: cache=%s case=%s window=%s blk=%d', ...
        string(cfg.stage11.cache_mode), string(cfg.stage11.case_mode), ...
        string(cfg.stage11.window_mode), cfg.stage11.enable_blk);

    input_dataset = stage11_build_input_dataset(cfg);
    log_msg(log_fid, 'INFO', 'Cache reuse mode: %s', input_dataset.cache_reuse_mode);
    if isfield(input_dataset, 'cache_files')
        if isfield(input_dataset.cache_files, 'stage10E1') && strlength(string(input_dataset.cache_files.stage10E1)) > 0
            log_msg(log_fid, 'INFO', 'Stage10.E1 cache reused: %s', input_dataset.cache_files.stage10E1);
        end
        if isfield(input_dataset.cache_files, 'stage10E') && strlength(string(input_dataset.cache_files.stage10E)) > 0
            log_msg(log_fid, 'INFO', 'Stage10.E cache reused: %s', input_dataset.cache_files.stage10E);
        end
    end
    log_msg(log_fid, 'INFO', 'Window reuse stats: reused=%d recomputed=%d', ...
        input_dataset.n_windows_reused, input_dataset.n_windows_recomputed);
    if isfield(input_dataset, 'total_window_cap_hit') && input_dataset.total_window_cap_hit
        log_msg(log_fid, 'INFO', 'Window generation stopped early due to max_total_windows=%d.', ...
            cfg.stage11.max_total_windows);
    end

    out = struct();
    out.cfg = cfg;
    out.input_dataset = input_dataset;
    out.window_table = input_dataset.window_table;
    out.case_table = input_dataset.case_table;
    out.files = struct();
    out.files.log_file = log_file;

    if cfg.stage11.enable_weak
        contrib_bank = stage11_extract_contributions(input_dataset, cfg);
        ref_library = stage11_build_reference_library(input_dataset, contrib_bank, cfg);
        weak_table = stage11_build_partition(input_dataset, contrib_bank, ref_library, cfg);

        out.contrib_bank = contrib_bank;
        out.reference_library = ref_library;
        out.weak_table = weak_table;
        out.window_table.contrib_recon_error_fro = [contrib_bank.recon_error_fro].';
        out.window_table.contrib_recon_error_max_abs = [contrib_bank.recon_error_max_abs].';
        out.window_table.W_pi = weak_table.W_pi;
        out.window_table.L_weak = weak_table.L_weak;
        out.window_table.eps_pi = weak_table.eps_pi;
        out.window_table.rho_pi = weak_table.rho_pi;
        out.window_table.eta_pi = weak_table.eta_pi;
        out.window_table.rep_source_used = weak_table.rep_source_used;
        out.window_table.reference_key_coverage = weak_table.reference_key_coverage;
        out.window_table.n_groups_total = weak_table.n_groups_total;
        out.window_table.n_groups_matched = weak_table.n_groups_matched;
        out.window_table.match_ratio = weak_table.match_ratio;
        out.window_table.has_reference_match = weak_table.has_reference_match;
        out.window_table.group_keys = weak_table.group_keys;
        out.window_table.matched_group_keys = weak_table.matched_group_keys;
        out.window_table.missing_group_keys = weak_table.missing_group_keys;
        out.window_table.partition_valid = weak_table.partition_valid;
        out.window_table.lambda_min_Wpi = weak_table.lambda_min_Wpi;
        out.window_table.weak_valid = weak_table.weak_valid;
    end

    if cfg.stage11.enable_sub
        if ~isfield(out, 'weak_table')
            error('Stage11 subspace bound requires weak_table / W_pi.');
        end
        sub_table = stage11_compute_subspace_bound(input_dataset, out.weak_table, cfg);
        out.sub_table = sub_table;
        out.window_table.L_sub = sub_table.L_sub;
        out.window_table.sub_valid = sub_table.sub_valid;
        out.window_table.spectral_gap = sub_table.spectral_gap;
        out.window_table.alpha = sub_table.alpha;
        out.window_table.beta = sub_table.beta;
        out.window_table.eig_gap = sub_table.eig_gap;
        out.window_table.e_scalar = sub_table.e_scalar;
        out.window_table.g_norm = sub_table.g_norm;
        out.window_table.Eperp_norm = sub_table.Eperp_norm;
        out.window_table.mu_bar = sub_table.mu_bar;
        out.window_table.rho_g = sub_table.rho_g;
    end

    if cfg.stage11.enable_blk
        if ~isfield(out, 'contrib_bank')
            error('Stage11 block bound requires contribution bank.');
        end
        blk_table = stage11_compute_block_bound(out.contrib_bank, input_dataset, cfg);
        out.blk_table = blk_table;
        out.window_table.L_partblk = blk_table.L_partblk;
        out.window_table.partblk_valid = blk_table.partblk_valid;
        out.window_table.partblk_mode = blk_table.partblk_mode;
    end

    if isfield(out, 'weak_table') || isfield(out, 'sub_table') || isfield(out, 'blk_table')
        if ~isfield(out, 'sub_table')
            out.sub_table = table(out.window_table.row_id, nan(height(out.window_table), 1), false(height(out.window_table), 1), ...
                'VariableNames', {'row_id', 'L_sub', 'sub_valid'});
        end
        if ~isfield(out, 'blk_table')
            out.blk_table = table(out.window_table.row_id, repmat("heuristic_partition_local", height(out.window_table), 1), ...
                nan(height(out.window_table), 1), false(height(out.window_table), 1), ...
                'VariableNames', {'row_id', 'partblk_mode', 'L_partblk', 'partblk_valid'});
        end
        joint_table = stage11_compute_joint_bound(out.window_table, out.weak_table, out.sub_table, out.blk_table, cfg);
        out.joint_table = joint_table;
        out.window_table.L_new = joint_table.L_new;
        out.window_table.Dg_new_window = joint_table.Dg_new_window;
        out.window_table.best_bound_source = joint_table.best_bound_source;
        out.window_table.new_stage_valid = joint_table.new_valid;
        out.window_table.new_valid = joint_table.new_valid;
        out.window_table.new_failure_reason = joint_table.new_failure_reason;
        out.window_table.new_stage_label = strings(height(out.window_table), 1);
        for i = 1:height(out.window_table)
            if ~out.window_table.new_stage_valid(i)
                out.window_table.new_stage_label(i) = "reject";
            elseif out.window_table.Dg_new_window(i) >= 1
                out.window_table.new_stage_label(i) = "safe_pass";
            else
                out.window_table.new_stage_label(i) = "warn_pass";
            end
        end
        out.case_table = stage11_aggregate_cases(out.case_table, out.window_table, cfg);
    end

    [sanity_table, sanity_flags] = stage11_sanity_checks(out, cfg);
    out.sanity_table = sanity_table;
    out.sanity_flags = sanity_flags;
    local_log_sanity(log_fid, sanity_table, sanity_flags);

    if cfg.stage11.enable_diagnosis
        [diag_summary, diag_failure_table, diag_lines] = stage11_diagnosis_summary(out, cfg);
        out.diagnosis_summary_table = diag_summary;
        out.diagnosis_failure_table = diag_failure_table;
        out.diagnosis_lines = diag_lines;
        local_log_diagnosis(log_fid, diag_lines, cfg);
    end

    summary_table = stage11_summarize_input_dataset(out, cfg);

    out.summary_table = summary_table;

    if cfg.stage11.write_csv
        table_files = stage11_export_tables(out, cfg, timestamp);
        out.files = local_merge_files(out.files, table_files);
    end
    if cfg.stage11.enable_diagnosis && (cfg.stage11.export_window_diagnostics || cfg.stage11.export_case_diagnostics)
        diag_files = stage11_export_diagnostics(out, cfg, timestamp);
        out.files = local_merge_files(out.files, diag_files);
    end

    if cfg.stage11.make_plot
        figure_files = stage11_export_figures(out, cfg, timestamp);
        out.files = local_merge_files(out.files, figure_files);
    end

    if cfg.stage11.write_report
        out.files.report_md = stage11_export_report(out, cfg, timestamp);
    end

    if cfg.stage11.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage11_summary_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    end

    log_msg(log_fid, 'INFO', 'Stage11 finished.');
end


function files = local_merge_files(files, extra_files)
    names = fieldnames(extra_files);
    for i = 1:numel(names)
        files.(names{i}) = extra_files.(names{i});
    end
end


function local_log_sanity(log_fid, sanity_table, sanity_flags)
    if isempty(sanity_table)
        return;
    end

    S = sanity_table(1,:);
    log_msg(log_fid, 'INFO', ['Sanity summary: eta_pi=[%.3g, %.3g, %.3g], ' ...
        'delta_new=[%.3g, %.3g, %.3g], safe_without_all_valid=%d, safe_threshold_violation=%d'], ...
        S.eta_pi_min, S.eta_pi_median, S.eta_pi_max, ...
        S.delta_new_min, S.delta_new_median, S.delta_new_max, ...
        S.safe_case_without_all_valid_count, S.safe_case_threshold_violation_count);

    flag_names = fieldnames(sanity_flags);
    for i = 1:numel(flag_names)
        if sanity_flags.(flag_names{i})
            log_msg(log_fid, 'WARN', 'Sanity flag raised: %s', string(flag_names{i}));
        end
    end
end


function local_log_diagnosis(log_fid, diag_lines, cfg)
    if ~cfg.stage11.diagnosis_verbose || isempty(diag_lines)
        return;
    end

    n_line = min(numel(diag_lines), cfg.stage11.max_diagnostic_rows);
    for i = 1:n_line
        log_msg(log_fid, 'INFO', '%s', diag_lines(i));
    end
end
