function startup()
    %STARTUP Initialize project paths and results folders for Chapter 4 fresh-start project.
    
        root_dir = fileparts(mfilename('fullpath'));
    
        addpath(root_dir);
        addpath(genpath(fullfile(root_dir, 'params')));
        addpath(genpath(fullfile(root_dir, 'src')));
        addpath(genpath(fullfile(root_dir, 'stages')));
        addpath(genpath(fullfile(root_dir, 'paper')));
        addpath(genpath(fullfile(root_dir, 'tests')));
    
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