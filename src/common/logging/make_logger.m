function logger = make_logger(cfg)
%MAKE_LOGGER Create a logger configuration struct.

if nargin < 1 || isempty(cfg)
    cfg = struct();
end

logger = struct();

logger.enable_console = local_get(cfg, 'enable_console', true);
logger.console_level = upper(char(string(local_get(cfg, 'console_level', 'INFO'))));

logger.enable_file = local_get(cfg, 'enable_file', false);
logger.file_path = char(string(local_get(cfg, 'file_path', '')));

logger.use_color = local_get(cfg, 'use_color', false);
logger.color_mode = lower(char(string(local_get(cfg, 'color_mode', 'auto'))));

logger.level_rank = struct( ...
    'DEBUG', 10, ...
    'INFO', 20, ...
    'WARN', 30, ...
    'ERROR', 40);

logger.is_desktop = usejava('desktop');
logger.diary_active = strcmpi(get(0, 'Diary'), 'on');

% accept both .m (2) and .p (6)
cprintf_exist_code = exist('cprintf', 'file');
logger.has_cprintf = any(cprintf_exist_code == [2, 6]);

logger.color_backend = local_resolve_color_backend(logger);

if logger.enable_file && ~isempty(logger.file_path)
    file_dir = fileparts(logger.file_path);
    if ~isempty(file_dir) && exist(file_dir, 'dir') ~= 7
        mkdir(file_dir);
    end
end
end

function backend = local_resolve_color_backend(logger)
backend = 'plain';

if ~logger.use_color
    return;
end

switch logger.color_mode
    case 'never'
        backend = 'plain';

    case 'ansi'
        backend = 'ansi';

    case 'cprintf'
        if logger.is_desktop && logger.has_cprintf && ~logger.diary_active
            backend = 'cprintf';
        else
            backend = 'plain';
        end

    case 'auto'
        if logger.is_desktop
            if logger.has_cprintf && ~logger.diary_active
                backend = 'cprintf';
            else
                backend = 'plain';
            end
        else
            backend = 'ansi';
        end

    otherwise
        backend = 'plain';
end
end

function v = local_get(s, f, d)
if isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = d;
end
end
