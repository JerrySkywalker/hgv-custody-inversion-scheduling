function out = pack_project_snapshot_head(include_outputs, include_chapter5, include_legacy)
%PACK_PROJECT_SNAPSHOT_HEAD Create head-style project snapshot.
%
% Note:
%   Current implementation shares the same filtered-copy core as
%   pack_project_snapshot_all, but records scope='head' for future
%   extension.

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
    'snapshot_name', 'project_snapshot_head', ...
    'scope', 'head', ...
    'code_only', false, ...
    'include_outputs', logical(include_outputs), ...
    'include_chapter5', logical(include_chapter5), ...
    'include_legacy', logical(include_legacy)));
end
