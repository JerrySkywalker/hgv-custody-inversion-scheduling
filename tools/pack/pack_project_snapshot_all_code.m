function out = pack_project_snapshot_all_code(include_chapter5, include_legacy)
%PACK_PROJECT_SNAPSHOT_ALL_CODE Create code-only project snapshot.
%
% Usage:
%   out = pack_project_snapshot_all_code();
%   out = pack_project_snapshot_all_code(false, false);

if nargin < 1 || isempty(include_chapter5)
    include_chapter5 = false;
end
if nargin < 2 || isempty(include_legacy)
    include_legacy = false;
end

out = pack_project_snapshot_core(struct( ...
    'snapshot_name', 'project_snapshot_all_code', ...
    'scope', 'all', ...
    'code_only', true, ...
    'include_outputs', false, ...
    'include_chapter5', logical(include_chapter5), ...
    'include_legacy', logical(include_legacy)));
end
