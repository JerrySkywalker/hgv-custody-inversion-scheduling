function out = milestone_common_merge_structs(base, override)
%MILESTONE_COMMON_MERGE_STRUCTS Recursively merge scalar structs.

if nargin < 1 || isempty(base)
    base = struct();
end
if nargin < 2 || isempty(override)
    out = base;
    return;
end

out = base;
names = fieldnames(override);
for k = 1:numel(names)
    name = names{k};
    if isfield(out, name) && isstruct(out.(name)) && isstruct(override.(name)) && ...
            isscalar(out.(name)) && isscalar(override.(name))
        out.(name) = milestone_common_merge_structs(out.(name), override.(name));
    else
        out.(name) = override.(name);
    end
end
end
