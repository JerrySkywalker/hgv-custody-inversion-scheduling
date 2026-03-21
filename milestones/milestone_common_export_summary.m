function files = milestone_common_export_summary(result, paths)
%MILESTONE_COMMON_EXPORT_SUMMARY Export standard milestone summary artifacts.

if nargin < 2 || isempty(paths)
    paths = milestone_common_output_paths(milestone_common_defaults(), ...
        result.milestone_id, result.title);
end

files = struct();
files.report_md = "";
files.summary_mat = "";

if ~isfield(result, 'summary')
    result.summary = struct();
end
if ~isfield(result, 'tables')
    result.tables = struct();
end
if ~isfield(result, 'figures')
    result.figures = struct();
end
if ~isfield(result, 'artifacts')
    result.artifacts = struct();
end

local_safe_save_summary_mat(paths.summary_mat, result);
files.summary_mat = string(paths.summary_mat);

fid = fopen(paths.summary_report, 'w');
if fid < 0
    error('Failed to open summary report for writing: %s', paths.summary_report);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# %s %s\n\n', result.milestone_id, strrep(result.title, '_', ' '));
fprintf(fid, '## Purpose\n\n%s\n\n', local_get_text(result, 'purpose', 'Milestone report export.'));
fprintf(fid, '## Inputs\n\n');
fprintf(fid, '- milestone_id: `%s`\n', result.milestone_id);
fprintf(fid, '- title: `%s`\n', result.title);
fprintf(fid, '- config timestamp: `%s`\n\n', local_get_text(result.config, 'timestamp', datestr(now, 'yyyy-mm-dd HH:MM:SS')));
fprintf(fid, '## Reused Computational Modules\n\n');
local_write_list(fid, local_get_cell(result, 'reused_modules'));
fprintf(fid, '\n## Outputs generated\n\n');
local_write_named_paths(fid, 'Tables', result.tables);
local_write_named_paths(fid, 'Figures', result.figures);
local_write_named_paths(fid, 'Artifacts', result.artifacts);
fprintf(fid, '\n## Key preliminary findings\n\n');
local_write_struct_lines(fid, result.summary);

files.report_md = string(paths.summary_report);
end

function local_write_list(fid, values)
if isempty(values)
    fprintf(fid, '- none\n');
    return;
end
for k = 1:numel(values)
    fprintf(fid, '- %s\n', string(values{k}));
end
end

function local_write_named_paths(fid, heading, S)
fprintf(fid, '### %s\n\n', heading);
if isempty(fieldnames(S))
    fprintf(fid, '- none\n\n');
    return;
end
names = fieldnames(S);
for k = 1:numel(names)
    value = S.(names{k});
    fprintf(fid, '- `%s`: `%s`\n', names{k}, local_stringify(value));
end
fprintf(fid, '\n');
end

function local_write_struct_lines(fid, S)
names = fieldnames(S);
if isempty(names)
    fprintf(fid, '- no summary fields available\n');
    return;
end
for k = 1:numel(names)
    fprintf(fid, '- `%s`: %s\n', names{k}, local_stringify(S.(names{k})));
end
end

function txt = local_get_text(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    txt = local_stringify(S.(field_name));
else
    txt = fallback;
end
end

function values = local_get_cell(S, field_name)
values = {};
if isstruct(S) && isfield(S, field_name)
    candidate = S.(field_name);
    if iscell(candidate)
        values = candidate;
    elseif isstring(candidate) || ischar(candidate)
        values = cellstr(string(candidate));
    end
end
end

function txt = local_stringify(value)
if istable(value)
    txt = sprintf('table[%d x %d]', height(value), width(value));
elseif isstruct(value)
    txt = sprintf('struct(%d fields)', numel(fieldnames(value)));
elseif iscell(value)
    txt = strjoin(cellfun(@local_stringify, value, 'UniformOutput', false), ', ');
elseif isstring(value) || ischar(value)
    txt = char(string(value));
elseif isnumeric(value) || islogical(value)
    if isscalar(value)
        txt = char(string(value));
    else
        txt = mat2str(value);
    end
else
    txt = char(string(value));
end
end

function local_safe_save_summary_mat(target_path, result)
target_dir = fileparts(target_path);
if ~isempty(target_dir) && ~exist(target_dir, 'dir')
    mkdir(target_dir);
end

tmp_path = [char(target_path) '.tmp'];
if exist(tmp_path, 'file')
    delete(tmp_path);
end

save(tmp_path, 'result', '-v7.3');

if exist(target_path, 'file')
    delete(target_path);
end
movefile(tmp_path, target_path, 'f');
end
