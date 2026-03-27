function out = pack_project_snapshot_head()
%PACK_PROJECT_SNAPSHOT_HEAD Create HEAD full snapshot.
%
% Semantics:
%   source  = head
%   content = all

out = pack_project_snapshot_core(struct( ...
    'snapshot_name', 'project_snapshot_head', ...
    'source', 'head', ...
    'content', 'all'));
end
