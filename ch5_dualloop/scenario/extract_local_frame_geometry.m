function geom = extract_local_frame_geometry(caseData, k, selected_ids)
%EXTRACT_LOCAL_FRAME_GEOMETRY
% WS-2-R1
% Build a target-centered local orthonormal frame from ECI state and
% extract relative candidate geometry for the selected satellite set.
%
% Outputs:
%   geom.k
%   geom.selected_ids
%   geom.target_r_eci_km
%   geom.target_v_eci_kmps
%   geom.target_frame_R   % columns = [e_theta, e_h, e_r]
%   geom.sat_r_eci_km
%   geom.rel_eci_km
%   geom.rel_local_km
%   geom.xy_radius_km
%   geom.baseline_km
%   geom.Bxy_cand
%   geom.Ruse
%   geom.num_sats

assert(isfield(caseData, 'truth') && isfield(caseData.truth, 'r_eci_km'), ...
    'caseData.truth.r_eci_km is required.');
assert(isfield(caseData.truth, 'vx') && isfield(caseData.truth, 'vy') && isfield(caseData.truth, 'vz'), ...
    'caseData.truth.vx/vy/vz are required.');
assert(isfield(caseData, 'satbank') && isfield(caseData.satbank, 'r_eci_km'), ...
    'caseData.satbank.r_eci_km is required.');

selected_ids = selected_ids(:).';
num_sats = numel(selected_ids);

tgt_r = caseData.truth.r_eci_km(k, :).';
tgt_v = [caseData.truth.vx(k); caseData.truth.vy(k); caseData.truth.vz(k)];

[e_theta, e_h, e_r] = local_build_target_frame(tgt_r, tgt_v);
R = [e_theta, e_h, e_r];

sat_pos = local_extract_sat_positions(caseData.satbank.r_eci_km, k, selected_ids);
rel_eci = sat_pos - tgt_r.';
rel_local = (R.' * rel_eci.').';

xy_radius = sqrt(rel_local(:,1).^2 + rel_local(:,2).^2);

baseline_km = 0.0;
if num_sats >= 2
    for i = 1:num_sats
        for j = i+1:num_sats
            baseline_km = max(baseline_km, norm(sat_pos(i,:) - sat_pos(j,:)));
        end
    end
end

Bxy_cand = 0.0;
if ~isempty(xy_radius)
    Bxy_cand = max(xy_radius);
end

geom = struct();
geom.k = k;
geom.selected_ids = selected_ids;
geom.target_r_eci_km = tgt_r;
geom.target_v_eci_kmps = tgt_v;
geom.target_frame_R = R;
geom.sat_r_eci_km = sat_pos;
geom.rel_eci_km = rel_eci;
geom.rel_local_km = rel_local;
geom.xy_radius_km = xy_radius;
geom.baseline_km = baseline_km;
geom.Bxy_cand = Bxy_cand;
geom.Ruse = Bxy_cand;
geom.num_sats = num_sats;
end

function [e_theta, e_h, e_r] = local_build_target_frame(r, v)
e_r = r / max(norm(r), eps);

h = cross(r, v);
if norm(h) < 1e-9
    zref = [0;0;1];
    h = cross(r, zref);
    if norm(h) < 1e-9
        xref = [1;0;0];
        h = cross(r, xref);
    end
end
e_h = h / max(norm(h), eps);

e_theta = cross(e_h, e_r);
e_theta = e_theta / max(norm(e_theta), eps);
end

function pos = local_extract_sat_positions(Rsat, k, ids)
% Support common layouts:
%   [Nt, Ns, 3]
%   [3, Ns, Nt]
%   [Nt, 3, Ns]
%   [Ns, Nt, 3]

sz = size(Rsat);
nd = ndims(Rsat);
assert(nd == 3, 'satbank.r_eci_km must be a 3-D array.');

pos = [];

% Case 1: [Nt, Ns, 3]
if sz(3) == 3 && k <= sz(1) && max(ids) <= sz(2)
    tmp = squeeze(Rsat(k, ids, :));
    if size(tmp,2) == 3
        pos = tmp;
        return
    end
end

% Case 2: [3, Ns, Nt]
if sz(1) == 3 && max(ids) <= sz(2) && k <= sz(3)
    tmp = squeeze(Rsat(:, ids, k)).';
    if size(tmp,2) == 3
        pos = tmp;
        return
    end
end

% Case 3: [Nt, 3, Ns]
if sz(2) == 3 && k <= sz(1) && max(ids) <= sz(3)
    tmp = squeeze(Rsat(k, :, ids)).';
    if size(tmp,2) == 3
        pos = tmp;
        return
    end
end

% Case 4: [Ns, Nt, 3]
if sz(3) == 3 && max(ids) <= sz(1) && k <= sz(2)
    tmp = squeeze(Rsat(ids, k, :));
    if size(tmp,2) == 3
        pos = tmp;
        return
    end
end

error('Unsupported satbank.r_eci_km layout for current extractor.');
end
