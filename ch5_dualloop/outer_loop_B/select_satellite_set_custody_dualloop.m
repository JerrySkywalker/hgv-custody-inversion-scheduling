function selected_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg)
%SELECT_SATELLITE_SET_CUSTODY_DUALLOOP
% Safe fallback to C; warn/trigger use feasible-set filtering then direct scoring.
%
% WS-4-R1:
%   - if prior is enabled, build a local-frame query feature and match a
%     reference template from prior library
%   - otherwise fall back to dynamic local template selection

if strcmp(mode, 'safe') && cfg.ch5.ck_safe_fallback_to_C
    selected_ids = select_satellite_set_custody(caseData, k, prev_ids, cfg);
    return
end

visible_ids = find(caseData.candidates.visible_mask(k, :) > 0);
if isempty(visible_ids)
    selected_ids = [];
    return
end

switch mode
    case 'warn'
        if isfield(cfg.ch5, 'ck_warn_cardinality') && ~isempty(cfg.ch5.ck_warn_cardinality)
            card = cfg.ch5.ck_warn_cardinality;
        else
            card = 2;
        end
    case 'trigger'
        if isfield(cfg.ch5, 'ck_trigger_cardinality') && ~isempty(cfg.ch5.ck_trigger_cardinality)
            card = cfg.ch5.ck_trigger_cardinality;
        else
            card = 2;
        end
    otherwise
        card = 2;
end

if numel(visible_ids) <= card
    selected_ids = visible_ids(:).';
    return
end

all_mat = nchoosek(visible_ids(:).', card);
all_sets = cell(size(all_mat,1),1);
for i = 1:size(all_mat,1)
    all_sets{i} = all_mat(i,:);
end

% Reference ids: prior library first, dynamic local template otherwise
if isfield(cfg.ch5, 'prior_enable') && cfg.ch5.prior_enable && ...
   isfield(cfg.ch5, 'prior_library') && ~isempty(cfg.ch5.prior_library)

    vis_feats = extract_candidate_local_features(caseData, k, visible_ids(:).');
    query_feat = vis_feats(1);
    m = match_reference_prior(cfg.ch5.prior_library, query_feat);
    ref_ids = m.ref_ids(:).';

else
    ref_ids = select_reference_template_dualloop(caseData, k, cfg);
end

records = struct('ids', {}, 'score', {}, 'is_feasible', {}, 'detail', {});
for i = 1:numel(all_sets)
    ids = all_sets{i};
    [s, detail] = build_window_objective_dualloop(mode, ids, prev_ids, ref_ids, caseData, k, cfg);

    rec = struct();
    rec.ids = ids(:).';
    rec.score = s;
    rec.is_feasible = detail.is_feasible;
    rec.detail = detail;
    records(end+1) = rec; %#ok<AGROW>
end

cand = records;
scores = [cand.score];
[~, idx] = min(scores);
selected_ids = cand(idx).ids(:).';
end
