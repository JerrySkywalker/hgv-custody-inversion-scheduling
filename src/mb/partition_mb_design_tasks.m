function partitions = partition_mb_design_tasks(design_table, parallel_policy)
%PARTITION_MB_DESIGN_TASKS Partition MB design tables for inner parallel evaluation.

if nargin < 1 || isempty(design_table) || ~istable(design_table)
    partitions = {table()};
    return;
end
if nargin < 2 || isempty(parallel_policy)
    parallel_policy = resolve_mb_parallel_policy(struct('parallel_policy', 'task_plus_partition'));
end

strategy = lower(char(string(local_getfield_or(parallel_policy, 'partition_strategy', "inclination"))));
max_partitions = max(1, local_getfield_or(parallel_policy, 'max_workers_inner', 4));

switch strategy
    case 'inclination'
        key_field = 'i_deg';
    case 'planes'
        key_field = 'P';
    otherwise
        key_field = 'i_deg';
end

if ~ismember(key_field, design_table.Properties.VariableNames)
    partitions = {design_table};
    return;
end

key_values = unique(design_table.(key_field), 'stable');
if numel(key_values) <= 1
    partitions = {design_table};
    return;
end

bucket_count = min(max_partitions, numel(key_values));
bucket_keys = cell(bucket_count, 1);
for idx = 1:numel(key_values)
    bucket_idx = mod(idx - 1, bucket_count) + 1;
    bucket_keys{bucket_idx, 1}(end + 1) = key_values(idx); %#ok<AGROW>
end

partitions = cell(bucket_count, 1);
for idx = 1:bucket_count
    key_set = bucket_keys{idx};
    partitions{idx, 1} = design_table(ismember(design_table.(key_field), key_set), :);
end
partitions = partitions(~cellfun(@isempty, partitions));
if isempty(partitions)
    partitions = {design_table};
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
