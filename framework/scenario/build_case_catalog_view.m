function casebank_view = build_case_catalog_view(registry)
%BUILD_CASE_CATALOG_VIEW Build legacy-compatible case catalog view from registry.

if ~isstruct(registry) || ~isfield(registry, 'items') || ~istable(registry.items)
    error('build_case_catalog_view:InvalidRegistry', ...
        'registry must be a valid trajectory registry struct.');
end

items = registry.items;

casebank_view = struct();
casebank_view.meta = build_meta(items, registry);
casebank_view.nominal = convert_subset(items(string(items.class_name) == "nominal", :));
casebank_view.heading = convert_subset(items(string(items.class_name) == "heading", :));
casebank_view.critical = convert_subset(items(string(items.class_name) == "critical", :));
end

function meta = build_meta(items, registry)
meta = struct();
meta.registry_name = char(registry.registry_name);
meta.created_at = registry.created_at;
meta.total_count = height(items);

if isempty(items)
    meta.scene_mode = '';
    meta.anchor_lat_deg = NaN;
    meta.anchor_lon_deg = NaN;
    meta.anchor_h_m = NaN;
    return;
end

payload = items.payload{1};
meta.scene_mode = get_payload_field(payload, 'scene_mode', '');
meta.anchor_lat_deg = get_payload_field(payload, 'anchor_lat_deg', NaN);
meta.anchor_lon_deg = get_payload_field(payload, 'anchor_lon_deg', NaN);
meta.anchor_h_m = get_payload_field(payload, 'anchor_h_m', NaN);
end

function cases = convert_subset(tbl)
n = height(tbl);
cases = repmat(struct(), n, 1);

for k = 1:n
    row = tbl(k,:);
    payload = row.payload{1};

    cases(k).case_id = map_case_id(row);
    cases(k).internal_id = char(string(row.traj_id));
    cases(k).family = map_family(row);
    cases(k).subfamily = map_subfamily(row);

    cases(k).entry_theta_deg = get_payload_field(payload, 'entry_theta_deg', NaN);
    cases(k).heading_deg = get_payload_field(payload, 'heading_deg', NaN);
    cases(k).heading_offset_deg = get_payload_field(payload, 'heading_offset_deg', NaN);

    cases(k).entry_point_xy_km = get_payload_field(payload, 'entry_point_xy_km', [NaN, NaN]);
    cases(k).heading_unit_xy = get_payload_field(payload, 'heading_unit_xy', [NaN, NaN]);

    cases(k).entry_point_enu_km = get_payload_field(payload, 'entry_point_enu_km', [NaN, NaN]);
    cases(k).entry_point_enu_m = get_payload_field(payload, 'entry_point_enu_m', [NaN, NaN]);
    cases(k).heading_unit_enu = get_payload_field(payload, 'heading_unit_enu', [NaN, NaN]);

    cases(k).scene_mode = get_payload_field(payload, 'scene_mode', '');
    cases(k).anchor_lat_deg = get_payload_field(payload, 'anchor_lat_deg', NaN);
    cases(k).anchor_lon_deg = get_payload_field(payload, 'anchor_lon_deg', NaN);
    cases(k).anchor_h_m = get_payload_field(payload, 'anchor_h_m', NaN);

    cases(k).class_name = char(string(row.class_name));
    cases(k).bundle_id = char(string(row.bundle_id));
    cases(k).base_traj_id = char(string(row.base_traj_id));
    cases(k).sample_id = row.sample_id;
    cases(k).variation_kind = char(string(row.variation_kind));
end
end

function case_id = map_case_id(row)
traj_id = char(string(row.traj_id));
class_name = string(row.class_name);

switch class_name
    case "nominal"
        tok = regexp(traj_id, '^traj_nominal_(\d+)$', 'tokens', 'once');
        if ~isempty(tok)
            idx = str2double(tok{1});
            case_id = sprintf('N%02d', idx);
        else
            case_id = traj_id;
        end

    case "heading"
        tok = regexp(traj_id, '^traj_nominal_(\d+)_h([+-]\d+)$', 'tokens', 'once');
        if ~isempty(tok)
            idx = str2double(tok{1});
            off = str2double(tok{2});
            case_id = sprintf('H%02d_%+04d', idx, off);
        else
            case_id = traj_id;
        end

    case "critical"
        case_id = traj_id;

    otherwise
        case_id = traj_id;
end
end

function family = map_family(row)
class_name = string(row.class_name);
switch class_name
    case "nominal"
        family = 'nominal';
    case "heading"
        family = 'heading';
    case "critical"
        family = 'critical';
    otherwise
        family = char(class_name);
end
end

function subfamily = map_subfamily(row)
class_name = string(row.class_name);
variation_kind = string(row.variation_kind);
bundle_id = string(row.bundle_id);

switch class_name
    case "nominal"
        subfamily = 'nominal';
    case "heading"
        subfamily = 'heading';
    case "critical"
        if strlength(variation_kind) > 0
            subfamily = char(variation_kind);
        else
            subfamily = char(bundle_id);
        end
    otherwise
        if strlength(variation_kind) > 0
            subfamily = char(variation_kind);
        else
            subfamily = char(bundle_id);
        end
end
end

function value = get_payload_field(payload, field_name, default_value)
if isstruct(payload) && isfield(payload, field_name)
    value = payload.(field_name);
else
    value = default_value;
end
end
