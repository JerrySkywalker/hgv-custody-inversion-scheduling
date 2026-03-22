function out = project_path_manager(action, varargin)
%PROJECT_PATH_MANAGER Audit and manage project MATLAB paths using a whitelist.

if nargin < 1 || isempty(action)
    action = 'init';
end

action = char(lower(string(action)));
root_dir = local_resolve_root(varargin{:});

switch action
    case 'audit'
        out = local_run_audit(root_dir);
    case 'show'
        out = local_show_plan(root_dir);
    case 'init'
        out = local_init_paths(root_dir, false);
    case 'refresh'
        out = local_init_paths(root_dir, true);
    otherwise
        error('project_path_manager:UnknownAction', 'Unknown action "%s".', action);
end
end

function out = local_run_audit(root_dir)
tables_dir = fullfile(root_dir, 'outputs', 'milestones', 'startup_audit', 'tables');
ensure_dir(tables_dir);

audit_table = local_build_path_audit_table(root_dir);
audit_csv = fullfile(tables_dir, 'path_audit_summary.csv');
writetable(audit_table, audit_csv);

perf_table = local_build_startup_performance_audit_summary(root_dir, audit_table);
perf_csv = fullfile(tables_dir, 'startup_performance_audit_summary.csv');
writetable(perf_table, perf_csv);

timing_table = local_measure_init_timings(root_dir);
timing_csv = fullfile(tables_dir, 'startup_timing_before_after.csv');
writetable(timing_table, timing_csv);

out = struct();
out.audit_csv = string(audit_csv);
out.performance_csv = string(perf_csv);
out.timing_csv = string(timing_csv);
out.audit_table = audit_table;
out.performance_table = perf_table;
out.timing_table = timing_table;
end

function out = local_show_plan(root_dir)
entries = local_whitelist_entries(root_dir);
rows = cell(numel(entries), 4);
for idx = 1:numel(entries)
    rows(idx, :) = {entries(idx).name, entries(idx).path, entries(idx).recursive, entries(idx).note};
end
out = cell2table(rows, 'VariableNames', {'entry_name', 'path', 'recursive', 'note'});
out.entry_name = string(out.entry_name);
out.path = string(out.path);
out.recursive = logical(out.recursive);
out.note = string(out.note);
disp(out);
end

function out = local_init_paths(root_dir, force_refresh)
persistent session_initialized session_root session_paths session_elapsed_s

if nargin < 2
    force_refresh = false;
end

if ~force_refresh && ~isempty(session_initialized) && session_initialized && strcmpi(session_root, root_dir)
    out = struct( ...
        'status', "reused_session", ...
        'root_dir', string(root_dir), ...
        'path_count', numel(session_paths), ...
        'elapsed_s', session_elapsed_s);
    return;
end

entries = local_whitelist_entries(root_dir);
paths_to_add = strings(0, 1);
for idx = 1:numel(entries)
    entry_paths = local_expand_entry(entries(idx));
    if ~isempty(entry_paths)
        paths_to_add = [paths_to_add; entry_paths(:)]; %#ok<AGROW>
    end
end
paths_to_add = unique(paths_to_add(strlength(paths_to_add) > 0), 'stable');

tic;
for idx = 1:numel(paths_to_add)
    path_value = char(paths_to_add(idx));
    if ~contains(path, [pathsep path_value pathsep]) && ~strcmp(path_value, pwd)
        addpath(path_value);
    elseif ~contains([pathsep path pathsep], [pathsep path_value pathsep])
        addpath(path_value);
    end
end
elapsed_s = toc;

session_initialized = true;
session_root = root_dir;
session_paths = paths_to_add;
session_elapsed_s = elapsed_s;

setappdata(0, 'project_path_manager_state', struct( ...
    'root_dir', string(root_dir), ...
    'paths', paths_to_add, ...
    'elapsed_s', elapsed_s, ...
    'timestamp', string(datetime('now'))));

out = struct( ...
    'status', "initialized", ...
    'root_dir', string(root_dir), ...
    'path_count', numel(paths_to_add), ...
    'elapsed_s', elapsed_s, ...
    'paths', paths_to_add);
end

function timing_table = local_measure_init_timings(root_dir)
fresh = local_init_paths(root_dir, true);
reused = local_init_paths(root_dir, false);
rows = { ...
    "full_refresh", double(local_getfield_or(fresh, 'elapsed_s', NaN)), ...
    "full whitelist initialization"; ...
    "same_session_reuse", double(local_getfield_or(reused, 'elapsed_s', NaN)), ...
    "reused session without scanning directories"};
