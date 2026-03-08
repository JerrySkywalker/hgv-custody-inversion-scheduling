function pool = ensure_parallel_pool(profile_name, num_workers)
    %ENSURE_PARALLEL_POOL Ensure a parallel pool exists and matches requested profile.
    %
    % Input:
    %   profile_name : 'threads' or 'local'
    %   num_workers  : [] for default, or positive integer
    %
    % Output:
    %   pool         : parallel pool object
    
        if nargin < 1 || isempty(profile_name)
            profile_name = 'threads';
        end
        if nargin < 2
            num_workers = [];
        end
    
        pool = gcp('nocreate');
        if ~isempty(pool)
            return;
        end
    
        try
            if isempty(num_workers)
                pool = parpool(profile_name);
            else
                pool = parpool(profile_name, num_workers);
            end
        catch
            if isempty(num_workers)
                pool = parpool('local');
            else
                pool = parpool('local', num_workers);
            end
        end
    end