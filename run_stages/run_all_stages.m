function outs = run_all_stages(interactive, run_stage09, run_stage09_plot, run_stage10_flag)
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root)
        addpath(proj_root);
        addpath(fullfile(proj_root, 'run_stages'));
    end
    startup();

    if nargin < 1 || isempty(interactive)
        interactive = (nargin == 0);
    end
    if nargin < 2 || isempty(run_stage09)
        run_stage09 = true;
    end
    if nargin < 3 || isempty(run_stage09_plot)
        run_stage09_plot = true;
    end
    if nargin < 4 || isempty(run_stage10_flag)
        run_stage10_flag = false;
    end

    cfg = default_params();
    opts = struct();

    % ------------------------------------------------------------
    % 先统一交互配置所有 stages（真正运行前）
    % ------------------------------------------------------------
    if interactive
        [cfg, opts] = rs_cli_configure('stage00', cfg, true, opts);
        [cfg, opts] = rs_cli_configure('stage01', cfg, true, opts);
        [cfg, opts] = rs_cli_configure('stage02', cfg, true, opts);
        [cfg, opts] = rs_cli_configure('stage03', cfg, true, opts);
        [cfg, opts] = rs_cli_configure('stage04', cfg, true, opts);
        [cfg, opts] = rs_cli_configure('stage05', cfg, true, opts);
        [cfg, opts] = rs_cli_configure('stage06', cfg, true, opts);
        [cfg, opts] = rs_cli_configure('stage07', cfg, true, opts);
        [cfg, opts] = rs_cli_configure('stage08', cfg, true, opts);
        if run_stage09
            [cfg, opts] = rs_cli_configure('stage09', cfg, true, opts);
        end
        if run_stage10_flag
            [cfg, opts] = rs_cli_configure('stage10', cfg, true, opts);
        end
    end

    fprintf('[run_stages] ========== 全流程 Stage00 -> Stage09 ==========\n');

    outs = struct();
    outs.stage00 = run_stage00_bootstrap(cfg, false);
    outs.stage01 = run_stage01_scenario_disk(cfg, false);
    outs.stage02 = run_stage02_hgv_nominal(cfg, false);
    outs.stage03 = run_stage03_visibility_pipeline(cfg, false);
    outs.stage04 = run_stage04_window_worstcase(cfg, false);
    outs.stage05 = run_stage05_nominal_walker(cfg, false);
    outs.stage06 = run_stage06_heading_walker(cfg, false);
    outs.stage07 = run_stage07_critical_geometry(cfg, false);
    outs.stage08 = run_stage08_window_selection(cfg, false);

    if run_stage09
        outs.stage09_scan = run_stage09_inverse_scan(cfg, false, opts);
        if run_stage09_plot
            outs.stage09_plot = run_stage09_inverse_plot(cfg, false);
        end
    end

    if run_stage10_flag
        outs.stage10 = run_stage10(cfg, false, opts);
    end

    fprintf('[run_stages] ========== 全流程完成 ==========\n');
end