function out = pack_project_snapshot_all(include_outputs, include_chapter5, include_legacy)
%PACK_PROJECT_SNAPSHOT_ALL Create all-content project snapshot.
%
% Usage:
%   out = pack_project_snapshot_all();
%   out = pack_project_snapshot_all(true);
%   out = pack_project_snapshot_all(true, true, false);

if nargin < 1 || isempty(include_outputs)
    include_outputs = false;
end
if nargin < 2 || isempty(include_chapter5)
    include_chapter5 = true;
end
if nargin < 3 || isempty(include_legacy)
    include_legacy = false;
end

out = pack_project_snapshot_core(struct( ...
    'snapshot_name', 'project_snapshot_all', ...
    'scope', 'all', ...
    'code_only', false, ...
    'include_outputs', logical(include_outputs), ...
    'include_chapter5', logical(include_chapter5), ...
    'include_legacy', logical(include_legacy)));
end
