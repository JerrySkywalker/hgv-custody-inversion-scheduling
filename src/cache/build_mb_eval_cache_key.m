function cache_key = build_mb_eval_cache_key(spec)
%BUILD_MB_EVAL_CACHE_KEY Build a deterministic cache key for MB evaluation and tune artifacts.

if nargin < 1 || isempty(spec)
    spec = struct();
end

normalized = local_normalize_spec(spec);
payload = jsonencode(normalized);

md = java.security.MessageDigest.getInstance('MD5');
md.update(uint8(payload));
hash_bytes = typecast(md.digest(), 'uint8');
hash_hex = lower(reshape(dec2hex(hash_bytes, 2).', 1, []));
cache_key = string(hash_hex);
end

function spec = local_normalize_spec(spec)
if ~isstruct(spec)
    spec = struct('value', spec);
end

field_names = sort(fieldnames(spec));
normalized = struct();
for idx = 1:numel(field_names)
    name = field_names{idx};
    normalized.(name) = local_normalize_value(spec.(name));
end
spec = normalized;
end

function value = local_normalize_value(value)
if isstruct(value)
    value = local_normalize_spec(value);
elseif iscell(value)
    cell_out = cell(size(value));
    for idx = 1:numel(value)
        cell_out{idx} = local_normalize_value(value{idx});
    end
    value = cell_out;
elseif isstring(value)
    value = cellstr(value(:).');
elseif ischar(value)
    value = {value};
elseif isnumeric(value) || islogical(value)
    value = reshape(value, 1, []);
end
end
