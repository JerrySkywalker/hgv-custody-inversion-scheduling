function info = load_latest_stage08_5_result(cache_dir, run_tag_hint)
%LOAD_LATEST_STAGE08_5_RESULT
% Load the latest Stage08.5 cache and extract the recommended Tw.
%
% Usage:
%   info = load_latest_stage08_5_result(cfg.paths.cache, '');
%   info = load_latest_stage08_5_result(cfg.paths.cache, 'twscan');
%
% Output fields:
%   info.cache_file
%   info.out
%   info.recommendation_table
%   info.final_summary_table
%   info.recommended_row
%   info.Tw_star
%   info.run_tag_hint

    if nargin < 1 || isempty(cache_dir)
        error('cache_dir is required.');
    end
    if nargin < 2
        run_tag_hint = '';
    end

    if ~isfolder(cache_dir)
        error('Cache directory does not exist: %s', cache_dir);
    end

    % ------------------------------------------------------------
    % locate cache file
    % ------------------------------------------------------------
    patterns = {};
    if ~isempty(run_tag_hint)
        patterns{end+1} = sprintf('stage08_finalize_window_selection_%s_*.mat', run_tag_hint); %#ok<AGROW>
    end
    patterns{end+1} = 'stage08_finalize_window_selection_*.mat';

    hit = [];
    hit_file = '';

    for i = 1:numel(patterns)
        listing = find_stage_cache_files(cache_dir, patterns{i});
        if ~isempty(listing)
            [~, idx] = max([listing.datenum]);
            hit = listing(idx);
            hit_file = fullfile(hit.folder, hit.name);
            break;
        end
    end

    if isempty(hit)
        error('No Stage08.5 cache found under: %s', cache_dir);
    end

    % ------------------------------------------------------------
    % load and extract out struct
    % ------------------------------------------------------------
    S = load(hit_file);
    out = local_extract_out_struct(S);
    if ~isstruct(out)
        error('Invalid Stage08.5 cache: %s', hit_file);
    end

    recommendation_table = local_get_table_field(out, {'recommendation_table'});
    final_summary_table  = local_get_table_field(out, {'final_summary_table'});

    if ~istable(recommendation_table) || height(recommendation_table) < 1
        error('Stage08.5 cache has no valid recommendation_table: %s', hit_file);
    end

    % ------------------------------------------------------------
    % resolve recommended row
    % ------------------------------------------------------------
    rec_idx = [];

    if any(strcmp(recommendation_table.Properties.VariableNames, 'is_recommended'))
        idx = find(recommendation_table.is_recommended, 1, 'first');
        if ~isempty(idx)
            rec_idx = idx;
        end
    end

    if isempty(rec_idx)
        rec_idx = 1;
    end

    recommended_row = recommendation_table(rec_idx, :);

    if ~any(strcmp(recommendation_table.Properties.VariableNames, 'Tw_s'))
        error('recommendation_table does not contain Tw_s.');
    end

    Tw_star = recommended_row.Tw_s(1);

    info = struct();
    info.cache_file = hit_file;
    info.out = out;
    info.recommendation_table = recommendation_table;
    info.final_summary_table = final_summary_table;
    info.recommended_row = recommended_row;
    info.Tw_star = Tw_star;
    info.run_tag_hint = string(run_tag_hint);
end


function out_struct = local_extract_out_struct(S)

    names = fieldnames(S);
    out_struct = [];

    if isfield(S, 'out') && isstruct(S.out)
        out_struct = S.out;
        return;
    end

    for i = 1:numel(names)
        if isstruct(S.(names{i}))
            out_struct = S.(names{i});
            return;
        end
    end
end


function T = local_get_table_field(out, candidate_names)

    T = table();
    if ~isstruct(out)
        return;
    end

    for i = 1:numel(candidate_names)
        name = candidate_names{i};
        if isfield(out, name) && istable(out.(name))
            T = out.(name);
            return;
        end
    end
end
