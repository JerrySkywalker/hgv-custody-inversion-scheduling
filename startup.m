function startup(varargin)
%STARTUP Initialize project paths, outputs folders, and graphics defaults.
%
% 用法：
%   startup()
%       同一 MATLAB 会话内只执行一次路径加载；后续重复调用直接跳过。
%
%   startup('force', true)
%       强制重新执行 startup。
%
% 设计原则：
% 1) 默认追求快，不在每次 startup 时递归扫描目录树是否变化。
% 2) 同一会话内只做一次 addpath；后续直接跳过。
% 3) 若工程目录结构发生变化，手动使用 startup('force', true) 刷新。
% 4) 计时拆分为 core/logger init/logger replay，避免误解 total 的统计口径。

    t_total = tic;

    % ---------------------------
    % Parse inputs
    % ---------------------------
    p = inputParser;
    addParameter(p, 'force', false, @(x)islogical(x) || isnumeric(x));
    parse(p, varargin{:});
    force_reinit = logical(p.Results.force);

    root_dir = fileparts(mfilename('fullpath'));
    session_key = 'PROJECT_STARTUP_DONE_V2';

    % ---------------------------
    % Fast skip for repeated startup in same session
    % ---------------------------
    if ~force_reinit && isappdata(0, session_key)
        dt_core = toc(t_total);

        t_logger_init = tic;
        init_project_logging(root_dir);
        dt_logger_init = toc(t_logger_init);

        t_logger_replay = tic;
        project_log('INFO', '[startup] Repeated startup detected in current MATLAB session. Path reload skipped.');
        project_log('INFO', '[startup] Use startup(''force'', true) to force reload paths.');
        project_log('INFO', '[startup] %-22s : %.3f s', 'core startup', dt_core);
        project_log('INFO', '[startup] %-22s : %.3f s', 'logger init', dt_logger_init);
        dt_logger_replay = toc(t_logger_replay);

        project_log('INFO', '[startup] %-22s : %.3f s', 'logger replay', dt_logger_replay);
        project_log('INFO', '[startup] %-22s : %.3f s', 'total startup', dt_core + dt_logger_init + dt_logger_replay);
        return;
    end

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
        struct('label', 'shared_scenarios',     'path', fullfile(root_dir, 'shared_scenarios'),     'recursive', true,  'required', true), ...
        struct('label', 'tests',                'path', fullfile(root_dir, 'tests'),                'recursive', true,  'required', false), ...
        struct('label', 'run_milestones',       'path', fullfile(root_dir, 'run_milestones'),       'recursive', true,  'required', false), ...
        struct('label', 'run_shared_scenarios', 'path', fullfile(root_dir, 'run_shared_scenarios'), 'recursive', true,  'required', false), ...
        struct('label', 'run_stages',           'path', fullfile(root_dir, 'run_stages'),           'recursive', true,  'required', true), ...
        struct('label', 'tools',                'path', fullfile(root_dir, 'tools'),                'recursive', true,  'required', false) ...
    };

    path_timing_lines = {};
    for i = 1:numel(path_specs)
        spec = path_specs{i};
        t_part = tic;
        add_path_if_needed_fast(spec.path, spec.recursive, spec.required);
        dt = toc(t_part);
        path_timing_lines{end+1} = sprintf('addpath %-22s : %.3f s', spec.label, dt); %#ok<AGROW>
    end

    % ---------------------------
    % Outputs initialization
    % ---------------------------
    t_outputs = tic;

    outputs_root = fullfile(root_dir, 'outputs');
    ensure_dir_safe(outputs_root);

    ensure_dir_safe(fullfile(outputs_root, 'stage'));
    ensure_dir_safe(fullfile(outputs_root, 'benchmark'));
    ensure_dir_safe(fullfile(outputs_root, 'logs'));
    ensure_dir_safe(fullfile(outputs_root, 'logs', 'session'));
    ensure_dir_safe(fullfile(outputs_root, 'bundles'));
    ensure_dir_safe(fullfile(outputs_root, 'milestones'));
    ensure_dir_safe(fullfile(outputs_root, 'shared_scenarios'));

    ensure_dir_safe(fullfile(outputs_root, 'stage', 'stage13'));

    ensure_dir_safe(fullfile(outputs_root, 'milestones', 'MA'));
    ensure_dir_safe(fullfile(outputs_root, 'milestones', 'MB'));
    ensure_dir_safe(fullfile(outputs_root, 'milestones', 'MC'));
    ensure_dir_safe(fullfile(outputs_root, 'milestones', 'MD'));
    ensure_dir_safe(fullfile(outputs_root, 'milestones', 'ME'));
    ensure_dir_safe(fullfile(outputs_root, 'shared_scenarios', 'SS1'));
    ensure_dir_safe(fullfile(outputs_root, 'shared_scenarios', 'SS2'));

    for k = 0:11
        stage_name = sprintf('stage%02d', k);
        ensure_dir_safe(fullfile(outputs_root, 'stage', stage_name));
        ensure_dir_safe(fullfile(outputs_root, 'stage', stage_name, 'cache'));
        ensure_dir_safe(fullfile(outputs_root, 'stage', stage_name, 'figs'));
        ensure_dir_safe(fullfile(outputs_root, 'stage', stage_name, 'tables'));
        ensure_dir_safe(fullfile(outputs_root, 'logs', stage_name));
    end

    dt_outputs = toc(t_outputs);

    % ---------------------------
    % Graphics defaults
    % ---------------------------
    t_graphics = tic;
    set(groot, 'defaultTextInterpreter', 'none');
    set(groot, 'defaultLegendInterpreter', 'none');
    set(groot, 'defaultAxesTickLabelInterpreter', 'none');
    dt_graphics = toc(t_graphics);

    % ---------------------------
    % Mark session initialized
    % ---------------------------
    setappdata(0, session_key, true);

    dt_core = toc(t_total);

    % ---------------------------
    % Initialize logger
    % ---------------------------
    t_logger_init = tic;
    init_project_logging(root_dir);
    dt_logger_init = toc(t_logger_init);

    % ---------------------------
    % Replay startup summary through logger
    % ---------------------------
    t_logger_replay = tic;
    project_log('INFO', '[startup] Project root: %s', root_dir);
    for i = 1:numel(path_timing_lines)
        project_log('INFO', '[startup] %s', path_timing_lines{i});
    end
    if force_reinit
        project_log('INFO', '[startup] Startup executed in force mode.');
    end
    project_log('INFO', '[startup] %-22s : %.3f s', 'ensure outputs', dt_outputs);
    project_log('INFO', '[startup] %-22s : %.3f s', 'graphics defaults', dt_graphics);
    project_log('INFO', '[startup] %-22s : %.3f s', 'core startup', dt_core);
    project_log('INFO', '[startup] %-22s : %.3f s', 'logger init', dt_logger_init);
    project_log('INFO', '[startup] Paths initialized successfully.');
    dt_logger_replay = toc(t_logger_replay);

    project_log('INFO', '[startup] %-22s : %.3f s', 'logger replay', dt_logger_replay);
    project_log('INFO', '[startup] %-22s : %.3f s', 'total startup', dt_core + dt_logger_init + dt_logger_replay);
end

function add_path_if_needed_fast(target_dir, recursive, required)
%ADD_PATH_IF_NEEDED_FAST
% 快速版本：
% - 只在首次 startup 或 force 模式时调用；
% - 不做目录树变化检测；
% - 不做复杂 path 比较；
% - 目录存在时直接 addpath / genpath。

    if nargin < 3
        required = false;
    end

    if exist(target_dir, 'dir') ~= 7
        if required
            warning('startup:MissingRequiredDir', ...
                'Required startup directory is missing: %s', target_dir);
        end
        return;
    end

    if recursive
        addpath(genpath(target_dir));
    else
        addpath(target_dir);
    end
end

function ensure_dir_safe(target_dir)
    if exist(target_dir, 'dir') ~= 7
        mkdir(target_dir);
    end
end