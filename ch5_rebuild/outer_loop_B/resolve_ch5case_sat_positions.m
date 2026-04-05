function sat_pos_k = resolve_ch5case_sat_positions(ch5case, k)
%RESOLVE_CH5CASE_SAT_POSITIONS Resolve satellite positions at step k from ch5case.
%
% Returns:
%   sat_pos_k : [3 x Ns]
%
% Preferred candidates:
%   ch5case.satbank.r_eci_km(:,:,k)    or
%   ch5case.satbank.r_eci_km(k,:,:)    or
%   ch5case.satbank.r_eci_km(:, :, k)  depending on storage order

assert(isstruct(ch5case), 'ch5case must be a struct.');
assert(isnumeric(k) && isscalar(k) && k >= 1, 'k invalid.');
assert(isfield(ch5case, 'satbank'), 'ch5case.satbank missing.');

satbank = ch5case.satbank;
assert(isfield(satbank, 'r_eci_km'), 'ch5case.satbank.r_eci_km missing.');

R = satbank.r_eci_km;
sz = size(R);

if ndims(R) ~= 3
    error('ch5case.satbank.r_eci_km must be a 3D array.');
end

% Try [Nt x 3 x Ns]
if numel(sz) == 3 && sz(2) == 3 && k <= sz(1)
    sat_pos_k = squeeze(R(k, :, :));
    if size(sat_pos_k, 1) == 3
        return;
    else
        sat_pos_k = sat_pos_k.';
        return;
    end
end

% Try [3 x Ns x Nt]
if numel(sz) == 3 && sz(1) == 3 && k <= sz(3)
    sat_pos_k = R(:, :, k);
    return;
end

% Try [Ns x 3 x Nt]
if numel(sz) == 3 && sz(2) == 3 && k <= sz(3)
    sat_pos_k = squeeze(R(:, :, k)).';
    return;
end

error('Unable to resolve satellite positions from ch5case.satbank.r_eci_km.');
end
