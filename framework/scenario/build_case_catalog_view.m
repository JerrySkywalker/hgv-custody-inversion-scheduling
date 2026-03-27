function casebank_view = build_case_catalog_view(registry)
%BUILD_STAGE01_CASEBANK_VIEW Build legacy-compatible Stage01 casebank view.
%
%   casebank_view.meta
%   casebank_view.nominal
%   casebank_view.heading
%   casebank_view.critical

if ~isstruct(registry) || ~isfield(registry, 'items') || ~istable(registry.items)
    error('build_stage01_casebank_view:InvalidRegistry', ...
        'registry must be a valid trajectory registry struct.');
end

items = registry.items;

casebank_view = struct();
casebank_view.meta = struct();
casebank_view.meta.registry_name = char(registry.registry_name);
casebank_view.meta.created_at = registry.created_at;
casebank_view.meta.total_count = height(items);

casebank_view.nominal = convert_subset(items(string(items.class_name) == "nominal", :));
casebank_view.heading = convert_subset(items(string(items.class_name) == "heading", :));
casebank_view.critical = convert_subset(items(string(items.class_name) == "critical", :));
end

function cases = convert_subset(tbl)
n = height(tbl);
cases = repmat(struct(), n, 1);

for k = 1:n
    row = tbl(k,:);
    payload = row.payload{1};

    cases(k).case_id = char(string(row.traj_id));
    cases(k).family = map_family(row);
    cases(k).subfamily = map_subfamily(row);

    cases(k).entry_theta_deg = get_payload_field(payload, 'entry_theta_deg', NaN);
    cases(k).heading_deg = get_payload_field(payload, 'heading_deg', NaN);
    cases(k).heading_offset_deg = get_payload_field(payload, 'heading_offset_deg', NaN);
    cases(k).entry_point_xy_km = get_payload_field(payload, 'entry_point_xy_km', [NaN, NaN]);
    cases(k).heading_unit_xy = get_payload_field(payload, 'heading_unit_xy', [NaN, NaN]);

    cases(k).class_name = char(string(row.class_name));
    cases(k).bundle_id = char(string(row.bundle_id));
    cases(k).base_traj_id = char(string(row.base_traj_id));
    cases(k).sample_id = row.sample_id;
    cases(k).variation_kind = char(string(row.variation_kind));
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
