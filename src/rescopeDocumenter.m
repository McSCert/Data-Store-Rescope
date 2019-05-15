function rescopeDocumenter(rescopedBlocks, initialAddresses, rescopeAddresses, model)
% RESCOPEDOCUMENTER Create a log file of the dataStoreResope operation.
%   Note:First three parameters must be of the same length, equal to the
%   number of rescoped data stores.
%
%   Inputs:
%       rescopedBlocks      List of rescoped Data Store Memory block paths.
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

    % Open log file
    modelpath = which(model);

    if isunix
        filename = [fileparts(modelpath) '/' model '_RescopeLog.txt'];
        file = fopen(filename, 'at');
    else
        filename = [fileparts(modelpath) '\' model '_RescopeLog.txt'];
        file = fopen(filename, 'at');
    end

    % Print current time and date
    fprintf(file, 'Log of rescope operation at date and time: %s\n\n', datestr(now));

    % Print overall statistics for the whole model
    fprintf(file, 'Total number of Data Store Memory blocks in model: %d\n', total);
    fprintf(file, 'Total number of Data Store Memory blocks rescoped: %d\n', numRescoped);
    if (total~=0)
        fprintf(file, 'Percentage of Data Store Memory blocks rescoped: %d%%\n\n', round((numRescoped/total)*100));
    else
        fprintf(file, 'Percentage of Data Store Memory blocks rescoped: N/A\n\n');
    end
    fprintf(file, 'List of rescoped Data Store Memory blocks:\n\n');

    % Print the change in addresses for each rescoped block
    for doc = 1:length(rescopedBlocks)
        if ~strcmp(initialAddresses{doc}, rescopeAddresses{doc})

            % Display name containing newlines with spaces instead
            fprintf(file, 'Block Name: %s\n', removeNewline(rescopedBlocks{doc}));
            fprintf(file, 'Initial Location: %s\n', removeNewline(initialAddresses{doc}));
            fprintf(file, 'New Location: %s\n\n', removeNewline(rescopeAddresses{doc}));
        end
    end

    if isempty(rescopedBlocks)
        fprintf(file, 'N/A\n\n');
    end
    fprintf(file, '-----------------------------------\n\n');
    fclose(file);
    fprintf('Data Store Rescope Log: %s\n', filename);
end