function startup()
%STARTUP Initialize project paths, outputs folders, and graphics defaults.

    t_total = tic;
    root_dir = fileparts(mfilename('fullpath'));

    fprintf('[startup] Project root: %s\n', root_dir);

    % ---------------------------
    % Path initialization
    % ---------------------------
    path_specs = { ...
        struct('label', 'root',                 'path', root_dir,                                   'recursive', false, 'required', true), ...
        struct('label', 'params',               'path', fullfile(root_dir, 'params'),               'recursive', true,  'required', true), ...
        struct('label', 'src',                  'path', fullfile(root_dir, 'src'),                  'recursive', true,  'required', true), ...
        struct('label', 'stages',               'path', fullfile(root_dir, 'stages'),               'recursive', true,  'required', false), ...
        struct('label', 'benchmarks',           'path', fullfile(root_dir, 'benchmarks'),           'recursive', true,  'required', false), ...
        struct('label', 'milestones',           'path', fullfile(root_dir, 'milestones'),           'recursive', true,  'required', true), ...
        struct('label', 'shared_scenarios',     'path', fullfile(root_dir, 'shared_scenarios'),     'recursive', true,  'required', true), ...'recursive', true,  'required', false), ...
        struct('label', 'tests',                'path', fullfile(root_dir, 'tests'),                'recursive', true,  'required', false), ...
        struct('label', 'run_milestones',       'path', fullfile(root_dir, 'run_milestones'),       'recursive', true,  'required', false), ...
        struct('label', 'run_shared_scenarios', 'path', fullfile(root_dir, 'run_shared_scenarios'), 'recursive', true,  'required', false), ...
        struct('label', 'run_stages',           'path', fullfile(root_dir, 'run_stages'),           'recursive', true,  'required', true), ...
        struct('label', 'tools',                'path', fullfile(root_dir, 'tools'),                'recursive', true,  'required', false), ...,         'recursive', true,  'required', false)  ...
    };

    for i = 1:numel(path_specs)
        spec = path_specs{i};
        t_part = tic;
        did_add = add_path_if_exists(spec.path, spec.recursive, spec.required);
        dt = toc(t_part);

        if did_add
            fprintf('[startup] addpath %-18s : %.3f s\n', spec.label, dt);
        else
            fprintf('[startup] skip    %-18s : missing\n', spec.label);
        end
    end

    % ---------------------------
    % Outputs initialization
    % ---------------------------
    t_outputs = tic;

    outputs_root = fullfile(root_dir, 'outputs');
    ensure_dir_safe(outputs_root);

    % Unified outputs roots
    ensure_dir_safe(fullfile(outputs_root, 'stage'));
    ensure_dir_safe(fullfile(outputs_root, 'benchmark'));
    ensure_dir_safe(fullfile(outputs_root, 'logs'));
    ensure_dir_safe(fullfile(outputs_root, 'bundles'));
    ensure_dir_safe(fullfile(outputs_root, 'milestones'));
    ensure_dir_safe(fullfile(outputs_root, 'shared_scenarios'));

    % Stage-specific compatibility / canonical folders
    ensure_dir_safe(fullfile(outputs_root, 'stage', 'stage13'));

    % Canonical paper-export subtree
    ensure_dir_safe(fullfile(outputs_root, 'milestones', 'MA'));
    ensure_dir_safe(fullfile(outputs_root, 'milestones', 'MB'));
    ensure_dir_safe(fullfile(outputs_root, 'milestones', 'MC'));
    ensure_dir_safe(fullfile(outputs_root, 'milestones', 'MD'));
    ensure_dir_safe(fullfile(outputs_root, 'milestones', 'ME'));
    ensure_dir_safe(fullfile(outputs_root, 'shared_scenarios', 'SS1'));
    ensure_dir_safe(fullfile(outputs_root, 'shared_scenarios', 'SS2'));

    % Stage root placeholders
    for k = 0:11
        stage_name = sprintf('stage%02d', k);
        ensure_dir_safe(fullfile(outputs_root, 'stage', stage_name));
        ensure_dir_safe(fullfile(outputs_root, 'stage', stage_name, 'cache'));
        ensure_dir_safe(fullfile(outputs_root, 'stage', stage_name, 'figs'));
        ensure_dir_safe(fullfile(outputs_root, 'stage', stage_name, 'tables'));
        ensure_dir_safe(fullfile(outputs_root, 'logs', stage_name));
    end

    fprintf('[startup] %-22s : %.3f s\n', 'ensure outputs', toc(t_outputs));

    % ---------------------------
    % Global graphics defaults
    % ---------------------------
    t_graphics = tic;
    set(groot, 'defaultTextInterpreter', 'none');
    set(groot, 'defaultLegendInterpreter', 'none');
    set(groot, 'defaultAxesTickLabelInterpreter', 'none');
    fprintf('[startup] %-22s : %.3f s\n', 'graphics defaults', toc(t_graphics));

    fprintf('[startup] %-22s : %.3f s\n', 'total startup', toc(t_total));
    fprintf('[startup] Paths initialized successfully.\n');
end

function did_add = add_path_if_exists(target_dir, recursive, required)
    if nargin < 3
        required = false;
    end

    if exist(target_dir, 'dir') ~= 7
        if required
            warning('startup:MissingRequiredDir', ...
                'Required startup directory is missing: %s', target_dir);
        end
        did_add = false;
        return;
    end

    if recursive
        addpath(genpath(target_dir));
    else
        addpath(target_dir);
    end

    did_add = true;
end

function ensure_dir_safe(target_dir)
    if exist(target_dir, 'dir') ~= 7
        mkdir(target_dir);
    end
end

