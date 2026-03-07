function seed_rng(seed_value)
    %SEED_RNG Set random seed for reproducibility.
    
        if nargin < 1 || isempty(seed_value)
            seed_value = 20260308;
        end
    
        rng(seed_value, 'twister');
    end