timing_table = cell2table(rows, 'VariableNames', {'scenario', 'elapsed_s', 'note'});
timing_table.scenario = string(timing_table.scenario);
timing_table.elapsed_s = double(timing_table.elapsed_s);
timing_table.note = string(timing_table.note);
end

function perf_table = local_build_startup_performance_audit_summary(root_dir, audit_table)
entries = local_whitelist_entries(root_dir);
recursive_count = nnz([entries.recursive]);
issue_rows = { ...
    "startup_genpath_usage", "high", "startup.m recursively adds multiple top-level directories via genpath", "replace with whitelist path manager"; ...
    "outputs_on_path_risk", "medium", sprintf('%d suspicious path calls mention outputs/cache/logs/archive classes', nnz(audit_table.suspected_risk ~= "code_dir_ok")), "exclude non-code directories using blacklist recursion"; ...
    "session_reinit_overhead", "medium", "startup currently performs full addpath workflow on every call", "cache initialization state and support force refresh"; ...
    "root_recursive_scope", "medium", sprintf('%d recursive whitelist entries remain after refactor plan', recursive_count), "keep recursion only for code subtrees with blacklist filtering"}; %#ok<SPRINTFN>
perf_table = cell2table(issue_rows, 'VariableNames', {'issue_name', 'severity', 'evidence', 'recommended_fix'});
perf_table.issue_name = string(perf_table.issue_name);
perf_table.severity = string(perf_table.severity);
perf_table.evidence = string(perf_table.evidence);
perf_table.recommended_fix = string(perf_table.recommended_fix);
end

function audit_table = local_build_path_audit_table(root_dir)
files = dir(fullfile(root_dir, '**', '*.m'));
rows = cell(0, 6);
pattern = '(?<call>addpath|genpath|restoredefaultpath|rmpath|userpath\s*\(|path\s*\()';
for idx_file = 1:numel(files)
    file_path = fullfile(files(idx_file).folder, files(idx_file).name);
    if contains(lower(file_path), [filesep '.git' filesep])
        continue;
    end
    contents = splitlines(string(fileread(file_path)));
    for idx_line = 1:numel(contents)
        line_text = contents(idx_line);
        if strlength(strtrim(line_text)) == 0
            continue;
        end
        if isempty(regexp(char(line_text), pattern, 'once'))
            continue;
        end
        call_type = local_detect_call_type(line_text);
        target_path = local_detect_target_path(line_text);
        is_recursive = contains(lower(line_text), 'genpath');
        relative_file = strrep(file_path, [root_dir filesep], '');
        rows(end + 1, :) = { ... %#ok<AGROW>
            string(relative_file), ...
            string(sprintf('line %d', idx_line)), ...
            string(call_type), ...
            string(target_path), ...
            logical(is_recursive), ...
            string(local_classify_path_risk(target_path, file_path, is_recursive))};
    end
end
audit_table = cell2table(rows, 'VariableNames', ...
    {'file', 'line_or_function', 'call_type', 'target_path', 'whether_recursive', 'suspected_risk'});
if isempty(audit_table)
    audit_table = table('Size', [0, 6], ...
        'VariableTypes', {'string', 'string', 'string', 'string', 'logical', 'string'}, ...
        'VariableNames', {'file', 'line_or_function', 'call_type', 'target_path', 'whether_recursive', 'suspected_risk'});
else
    audit_table.file = string(audit_table.file);
    audit_table.line_or_function = string(audit_table.line_or_function);
    audit_table.call_type = string(audit_table.call_type);
    audit_table.target_path = string(audit_table.target_path);
    audit_table.whether_recursive = logical(audit_table.whether_recursive);
    audit_table.suspected_risk = string(audit_table.suspected_risk);
end
end

