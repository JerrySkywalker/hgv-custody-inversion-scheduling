function [support_sources, num_support_sources] = merge_slice_source_support(slice_sources)
%MERGE_SLICE_SOURCE_SUPPORT Collapse repeated slice-source labels into a stable list.

if nargin < 1 || isempty(slice_sources)
    support_sources = "";
    num_support_sources = 0;
    return;
end

if iscell(slice_sources)
    values = string(slice_sources);
else
    values = string(slice_sources);
end

tokens = strings(0, 1);
for k = 1:numel(values)
    parts = split(values(k), ",");
    parts = strtrim(parts);
    parts = parts(parts ~= "");
    tokens = [tokens; parts(:)]; %#ok<AGROW>
end

if isempty(tokens)
    support_sources = "";
    num_support_sources = 0;
    return;
end

[~, ia] = unique(tokens, 'stable');
tokens = tokens(sort(ia));
support_sources = strjoin(tokens, ",");
num_support_sources = numel(tokens);
end
