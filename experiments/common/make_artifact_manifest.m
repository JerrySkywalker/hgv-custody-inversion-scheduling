function manifest = make_artifact_manifest(experiment_name, artifacts)
if nargin < 2
    error('make_artifact_manifest:InvalidInput', ...
        'experiment_name and artifacts are required.');
end

if ~iscell(artifacts)
    artifacts = {artifacts};
end

manifest = struct();
manifest.experiment_name = experiment_name;
manifest.artifact_count = numel(artifacts);
manifest.artifacts = artifacts;
manifest.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');
manifest.meta = struct('status', 'ok');
end
