function feats = extract_candidate_local_features(caseData, k, candidate_sets)
%EXTRACT_CANDIDATE_LOCAL_FEATURES
% WS-2-R1
% Batch wrapper around extract_local_frame_geometry.

n = numel(candidate_sets);
feats = struct([]);

for i = 1:n
    ids = candidate_sets{i};
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
