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

    toRescope = {};
    for i = 1:length(dataStores)
        % Check if block in list dataStores is a Data Store block
        try
            dataStoreName = get_param(dataStores{i}, 'DataStoreName');
        catch E
            disp(['Error using ' mfilename ':' char(10) ...
                ' Selected block ' getfullname(dataStores{i}) ' is not a Data Store.'])
        end
        
        % Check if selected data store block is the DataStoreMemory block
        if ~strcmp(get_param(dataStores{i}, 'BlockType'), 'DataStoreMemory')
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