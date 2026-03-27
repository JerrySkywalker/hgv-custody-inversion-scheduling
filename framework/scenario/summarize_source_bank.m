function summary = summarize_source_bank(source_bank)
%SUMMARIZE_SOURCE_BANK Build a lightweight summary of a source bank.

if ~isstruct(source_bank) || ~isfield(source_bank, 'sources')
    error('summarize_source_bank:InvalidInput', ...
        'source_bank must be a valid struct with field sources.');
end

sources = source_bank.sources;
summary = struct();

summary.source_count = numel(sources);

if isempty(sources)
    summary.source_ids = strings(0,1);
    summary.source_types = strings(0,1);
    summary.generator_names = strings(0,1);
    summary.enabled_source_ids = strings(0,1);
else
    source_ids = strings(numel(sources),1);
    source_types = strings(numel(sources),1);
    generator_names = strings(numel(sources),1);
    enabled_mask = false(numel(sources),1);

    for k = 1:numel(sources)
        source_ids(k) = string(sources(k).source_id);
        source_types(k) = string(sources(k).source_type);
        generator_names(k) = string(sources(k).generator_name);
        enabled_mask(k) = logical(sources(k).enabled);
    end

    summary.source_ids = source_ids;
    summary.source_types = source_types;
    summary.generator_names = generator_names;
    summary.enabled_source_ids = source_ids(enabled_mask);
end
end
