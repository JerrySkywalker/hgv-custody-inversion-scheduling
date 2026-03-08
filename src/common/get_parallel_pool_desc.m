function desc = get_parallel_pool_desc(pool, requested_profile)
    %GET_PARALLEL_POOL_DESC Safe string description for both thread/process pools.
    
        if nargin < 2 || isempty(requested_profile)
            requested_profile = "";
        end
    
        if isempty(pool)
            desc = "No parallel pool";
            return;
        end
    
        pool_type = string(class(pool));
    
        if strlength(string(requested_profile)) > 0
            desc = sprintf('RequestedProfile=%s, PoolType=%s, Workers=%d', ...
                string(requested_profile), pool_type, pool.NumWorkers);
        else
            desc = sprintf('PoolType=%s, Workers=%d', ...
                pool_type, pool.NumWorkers);
        end
    end