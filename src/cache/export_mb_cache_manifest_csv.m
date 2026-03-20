function csv_file = export_mb_cache_manifest_csv(manifest, csv_file)
%EXPORT_MB_CACHE_MANIFEST_CSV Export a human-readable single-row MB cache manifest CSV.

if nargin < 1 || ~isstruct(manifest)
    error('export_mb_cache_manifest_csv requires a manifest struct.');
end
if nargin < 2 || strlength(string(csv_file)) == 0
    error('export_mb_cache_manifest_csv requires csv_file.');
end

fields = fieldnames(manifest);
values = cell(1, numel(fields));
for idx = 1:numel(fields)
    values{idx} = local_stringify(manifest.(fields{idx}));
end
T = cell2table(values, 'VariableNames', fields);
writetable(T, csv_file);
end

function txt = local_stringify(value)
if isstruct(value)
    try
        txt = jsonencode(value);
    catch
        txt = char(string(value));
    end
elseif iscell(value)
    txt = char(string(strjoin(cellstr(string(value)), ', ')));
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
