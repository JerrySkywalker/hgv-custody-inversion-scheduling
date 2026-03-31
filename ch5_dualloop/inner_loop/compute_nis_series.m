function nis_series = compute_nis_series(varargin)
%COMPUTE_NIS_SERIES  Compute NIS series from either a packaged inner-loop struct
%or from raw innovation / covariance series.
%
% Supported calls:
%   nis_series = compute_nis_series(inner_struct)
%   nis_series = compute_nis_series(nu_series, S_series)
%
% Accepted struct field aliases:
%   innovation / innovations / nu / nu_series
%   S / S_series / innovation_cov / innovation_cov_series
%   nis / nis_series
%
% Output:
%   nis_series : [N x 1]

if nargin < 1
    error('compute_nis_series requires at least one input.');
end

% ------------------------------------------------------------
% Mode A: already-packaged inner-loop struct
% ------------------------------------------------------------
if nargin == 1 && isstruct(varargin{1})
    inner = varargin{1};

    % 1) If NIS already exists, return it directly
    nis_field_candidates = {'nis_series', 'nis'};
    for i = 1:numel(nis_field_candidates)
        fn = nis_field_candidates{i};
        if isfield(inner, fn) && ~isempty(inner.(fn))
            nis_series = inner.(fn)(:);
            return;
        end
    end

    % 2) Otherwise find innovation and covariance fields
    nu = [];
    S = [];

    nu_field_candidates = {'innovation', 'innovations', 'nu', 'nu_series', 'innovation_series'};
    for i = 1:numel(nu_field_candidates)
        fn = nu_field_candidates{i};
        if isfield(inner, fn) && ~isempty(inner.(fn))
            nu = inner.(fn);
            break;
        end
    end

    S_field_candidates = {'S', 'S_series', 'innovation_cov', 'innovation_cov_series', 'innovation_covariance'};
    for i = 1:numel(S_field_candidates)
        fn = S_field_candidates{i};
        if isfield(inner, fn) && ~isempty(inner.(fn))
            S = inner.(fn);
            break;
        end
    end

    if isempty(nu) || isempty(S)
        error(['compute_nis_series: struct input does not contain usable NIS data. ', ...
               'Expected existing nis_series, or innovation + covariance fields.']);
    end

    nis_series = local_compute_from_raw(nu, S);
    return;
end

% ------------------------------------------------------------
% Mode B: raw series input
% ------------------------------------------------------------
if nargin == 2
    nu = varargin{1};
    S = varargin{2};
    nis_series = local_compute_from_raw(nu, S);
    return;
end

error('Unsupported call pattern for compute_nis_series.');
end

function nis_series = local_compute_from_raw(nu_series, S_series)
%LOCAL_COMPUTE_FROM_RAW  Compute NIS from raw innovation and covariance series.

% Normalize innovation shape:
%   accepted:
%     [N x m]
%     [m x N]
if ndims(nu_series) ~= 2
    error('nu_series must be a 2-D array.');
end

if ndims(S_series) ~= 3
    error('S_series must be a 3-D array of size [m x m x N].');
end

[m1, m2, N] = size(S_series);
if m1 ~= m2
    error('Each covariance slice in S_series must be square.');
end

% Convert nu_series to [N x m]
if size(nu_series, 1) == N && size(nu_series, 2) == m1
    nuN = nu_series;
elseif size(nu_series, 2) == N && size(nu_series, 1) == m1
    nuN = nu_series.';
else
    error('nu_series size is incompatible with S_series.');
end

nis_series = zeros(N, 1);

for k = 1:N
    nu = nuN(k, :).';
    S = S_series(:, :, k);

    % Symmetrize for safety
    S = 0.5 * (S + S.');

    % Robust solve; fall back to pinv if needed
    if all(isfinite(S), 'all') && rcond(S) > 1e-12
        nis_series(k) = real(nu' * (S \ nu));
    else
        nis_series(k) = real(nu' * (pinv(S) * nu));
    end
    if ~isfinite(nis_series(k))
        nis_series(k) = 0;
    end
end
end
