function out = pack_project_snapshot_head_code(include_chapter5, include_legacy)
%PACK_PROJECT_SNAPSHOT_HEAD_CODE Create head-style code-only project snapshot.
%
% Note:
%   Current implementation shares the same filtered-copy core as
%   pack_project_snapshot_all_code, but records scope='head' for future
%   extension.

if nargin < 1 || isempty(include_chapter5)
    include_chapter5 = false;
end
if nargin < 2 || isempty(include_legacy)
    include_legacy = false;
end

out = pack_project_snapshot_core(struct( ...
    'snapshot_name', 'project_snapshot_head_code', ...
    'scope', 'head', ...
    'code_only', true, ...
    'include_outputs', false, ...
    'include_chapter5', logical(include_chapter5), ...
    'include_legacy', logical(include_legacy)));
end
