function summary = summarize_array(x, name)
    %SUMMARIZE_ARRAY Return simple numeric summary for debug.
    
        if nargin < 2
            name = 'array';
        end
    
        summary = struct();
        summary.name  = name;
        summary.size  = size(x);
        summary.numel = numel(x);
    
        if isnumeric(x) || islogical(x)
            x_valid = x(isfinite(x));
            if isempty(x_valid)
                summary.min  = NaN;
                summary.max  = NaN;
                summary.mean = NaN;
                summary.std  = NaN;
            else
                summary.min  = min(x_valid(:));
                summary.max  = max(x_valid(:));
                summary.mean = mean(x_valid(:));
                summary.std  = std(double(x_valid(:)));
            end
        else
            summary.min  = [];
            summary.max  = [];
            summary.mean = [];
            summary.std  = [];
        end
    end