function s = pretty_label_stage02(kind, raw_value)
    %PRETTY_LABEL_STAGE02 Convert internal Stage02 labels to human-friendly text.
    %
    % Usage examples:
    %   pretty_label_stage02('critical', 'C1_track_plane_aligned')
    %   pretty_label_stage02('critical', 'C2_small_crossing_angle')
    %   pretty_label_stage02('heading', -30)
    %   pretty_label_stage02('family', 'nominal')
    %
    % Inputs:
    %   kind      : label category, one of
    %               'critical', 'heading', 'family', 'case_id'
    %   raw_value : original value
    %
    % Output:
    %   s         : human-friendly char label for plots / legends / summaries
    
        kind = lower(string(kind));
    
        switch kind
            case "critical"
                raw_value = string(raw_value);
                switch raw_value
                    case "C1_track_plane_aligned"
                        s = 'C1: track-plane-aligned';
                    case "C2_small_crossing_angle"
                        s = 'C2: small-crossing-angle';
                    otherwise
                        s = char(raw_value);
                end
    
            case "heading"
                if isnumeric(raw_value)
                    s = sprintf('Heading %+d deg', round(raw_value));
                else
                    s = sprintf('Heading %s', char(string(raw_value)));
                end
    
            case "family"
                raw_value = lower(string(raw_value));
                switch raw_value
                    case "nominal"
                        s = 'Nominal';
                    case "heading"
                        s = 'Heading family';
                    case "critical"
                        s = 'Critical family';
                    otherwise
                        s = char(raw_value);
                end
    
            case "case_id"
                % usually keep original case_id as-is, but strip underscores if desired
                raw_value = char(string(raw_value));
                s = strrep(raw_value, '_', '-');
    
            otherwise
                s = char(string(raw_value));
        end
    end