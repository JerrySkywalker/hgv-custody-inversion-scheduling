function file_path = milestone_common_save_table(data, file_path)
%MILESTONE_COMMON_SAVE_TABLE Save a milestone table-like artifact.

if istable(data)
    writetable(data, file_path);
elseif isstruct(data)
    names = fieldnames(data);
    values = cell(numel(names), 1);
    for k = 1:numel(names)
        values{k} = string(local_stringify(data.(names{k})));
    end
    T = table(string(names), string(values), 'VariableNames', {'field', 'value'});
    writetable(T, file_path);
else
    T = table(string(local_stringify(data)), 'VariableNames', {'value'});
    writetable(T, file_path);
end
end

function txt = local_stringify(value)
if isnumeric(value) || islogical(value)
    if isscalar(value)
        txt = char(string(value));
    else
        txt = mat2str(value);
    end
elseif isstring(value) || ischar(value)
    txt = char(string(value));
else
    txt = char(string(value));
end
end
