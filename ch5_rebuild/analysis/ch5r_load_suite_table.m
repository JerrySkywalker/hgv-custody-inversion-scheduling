function [T, meta] = ch5r_load_suite_table(source)
%CH5R_LOAD_SUITE_TABLE
% Load multicase suite results from:
% - table
% - struct with .table or .paths.csv_file
% - csv file path
%
% Automatically backfills:
% - RMSE fields
% - SC/DC/LoC state metrics

meta = struct();
meta.source_type = '';
meta.csv_file = '';
meta.rmse_backfilled = false;
meta.state_backfilled = false;

if istable(source)
    T = source;
    meta.source_type = 'table';
    T = local_try_backfill(T, meta);
    meta.rmse_backfilled = true;
    meta.state_backfilled = true;
    return;
end

if isstruct(source)
    if isfield(source, 'table') && istable(source.table)
        T = source.table;
        meta.source_type = 'struct.table';
        if isfield(source, 'paths') && isstruct(source.paths) && isfield(source.paths, 'csv_file')
            meta.csv_file = source.paths.csv_file;
        end
        T = local_try_backfill(T, meta);
        meta.rmse_backfilled = true;
        meta.state_backfilled = true;
        return;
    end

    if isfield(source, 'paths') && isstruct(source.paths) && isfield(source.paths, 'csv_file')
        csv_file = char(string(source.paths.csv_file));
        T = readtable(csv_file, 'TextType', 'string');
        meta.source_type = 'struct.csv_file';
        meta.csv_file = csv_file;
        T = local_try_backfill(T, meta);
        meta.rmse_backfilled = true;
        meta.state_backfilled = true;
        return;
    end
end

if ischar(source) || isstring(source)
    csv_file = char(string(source));
    T = readtable(csv_file, 'TextType', 'string');
    meta.source_type = 'csv_file';
    meta.csv_file = csv_file;
    T = local_try_backfill(T, meta);
    meta.rmse_backfilled = true;
    meta.state_backfilled = true;
    return;
end

error('ch5r_load_suite_table:UnsupportedInput', ...
    'Unsupported source type: %s', class(source));
end

function T = local_try_backfill(T, meta) %#ok<INUSD>
try
    if ismember('mat_file', T.Properties.VariableNames)
        T = ch5r_backfill_suite_state_metrics_from_mat(T);
    end
catch ME
    warning('[ch5r_load_suite_table] State backfill skipped: %s', ME.message);
end

try
    if ismember('mat_file', T.Properties.VariableNames) && ...
       ismember('mean_rmse_pos_km', T.Properties.VariableNames) && ...
       ismember('final_rmse_pos_km', T.Properties.VariableNames)
        T = ch5r_backfill_suite_rmse_from_mat(T);
    end
catch ME
    warning('[ch5r_load_suite_table] RMSE backfill skipped: %s', ME.message);
end
end