function entries = local_whitelist_entries(root_dir)
entries = [ ...
    local_entry("root", root_dir, false, "root-level runners and startup"), ...
    local_entry("params", fullfile(root_dir, 'params'), true, "parameter definitions"), ...
    local_entry("src", fullfile(root_dir, 'src'), true, "shared source tree"), ...
    local_entry("stages", fullfile(root_dir, 'stages'), true, "stage implementations"), ...
    local_entry("benchmarks", fullfile(root_dir, 'benchmarks'), true, "benchmark runners"), ...
    local_entry("milestones", fullfile(root_dir, 'milestones'), true, "milestone implementations"), ...
    local_entry("shared_scenarios", fullfile(root_dir, 'shared_scenarios'), true, "shared scenario implementations"), ...
    local_entry("run_milestones", fullfile(root_dir, 'run_milestones'), false, "milestone entrypoints"), ...
    local_entry("run_shared_scenarios", fullfile(root_dir, 'run_shared_scenarios'), false, "shared scenario entrypoints"), ...
    local_entry("run_stages", fullfile(root_dir, 'run_stages'), false, "stage entrypoints"), ...
    local_entry("paper", fullfile(root_dir, 'paper'), false, "paper export helpers"), ...
    local_entry("tests", fullfile(root_dir, 'tests'), false, "test utilities"), ...
    local_entry("deliverables", fullfile(root_dir, 'deliverables'), true, "optional deliverable helpers")];
entries = entries(arrayfun(@(e) isfolder(e.path), entries));
end

function entry = local_entry(name, path_value, recursive, note)
entry = struct('name', string(name), 'path', string(path_value), 'recursive', logical(recursive), 'note', string(note));
end

function paths_out = local_expand_entry(entry)
if ~isfolder(entry.path)
    paths_out = strings(0, 1);
    return;
end
if ~entry.recursive
    paths_out = string(entry.path);
    return;
end
dirs = string(genpath(char(entry.path)));
if strlength(dirs) == 0
    paths_out = string(entry.path);
    return;
end
parts = split(dirs, pathsep);
parts = parts(strlength(parts) > 0);
keep = false(size(parts));
for idx = 1:numel(parts)
    keep(idx) = ~local_is_blacklisted_path(parts(idx));
end
paths_out = parts(keep);
end

function risk = local_classify_path_risk(target_path, file_path, is_recursive)
lower_target = lower(char(target_path));
lower_file = lower(char(file_path));
if contains(lower_target, 'outputs') || contains(lower_target, 'figures') || contains(lower_target, 'tables')
    risk = "outputs_should_not_be_on_path";
elseif contains(lower_target, 'cache')
    risk = "cache_should_not_be_on_path";
elseif contains(lower_target, '.git') || contains(lower_target, 'archive') || contains(lower_target, 'worktree')
    risk = "worktree_or_archive_should_not_be_on_path";
elseif is_recursive && contains(lower_file, [filesep 'startup.m'])
    risk = "repo_root_too_broad";
elseif contains(lower_target, 'src') || contains(lower_target, 'stages') || contains(lower_target, 'milestones') || contains(lower_target, 'params')
    risk = "code_dir_ok";
else
    risk = "unknown_needs_manual_review";
end
end

function tf = local_is_blacklisted_path(path_value)
tokens = ["outputs", "cache", "figures", "tables", "logs", "archive", "snapshots", "worktree", ".git", ".github", "temp", "tmp", "old", "backup", "docs"];
path_lc = lower(char(path_value));
tf = false;
for idx = 1:numel(tokens)
    token = char(tokens(idx));
    if contains(path_lc, [filesep token filesep]) || endsWith(path_lc, [filesep token]) || contains(path_lc, ['/' token '/'])
        tf = true;
        return;
    end
end
end

function call_type = local_detect_call_type(line_text)
line_lc = lower(char(line_text));
if contains(line_lc, 'addpath')
    call_type = "addpath";
elseif contains(line_lc, 'genpath')
    call_type = "genpath";
elseif contains(line_lc, 'rmpath')
    call_type = "rmpath";
elseif contains(line_lc, 'restoredefaultpath')
    call_type = "restoredefaultpath";
elseif contains(line_lc, 'userpath')
    call_type = "userpath";
else
    call_type = "path";
end
end

function target_path = local_detect_target_path(line_text)
tokens = regexp(char(line_text), '''([^'']+)''', 'tokens');
if ~isempty(tokens)
    target_path = string(tokens{1}{1});
    return;
end
double_tokens = regexp(char(line_text), '"([^"]+)"', 'tokens');
if ~isempty(double_tokens)
    target_path = string(double_tokens{1}{1});
    return;
end
target_path = strtrim(line_text);
end

function root_dir = local_resolve_root(varargin)
root_dir = fileparts(mfilename('fullpath'));
if nargin >= 1 && ~isempty(varargin{1}) && ~(isstruct(varargin{1}) || islogical(varargin{1}))
    candidate = char(string(varargin{1}));
    if isfolder(candidate)
        root_dir = candidate;
    end
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
