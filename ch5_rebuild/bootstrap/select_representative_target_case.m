function target_case = select_representative_target_case(cfg, stage04_info, stage05_info)
%SELECT_REPRESENTATIVE_TARGET_CASE  Select representative target case for R0.

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end

target_case = struct();
target_case.family = 'nominal';
target_case.case_id = cfg.ch5r.bootstrap.default_case_id;
target_case.source = 'fallback_default';

if isfield(cfg, 'stage04') && isfield(cfg.stage04, 'example_case_id')
    if ~isempty(cfg.stage04.example_case_id)
        target_case.case_id = cfg.stage04.example_case_id;
        target_case.source = 'cfg.stage04.example_case_id';
    end
end

if isstruct(stage05_info) && isfield(stage05_info, 'feasible_table') && istable(stage05_info.feasible_table)
    T = stage05_info.feasible_table;
    if ~isempty(T) && ismember('case_id', T.Properties.VariableNames)
        val = T.case_id(1);
        if iscell(val)
            target_case.case_id = val{1};
        else
            target_case.case_id = char(string(val));
        end
        target_case.source = 'stage05_feasible_table_first_case';
    end
end

if isstruct(stage04_info) && isfield(stage04_info, 'found') && stage04_info.found
    target_case.stage04_cache_file = stage04_info.file;
end
if isstruct(stage05_info) && isfield(stage05_info, 'found') && stage05_info.found
    target_case.stage05_cache_file = stage05_info.file;
end
end
