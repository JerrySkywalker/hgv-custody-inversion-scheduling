function cfg = configure_stage_output_paths(cfg, project_stage)
%CONFIGURE_STAGE_OUTPUT_PATHS Resolve stage-scoped output folders.

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end
if nargin < 2 || isempty(project_stage)
    if isfield(cfg, 'project_stage') && ~isempty(cfg.project_stage)
        project_stage = cfg.project_stage;
    else
        project_stage = local_infer_project_stage();
    end
end

project_stage = char(string(project_stage));
stage_bucket = local_extract_stage_bucket(project_stage);
stage_root = fullfile(cfg.paths.stage_outputs, stage_bucket);

cfg.project_stage = project_stage;
cfg.paths.stage_bucket = stage_bucket;
cfg.paths.stage_root = stage_root;
cfg.paths.stage_cache = fullfile(stage_root, 'cache');
cfg.paths.stage_figs = fullfile(stage_root, 'figs');
cfg.paths.stage_tables = fullfile(stage_root, 'tables');
cfg.paths.stage_logs = fullfile(cfg.paths.log_outputs, stage_bucket);

% Deprecated compatibility fields now point at the stage-scoped layout.
cfg.paths.results = stage_root;
cfg.paths.cache = cfg.paths.stage_cache;
cfg.paths.figs = cfg.paths.stage_figs;
cfg.paths.tables = cfg.paths.stage_tables;
cfg.paths.logs = cfg.paths.stage_logs;
end

function project_stage = local_infer_project_stage()
project_stage = 'stage00_bootstrap';
stack = dbstack('-completenames');
for k = 2:numel(stack)
    name = stack(k).name;
    token = regexp(name, '(stage\d{2}[A-Za-z0-9_]*)', 'match', 'once');
    if ~isempty(token)
        project_stage = token;
        return;
    end
end
end

function stage_bucket = local_extract_stage_bucket(project_stage)
token = regexp(char(string(project_stage)), '(stage\d{2})', 'tokens', 'once');
if isempty(token)
    stage_bucket = 'stage_misc';
else
    stage_bucket = token{1};
end
end
