function out = merge_struct_deep(base, override)
%MERGE_STRUCT_DEEP Recursively merge two structs.
%   out = MERGE_STRUCT_DEEP(base, override)
%   - If both inputs are structs, fields in override overwrite or extend base.
%   - Nested structs are merged recursively.
%   - For non-struct values, override replaces base.
%
%   This utility is intentionally simple and deterministic for framework
%   configuration assembly.

    if nargin < 1 || isempty(base)
        base = struct();
    end
    if nargin < 2 || isempty(override)
        override = struct();
    end

    if ~isstruct(base) || ~isstruct(override)
        error('merge_struct_deep:TypeError', ...
            'Both inputs must be structs or empty.');
    end

    out = base;
    fn = fieldnames(override);

    for k = 1:numel(fn)
        key = fn{k};
        value = override.(key);

        if isfield(out, key) && isstruct(out.(key)) && isstruct(value)
            out.(key) = merge_struct_deep(out.(key), value);
        else
            out.(key) = value;
        end
    end
end
