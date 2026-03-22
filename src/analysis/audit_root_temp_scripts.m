function artifacts = audit_root_temp_scripts(root_dir, archive_label)
%AUDIT_ROOT_TEMP_SCRIPTS Audit and safely archive root temp_*.m scripts.

if nargin < 1 || strlength(string(root_dir)) == 0
    root_dir = pwd;
end
if nargin < 2 || strlength(string(archive_label)) == 0
    archive_label = "final_round";
end

root_dir = char(string(root_dir));
archive_label = string(archive_label);
cfg = milestone_common_defaults();
tables_dir = fullfile(cfg.paths.outputs, 'milestones', 'startup_audit', 'tables');
ensure_dir(tables_dir);

archive_root = fullfile(root_dir, 'sandbox', 'temp_scripts_archive', char(archive_label));
ensure_dir(archive_root);

files = dir(fullfile(root_dir, 'temp_*.m'));
audit_rows = cell(0, 7);
cleanup_rows = cell(0, 6);
for idx = 1:numel(files)
    file_name = string(files(idx).name);
    file_path = string(fullfile(files(idx).folder, files(idx).name));
    referenced_by_repo = local_is_referenced(root_dir, file_name, ["src", "milestones", "run_stages", "params"], [".m", ".matlab"]);
    referenced_by_docs = local_is_referenced(root_dir, file_name, [".", "docs"], [".md", ".txt"]);
    likely_temp_test = true;
    safe_to_delete = false;
    if referenced_by_repo || referenced_by_docs
        reason = "referenced by tracked code/docs; archive conservatively";
    else
        reason = "unreferenced root temp script; archive conservatively";
    end
    recommended_action = "archive";
    audit_rows(end + 1, :) = {file_name, logical(referenced_by_repo), logical(referenced_by_docs), logical(likely_temp_test), logical(safe_to_delete), string(reason), string(recommended_action)}; %#ok<AGROW>

    archive_path = string(fullfile(archive_root, files(idx).name));
    if exist(char(archive_path), 'file') == 2
        archive_path = string(fullfile(archive_root, local_uniquify_name(files(idx).name)));
    end
    movefile(char(file_path), char(archive_path));
    cleanup_rows(end + 1, :) = {file_name, "archived", logical(safe_to_delete), string(reason), string(archive_path), string(recommended_action)}; %#ok<AGROW>
end

audit_table = cell2table(audit_rows, 'VariableNames', { ...
    'filename', 'referenced_by_repo', 'referenced_by_docs', 'likely_temp_test', ...
    'safe_to_delete', 'reason', 'recommended_action'});
cleanup_table = cell2table(cleanup_rows, 'VariableNames', { ...
    'filename', 'cleanup_action', 'safe_to_delete', 'reason', 'archive_path', 'recommended_action'});

if isempty(audit_table)
    audit_table = local_empty_audit_table();
end
if isempty(cleanup_table)
    cleanup_table = local_empty_cleanup_table();
end

audit_csv = fullfile(tables_dir, 'temp_script_audit_summary.csv');
cleanup_csv = fullfile(tables_dir, 'temp_script_cleanup_summary.csv');
milestone_common_save_table(audit_table, audit_csv);
milestone_common_save_table(cleanup_table, cleanup_csv);

artifacts = struct();
artifacts.audit_csv = string(audit_csv);
artifacts.cleanup_csv = string(cleanup_csv);
artifacts.archive_root = string(archive_root);
end

function tf = local_is_referenced(root_dir, needle, scopes, extensions)
tf = false;
for idx_scope = 1:numel(scopes)
    scope = scopes(idx_scope);
    if scope == "."
        scope_dir = root_dir;
    else
        scope_dir = fullfile(root_dir, char(scope));
    end
    if ~isfolder(scope_dir)
        continue;
    end
    files = local_collect_text_files(scope_dir, extensions);
    for idx_file = 1:numel(files)
        if strcmpi(files(idx_file), fullfile(root_dir, char(needle)))
            continue;
        end
        try
            text = fileread(files(idx_file));
        catch
            continue;
        end
        if contains(string(text), needle)
            tf = true;
            return;
        end
    end
end
end

function files = local_collect_text_files(base_dir, extensions)
files = strings(0, 1);
listing = dir(fullfile(base_dir, '**', '*'));
for idx = 1:numel(listing)
    item = listing(idx);
    if item.isdir
        continue;
    end
    [~, ~, ext] = fileparts(item.name);
    if ~ismember(lower(string(ext)), lower(string(extensions)))
        continue;
    end
    files(end + 1, 1) = string(fullfile(item.folder, item.name)); %#ok<AGROW>
end
end

function name = local_uniquify_name(file_name)
[~, stem, ext] = fileparts(file_name);
name = sprintf('%s_archived_%s%s', stem, datestr(now, 'yyyymmdd_HHMMSSFFF'), ext);
end

function T = local_empty_audit_table()
T = table('Size', [0, 7], ...
    'VariableTypes', {'string', 'logical', 'logical', 'logical', 'logical', 'string', 'string'}, ...
    'VariableNames', {'filename', 'referenced_by_repo', 'referenced_by_docs', 'likely_temp_test', 'safe_to_delete', 'reason', 'recommended_action'});
end

function T = local_empty_cleanup_table()
T = table('Size', [0, 6], ...
    'VariableTypes', {'string', 'string', 'logical', 'string', 'string', 'string'}, ...
    'VariableNames', {'filename', 'cleanup_action', 'safe_to_delete', 'reason', 'archive_path', 'recommended_action'});
end
