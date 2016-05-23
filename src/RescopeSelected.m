function RescopeSelected(address, dataStores)
% RESCOPESELECTED Run the DataStoreRescope function on the selected Data 
% Store Memory blocks.
%   RescopeSelected(A, D) calls the DataStoreRescope function on model at 
%   address A such that the Data Store Memory blocks listed in D are rescoped.

    toRescope = {};
    for i = 1:length(dataStores)
        % Check if current block in list dataStores is a data store block
        try
            dataStoreName = get_param(dataStores{i}, 'DataStoreName');
        catch E
            disp(['Error using ' mfilename ':' char(10) ...
                ' Selected block ' getfullname(dataStores{i}) ' is not a Data Store.'])
        end
        
        % Check if selected data store block is the DataStoreMemory block
        if ~strcmp(get_param(dataStores{i}, 'BlockType'), 'DataStoreMemory')
            % If not, find corresponding DataStoreMemory block before adding
            temp = find_system(address, 'BlockType', 'DataStoreMemory', 'DataStoreName', dataStoreName);
            toRescope{end + 1} = temp{1};
        else
            toRescope{end + 1} = dataStores{i};
        end
    end
    
    % Find all other data store memory blocks that aren't in list "toRescope" 
    % and pass those to DataStoreRescope as the list of blocks to not rescope
    otherMems = find_system(address, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'BlockType', 'DataStoreMemory');
    otherMems = setdiff(otherMems, toRescope);
    DataStoreRescope(address, otherMems);
end