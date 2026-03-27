function out = pack_project_snapshot_head_code()
%PACK_PROJECT_SNAPSHOT_HEAD_CODE Create HEAD code-only snapshot.
%
% Semantics:
%   source  = head
%   content = code

out = pack_project_snapshot_core(struct( ...
    'snapshot_name', 'project_snapshot_head_code', ...
    'source', 'head', ...
    'content', 'code'));
end
