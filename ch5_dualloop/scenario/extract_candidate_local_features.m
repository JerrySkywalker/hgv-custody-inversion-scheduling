function feats = extract_candidate_local_features(caseData, k, candidate_sets)
%EXTRACT_CANDIDATE_LOCAL_FEATURES
% WS-2-R1
% Batch wrapper around extract_local_frame_geometry.
%
% Supported candidate_sets input forms:
%   1) cell array, each cell is an id vector
%   2) numeric matrix, each row is a candidate id vector (zeros/NaN ignored)
%   3) struct array with field 'ids'
%   4) single numeric vector

n = local_num_candidates(candidate_sets);
feats = struct([]);

for i = 1:n
    ids = local_get_ids(candidate_sets, i);
    g = extract_local_frame_geometry(caseData, k, ids);

    rec = struct();
    rec.k = k;
    rec.ids = ids(:).';
    rec.num_sats = g.num_sats;
    rec.baseline_km = g.baseline_km;
    rec.Bxy_cand = g.Bxy_cand;
    rec.Ruse = g.Ruse;
    rec.xy_radius_km = g.xy_radius_km;
    rec.rel_local_km = g.rel_local_km;
    rec.target_r_eci_km = g.target_r_eci_km;
    feats(i) = rec; %#ok<AGROW>
end
end

function n = local_num_candidates(candidate_sets)
if iscell(candidate_sets)
    n = numel(candidate_sets);
elseif isstruct(candidate_sets)
    n = numel(candidate_sets);
elseif isnumeric(candidate_sets)
    if isvector(candidate_sets)
        n = 1;
    else
        n = size(candidate_sets, 1);
    end
else
    error('Unsupported candidate_sets type.');
end
end

function ids = local_get_ids(candidate_sets, i)
if iscell(candidate_sets)
    ids = candidate_sets{i};

elseif isstruct(candidate_sets)
    assert(isfield(candidate_sets, 'ids'), 'Struct candidate_sets must contain field ''ids''.');
    ids = candidate_sets(i).ids;

elseif isnumeric(candidate_sets)
    if isvector(candidate_sets)
        ids = candidate_sets;
    else
        ids = candidate_sets(i, :);
    end

    ids = ids(isfinite(ids));
    ids = ids(ids > 0);

else
    error('Unsupported candidate_sets type.');
end

ids = unique(ids(:).', 'stable');
assert(~isempty(ids), 'Empty candidate ids after normalization.');
end
