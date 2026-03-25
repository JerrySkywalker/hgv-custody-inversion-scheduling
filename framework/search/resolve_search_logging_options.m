function opts = resolve_search_logging_options(search_spec)
if nargin < 1 || isempty(search_spec)
    search_spec = struct();
end

opts = struct();
opts.enable_console = true;
opts.enable_file = false;
opts.console_level = 'INFO';
opts.file_level = 'DEBUG';
opts.file_path = '';
opts.show_progress = true;
opts.progress_every = 1;

if isfield(search_spec, 'logger') && isstruct(search_spec.logger)
    lg = search_spec.logger;
    if isfield(lg, 'enable_console'), opts.enable_console = logical(lg.enable_console); end
    if isfield(lg, 'enable_file'), opts.enable_file = logical(lg.enable_file); end
    if isfield(lg, 'console_level'), opts.console_level = lg.console_level; end
    if isfield(lg, 'file_level'), opts.file_level = lg.file_level; end
    if isfield(lg, 'file_path'), opts.file_path = lg.file_path; end
end

if isfield(search_spec, 'show_progress')
    opts.show_progress = logical(search_spec.show_progress);
end
if isfield(search_spec, 'progress_every') && ~isempty(search_spec.progress_every)
    opts.progress_every = search_spec.progress_every;
end
end
