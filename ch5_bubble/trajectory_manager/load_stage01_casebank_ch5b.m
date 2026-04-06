function [casebank, stage01_file] = load_stage01_casebank_ch5b(cfg)
%LOAD_STAGE01_CASEBANK_CH5B Load latest Stage01 casebank for ch5_bubble.
%
% Strategy:
%   - recursively scan outputs for stage01_scenario_disk*.mat
%   - choose the newest file
%   - require tmp.out.casebank format

if nargin < 1 || isempty(cfg)
    cfg = default_ch5b_params();
end

persistent cached_root cached_file cached_casebank

root_dir = cfg.path.root_dir;
if ~isempty(cached_root) && strcmp(cached_root, root_dir) && ...
        ~isempty(cached_file) && exist(cached_file, 'file') == 2
    casebank = cached_casebank;
    stage01_file = cached_file;
    return;
end

found = dir(fullfile(root_dir, 'outputs', '**', 'stage01_scenario_disk*.mat'));
assert(~isempty(found), ...
    'load_stage01_casebank_ch5b:Stage01CacheNotFound', ...
    'No Stage01 cache file matching stage01_scenario_disk*.mat was found under outputs/.');

[~, idx] = max([found.datenum]);
stage01_file = fullfile(found(idx).folder, found(idx).name);

tmp = load(stage01_file, 'out');
assert(isfield(tmp, 'out') && isfield(tmp.out, 'casebank'), ...
    'load_stage01_casebank_ch5b:InvalidStage01Cache', ...
    'Invalid Stage01 cache format: missing out.casebank');

casebank = tmp.out.casebank;

cached_root = root_dir;
cached_file = stage01_file;
cached_casebank = casebank;
end
