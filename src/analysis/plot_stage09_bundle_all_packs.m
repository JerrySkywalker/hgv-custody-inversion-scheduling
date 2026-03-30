function out = plot_stage09_bundle_all_packs(base, mode_tag)
%PLOT_STAGE09_BUNDLE_ALL_PACKS
% Plot-only dispatcher for DG / DA / DT / joint packs using a precomputed
% Phase1-B base struct. This function must not rerun the Stage09 search.

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'phase3_bundle';
    end
    if isstring(mode_tag)
        mode_tag = char(mode_tag);
    end

    if ~isstruct(base) || ~isfield(base, 'views') || ~isfield(base, 'frontiers')
        error('plot_stage09_bundle_all_packs:InvalidBase', ...
            ['Input base must be the Phase1-B output struct and contain at least:' newline ...
             '  views, frontiers, and recoverable cfg (cfg / s5.cfg / s4.cfg / s1.cfg).']);
    end

    cfg = local_pick_cfg(base);
    run_tag = local_get_run_tag(cfg);
    time_tag = datestr(now, 'yyyymmdd_HHMMSS');

    bundle = struct();
    bundle.DG    = plot_stage09_DG_stage05_pack(base, sprintf('%s_DG', mode_tag));
    bundle.DA    = plot_stage09_DA_stage05_pack(base, sprintf('%s_DA', mode_tag));
    bundle.DT    = plot_stage09_DT_stage05_pack(base, sprintf('%s_DT', mode_tag));
    bundle.joint = plot_stage09_joint_closure_pack(base, sprintf('%s_joint', mode_tag));

    rowDG    = local_pack_row('DG_stage05_pack',    bundle.DG);
    rowDA    = local_pack_row('DA_stage05_pack',    bundle.DA);
    rowDT    = local_pack_row('DT_stage05_pack',    bundle.DT);
    rowJoint = local_pack_row('joint_closure_pack', bundle.joint);
    pack_index = [rowDG; rowDA; rowDT; rowJoint];

    figDG    = local_flatten_figure_index('DG_stage05_pack',    bundle.DG);
    figDA    = local_flatten_figure_index('DA_stage05_pack',    bundle.DA);
    figDT    = local_flatten_figure_index('DT_stage05_pack',    bundle.DT);
    figJoint = local_flatten_figure_index('joint_closure_pack', bundle.joint);
    master_index = [figDG; figDA; figDT; figJoint];

    table_dir = fullfile(cfg.paths.tables, 'bundle_pack');
    if ~exist(table_dir, 'dir')
        mkdir(table_dir);
    end

    pack_index_csv = fullfile(table_dir, ...
        sprintf('stage09_bundle_pack_index_%s_%s_%s.csv', run_tag, mode_tag, time_tag));
    master_index_csv = fullfile(table_dir, ...
        sprintf('stage09_bundle_master_figure_index_%s_%s_%s.csv', run_tag, mode_tag, time_tag));

    writetable(pack_index, pack_index_csv);
    writetable(master_index, master_index_csv);

    out = struct();
    out.bundle = bundle;
    out.pack_index = pack_index;
    out.master_index = master_index;
    out.files = struct();
    out.files.pack_index_csv = pack_index_csv;
    out.files.master_index_csv = master_index_csv;

    fprintf('\n');
    fprintf('================ Stage09 Bundle Pack Summary ================\n');
    fprintf('run_tag             : %s\n', run_tag);
    fprintf('mode_tag            : %s\n', mode_tag);
    fprintf('Pack index CSV      : %s\n', pack_index_csv);
    fprintf('Master figure CSV   : %s\n', master_index_csv);
    fprintf('DG figure index     : %s\n', local_get_figure_index_csv(bundle.DG));
    fprintf('DA figure index     : %s\n', local_get_figure_index_csv(bundle.DA));
    fprintf('DT figure index     : %s\n', local_get_figure_index_csv(bundle.DT));
    fprintf('Joint figure index  : %s\n', local_get_figure_index_csv(bundle.joint));
    fprintf('=============================================================\n');
    fprintf('\n');
end

