function out = pack_project_snapshot_all()
%PACK_PROJECT_SNAPSHOT_ALL Create working-tree full snapshot.
%
% Semantics:
%   source  = working
%   content = all

out = pack_project_snapshot_core(struct( ...
    'snapshot_name', 'project_snapshot_all', ...
    'source', 'working', ...
    'content', 'all'));
end
