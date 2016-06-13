function rescopeSelected(model, dataStores)
% RESCOPESELECTED Run the dataStoreRescope function on the selected Data 
% Store Memory blocks.
%
%   RESCOPESELECTED(M, D) calls the dataStoreRescope function on model M
%   such that only the Data Store Memory blocks listed in D are rescoped, 
%   where:
%       M is the Simulink model name (or top-level system name)
%       D is a cell array of Data Store Memory block path names
%
%   Example:
%   
%   rescopeSelected(bdroot, gcbs)    % rescope the selected Data Store Memory
%                                    % blocks in the current Simulink system

    % Perform a check to see if the model is open and unlocked
    try
        assert(strcmp(get_param(bdroot(model), 'Lock'), 'off'))
    catch E
        if strcmp(E.identifier, 'MATLAB:assert:failed') || ... 
                strcmp(E.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ...
                ' File is locked.'])
            return
        else
            disp(['Error using ' mfilename ':' char(10) ...
                ' Invalid model name argument M.' char(10)])
            help(mfilename)
            return
        end
    end

    toRescope = {};
    for i = 1:length(dataStores)
        
        % Check if block in list dataStores is a Data Store block
        blockType = get_param(dataStores{i}, 'BlockType');
        try
            assert(strcmp(blockType, 'DataStoreRead') || ...
                strcmp(blockType, 'DataStoreWrite') || ...
                strcmp(blockType, 'DataStoreMemory'));
        catch E
            if strcmp(E.identifier, 'MATLAB:assert:failed') || ...
                    strcmp(E.identifier, 'MATLAB:assertion:failed')
                disp(['Error using ' mfilename ':' char(10) ...
                    ' ' getfullname(dataStores{i}) ' is not a Data Store block.'])
                continue
            else
                disp(['Error using ' mfilename ':' char(10) ...
                ' Invalid data store list argument D.' char(10)])
                help(mfilename)
                return
            end
        end
        
        dataStoreName = get_param(dataStores{i}, 'DataStoreName');

        % Check if selected data store block is the DataStoreMemory block
        if ~strcmp(blockType, 'DataStoreMemory')
            % If not, find corresponding DataStoreMemory block before adding
            temp = find_system(model, 'BlockType', 'DataStoreMemory', 'DataStoreName', dataStoreName);
            toRescope{end + 1} = temp{1};
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