function startup()
% Root startup wrapper after legacy migration.
% 1) Add new framework and experiments paths
% 2) Delegate legacy path setup to legacy/startup.m

repo_root = fileparts(mfilename('fullpath'));

addpath(genpath(fullfile(repo_root, 'framework')));
addpath(genpath(fullfile(repo_root, 'experiments')));

legacy_startup = fullfile(repo_root, 'legacy', 'startup.m');
if exist(legacy_startup, 'file') == 2
    run(legacy_startup);
else
    warning('legacy startup.m not found: %s', legacy_startup);
end
end
