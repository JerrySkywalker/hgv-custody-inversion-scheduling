function raan_values_deg = build_manual_raan_values(region_phase_spec)
%BUILD_MANUAL_RAAN_VALUES Build manual RAAN sample values from range+step spec.
%
% Required fields:
%   region_phase_spec.range_deg = [start_deg, end_deg]
%   region_phase_spec.step_deg  = scalar positive step
%
% Output:
%   column vector of sampled RAAN values in degrees

if nargin < 1 || isempty(region_phase_spec)
    error('build_manual_raan_values:MissingSpec', 'region_phase_spec is required.');
end

if ~isfield(region_phase_spec, 'range_deg') || numel(region_phase_spec.range_deg) ~= 2
    error('build_manual_raan_values:MissingRange', ...
        'region_phase_spec.range_deg must be a 2-element vector.');
end

if ~isfield(region_phase_spec, 'step_deg') || isempty(region_phase_spec.step_deg)
    error('build_manual_raan_values:MissingStep', ...
        'region_phase_spec.step_deg is required.');
end

range_deg = region_phase_spec.range_deg(:).';
step_deg = region_phase_spec.step_deg;

if step_deg <= 0
    error('build_manual_raan_values:InvalidStep', 'step_deg must be positive.');
end

start_deg = range_deg(1);
end_deg = range_deg(2);

if end_deg < start_deg
    error('build_manual_raan_values:InvalidRange', ...
        'range_deg must satisfy end_deg >= start_deg.');
end

raan_values_deg = (start_deg:step_deg:end_deg).';
if isempty(raan_values_deg) || raan_values_deg(end) ~= end_deg
    % Keep strict manual grid behavior: do not force-append end_deg.
    % The user-specified step controls the actual sampled points.
end
end
