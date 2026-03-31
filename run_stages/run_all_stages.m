function outs = run_all_stages(interactive, run_stage09, run_stage09_plot, run_stage10_flag, final_stage, start_stage)
%RUN_ALL_STAGES Run a selectable stage interval in the development pipeline.
%
% Usage:
%   outs = run_all_stages()
%   outs = run_all_stages(false, true, true, true, 14)
%   outs = run_all_stages(false, true, true, true, 14, 4)
%
% Notes:
%   - The 5th argument remains final_stage for backward compatibility.
%   - The optional 6th argument is start_stage.
%   - Stage12 is treated as a bundled composite stage (12A~12E).
%   - Stage14 is treated as a bundled composite stage (A-line + B-line).

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
    start_stage_was_provided = (nargin >= 6) && ~isempty(start_stage);

    if nargin < 2 || isempty(run_stage09)
        run_stage09 = true;
    end
    if nargin < 3 || isempty(run_stage09_plot)
        run_stage09_plot = true;
    end
    if nargin < 5 || isempty(final_stage)
        final_stage = 14;
    end
    if nargin < 6 || isempty(start_stage)
        start_stage = 0;
    end
    if nargin < 4 || isempty(run_stage10_flag)
        run_stage10_flag = local_stage_in_range(10, start_stage, final_stage);
    end

    if interactive && ~start_stage_was_provided
        start_stage = local_prompt_start_stage(start_stage);
    end
    if interactive && ~final_stage_was_provided
        final_stage = local_prompt_final_stage(max(final_stage, start_stage), start_stage);
        if nargin < 4 || isempty(run_stage10_flag)
            run_stage10_flag = local_stage_in_range(10, start_stage, final_stage);
        end
    end

    validateattributes(start_stage, {'numeric'}, {'scalar', 'integer', '>=', 0, '<=', 14}, ...
        mfilename, 'start_stage');
    validateattributes(final_stage, {'numeric'}, {'scalar', 'integer', '>=', 0, '<=', 14}, ...
        mfilename, 'final_stage');
    if start_stage > final_stage
        error('start_stage must be less than or equal to final_stage.');
    end

    run_stage09_effective = local_stage_in_range(9, start_stage, final_stage) && run_stage09;
    run_stage10_effective = local_stage_in_range(10, start_stage, final_stage) && run_stage10_flag;

    cfg = default_params();
    opts = struct();

    % ------------------------------------------------------------
    % 先统一交互配置所有 stages（真正运行前）
    % Phase A: 仅扩展入口覆盖范围到 Stage14。
    % Phase B: 在 rs_cli_configure 中升级为两层菜单。
    % Phase C: 在此处引入“全局真值覆盖”总览。
    % ------------------------------------------------------------
    if interactive
        if local_stage_in_range(0, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage00', cfg, true, opts);
        end
        if local_stage_in_range(1, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage01', cfg, true, opts);
        end
        if local_stage_in_range(2, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage02', cfg, true, opts);
        end
        if local_stage_in_range(3, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage03', cfg, true, opts);
        end
        if local_stage_in_range(4, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage04', cfg, true, opts);
        end
        if local_stage_in_range(5, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage05', cfg, true, opts);
        end
        if local_stage_in_range(6, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage06', cfg, true, opts);
        end
        if local_stage_in_range(7, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage07', cfg, true, opts);
        end
        if local_stage_in_range(8, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage08', cfg, true, opts);
        end
        if run_stage09_effective
            [cfg, opts] = rs_cli_configure('stage09', cfg, true, opts);
        end
        if run_stage10_effective
            [cfg, opts] = rs_cli_configure('stage10', cfg, true, opts);
        end
        if local_stage_in_range(11, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage11', cfg, true, opts);
        end
        if local_stage_in_range(12, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage12', cfg, true, opts);
        end
        if local_stage_in_range(13, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage13', cfg, true, opts);
        end
        if local_stage_in_range(14, start_stage, final_stage)
            [cfg, opts] = rs_cli_configure('stage14', cfg, true, opts);
        end
    end

    fprintf('[run_stages] ========== 全流程 Stage%02d -> Stage%02d ==========\n', start_stage, final_stage);
    fprintf('[run_stages] Stage12 policy : bundled composite (12A~12E)\n');
    fprintf('[run_stages] Stage14 policy : bundled composite (A-line + B-line)\n');

    outs = struct();

    if local_stage_in_range(0, start_stage, final_stage)
        outs.stage00 = run_stage00_bootstrap(cfg, false, opts);
    end
    if local_stage_in_range(1, start_stage, final_stage)
        outs.stage01 = run_stage01_scenario_disk(cfg, false, opts);
    end
    if local_stage_in_range(2, start_stage, final_stage)
        outs.stage02 = run_stage02_hgv_nominal(cfg, false, opts);
    end
    if local_stage_in_range(3, start_stage, final_stage)
        outs.stage03 = run_stage03_visibility_pipeline(cfg, false, opts);
    end
    if local_stage_in_range(4, start_stage, final_stage)
        outs.stage04 = run_stage04_window_worstcase(cfg, false, opts);
    end
    if local_stage_in_range(5, start_stage, final_stage)
        outs.stage05 = run_stage05_nominal_walker(cfg, false, opts);
    end
    if local_stage_in_range(6, start_stage, final_stage)
        outs.stage06 = run_stage06_heading_walker(cfg, false, opts);
    end
    if local_stage_in_range(7, start_stage, final_stage)
        outs.stage07 = run_stage07_critical_geometry(cfg, false, opts);
    end
    if local_stage_in_range(8, start_stage, final_stage)
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

    if local_stage_in_range(11, start_stage, final_stage)
        outs.stage11 = run_stage11(cfg, false, opts);
    end

    if local_stage_in_range(12, start_stage, final_stage)
        outs.stage12 = local_run_stage12_bundle(cfg);
    end

    if local_stage_in_range(13, start_stage, final_stage)
        outs.stage13 = run_stage13(cfg, false, opts);
    end

    if local_stage_in_range(14, start_stage, final_stage)
        outs.stage14 = local_run_stage14_bundle(cfg, opts);
    end

    fprintf('[run_stages] ========== 全流程完成 ==========\n');
end

function start_stage = local_prompt_start_stage(default_stage)
    fprintf('[run_stages] 请选择起始 Stage。\n');
    fprintf('[run_stages] 可选范围: 0 到 14，默认值: %d\n', default_stage);

    s = strtrim(input(sprintf('[run_stages] start_stage [default=%d]: ', default_stage), 's'));
    if isempty(s)
        start_stage = default_stage;
        return;
    end

    parsed = str2double(s);
    if ~isfinite(parsed) || parsed ~= floor(parsed) || parsed < 0 || parsed > 14
        error('start_stage must be an integer between 0 and 14.');
    end

    start_stage = parsed;
end

function final_stage = local_prompt_final_stage(default_stage, min_stage)
    fprintf('[run_stages] 请选择运行到哪个最终 Stage。\n');
    fprintf('[run_stages] 可选范围: %d 到 14，默认值: %d\n', min_stage, default_stage);

    s = strtrim(input(sprintf('[run_stages] final_stage [default=%d]: ', default_stage), 's'));
    if isempty(s)
        final_stage = default_stage;
        return;
    end

    parsed = str2double(s);
    if ~isfinite(parsed) || parsed ~= floor(parsed) || parsed < min_stage || parsed > 14
        error('final_stage must be an integer between %d and 14.', min_stage);
    end

    final_stage = parsed;
end

function tf = local_stage_in_range(stage_idx, start_stage, final_stage)
    tf = (stage_idx >= start_stage) && (stage_idx <= final_stage);
end

function out = local_run_stage12_bundle(cfg)
    fprintf('[run_stages] === Stage12 bundled composite: 12A~12E ===\n');

    out = struct();
    out.stage12A = run_stage12A_truth_baseline_kernel(cfg, false, struct());
    out.stage12B = run_stage12B_truth_case_window_scan(cfg, false, struct());
    out.stage12C_hi = run_stage12C_inverse_slice_packager(cfg, false, 'hi', struct());
    out.stage12C_pt = run_stage12C_inverse_slice_packager(cfg, false, 'pt', struct());
    out.stage12D_nominal = run_stage12D_task_slice_packager(cfg, false, 'nominal', struct());
    out.stage12D_heading = run_stage12D_task_slice_packager(cfg, false, 'heading', struct());
    out.stage12D_critical = run_stage12D_task_slice_packager(cfg, false, 'critical', struct());

    inputs = { ...
        out.stage12A, ...
        out.stage12B, ...
        out.stage12C_hi, ...
        out.stage12C_pt, ...
        out.stage12D_nominal, ...
        out.stage12D_heading, ...
        out.stage12D_critical};

    out.stage12E = run_stage12E_minimum_design_packager(inputs, cfg, false, struct());

    fprintf('[run_stages] === Stage12 bundled composite complete ===\n');
end

function out = local_run_stage14_bundle(cfg, opts)
    fprintf('[run_stages] === Stage14 bundled composite: A-line + B-line ===\n');

    out = struct();

    out.Aline = run_stage14_openD(cfg, false, local_merge_structs(opts, struct( ...
        'mode', 'mainline_A_full')));

    out.Bline_A1_orientation = run_stage14_openD(cfg, false, local_merge_structs(opts, struct( ...
        'mode', 'joint_phase_orientation_a1')));

    out.Bline_A2_orientation = run_stage14_openD(cfg, false, local_merge_structs(opts, struct( ...
        'mode', 'joint_phase_orientation_a2')));

    out.Bline_A1_ns_passratio = run_stage14_openD(cfg, false, local_merge_structs(opts, struct( ...
        'mode', 'joint_phase_ns_passratio_a1')));

    out.Bline_A2_ns_passratio = run_stage14_openD(cfg, false, local_merge_structs(opts, struct( ...
        'mode', 'joint_phase_ns_passratio_a2')));

    fprintf('[run_stages] === Stage14 bundled composite complete ===\n');
end

function out = local_merge_structs(base, patch)
    out = base;
    if nargin < 1 || isempty(base)
        out = struct();
    end
    if nargin < 2 || isempty(patch)
        return;
    end

    fn = fieldnames(patch);
    for k = 1:numel(fn)
        out.(fn{k}) = patch.(fn{k});
    end
end
