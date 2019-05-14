function rescopeSelected(model, dataStores)
% RESCOPESELECTED Rescope specific Data Store Memory blocks.
%
%   Inports:
%       model       Simulink model name.
%       dataStores  Cell array of Data Store Memory block pathnames.
%
%   Outports:
%       N/A
%
%   Example:
%       rescopeSelected(bdroot, gcbs)
%           Rescopes the selected Data Store Memory blocks in the current Simulink system.

    % Check model argument
    % 1) Ensure the model is open
    
    try
        model = bdroot(model);
        assert(ischar(model));
        assert(bdIsLoaded(model));
    catch
        error(['Invalid model ''' num2str(model) '''. The model may not be loaded or the name is invalid.'])
    end

    % 2) Check that the model is unlocked
    try
        assert(strcmp(get_param(bdroot(model), 'Lock'), 'off'))
    catch E
        if strcmp(E.identifier, 'MATLAB:assert:failed') || ...
                strcmp(E.identifier, 'MATLAB:assertion:failed')
            error('Model is locked.')
        else
            error(['Invalid model name ''' num2str(model) '''.'])
        end
    end

    % Check dataStores argument 
    % 1) Ensure it is a cell array
    try
        assert(iscell(dataStores));
    catch
        error('Argument dataStores must be a cell array.')
    end
    
    % 2) Ensure it does not have nesting
    try
       assert(~iscellcell(dataStores));
    catch
       error('Argument dataStores must be a cell array with no nested cells.')
    end

    toRescope = {};
    for i = 1:length(dataStores)

        try
            % Try to get block type
            blockType = get_param(dataStores{i}, 'BlockType');
        catch
            % Not a block
            warning(['''' num2str(dataStores{i}) ''' is not a block.'])
            continue
        end

        % Check that block is a Data Store Memory/Read/Write
        try
            assert(strcmp(blockType, 'DataStoreRead') || ...
                strcmp(blockType, 'DataStoreWrite') || ...
                strcmp(blockType, 'DataStoreMemory'));
        catch E
            if strcmp(E.identifier, 'MATLAB:assert:failed') || ...
                    strcmp(E.identifier, 'MATLAB:assertion:failed')
                warning(['''' getfullname(dataStores{i}) ''' is not a Data Store block and has not been rescoped.'])
                continue
            else
                error('Invalid Data Store cell array argument.')
            end
        end

        dataStoreName = get_param(dataStores{i}, 'DataStoreName');

        % Check if selected data store block is the DataStoreMemory block
        if ~strcmp(blockType, 'DataStoreMemory')
            % If not, find corresponding DataStoreMemory block before adding
            temp = find_system(model, 'BlockType', 'DataStoreMemory', 'DataStoreName', dataStoreName);
            if ~isempty(temp)
                for j = 1:length(temp)
                    toRescope{end + 1} = temp{j};
                end
            end
        else
            toRescope{end + 1} = dataStores{i};
        end
    end

    % Find all other data store memory blocks that aren't in list "toRescope"
    % and pass those to DataStoreRescope as the list of blocks to not rescope
    otherMems = find_system(model, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'BlockType', 'DataStoreMemory');
    otherMems = setdiff(otherMems, toRescope);
    dataStoreRescope(model, otherMems);
end