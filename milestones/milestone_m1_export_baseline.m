function out = milestone_m1_export_baseline()
    %MILESTONE_M1_EXPORT_BASELINE
    % Export baseline figures/tables/notes for Chapter 4 milestone package.
    %
    % Covered stages:
    %   Stage01  scenario
    %   Stage02  trajectory bank
    %   Stage03  visibility baseline
    %   Stage04  worst-window spectrum and margin
    %
    % Outputs are written to:
    %   deliverables/milestone_m1/figs/
    %   deliverables/milestone_m1/tables/
    %   deliverables/milestone_m1/notes/
    %
    % This script does NOT rerun heavy stages. It only reads latest caches and
    % exports milestone-ready artifacts.
    
        % ------------------------------------------------------------
        % Init
        % ------------------------------------------------------------
        startup();
        cfg = default_params();

        project_root = fileparts(fileparts(mfilename('fullpath')));

        out_dirs = struct();
        out_dirs.root   = fullfile(project_root, 'deliverables', 'milestone_m1');
        out_dirs.figs   = fullfile(out_dirs.root, 'figs');
        out_dirs.tables = fullfile(out_dirs.root, 'tables');
        out_dirs.notes  = fullfile(out_dirs.root, 'notes');

        % Auto-create directories if missing
        local_ensure_dir(out_dirs.root);
        local_ensure_dir(out_dirs.figs);
        local_ensure_dir(out_dirs.tables);
        local_ensure_dir(out_dirs.notes);

        fprintf('[M1] Output root  : %s\n', out_dirs.root);
        fprintf('[M1] Figures dir  : %s\n', out_dirs.figs);
        fprintf('[M1] Tables dir   : %s\n', out_dirs.tables);
        fprintf('[M1] Notes dir    : %s\n', out_dirs.notes);
    
        % ------------------------------------------------------------
        % Load latest caches
        % ------------------------------------------------------------
        stage01 = local_load_latest_cache(cfg.paths.cache, 'stage01_scenario_disk_*.mat');
        stage02 = local_load_latest_cache(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
        stage03 = local_load_latest_cache(cfg.paths.cache, 'stage03_visibility_pipeline_*.mat');
        stage04 = local_load_latest_cache(cfg.paths.cache, 'stage04_window_worstcase_*.mat');
    
        % ------------------------------------------------------------
        % M1.1: scenario + trajectory baseline
        % ------------------------------------------------------------
        local_copy_if_exists(stage01.out.fig_file, fullfile(out_dirs.figs, 'fig_m1_1_scenario.png'));
        local_copy_if_exists(stage02.out.fig_file, fullfile(out_dirs.figs, 'fig_m1_1_traj_2d.png'));
    
        if isfield(stage02.out, 'fig3d_file') && ~isempty(stage02.out.fig3d_file)
            local_copy_if_exists(stage02.out.fig3d_file, fullfile(out_dirs.figs, 'fig_m1_1_traj_3d.png'));
        end
    
        % Case design table from Stage01
        tab_case_design = local_build_case_design_table(stage01.out.casebank);
        writetable(tab_case_design, fullfile(out_dirs.tables, 'tab_m1_1_case_design.csv'));
    
        % Trajectory summary tables from Stage02
        writetable(stage02.out.summary.family_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_1_traj_family_summary.csv'));
        writetable(stage02.out.summary.heading_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_1_traj_heading_summary.csv'));
        writetable(stage02.out.summary.critical_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_1_traj_critical_summary.csv'));
    
        % Parameter summary table
        tab_param = local_build_parameter_table(cfg);
        writetable(tab_param, fullfile(out_dirs.tables, 'tab_m1_1_parameter_summary.csv'));
    
        % ------------------------------------------------------------
        % M1.2: walker visibility baseline
        % ------------------------------------------------------------
        local_copy_if_exists(stage03.out.fig_file, fullfile(out_dirs.figs, 'fig_m1_2_visibility_case.png'));
    
        tab_walker = local_build_walker_baseline_table(stage03.out.walker, cfg);
        writetable(tab_walker, fullfile(out_dirs.tables, 'tab_m1_2_walker_baseline.csv'));
    
        tab_vis = stage03.out.summary.case_table;
        writetable(tab_vis, fullfile(out_dirs.tables, 'tab_m1_2_visibility_case_summary.csv'));
    
        % ------------------------------------------------------------
        % M1.3: worst-window spectrum and margin
        % ------------------------------------------------------------
        local_copy_if_exists(stage04.out.fig_file, fullfile(out_dirs.figs, 'fig_m1_3_window_case.png'));
    
        if isfield(stage04.out, 'fig_family_file') && ~isempty(stage04.out.fig_family_file)
            local_copy_if_exists(stage04.out.fig_family_file, ...
                fullfile(out_dirs.figs, 'fig_m1_3_window_family.png'));
        end
    
        if isfield(stage04.out, 'fig_margin_file') && ~isempty(stage04.out.fig_margin_file)
            local_copy_if_exists(stage04.out.fig_margin_file, ...
                fullfile(out_dirs.figs, 'fig_m1_3_margin.png'));
        end
    
        % spectrum summaries
        writetable(stage04.out.summary_spectrum.family_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_3_family_summary.csv'));
        writetable(stage04.out.summary_spectrum.heading_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_3_heading_summary.csv'));
        writetable(stage04.out.summary_spectrum.critical_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_3_critical_summary.csv'));
    
        % margin summaries
        writetable(stage04.out.summary_margin.family_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_3_margin_family.csv'));
        writetable(stage04.out.summary_margin.heading_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_3_margin_heading.csv'));
        writetable(stage04.out.summary_margin.critical_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_3_margin_critical.csv'));
    
        % ------------------------------------------------------------
        % M1.4: notes export
        % ------------------------------------------------------------
        notes_file = fullfile(out_dirs.notes, 'notes_m1_baseline_summary.md');
        local_write_notes_m1(notes_file, cfg, stage02.out, stage03.out, stage04.out);
    
        % ------------------------------------------------------------
        % Output summary struct
        % ------------------------------------------------------------
        out = struct();
        out.out_dirs = out_dirs;
        out.stage01_cache = stage01.file;
        out.stage02_cache = stage02.file;
        out.stage03_cache = stage03.file;
        out.stage04_cache = stage04.file;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        fprintf('\n');
        fprintf('========== Milestone M1 Export ==========\n');
        fprintf('Output root : %s\n', out_dirs.root);
        fprintf('Figures dir : %s\n', out_dirs.figs);
        fprintf('Tables dir  : %s\n', out_dirs.tables);
        fprintf('Notes dir   : %s\n', out_dirs.notes);
        fprintf('=========================================\n');
    end
    
    % ========================================================================
    % Helpers
    % ========================================================================
    
    function S = local_load_latest_cache(cache_dir, pattern)
        d = dir(fullfile(cache_dir, pattern));
        assert(~isempty(d), 'No cache found for pattern: %s', pattern);
        [~, idx_latest] = max([d.datenum]);
        file = fullfile(d(idx_latest).folder, d(idx_latest).name);
        tmp = load(file);
        S = struct();
        S.file = file;
        S.out = tmp.out;
    end
    
    function local_copy_if_exists(src, dst)
        if isempty(src)
            warning('Source file is empty. Skip copy.');
            return;
        end
        if exist(src, 'file') ~= 2
            warning('Source file does not exist: %s', src);
            return;
        end
        copyfile(src, dst);
    end
    
    function T = local_build_case_design_table(casebank)
        all_cases = [casebank.nominal; casebank.heading; casebank.critical];
    
        n = numel(all_cases);
        case_id = strings(n,1);
        family = strings(n,1);
        subfamily = strings(n,1);
        entry_theta_deg = nan(n,1);
        heading_deg = nan(n,1);
        heading_offset_deg = nan(n,1);
        x_entry_km = nan(n,1);
        y_entry_km = nan(n,1);
    
        for k = 1:n
            c = all_cases(k);
            case_id(k) = string(c.case_id);
            family(k) = string(c.family);
            subfamily(k) = string(c.subfamily);
    
            if isfield(c, 'entry_theta_deg');    entry_theta_deg(k) = c.entry_theta_deg; end
            if isfield(c, 'heading_deg');        heading_deg(k) = c.heading_deg; end
            if isfield(c, 'heading_offset_deg'); heading_offset_deg(k) = c.heading_offset_deg; end
            if isfield(c, 'entry_point_xy_km')
                x_entry_km(k) = c.entry_point_xy_km(1);
                y_entry_km(k) = c.entry_point_xy_km(2);
            end
        end
    
        T = table(case_id, family, subfamily, entry_theta_deg, ...
                  heading_deg, heading_offset_deg, x_entry_km, y_entry_km);
    end
    
    function T = local_build_parameter_table(cfg)
        section = strings(0,1);
        name = strings(0,1);
        value = strings(0,1);
        note = strings(0,1);
    
        % Stage01
        section(end+1,1) = "stage01";
        name(end+1,1) = "R_D_km";
        value(end+1,1) = string(cfg.stage01.R_D_km);
        note(end+1,1) = "protected disk radius";
    
        section(end+1,1) = "stage01";
        name(end+1,1) = "R_in_km";
        value(end+1,1) = string(cfg.stage01.R_in_km);
        note(end+1,1) = "entry boundary radius";
    
        % Stage02
        section(end+1,1) = "stage02";
        name(end+1,1) = "v0_mps";
        value(end+1,1) = string(cfg.stage02.v0_mps);
        note(end+1,1) = "initial speed";
    
        section(end+1,1) = "stage02";
        name(end+1,1) = "h0_m";
        value(end+1,1) = string(cfg.stage02.h0_m);
        note(end+1,1) = "initial altitude";
    
        section(end+1,1) = "stage02";
        name(end+1,1) = "theta0_deg";
        value(end+1,1) = string(cfg.stage02.theta0_deg);
        note(end+1,1) = "initial flight-path angle";
    
        % Stage03
        section(end+1,1) = "stage03";
        name(end+1,1) = "walker_h_km";
        value(end+1,1) = string(cfg.stage03.h_km);
        note(end+1,1) = "Walker baseline altitude";
    
        section(end+1,1) = "stage03";
        name(end+1,1) = "walker_i_deg";
        value(end+1,1) = string(cfg.stage03.i_deg);
        note(end+1,1) = "Walker baseline inclination";
    
        section(end+1,1) = "stage03";
        name(end+1,1) = "walker_P";
        value(end+1,1) = string(cfg.stage03.P);
        note(end+1,1) = "number of planes";
    
        section(end+1,1) = "stage03";
        name(end+1,1) = "walker_T";
        value(end+1,1) = string(cfg.stage03.T);
        note(end+1,1) = "satellites per plane";
    
        section(end+1,1) = "stage03";
        name(end+1,1) = "walker_F";
        value(end+1,1) = string(cfg.stage03.F);
        note(end+1,1) = "Walker phasing";
    
        % Stage04
        section(end+1,1) = "stage04";
        name(end+1,1) = "Tw_s";
        value(end+1,1) = string(cfg.stage04.Tw_s);
        note(end+1,1) = "window length";
    
        section(end+1,1) = "stage04";
        name(end+1,1) = "window_step_s";
        value(end+1,1) = string(cfg.stage04.window_step_s);
        note(end+1,1) = "window scan step";
    
        section(end+1,1) = "stage04";
        name(end+1,1) = "gamma_req";
        value(end+1,1) = string(cfg.stage04.gamma_req);
        note(end+1,1) = "margin threshold";
    
        T = table(section, name, value, note);
    end
    
    function T = local_build_walker_baseline_table(walker, cfg)
        name = [
            "h_km"
            "i_deg"
            "P"
            "T"
            "F"
            "Ns"
            "max_range_km"
            "enable_offnadir_constraint"
            "max_offnadir_deg"
            "Tw_s"
            "gamma_req"
            ];
        value = [
            string(walker.h_km)
            string(walker.i_deg)
            string(walker.P)
            string(walker.T)
            string(walker.F)
            string(walker.Ns)
            string(cfg.stage03.max_range_km)
            string(cfg.stage03.enable_offnadir_constraint)
            string(cfg.stage03.max_offnadir_deg)
            string(cfg.stage04.Tw_s)
            string(cfg.stage04.gamma_req)
            ];
        note = [
            "Walker altitude"
            "Walker inclination"
            "number of planes"
            "satellites per plane"
            "Walker phasing"
            "total number of satellites"
            "visibility range gate"
            "off-nadir constraint enabled"
            "maximum off-nadir angle"
            "worst-window length"
            "D_G threshold denominator"
            ];
    
        T = table(name, value, note);
    end
    
    function local_write_notes_m1(notes_file, cfg, out2, out3, out4)
        fid = fopen(notes_file, 'w');
        assert(fid > 0, 'Failed to open notes file: %s', notes_file);
        c = onCleanup(@() fclose(fid)); %#ok<NASGU>
    
        fprintf(fid, '# Milestone M1 baseline summary\n\n');
        fprintf(fid, 'Generated: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    
        fprintf(fid, '## Key settings\n\n');
        fprintf(fid, '- Protected disk radius: %.1f km\n', cfg.stage01.R_D_km);
        fprintf(fid, '- Entry boundary radius: %.1f km\n', cfg.stage01.R_in_km);
        fprintf(fid, '- Walker baseline: h=%.1f km, i=%.1f deg, P=%d, T=%d, F=%d\n', ...
            cfg.stage03.h_km, cfg.stage03.i_deg, cfg.stage03.P, cfg.stage03.T, cfg.stage03.F);
        fprintf(fid, '- Worst-window length: %.1f s\n', cfg.stage04.Tw_s);
        fprintf(fid, '- Margin threshold gamma_req: %.3f\n\n', cfg.stage04.gamma_req);
    
        fprintf(fid, '## Stage02 trajectory-level observations\n\n');
        fprintf(fid, '- Nominal, heading, and critical trajectory families were all generated successfully.\n');
        fprintf(fid, '- Stage02 produced scenario plot, 2D trajectory plot, and 3D explanatory trajectory plot.\n\n');
    
        fprintf(fid, '## Stage03 visibility-level observations\n\n');
        fprintf(fid, '- Single-layer Walker baseline was connected to the Stage02 trajectory bank.\n');
        fprintf(fid, '- Visibility and LOS geometry differences already appeared across nominal / heading / critical cases.\n\n');
    
        fprintf(fid, '## Stage04 worst-window observations\n\n');
    
        Tm = out4.summary_margin.family_summary;
        for i = 1:height(Tm)
            fprintf(fid, '- Family %s: D_G_mean = %.6g, pass_ratio = %.6g\n', ...
                char(string(Tm.group_value(i))), Tm.D_G_mean(i), Tm.pass_ratio(i));
        end
        fprintf(fid, '\n');
    
        fprintf(fid, '## Interim conclusions\n\n');
        fprintf(fid, '1. The single-layer Walker baseline is not uniformly feasible across the full scenario set.\n');
        fprintf(fid, '2. Nominal scenarios only partially pass the threshold; heading expansion further reduces pass ratio.\n');
        fprintf(fid, '3. Critical scenarios fail under the current threshold, showing strong worst-window fragility.\n');
        fprintf(fid, '4. Worst-window spectrum is more discriminative than average visibility-type indicators.\n\n');
    
        fprintf(fid, '## Next step\n\n');
        fprintf(fid, '- Proceed to Stage05A: h-i slice scanning for single-layer baseline feasibility mapping.\n');
    end

    function local_ensure_dir(dir_path)
        if exist(dir_path, 'dir') ~= 7
            [ok, msg, msgid] = mkdir(dir_path);
            assert(ok, 'Failed to create directory: %s\n%s (%s)', dir_path, msg, msgid);
        end
    end