function cfg = local_pick_cfg(base)

    if isfield(base, 'cfg') && isstruct(base.cfg)
        cfg = base.cfg;
        return;
    end

    if isfield(base, 's5') && isstruct(base.s5) && isfield(base.s5, 'cfg') && isstruct(base.s5.cfg)
        cfg = base.s5.cfg;
        return;
    end

    if isfield(base, 's4') && isstruct(base.s4) && isfield(base.s4, 'cfg') && isstruct(base.s4.cfg)
        cfg = base.s4.cfg;
        return;
    end

    if isfield(base, 's1') && isstruct(base.s1) && isfield(base.s1, 'cfg') && isstruct(base.s1.cfg)
        cfg = base.s1.cfg;
        return;
    end

    error('plot_stage09_bundle_all_packs:MissingCfg', ...
        ['Unable to locate cfg from Phase1-B base.' newline ...
         'Checked: cfg, s5.cfg, s4.cfg, s1.cfg']);
end

function run_tag = local_get_run_tag(cfg)
    run_tag = 'stage09';
    try
        if isfield(cfg, 'stage09') && isfield(cfg.stage09, 'run_tag')
            value = cfg.stage09.run_tag;
            if isstring(value)
                run_tag = char(value);
            elseif ischar(value)
                run_tag = value;
            end
        end
    catch
    end
end

function row = local_pack_row(pack_name, pack_out)
    row = table( ...
        string(pack_name), ...
        string(local_get_figure_index_csv(pack_out)), ...
        'VariableNames', {'pack_name', 'figure_index_csv'});
end

function csv_path = local_get_figure_index_csv(pack_out)
    csv_path = "";
    if isstruct(pack_out) && isfield(pack_out, 'files') ...
            && isstruct(pack_out.files) && isfield(pack_out.files, 'figure_index_csv')
        value = pack_out.files.figure_index_csv;
        if isstring(value)
            csv_path = value;
        elseif ischar(value)
            csv_path = string(value);
        end
    end
end

function rows = local_flatten_figure_index(pack_name, pack_out)
    rows = table( ...
        strings(0,1), strings(0,1), strings(0,1), strings(0,1), ...
        'VariableNames', {'pack_name', 'figure_key', 'figure_path', 'source_index_csv'});

    if ~isstruct(pack_out) || ~isfield(pack_out, 'figure_index') || ~istable(pack_out.figure_index)
        return;
    end

    T = pack_out.figure_index;
    source_csv = repmat(local_get_figure_index_csv(pack_out), 0, 1);

    % Case A: DG / DA / DT ninepack output
    if all(ismember({'figure_name', 'figure_path'}, T.Properties.VariableNames))
        n = height(T);
        rows = table( ...
            repmat(string(pack_name), n, 1), ...
            string(T.figure_name), ...
            string(T.figure_path), ...
            repmat(local_get_figure_index_csv(pack_out), n, 1), ...
            'VariableNames', {'pack_name', 'figure_key', 'figure_path', 'source_index_csv'});
        return;
    end

    % Case B: joint closure wide one-row table
    if height(T) == 1
        keys = string(T.Properties.VariableNames(:));
        n = numel(keys);
        values = strings(n, 1);

        for k = 1:n
            value = T{1, k};
            if iscell(value)
                value = value{1};
            end

            if isstring(value)
                values(k) = value(1);
            elseif ischar(value)
                values(k) = string(value);
            else
                values(k) = string(missing);
            end
        end

        rows = table( ...
            repmat(string(pack_name), n, 1), ...
            keys, ...
            values, ...
            repmat(local_get_figure_index_csv(pack_out), n, 1), ...
            'VariableNames', {'pack_name', 'figure_key', 'figure_path', 'source_index_csv'});
        return;
    end

    % Fallback: flatten by row/column
    keys = strings(0,1);
    vals = strings(0,1);
    for r = 1:height(T)
        for c = 1:width(T)
            key = sprintf('%s_r%d', T.Properties.VariableNames{c}, r);
            value = T{r, c};
            if iscell(value)
                value = value{1};
            end

            if isstring(value)
                sval = value(1);
            elseif ischar(value)
                sval = string(value);
            else
                sval = string(missing);
            end

            keys(end+1,1) = string(key); %#ok<AGROW>
            vals(end+1,1) = sval; %#ok<AGROW>
        end
    end

    n = numel(keys);
    rows = table( ...
        repmat(string(pack_name), n, 1), ...
        keys, ...
        vals, ...
        repmat(local_get_figure_index_csv(pack_out), n, 1), ...
        'VariableNames', {'pack_name', 'figure_key', 'figure_path', 'source_index_csv'});
end
