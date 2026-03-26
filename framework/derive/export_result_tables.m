function table_paths = export_result_tables(outputs, export_spec)
%EXPORT_RESULT_TABLES Export selected tables/struct-table products to CSV/MAT.

if nargin < 2
    export_spec = struct();
end

artifact_root = local_get(export_spec, 'artifact_root', fullfile('outputs','experiments','chapter4','stage05_manual_raan'));
tables_dir = fullfile(artifact_root, 'tables');

if exist(tables_dir, 'dir') ~= 7
    mkdir(tables_dir);
end

if isfield(export_spec, 'table_names') && ~isempty(export_spec.table_names)
    table_names = cellstr(string(export_spec.table_names));
else
    table_names = fieldnames(outputs);
end

table_paths = struct();

for i = 1:numel(table_names)
    name = table_names{i};
    if ~isfield(outputs, name)
        continue;
    end

    obj = outputs.(name);
    tbl = local_try_as_table(obj);
    if isempty(tbl)
        continue;
    end

    csv_path = fullfile(tables_dir, [name '.csv']);
    mat_path = fullfile(tables_dir, [name '.mat']);

    writetable(tbl, csv_path);
    save(mat_path, 'tbl');

    table_paths.(name) = struct( ...
        'csv_path', string(csv_path), ...
        'mat_path', string(mat_path));
end
end

function tbl = local_try_as_table(obj)
tbl = [];
if istable(obj)
    tbl = obj;
elseif isstruct(obj)
    req_fields = {'row_values','col_values','value_matrix'};
    if all(isfield(obj, req_fields))
        return;
    end
    try
        tbl = struct2table(obj);
    catch
        tbl = [];
    end
end
end

function v = local_get(s, f, d)
if isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = d;
end
end
