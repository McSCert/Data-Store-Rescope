function rescopeDocumenter(rescopedBlocks, rescopedDSNames, initialAddresses, rescopeAddresses, model)
% RESCOPEDOCUMENTER Create a log file of the dataStoreResope operation.
%   Note: First three parameters must be of the same length, equal to the
%   number of rescoped data stores.
%
%   Inputs:
%       rescopedBlocks      List of rescoped Data Store Memory block paths.
%       rescopedDSNames     List of rescoped Data Store Memory names.
%       initialAddresses    List of initial addresses of Data Store Memory blocks.
%       rescopeAddresses    List of final addresses of Data Store Memory blocks.
%       model               Simulink system name.
%
%   Outputs:
%       N/A

    % Perform checks to verify arguments are correct
    % 1) Ensure that rescopedBlocks, initialAddresses, rescopeAddresses are
    % cell arrays
    try
        assert(iscellstr(rescopedBlocks))
    catch
        error('Input argument rescopedBlocks is not a cell array of strings.');
    end
    
    try
        assert(iscellstr(rescopedDSNames))
    catch
        error('Input argument rescopedDSNames is not a cell array of strings.');
    end

    try
        assert(iscellstr(initialAddresses))
    catch
       error('Input argument initialAddresses is not a cell array of strings.');
    end

    try
        assert(iscellstr(rescopeAddresses))
    catch
        error('Input argument rescopeAddresses is not a cell array of strings.');
    end

    % 2) Check that rescopedBlocks, initialAddresses, rescopeAddresses are
    % the same length
    numRescoped = length(rescopedBlocks);
    try
        assert((numRescoped == length(initialAddresses)) && ...
            (numRescoped == length(rescopeAddresses)) && ...
            (numRescoped == length(rescopedDSNames)));
    catch E
        if strcmp(E.identifier, 'MATLAB:assert:failed') || ...
                strcmp(E.identifier, 'MATLAB:assertion:failed')
            error('Input arguments rescopedBlocks, initialAddresses, and rescopeAddresses are of different lengths.');
        else
            rethrow(E)
        end
    end

    % Get totals
    total = length(find_system(model, 'BlockType', 'DataStoreMemory'));

    % Open log file
    modelpath = which(model);
    if strcmp(modelpath, 'new Simulink model') % Model is new and not saved
        modelpath = pwd;
    else
        modelpath = fileparts(modelpath);
    end
    filename = [modelpath filesep model '_RescopeLog.txt'];
    file = fopen(filename, 'at');

    % Print current time and date
    fprintf(file, 'Log of rescope operation at date and time: %s\n\n', datestr(now));

    % Print overall statistics for the whole model
    fprintf(file, 'Total number of Data Store Memory blocks in model: %d\n', total);
    fprintf(file, 'Total number of Data Store Memory blocks rescoped: %d\n', numRescoped);
    if total == 0
        fprintf(file, 'Percentage of Data Store Memory blocks rescoped: N/A\n\n');
    else
        fprintf(file, 'Percentage of Data Store Memory blocks rescoped: %d%%\n\n', round((numRescoped/total)*100));
    end
    fprintf(file, 'List of rescoped Data Store Memory blocks:\n\n');

    % Print the change in addresses for each rescoped block
    for i = 1:length(rescopedBlocks)
        if ~strcmp(initialAddresses{i}, rescopeAddresses{i})

            % Display name containing newlines with spaces instead
            fprintf(file, 'Data Store Name: %s\n', rescopedDSNames{i});
            fprintf(file, 'Block Name: %s\n', removeNewline(rescopedBlocks{i}));
            fprintf(file, 'Initial Location: %s\n', removeNewline(initialAddresses{i}));
            fprintf(file, 'New Location: %s\n\n', removeNewline(rescopeAddresses{i}));
        end
    end

    if isempty(rescopedBlocks)
        fprintf(file, 'N/A\n\n');
    end
    fprintf(file, '-----------------------------------\n\n');
    fclose(file);
    fprintf('Data Store Rescope Log: %s\n', filename);
end