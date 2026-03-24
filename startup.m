function startup()
% Root startup wrapper after legacy migration.
% Purpose:
% 1) keep repository bootstrappable from root
% 2) delegate old path setup to legacy/startup.m when present

repo_root = fileparts(mfilename('fullpath'));
legacy_startup = fullfile(repo_root, 'legacy', 'startup.m');

if exist(legacy_startup, 'file') == 2
    run(legacy_startup);
else
    warning('legacy startup.m not found: %s', legacy_startup);
end
end
