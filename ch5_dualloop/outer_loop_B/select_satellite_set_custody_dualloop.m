function selected_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg)
%SELECT_SATELLITE_SET_CUSTODY_DUALLOOP
% WS-5-R1
% Template-guided reference selection + candidate filtering prototype.

if strcmp(mode, 'safe') && isfield(cfg.ch5, 'ck_safe_fallback_to_C') && cfg.ch5.ck_safe_fallback_to_C
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

match = [];
ref_ids = [];

% ------------------------------------------------
% Reference ids: prior library first, dynamic local template otherwise
% ------------------------------------------------
if isfield(cfg, 'ch5') && isfield(cfg.ch5, 'prior_enable') && cfg.ch5.prior_enable && ...
   isfield(cfg.ch5, 'prior_library') && ~isempty(cfg.ch5.prior_library)

    vis_feat = extract_candidate_local_features(caseData, k, visible_ids(:).');
    query_feat = vis_feat(1);
    match = match_reference_prior(cfg.ch5.prior_library, query_feat);
    ref_ids = match.ref_ids(:).';
else
    ref_ids = select_reference_template_dualloop(caseData, k, cfg);
end

% ------------------------------------------------
% Candidate filtering by template prototype
% ------------------------------------------------
if isfield(cfg, 'ch5') && isfield(cfg.ch5, 'template_filter_enable') && cfg.ch5.template_filter_enable && ...
   ~isempty(match) && isfield(cfg.ch5, 'prior_library') && ~isempty(cfg.ch5.prior_library)

    cand_feats = extract_candidate_local_features(caseData, k, all_mat);
    if isfield(cfg.ch5, 'template_filter_topk') && ~isempty(cfg.ch5.template_filter_topk)
        topK = cfg.ch5.template_filter_topk;
    else
        topK = min(8, numel(cand_feats));
    end

    filt = filter_candidates_by_template(cand_feats, cfg.ch5.prior_library, match, topK);
    all_sets = all_sets(filt.keep_idx);
end

records = cell(1, numel(all_sets));
for i = 1:numel(all_sets)
    ids = all_sets{i};
    [s, detail] = build_window_objective_dualloop(mode, ids, prev_ids, ref_ids, caseData, k, cfg);

    rec = struct();
    rec.ids = ids(:).';
    rec.score = s;
    rec.is_feasible = detail.is_feasible;
    rec.detail = detail;
    records{i} = rec;
end

cand = [records{:}];
scores = [cand.score];
[~, idx] = min(scores);
selected_ids = cand(idx).ids(:).';
end
