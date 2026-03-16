function startup()
    %STARTUP Initialize project paths and results folders for Chapter 4 fresh-start project.
    
        root_dir = fileparts(mfilename('fullpath'));
    
        addpath(root_dir);
        addpath(genpath(fullfile(root_dir, 'params')));
        addpath(genpath(fullfile(root_dir, 'src')));
        addpath(genpath(fullfile(root_dir, 'stages')));
        addpath(genpath(fullfile(root_dir, 'benchmarks')));
        addpath(genpath(fullfile(root_dir, 'milestones')));
        addpath(genpath(fullfile(root_dir, 'shared_scenarios')));
        addpath(genpath(fullfile(root_dir, 'paper')));
        addpath(genpath(fullfile(root_dir, 'tests')));
        addpath(genpath(fullfile(root_dir, 'run_milestones')));
        addpath(genpath(fullfile(root_dir, 'run_shared_scenarios')));
        addpath(genpath(fullfile(root_dir, 'run_stages')));
    
        % Add deliverables / milestone scripts
        deliverables_dir = fullfile(root_dir, 'deliverables');
        if exist(deliverables_dir, 'dir')
            addpath(genpath(deliverables_dir));
        end
    
        % Ensure result folders exist
        ensure_dir(fullfile(root_dir, 'results'));
        ensure_dir(fullfile(root_dir, 'results', 'cache'));
        ensure_dir(fullfile(root_dir, 'results', 'figs'));
        ensure_dir(fullfile(root_dir, 'results', 'logs'));
        ensure_dir(fullfile(root_dir, 'results', 'tables'));
        ensure_dir(fullfile(root_dir, 'results', 'bundles'));
        ensure_dir(fullfile(root_dir, 'results', 'benchmarks'));
        ensure_dir(fullfile(root_dir, 'output'));
        ensure_dir(fullfile(root_dir, 'output', 'milestones'));
        ensure_dir(fullfile(root_dir, 'output', 'shared_scenarios'));
        ensure_dir(fullfile(root_dir, 'output', 'shared_scenarios', 'SS1'));
        ensure_dir(fullfile(root_dir, 'output', 'shared_scenarios', 'SS2'));
    
        fprintf('[startup] Project root: %s\n', root_dir);
        fprintf('[startup] Paths initialized successfully.\n');
    
        % ---------------------------
        % Global graphics defaults
        % Use plain text by default; enable LaTeX only where explicitly requested.
        % ---------------------------
        set(groot, 'defaultTextInterpreter', 'none');
        set(groot, 'defaultLegendInterpreter', 'none');
        set(groot, 'defaultAxesTickLabelInterpreter', 'none');
    end
