function startup()
% Root startup wrapper
% 1) Prevent duplicate startup
% 2) Add framework, experiments, tests, and tools paths
% 3) Delegate legacy path setup
% 4) Print startup timing

persistent STARTUP_DONE;
persistent STARTUP_ROOT;

t0 = tic;
repo_root = fileparts(mfilename('fullpath'));

if ~isempty(STARTUP_DONE) && STARTUP_DONE
    fprintf('[startup] Already initialized. Root: %s\n', STARTUP_ROOT);
    fprintf('[startup] Skipping repeated initialization.\n');
    return;
end

fprintf('[startup] Initializing project paths...\n');
fprintf('[startup] Repository root: %s\n', repo_root);

fprintf('[startup] Adding framework paths...\n');
addpath(genpath(fullfile(repo_root, 'framework')));

fprintf('[startup] Adding experiments paths...\n');
addpath(genpath(fullfile(repo_root, 'experiments')));

fprintf('[startup] Adding tests paths...\n');
addpath(genpath(fullfile(repo_root, 'tests')));

fprintf('[startup] Adding tools paths...\n');
addpath(genpath(fullfile(repo_root, 'tools')));

legacy_startup = fullfile(repo_root, 'legacy', 'startup.m');
if exist(legacy_startup, 'file') == 2
    fprintf('[startup] Delegating to legacy startup...\n');
    run(legacy_startup);
else
    warning('[startup] legacy startup.m not found: %s', legacy_startup);
end

STARTUP_DONE = true;
STARTUP_ROOT = repo_root;

elapsed = toc(t0);
fprintf('[startup] Initialization complete in %.3f s\n', elapsed);
end
