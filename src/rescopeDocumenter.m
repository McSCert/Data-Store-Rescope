function rescopeDocumenter(rescopedBlocks, initialAddresses, rescopeAddresses, model)
% RESCOPEDOCUMENTER Create a logfile of the dataStoreResope operation.
%
%   RESCOPEDOCUMENTER(DSM, A1, A2, M) creates a text logfile summarizing 
%   the effect of the dataStoreRecope operation, where,
%       DSM is a list of rescoped Data Store Memory block paths
%       A1 is a list of initial addresses of DSM
%       A2 is a list of final addresses of DSM
%       M is the Simulink model name (or top-level system name)
% The first three parameters must be of the same length, equal to the 
% number of moved data stores.

    % Perform checks to verify arguments are correct
    % 1) Ensure that rescopedBlocks, initialAddresses, rescopeAddresses are
    % cell arrays
    try
        assert(iscellstr(rescopedBlocks))
    catch
        disp(['Error using ' mfilename ':' char(10) ...
                ' Input argument DSM is not a cell array of strings.'])
        help(mfilename)
        return
    end
    
    try
        assert(iscellstr(initialAddresses))
    catch
        disp(['Error using ' mfilename ':' char(10) ...
                ' Input argument A1 is not a cell array of strings.'])
        help(mfilename)
        return
    end
    
    try
        assert(iscellstr(rescopeAddresses))
    catch
        disp(['Error using ' mfilename ':' char(10) ...
                ' Input argument A2 is not a cell array of strings.'])
        help(mfilename)
        return
    end
    
    % 2) Check that rescopedBlocks, initialAddresses, rescopeAddresses are
    % the same length
    try
        assert((length(rescopedBlocks) == length(initialAddresses)) && ...
            (length(rescopeAddresses) == length(rescopedBlocks)));
    catch E
        if strcmp(E.identifier, 'MATLAB:assert:failed') || ... 
                strcmp(E.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ...
                ' Input arguments DSM, A1, and A2 are of different lengths.'])
            help(mfilename)
        end
        return
    end

    % Get totals
    total = length(find_system(model, 'BlockType', 'DataStoreMemory'));
    numRescoped = length(rescopedBlocks);
    
    % Open logfile
    filename = [model '_RescopeLog.txt'];
    file = fopen(filename, 'wt');
    
    % Print overall statistics for the whole model
    fprintf(file, 'Total number of Data Store Memory blocks in model: %d\n', total);
    fprintf(file, 'Total number of Data Store Memory blocks rescoped: %d\n', numRescoped);
    fprintf(file, 'Percentage of Data Store Memory blocks rescoped: %d%%\n\n', round((numRescoped/total)*100));
    fprintf(file, 'List of rescoped Data Store Memory blocks:\n\n');

    % Print the change in addesses for each rescoped block 
    for doc = 1:length(rescopedBlocks)
        if ~strcmp(initialAddresses{doc}, rescopeAddresses{doc})
            fprintf(file, 'Block Name: %s\n', rescopedBlocks{doc});
            fprintf(file, 'Initial Location: %s\n', initialAddresses{doc});
            fprintf(file, 'New Location: %s\n\n', rescopeAddresses{doc});
        end
    end
    fclose(file);
end