function startup()
    %STARTUP Initialize project paths and outputs folders for Chapter 4 fresh-start project.
    
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

        addpath(genpath(fullfile(root_dir, 'tools')));
        addpath(genpath(fullfile(root_dir, 'tests')));
    
        % Add deliverables / milestone scripts
        deliverables_dir = fullfile(root_dir, 'deliverables');
        if exist(deliverables_dir, 'dir')
            addpath(genpath(deliverables_dir));
        end
    
        % Ensure unified outputs/ folders exist.
        outputs_root = fullfile(root_dir, 'outputs');
        ensure_dir(outputs_root);
        ensure_dir(fullfile(outputs_root, 'stage'));
        ensure_dir(fullfile(outputs_root, 'benchmark'));
        ensure_dir(fullfile(outputs_root, 'logs'));
        ensure_dir(fullfile(outputs_root, 'bundles'));
        ensure_dir(fullfile(outputs_root, 'milestones'));
        ensure_dir(fullfile(outputs_root, 'shared_scenarios'));
        ensure_dir(fullfile(outputs_root, 'stage', 'stage13'));

        % Create the canonical paper-export subtree eagerly.
        ensure_dir(fullfile(outputs_root, 'milestones', 'MA'));
        ensure_dir(fullfile(outputs_root, 'milestones', 'MB'));
        ensure_dir(fullfile(outputs_root, 'milestones', 'MC'));
        ensure_dir(fullfile(outputs_root, 'milestones', 'MD'));
        ensure_dir(fullfile(outputs_root, 'milestones', 'ME'));
        ensure_dir(fullfile(outputs_root, 'shared_scenarios', 'SS1'));
        ensure_dir(fullfile(outputs_root, 'shared_scenarios', 'SS2'));

        % Stage root placeholders keep the intended stage-oriented layout visible
        % while stage code continues to use shared compatibility folders.
        for k = 0:11
            stage_name = sprintf('stage%02d', k);
            ensure_dir(fullfile(outputs_root, 'stage', stage_name));
            ensure_dir(fullfile(outputs_root, 'stage', stage_name, 'cache'));
            ensure_dir(fullfile(outputs_root, 'stage', stage_name, 'figs'));
            ensure_dir(fullfile(outputs_root, 'stage', stage_name, 'tables'));
            ensure_dir(fullfile(outputs_root, 'logs', stage_name));
        end
    
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

