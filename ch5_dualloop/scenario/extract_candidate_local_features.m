function feats = extract_candidate_local_features(caseData, k, candidate_sets)
%EXTRACT_CANDIDATE_LOCAL_FEATURES
% WS-2-R1
% Batch wrapper around extract_local_frame_geometry.
%
% Supported candidate_sets input forms:
%   1) cell array, each cell is an id vector or mask vector
%   2) numeric matrix, each row is either:
%        - an id vector
%        - or a 0/1 mask over Ns satellites
%   3) struct array with field 'ids' or 'mask'
%   4) single numeric vector (ids or mask)

assert(isfield(caseData, 'satbank') && isfield(caseData.satbank, 'Ns'), ...
    'caseData.satbank.Ns is required.');

Ns = caseData.satbank.Ns;
n = local_num_candidates(candidate_sets);
feats = struct([]);

for i = 1:n
    ids = local_get_ids(candidate_sets, i, Ns);
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
elseif isnumeric(candidate_sets) || islogical(candidate_sets)
    if isvector(candidate_sets)
        n = 1;
    else
        n = size(candidate_sets, 1);
    end
else
    error('Unsupported candidate_sets type.');
end
end

function ids = local_get_ids(candidate_sets, i, Ns)
if iscell(candidate_sets)
    row = candidate_sets{i};
    ids = local_normalize_row(row, Ns);

elseif isstruct(candidate_sets)
    if isfield(candidate_sets, 'ids')
        row = candidate_sets(i).ids;
        ids = local_normalize_row(row, Ns);
    elseif isfield(candidate_sets, 'mask')
        row = candidate_sets(i).mask;
        ids = local_normalize_row(row, Ns);
    else
        error('Struct candidate_sets must contain field ''ids'' or ''mask''.');
    end

elseif isnumeric(candidate_sets) || islogical(candidate_sets)
    if isvector(candidate_sets)
        row = candidate_sets;
    else
        row = candidate_sets(i, :);
    end
    ids = local_normalize_row(row, Ns);

else
    error('Unsupported candidate_sets type.');
end

ids = unique(ids(:).', 'stable');
assert(~isempty(ids), 'Empty candidate ids after normalization.');
end

function ids = local_normalize_row(row, Ns)
row = row(:).';

if isempty(row)
    ids = [];
    return
end

if islogical(row)
    ids = find(row);
    return
end

row = row(isfinite(row));

if isempty(row)
    ids = [];
    return
end

% Case A: binary / occupancy mask over Ns satellites
is_binary = all(row == 0 | row == 1);
if numel(row) == Ns && is_binary
    ids = find(row > 0);
    return
end

% Case B: sparse positive mask-like row (same width as Ns, but maybe nonlogical numeric)
if numel(row) == Ns && all(row >= 0) && nnz(row > 0) <= Ns
    vals = unique(row(row > 0));
    if all(vals == 1)
        ids = find(row > 0);
        return
    end
end

% Case C: explicit id list
row = row(row > 0);
ids = row;
end
