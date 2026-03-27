function logger = init_project_logging(root_dir)
%INIT_PROJECT_LOGGING Initialize global project logger.
%
% logger = init_project_logging(root_dir)

    if nargin < 1 || isempty(root_dir)
        this_dir = fileparts(mfilename('fullpath'));   % src/common
        src_dir = fileparts(this_dir);                 % src
        root_dir = fileparts(src_dir);                 % repo root
    end

    logs_root = fullfile(root_dir, 'outputs', 'logs', 'session');
    if exist(logs_root, 'dir') ~= 7
        mkdir(logs_root);
    end

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    log_file = fullfile(logs_root, sprintf('session_%s.log', timestamp));

    cfg = struct();
    cfg.enable_console = true;
    cfg.console_level = 'INFO';
    cfg.enable_file = true;
    cfg.file_path = log_file;
    cfg.use_color = true;
    cfg.color_mode = 'auto';

    logger = make_logger(cfg);

    setappdata(0, 'PROJECT_LOGGER', logger);
    setappdata(0, 'PROJECT_LOG_FILE', log_file);
end
