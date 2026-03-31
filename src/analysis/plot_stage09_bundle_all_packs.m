function out = plot_stage09_bundle_all_packs(base, mode_tag, opts)
%PLOT_STAGE09_BUNDLE_ALL_PACKS
% Master dispatcher for Stage09 layered plotting suite.
%
% Inputs:
%   base     : struct with fields
%              - cfg
%              - views
%              - frontiers
%              - cubes
%   mode_tag : exporter tag
%   opts     : struct, optional
%              - enable_closure_heatmaps (default true)
%              - enable_multih_heatmaps  (default true)
%              - enable_stack3d          (default false)
%
% Outputs:
%   out.files.pack_index_csv
%   out.files.master_index_csv
%   out.files.summary_csv
%
% Notes:
%   This function is the Stage09 master bundle entry for the layered suite.

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'bundle_all';
    end
    if nargin < 3 || isempty(opts)
        opts = struct();
    end

    local_validate_base(base);

    cfg = base.cfg;
    run_tag = local_resolve_run_tag(base);
    timestamp = local_nowstamp();

    enable_closure = local_get_opt_logical(opts, 'enable_closure_heatmaps', true);
    enable_multih  = local_get_opt_logical(opts, 'enable_multih_heatmaps', true);
    enable_stack3d = local_get_opt_logical(opts, 'enable_stack3d', false);

    [fig_root, tbl_root] = local_resolve_stage09_roots(cfg);

    pack_tbl_dir = fullfile(tbl_root, 'bundle_pack');
    if ~exist(pack_tbl_dir, 'dir')
        mkdir(pack_tbl_dir);
    end

    fprintf('\n');
    fprintf('================ Stage09 Master Bundle Dispatcher ================\n');
    fprintf('run_tag       : %s\n', run_tag);
    fprintf('mode_tag      : %s\n', mode_tag);
    fprintf('enable_closure: %d\n', enable_closure);
    fprintf('enable_multih : %d\n', enable_multih);
    fprintf('enable_stack3d: %d\n', enable_stack3d);
    fprintf('=================================================================\n\n');

    % ------------------------------------------------------------
    % 1) DG / DA / DT stage05 packs
    % ------------------------------------------------------------
    outDG = plot_stage09_DG_stage05_pack(base, [char(mode_tag) '_DG']);
    outDA = plot_stage09_DA_stage05_pack(base, [char(mode_tag) '_DA']);
    outDT = plot_stage09_DT_stage05_pack(base, [char(mode_tag) '_DT']);

    % ------------------------------------------------------------
    % 2) Joint closure pack
    % ------------------------------------------------------------
    outJoint = plot_stage09_joint_closure_pack(base, [char(mode_tag) '_joint']);

    % ------------------------------------------------------------
    % 3) Closure heatmaps
    % ------------------------------------------------------------
    outClosure = struct();
    closure_skipped = false;
    closure_skip_reason = "";

    if enable_closure
        outClosure = plot_stage09_closure_heatmaps(base, char(mode_tag));
    else
        closure_skipped = true;
        closure_skip_reason = "disabled_by_option";
    end

    % ------------------------------------------------------------
    % 4) Multih heatmaps
    % ------------------------------------------------------------
    outMultih = struct();
    multih_skipped = false;
    multih_skip_reason = "";

    h_count = local_get_h_count(base.cubes);
    if enable_multih && h_count >= 2
        outMultih = plot_stage09_multih_heatmaps(base, char(mode_tag));
    else
        multih_skipped = true;
        if ~enable_multih
            multih_skip_reason = "disabled_by_option";
        else
            multih_skip_reason = "insufficient_h_levels";
        end
    end

    % ------------------------------------------------------------
    % 5) Phase5 stack3d
    % ------------------------------------------------------------
    outStack3D = struct();
    stack3d_skipped = false;
    stack3d_skip_reason = "";

    if enable_stack3d && h_count >= 2
        outStack3D = manual_smoke_stage09_phase5_stack3d_plots(base);
    else
        stack3d_skipped = true;
        if ~enable_stack3d
            stack3d_skip_reason = "disabled_by_option";
        else
            stack3d_skip_reason = "insufficient_h_levels";
        end
    end

    % ------------------------------------------------------------
    % 6) Pack index
    % ------------------------------------------------------------
    pack_index = table( ...
        ["DG_stage05_pack"; "DA_stage05_pack"; "DT_stage05_pack"; "joint_closure_pack"; "closure_heatmaps"; "multih_heatmaps"; "phase5_stack3d"], ...
        [false; false; false; false; closure_skipped; multih_skipped; stack3d_skipped], ...
        [""; ""; ""; ""; closure_skip_reason; multih_skip_reason; stack3d_skip_reason], ...
        [string(outDG.files.figure_index_csv); ...
         string(outDA.files.figure_index_csv); ...
         string(outDT.files.figure_index_csv); ...
         string(outJoint.files.figure_index_csv); ...
         local_struct_figure_index_csv(outClosure); ...
         local_struct_figure_index_csv(outMultih); ...
         local_phase5_pack_csv(outStack3D)], ...
        'VariableNames', {'component','skipped','skip_reason','index_csv'});

    pack_index_csv = fullfile(pack_tbl_dir, ...
        sprintf('stage09_bundle_pack_index_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    writetable(pack_index, pack_index_csv);

    % ------------------------------------------------------------
    % 7) Master figure index
    %    One-row summary pointing to each child figure-index CSV.
    % ------------------------------------------------------------
    master_index = table( ...
        string(run_tag), ...
        string(mode_tag), ...
        string(timestamp), ...
        string(outDG.files.figure_index_csv), ...
        string(outDA.files.figure_index_csv), ...
        string(outDT.files.figure_index_csv), ...
        string(outJoint.files.figure_index_csv), ...
        local_struct_figure_index_csv(outClosure), ...
        local_struct_figure_index_csv(outMultih), ...
        local_phase5_pack_csv(outStack3D), ...
        'VariableNames', { ...
            'run_tag', 'mode_tag', 'timestamp', ...
            'dg_figure_index_csv', ...
            'da_figure_index_csv', ...
            'dt_figure_index_csv', ...
            'joint_figure_index_csv', ...
            'closure_figure_index_csv', ...
            'multih_figure_index_csv', ...
            'phase5_stack3d_index_csv'});

    master_index_csv = fullfile(pack_tbl_dir, ...
        sprintf('stage09_bundle_master_figure_index_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    writetable(master_index, master_index_csv);

    % ------------------------------------------------------------
    % 8) Suite summary
    % ------------------------------------------------------------
    summary_rows = table( ...
        ["bundle_all_packs"; "closure_heatmaps"; "multih_heatmaps"; "phase5_stack3d"], ...
        [false; closure_skipped; multih_skipped; stack3d_skipped], ...
        [""; closure_skip_reason; multih_skip_reason; stack3d_skip_reason], ...
        [string(master_index_csv); ...
         local_struct_figure_index_csv(outClosure); ...
         local_struct_figure_index_csv(outMultih); ...
         local_phase5_pack_csv(outStack3D)], ...
        'VariableNames', {'component','skipped','skip_reason','primary_index_csv'});

    summary_csv = fullfile(pack_tbl_dir, ...
        sprintf('stage09_bundle_suite_summary_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    writetable(summary_rows, summary_csv);

    out = struct();
    out.run_tag = run_tag;
    out.mode_tag = string(mode_tag);
    out.timestamp = string(timestamp);

    out.DG = outDG;
    out.DA = outDA;
    out.DT = outDT;
    out.joint = outJoint;
    out.closure = outClosure;
    out.multih = outMultih;
    out.stack3d = outStack3D;

    out.pack_index = pack_index;
    out.master_index = master_index;
    out.summary = summary_rows;

    out.files = struct();
    out.files.pack_index_csv = pack_index_csv;
    out.files.master_index_csv = master_index_csv;
    out.files.summary_csv = summary_csv;

    fprintf('\n');
    fprintf('================ Stage09 Bundle Pack Summary ================\n');
    fprintf('run_tag             : %s\n', run_tag);
    fprintf('mode_tag            : %s\n', string(mode_tag));
    fprintf('Pack index CSV      : %s\n', pack_index_csv);
    fprintf('Master figure CSV   : %s\n', master_index_csv);
    fprintf('DG figure index     : %s\n', outDG.files.figure_index_csv);
    fprintf('DA figure index     : %s\n', outDA.files.figure_index_csv);
    fprintf('DT figure index     : %s\n', outDT.files.figure_index_csv);
    fprintf('Joint figure index  : %s\n', outJoint.files.figure_index_csv);
    fprintf('Closure index       : %s\n', local_struct_figure_index_csv(outClosure));
    fprintf('Multih index        : %s\n', local_struct_figure_index_csv(outMultih));
    fprintf('Stack3D index       : %s\n', local_phase5_pack_csv(outStack3D));
    fprintf('Suite summary CSV   : %s\n', summary_csv);
    fprintf('=============================================================\n\n');
end


function local_validate_base(base)
    must_fields = {'cfg','views','frontiers','cubes'};
    for k = 1:numel(must_fields)
        f = must_fields{k};
        if ~isstruct(base) || ~isfield(base, f)
            error('plot_stage09_bundle_all_packs:InvalidBase', ...
                'base must contain field: %s', f);
        end
    end
end


function run_tag = local_resolve_run_tag(base)
    run_tag = 'inverse_aligned';
    if isstruct(base) && isfield(base, 'cfg') && isstruct(base.cfg) ...
            && isfield(base.cfg, 'stage09') && isstruct(base.cfg.stage09) ...
            && isfield(base.cfg.stage09, 'run_tag') && ~isempty(base.cfg.stage09.run_tag)
        run_tag = char(string(base.cfg.stage09.run_tag));
    end
end


function [fig_root, tbl_root] = local_resolve_stage09_roots(cfg)
    fig_root = '';
    tbl_root = '';

    if isfield(cfg, 'paths') && isstruct(cfg.paths) ...
            && isfield(cfg.paths, 'outputs') && isstruct(cfg.paths.outputs)

        outputs = cfg.paths.outputs;

        if isfield(outputs, 'stage09_figs') && ~isempty(outputs.stage09_figs)
            fig_root = outputs.stage09_figs;
        end
        if isfield(outputs, 'stage09_tables') && ~isempty(outputs.stage09_tables)
            tbl_root = outputs.stage09_tables;
        end
    end

    if isempty(fig_root) || isempty(tbl_root)
        startup_path = which('startup.m');
        if ~isempty(startup_path)
            project_root = fileparts(startup_path);
        else
            project_root = pwd;
        end

        if isempty(fig_root)
            fig_root = fullfile(project_root, 'outputs', 'stage', 'stage09', 'figs');
        end
        if isempty(tbl_root)
            tbl_root = fullfile(project_root, 'outputs', 'stage', 'stage09', 'tables');
        end
    end
end


function h_count = local_get_h_count(cubes)
    h_count = 0;
    if ~isstruct(cubes) || ~isfield(cubes, 'index_tables') || ~isstruct(cubes.index_tables)
        return;
    end
    if ~isfield(cubes.index_tables, 'h')
        return;
    end

    htab = cubes.index_tables.h;
    if istable(htab)
        h_count = height(htab);
    else
        h_count = numel(htab);
    end
end


function s = local_struct_figure_index_csv(S)
    s = "";
    if isstruct(S) && isfield(S, 'files') && isstruct(S.files) && isfield(S.files, 'figure_index_csv')
        value = S.files.figure_index_csv;
        if isstring(value)
            s = value;
        elseif ischar(value)
            s = string(value);
        end
    end
end


function s = local_phase5_pack_csv(S)
    s = "";
    if isstruct(S) && isfield(S, 'joint') && isstruct(S.joint) ...
            && isfield(S.joint, 'files') && isstruct(S.joint.files) ...
            && isfield(S.joint.files, 'figure_index_csv')
        value = S.joint.files.figure_index_csv;
        if isstring(value)
            s = value;
        elseif ischar(value)
            s = string(value);
        end
    end
end


function value = local_get_opt_logical(opts, field_name, default_value)
    value = default_value;
    if isstruct(opts) && isfield(opts, field_name) && ~isempty(opts.(field_name))
        value = logical(opts.(field_name));
    end
end


