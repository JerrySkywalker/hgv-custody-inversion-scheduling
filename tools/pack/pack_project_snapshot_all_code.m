function out = pack_project_snapshot_all_code()
%PACK_PROJECT_SNAPSHOT_ALL_CODE Create working-tree code-only snapshot.
%
% Semantics:
%   source  = working
%   content = code

out = pack_project_snapshot_core(struct( ...
    'snapshot_name', 'project_snapshot_all_code', ...
    'source', 'working', ...
    'content', 'code'));
end
