function RescopeSelected(address, dataStores)
% RESCOPESELECTED Gets all selected blocks, and runs DataStoreRescope such that only
% the selected blocks are rescoped.
%   RescopeSelected(address, dataStores) calls the DataStoreRescope operation on model
%   "address" such that the data stores in list "dataStores" are rescoped.

    %initialize list of DataStoreMemory blocks to push
    toRescope = {};
    for i = 1:length(dataStores)
        %check if current block in list dataStores is a data store block.
        try
            dataStoreName = get_param(dataStores{i}, 'DataStoreName');
        catch E
            if strcmp(E.identifier, 'Simulink:Commands:ParamUnknown')
                errstring = ['Selected block ' getfullname(dataStores{i}) ' is not a data store'];
                disp(errstring);
            end
        end
        
        %check if selected data store block is the DataStoreMemory block.
        if ~strcmp(get_param(dataStores{i}, 'BlockType'), 'DataStoreMemory')
            %if not, find corresponding DataStoreMemory block before adding
            temp = find_system(address, 'BlockType', 'DataStoreMemory', 'DataStoreName', dataStoreName);
            toRescope{end+1} = temp{1};
        else
            toRescope{end+1} = dataStores{i};
        end
    end
    
    %find all other data store memory blocks that aren't in list "toRescope" 
    %and pass those to DataStoreRescope as the list of blocks to not rescope.
    otherMems = find_system(address, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'BlockType', 'DataStoreMemory');
    otherMems = setdiff(otherMems, toRescope);
    DataStoreRescope(address, otherMems);
end