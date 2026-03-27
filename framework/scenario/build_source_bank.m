function source_bank = build_source_bank(cfg)
%BUILD_SOURCE_BANK Build source definitions from framework config.
%
%   source_bank = BUILD_SOURCE_BANK(cfg)
%
%   The source bank is a lightweight source-definition object used by
%   experiment runners to materialize track registries.

if nargin < 1 || ~isstruct(cfg)
    error('build_source_bank:InvalidInput', ...
        'cfg must be a struct.');
end

if ~isfield(cfg, 'trajectory_registry_def') || ~isstruct(cfg.trajectory_registry_def)
    error('build_source_bank:MissingTrajectoryRegistryDef', ...
        'cfg.trajectory_registry_def must exist.');
end

trd = cfg.trajectory_registry_def;
sources = struct([]);

% source 1: nominal ring
if isfield(trd, 'nominal_spec') && ~isempty(trd.nominal_spec)
    sources(end+1).source_id = "src_nominal_ring"; %#ok<AGROW>
    sources(end).source_type = "pattern";
    sources(end).generator_name = "generate_disk_ring_nominal";
    sources(end).enabled = true;
    sources(end).depends_on = "";
    sources(end).spec = trd.nominal_spec;
end

% source 2: heading bundle
if isfield(trd, 'heading_spec') && ~isempty(trd.heading_spec)
    heading_enabled = false;
    if isfield(trd.heading_spec, 'enabled')
        heading_enabled = logical(trd.heading_spec.enabled);
    end

    sources(end+1).source_id = "src_heading_bundle"; %#ok<AGROW>
    sources(end).source_type = "derived_bundle";
    sources(end).generator_name = "generate_heading_offset_family";
    sources(end).enabled = heading_enabled;
    sources(end).depends_on = "src_nominal_ring";
    sources(end).spec = trd.heading_spec;
end

% source 3: critical explicit tracks
if isfield(trd, 'critical_spec') && ~isempty(trd.critical_spec)
    critical_enabled = false;
    if isfield(trd.critical_spec, 'enabled')
        critical_enabled = logical(trd.critical_spec.enabled);
    end

    sources(end+1).source_id = "src_critical_tracks"; %#ok<AGROW>
    sources(end).source_type = "explicit_track_set";
    sources(end).generator_name = "generate_single_track_set";
    sources(end).enabled = critical_enabled;
    sources(end).depends_on = "";
    sources(end).spec = trd.critical_spec;
end

source_bank = struct();
source_bank.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');
source_bank.sources = sources;
source_bank.source_count = numel(sources);
end
