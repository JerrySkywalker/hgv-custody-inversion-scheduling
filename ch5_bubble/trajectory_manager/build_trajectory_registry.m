function registry = build_trajectory_registry(cfg)
%BUILD_TRAJECTORY_REGISTRY Build trajectory registry for ch5_bubble.
%
% Current preferred path:
%   manual recipes -> registry
%
% Legacy path:
%   stage01 casebank -> registry

if nargin < 1 || isempty(cfg)
    cfg = default_ch5b_params();
end

switch lower(cfg.trajectory.source_mode)
    case 'manual_recipe'
        recipes = default_ch5b_trajectory_recipes(cfg);

        samples = struct([]);
        for k = 1:numel(recipes)
            r = recipes(k);
            samples(k).sample_id = r.case_id; %#ok<AGROW>
            samples(k).family_id = upper(r.family); %#ok<AGROW>
            samples(k).case_label = r.case_id; %#ok<AGROW>
            samples(k).source_tag = 'manual_recipe'; %#ok<AGROW>
            samples(k).family_name = r.family; %#ok<AGROW>
            samples(k).subfamily = r.subfamily; %#ok<AGROW>
            samples(k).heading_deg = r.heading_deg; %#ok<AGROW>
            samples(k).heading_offset_deg = r.heading_offset_deg; %#ok<AGROW>
            samples(k).entry_theta_deg = NaN; %#ok<AGROW>
        end

        registry = struct();
        registry.framework = 'ch5_bubble';
        registry.phase = 'B1';
        registry.version = 'phaseB1_registry_manual_recipe';
        registry.source_mode = 'manual_recipe';
        registry.source_cache_file = '';
        registry.sample_count = numel(samples);
        registry.samples = samples;
        registry.family_ids = unique({samples.family_id});
        registry.sample_ids = {samples.sample_id};
        registry.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');

    case 'stage01_casebank'
        [casebank, stage01_file] = load_stage01_casebank_ch5b(cfg);

        all_records = struct([]);
        idx = 0;

        if isfield(casebank, 'nominal')
            [all_records, idx] = local_append_family(all_records, idx, casebank.nominal, 'nominal');
        end
        if isfield(casebank, 'heading')
            [all_records, idx] = local_append_family(all_records, idx, casebank.heading, 'heading');
        end
        if isfield(casebank, 'critical')
            [all_records, idx] = local_append_family(all_records, idx, casebank.critical, 'critical');
        end

        registry = struct();
        registry.framework = 'ch5_bubble';
        registry.phase = 'B1';
        registry.version = 'phaseB1_registry_real_stage01';
        registry.source_mode = 'stage01_casebank';
        registry.source_cache_file = stage01_file;
        registry.sample_count = numel(all_records);
        registry.samples = all_records;
        registry.family_ids = unique({all_records.family_id});
        registry.sample_ids = {all_records.sample_id};
        registry.created_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');

    otherwise
        error('build_trajectory_registry:UnsupportedSourceMode', ...
            'Unsupported cfg.trajectory.source_mode = %s', cfg.trajectory.source_mode);
end

end

function [all_records, idx] = local_append_family(all_records, idx, family_struct, family_name)

for k = 1:numel(family_struct)
    case_i = family_struct(k);

    idx = idx + 1;
    all_records(idx).sample_id = case_i.case_id; %#ok<AGROW>
    all_records(idx).family_id = upper(char(string(local_get_field(case_i, 'family', family_name)))); %#ok<AGROW>
    all_records(idx).case_label = case_i.case_id; %#ok<AGROW>
    all_records(idx).source_tag = 'stage01_casebank'; %#ok<AGROW>
    all_records(idx).family_name = family_name; %#ok<AGROW>
    all_records(idx).subfamily = local_get_field(case_i, 'subfamily', ''); %#ok<AGROW>
    all_records(idx).heading_deg = local_get_field(case_i, 'heading_deg', NaN); %#ok<AGROW>
    all_records(idx).heading_offset_deg = local_get_field(case_i, 'heading_offset_deg', NaN); %#ok<AGROW>
    all_records(idx).entry_theta_deg = local_get_field(case_i, 'entry_theta_deg', NaN); %#ok<AGROW>
end

end

function v = local_get_field(s, name, defaultv)
if isfield(s, name)
    v = s.(name);
else
    v = defaultv;
end
end
