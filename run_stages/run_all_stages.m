function outs = run_all_stages(interactive, run_stage09, run_stage09_plot, run_stage10_flag, final_stage)
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root)
        addpath(proj_root);
        addpath(fullfile(proj_root, 'run_stages'));
    end
    startup();

    if nargin < 1 || isempty(interactive)
        interactive = (nargin == 0);
    end
    final_stage_was_provided = (nargin >= 5) && ~isempty(final_stage);
    if nargin < 2 || isempty(run_stage09)
        run_stage09 = true;
    end
    if nargin < 3 || isempty(run_stage09_plot)
        run_stage09_plot = true;
    end
    if nargin < 5 || isempty(final_stage)
        final_stage = 10;
    end
    if nargin < 4 || isempty(run_stage10_flag)
        run_stage10_flag = (final_stage >= 10);
    end
    if interactive && ~final_stage_was_provided
        final_stage = local_prompt_final_stage(final_stage);
        if nargin < 4 || isempty(run_stage10_flag)
            run_stage10_flag = (final_stage >= 10);
        end
    end

    validateattributes(final_stage, {'numeric'}, {'scalar', 'integer', '>=', 1, '<=', 10}, ...
        mfilename, 'final_stage');

    run_stage09_effective = (final_stage >= 9) && run_stage09;
    run_stage10_effective = (final_stage >= 10) && run_stage10_flag;

    cfg = default_params();
    opts = struct();

    % ------------------------------------------------------------
    % 先统一交互配置所有 stages（真正运行前）
    % ------------------------------------------------------------
    if interactive
        [cfg, opts] = rs_cli_configure('stage00', cfg, true, opts);
        if final_stage >= 1
            [cfg, opts] = rs_cli_configure('stage01', cfg, true, opts);
        end
        if final_stage >= 2
            [cfg, opts] = rs_cli_configure('stage02', cfg, true, opts);
        end
        if final_stage >= 3
            [cfg, opts] = rs_cli_configure('stage03', cfg, true, opts);
        end
        if final_stage >= 4
            [cfg, opts] = rs_cli_configure('stage04', cfg, true, opts);
        end
        if final_stage >= 5
            [cfg, opts] = rs_cli_configure('stage05', cfg, true, opts);
        end
        if final_stage >= 6
            [cfg, opts] = rs_cli_configure('stage06', cfg, true, opts);
        end
        if final_stage >= 7
            [cfg, opts] = rs_cli_configure('stage07', cfg, true, opts);
        end
        if final_stage >= 8
            [cfg, opts] = rs_cli_configure('stage08', cfg, true, opts);
        end
        if run_stage09_effective
            [cfg, opts] = rs_cli_configure('stage09', cfg, true, opts);
        end
        if run_stage10_effective
            [cfg, opts] = rs_cli_configure('stage10', cfg, true, opts);
        end
    end

    fprintf('[run_stages] ========== 全流程 Stage00 -> Stage%02d ==========\n', final_stage);

    outs = struct();
    outs.stage00 = run_stage00_bootstrap(cfg, false, opts);
    if final_stage >= 1
        outs.stage01 = run_stage01_scenario_disk(cfg, false, opts);
    end
    if final_stage >= 2
        outs.stage02 = run_stage02_hgv_nominal(cfg, false, opts);
    end
    if final_stage >= 3
        outs.stage03 = run_stage03_visibility_pipeline(cfg, false, opts);
    end
    if final_stage >= 4
        outs.stage04 = run_stage04_window_worstcase(cfg, false, opts);
    end
    if final_stage >= 5
        outs.stage05 = run_stage05_nominal_walker(cfg, false, opts);
    end
    if final_stage >= 6
        outs.stage06 = run_stage06_heading_walker(cfg, false, opts);
    end
    if final_stage >= 7
        outs.stage07 = run_stage07_critical_geometry(cfg, false, opts);
    end
    if final_stage >= 8
        outs.stage08 = run_stage08_window_selection(cfg, false, opts);
    end

    if run_stage09_effective
        outs.stage09_scan = run_stage09_inverse_scan(cfg, false, opts);
        if run_stage09_plot
            outs.stage09_plot = run_stage09_inverse_plot(cfg, false, opts);
        end
    end

    if run_stage10_effective
        outs.stage10 = run_stage10(cfg, false, opts);
    end

    fprintf('[run_stages] ========== 全流程完成 ==========\n');
end

function final_stage = local_prompt_final_stage(default_stage)
    fprintf('[run_stages] 请选择运行到哪个最终 Stage。\n');
    fprintf('[run_stages] 可选范围: 1 到 10，默认值: %d\n', default_stage);

    s = strtrim(input(sprintf('[run_stages] final_stage [default=%d]: ', default_stage), 's'));
    if isempty(s)
        final_stage = default_stage;
        return;
    end

    parsed = str2double(s);
    if ~isfinite(parsed) || parsed ~= floor(parsed) || parsed < 1 || parsed > 10
        error('final_stage must be an integer between 1 and 10.');
    end

    final_stage = parsed;
end
