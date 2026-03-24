function paths = make_experiment_paths()
repo_root = fileparts(fileparts(mfilename('fullpath')));
paths = struct();
paths.repo_root = repo_root;
paths.outputs_root = fullfile(repo_root, 'outputs', 'experiments');
end
