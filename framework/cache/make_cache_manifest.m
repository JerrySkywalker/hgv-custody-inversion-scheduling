function manifest = make_cache_manifest(cache_kind, cache_path, payload, meta)
%MAKE_CACHE_MANIFEST Build a generic cache manifest struct.
% Inputs:
%   cache_kind : 'truth_table' or 'derived_table'
%   cache_path : saved MAT cache path
%   payload    : saved cache payload
%   meta       : cache meta struct

if nargin < 4 || isempty(meta)
    meta = struct();
end

manifest = struct();
manifest.cache_kind = char(string(cache_kind));
manifest.cache_path = cache_path;
manifest.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');
manifest.meta = meta;

if isstruct(payload) && isfield(payload, 'grid_table') && istable(payload.grid_table)
    manifest.row_count = height(payload.grid_table);
    manifest.col_count = width(payload.grid_table);
elseif isstruct(payload) && isfield(payload, 'derived_table') && istable(payload.derived_table)
    manifest.row_count = height(payload.derived_table);
    manifest.col_count = width(payload.derived_table);
elseif isstruct(payload) && isfield(payload, 'tables') && isstruct(payload.tables)
    manifest.row_count = NaN;
    manifest.col_count = NaN;
else
    manifest.row_count = NaN;
    manifest.col_count = NaN;
end
end
