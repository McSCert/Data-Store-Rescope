function dataStoreRescope(model, dontMove)
% DATASTORERESCOPE Move Data Store Memory blocks to their proper scopes.
%
%   Inputs:
%       model       Simulink model name.
%       dontMove    Cell array of Data Store Memory block pathnames.
%
%   Outputs:
%       N/A
%
%   Examples:
%       >> dataStoreRescope(bdroot, {})
%           Rescopes all Data Store Memory blocks in the current Simulink system.
%
%       >> dataStoreRescope('DataStoreRescopeDemo', {'DataStoreRescopeDemo/Data Store Memory 1'})
%           Rescopes all Data Store Memory blocks except for Data Store Memory 1.

    % Check model argument
    % 1) Ensure the model is open
    try
        model = bdroot(model);
        assert(ischar(model));
        assert(bdIsLoaded(model));
    catch
        error('Invalid model argument. Model may not be loaded or name is invalid.');
    end

    % 2) Check that model is unlocked
    try
        assert(strcmp(get_param(bdroot(model), 'Lock'), 'off'))
    catch E
        if strcmp(E.identifier, 'MATLAB:assert:failed') || ...
                strcmp(E.identifier, 'MATLAB:assertion:failed')
            error('File is locked.');
        else
            error('Invalid model argument.');
        end
    end

    % Check dontMove argument 
    % 1) Ensure it is a cell array
    try
        assert(iscell(dontMove));
    catch
        error('Argument dontMove must be a cell array.')
    end
    
    % 2) Ensure it does not have nesting
    try
        assert(~iscellcell(dontMove));
    catch
        error('Argument dontMove must be a cell array with no nested cells.')
    end
  
    % Check that dontMove contains blocks
    try
        for i = 1:length(dontMove)
            assert(ischar(dontMove{i}))
        end
    catch
        error('Invalid argument type in dontMove argument.')
    end

    % Initial declarations
    dataStoresToIgnore = {};
    memToRescope = {};
    toRescopeAddress = {};
    initialAddress = {};

    % Get config file params
    linkedBlocksEnabled = getDataStoreRescopeConfig('linkedBlocksEnabled', 0);
    linkedBlocksEnabled = str2num(linkedBlocksEnabled);

    % Find all Data Store Memory blocks in the model
    dataStoreMem = find_system(model, 'FollowLinks', 'on', 'LookUnderMasks', 'all', 'BlockType', 'DataStoreMemory');

    % Check if blocks in dontMove exist and are Data Store blocks
    for i = 1:length(dontMove)
        try
            get_param(dontMove{i}, 'DataStoreName');
        catch E
            if strcmp(E.identifier, 'Simulink:Commands:InvSimulinkObjectName')
                error(['Block ''' removeNewline(dontMove{i}) ''' does not exist.']);
            elseif strcmp(E.identifier, 'Simulink:Commands:InvSimulinkObjHandle')
                error(['''' removeNewline(num2str(dontMove{i})) ''' is not a valid block.']);
            elseif strcmp(E.identifier, 'Simulink:Commands:ParamUnknown')
                error(['Block ''' removeNewline(dontMove{i}) ''' is not a Data Store block.']);
            end
        end
    end

    % Remove data stores that are listed to not be rescoped from the list of data stores to examine
    for j = 1:length(dataStoreMem)
        for k = 1:length(dontMove)
            if strcmp(dataStoreMem{j}, dontMove{k})
                dataStoresToIgnore = [dataStoresToIgnore dataStoreMem{j}];
            end
        end
    end
    dataStoreMem = setdiff(dataStoreMem, dataStoresToIgnore);

    % Main loop for finding the Data Store Memory blocks to be rescoped, and their updated locations
    for i = 1:length(dataStoreMem)
        % Get initial location, name of the data store
        initialLocation = get_param(dataStoreMem{i}, 'parent');

        % Ensure that found Data Store Memory block isn't in a linked
        % subsystem
        if ~linkedBlocksEnabled
            try
                isRef = get_param(initialLocation, 'ReferenceBlock');
            catch
                isRef = '';
            end

            if ~isempty(isRef)
                continue
            end
        end

        % Get other Data Store Memory blocks that share the same name
        dataStoreName = get_param(dataStoreMem{i}, 'DataStoreName');
        memsWithSameName = find_system(model, 'BlockType', 'DataStoreMemory', ...
            'DataStoreName', dataStoreName);
        memsWithSameName = setdiff(memsWithSameName, dataStoreMem{i});

        memSplit = regexp(initialLocation, '/', 'split');
        currentLowerBound = [];
        pushDownOnly = false;
        memsAboveLevels = {};
        otherMemLevels = {};

        % Get bounds on which Data Store Memory blocks already cover which
        % scopes
        for j = 1:length(memsWithSameName)
            otherMemLevel = get_param(memsWithSameName{j}, 'parent');
            otherMemSplit = regexp(otherMemLevel, '/', 'split');
            inter = intersect(otherMemSplit, memSplit);
            if length(inter) == length(otherMemLevel)
                pushDownOnly = true;
                memsAboveLevels{end+1} = otherMemLevel;
            elseif length(inter) == length(memSplit)
                if length(otherMemLevel) < length(currentLowerBound)|| ...
                        isempty(currentLowerBound)
                    currentLowerBound = otherMemLevel;
                end
            else
                otherMemLevels{end+1} = otherMemLevel;
                pushDownOnly = true;
            end
        end

        % Get list of all Data Store Read and Write blocks
        dataStoreBlocks = find_system(model, 'FollowLinks', 'on', ...
            'LookUnderMasks', 'all', 'DataStoreName', dataStoreName);
        dataStoreReadWrite = setdiff(dataStoreBlocks, dataStoreMem);

        % Find the lowest common ancestor of the Data Store Read and Write blocks.
        % Start by assuming the first Data Store Read/Write block is the lowest
        % common ancestor, and check if that block is in the scope of the
        % current Data Store Memory block. Then, iterate until you find a
        % correct Data Store Read/Write.
        try
            flag = true;
            k = 1;
            while flag
                flag = false;
                readWriteLevel = get_param(dataStoreReadWrite{k}, 'parent');
                if pushDownOnly
                    readWriteLevelSplit = regexp(readWriteLevel, '/', 'split');
                    inter = intersect(readWriteLevelSplit, memSplit);
                    if length(inter) ~= length(memSplit)
                        flag = true;
                    end
                end
                lowestCommonAncestor = readWriteLevel;
                k = k + 1;
            end
        catch E
            % If a Data Store Memory has no associated Reads/Writes,
            % its lowest common ancestor is set as its own location
            if strcmp(E.identifier, 'MATLAB:badsubscript')
                lowestCommonAncestor = initialLocation;
            end
        end

        for j = 2:length(dataStoreReadWrite)

            % Split off current lowest common ancestor name and current data
            % store block name into substrings for each subsystem in the block path
            LCASubstrings = regexp(lowestCommonAncestor, '/', 'split');
            dataStoreSubstrings = regexp(dataStoreReadWrite{j}, '/', 'split');
            dataStoreLevel = get_param(dataStoreReadWrite{j}, 'parent');
            dataStoreLevelSplit = regexp(dataStoreLevel, '/', 'split');

            % Check if the Data Store Read/Write is in the scope of this
            % particular data store

            % If there's a Data Store Memory block higher than the current
            % one in the subsystem hierarchy that shares a DataStoreName,
            % don't consider blocks that could be in that data store's
            % scope. Additionally, if there are Reads/Writes in the scope
            % of another Data Store Memory on another branch of the
            % hierarchy, don't consider those
            if pushDownOnly
                inter = intersect(dataStoreLevelSplit, memSplit);
                if length(inter) ~= length(memSplit)
                    flag = true;
                    for k = 1:length(memsAboveLevels)
                        memsAboveSplit = regexp(memsAboveLevels{k}, '/', 'split');
                        inter = intersect(memsAboveSplit, dataStoreLevelSplit);
                        if length(inter) == length(memsAboveSplit)
                            flag = false;
                        end
                    end
                    for k = 1:length(otherMemLevels)
                        otherMemSplit = regexp(otherMemLevels{k}, '/', 'split');
                        inter = intersect(otherMemSplit, dataStoreLevelSplit);
                        if length(inter) == length(otherMemSplit)
                            flag = false;
                        end
                    end
                    if flag

                        msg = ['Block "' removeNewline(dataStoreReadWrite{j}) ...
                        '" is out of scope of all Data Store Memory blocks ' ...
                        'with DataStoreName "' dataStoreName '".' char(10) ...
                        'Due to multiple matching Data Store Memory ' ...
                        'blocks in the model with this DataStoreName, ' ...
                        'it cannot be determined which is to be used.' char(10) ...
                        'If the desired Data Story Memory block ' ...
                        'is "' removeNewline(dataStoreMem{i}) ...
                        '", move it to the root, and re-run this operation.'];
                        warning(msg);
                    end
                    continue
                end
            end

            % If there's a Data Store Memory block lower than the current
            % one in the subsystem hierarchy that shares a DataStoreName,
            % don't consider blocks in that Data Store Memory's scope
            if ~isempty(currentLowerBound)
                inter = intersect(dataStoreLevelSplit, currentLowerBound);
                if length(inter) == length(currentLowerBound)
                    continue
                end
            end

            % Find the lowest common ancestor based on the block paths
            % between current lowest common ancestor and the current block
            flag = true;
            lowestCommonAncestor = '';
            k = 1;

            while flag
                try
                    if strcmp(LCASubstrings{k}, dataStoreSubstrings{k})
                        lowestCommonAncestor = [lowestCommonAncestor LCASubstrings{k} '/'];
                    else
                        flag = false;
                    end
                catch
                    flag = false;
                end
                k = k + 1;
            end
            if (lowestCommonAncestor(end) == '/')
                lowestCommonAncestor(end) = '';
            end
        end

        % Check if lowest common ancestor is in a referenced subsystem
        % (library subsystem) where Data Store Memory blocks shouldn't be
        % rescoped
        if ~linkedBlocksEnabled
            notRef = false;
            while ~notRef
                % Check if lowest common ancestor is in a referenced subsystem
                try
                    isRef = get_param(lowestCommonAncestor, 'ReferenceBlock');
                catch
                    isRef = '';
                end

                if strcmp(isRef, '')
                    notRef = true;
                else
                    % If the current subsystem is referenced, move up one
                    % subsytem for the lowest common ancestor
                    notRef = false;
                    LCASubstrings = regexp(lowestCommonAncestor, '/', 'split');
                    LCASubstrings(end) = [];
                    lowestCommonAncestor = strjoin(LCASubstrings, '/');
                end
            end
        end

        % Check if Data Store Memory lowest common ancestor is in the same
        % system as started. If it is, the block should not be rescoped
        dontMove = false;
        if strcmp(lowestCommonAncestor, initialLocation)
            dontMove = true;
        end

        % Note the block to rescope, its current location, and the address for
        % which the block is to be rescoped
        if ~dontMove
            memToRescope{end+1} = dataStoreMem{i};
            initialAddress{end+1} = initialLocation;
            toRescopeAddress{end+1} = lowestCommonAncestor;
        end
    end

    % Set up a map object with the keys being the final desinations of the objects
    addressMap = containers.Map();
    for i = 1:length(toRescopeAddress)
        addressMap(toRescopeAddress{i}) = {};
    end

    % For each block to rescope, add it to the list of blocks to be rescoped
    % for its corresponding toRescopeAddress
    for i = 1:length(memToRescope)
        temp = addressMap(toRescopeAddress{i});
        temp{end+1} = memToRescope{i};
        addressMap(toRescopeAddress{i}) = temp;
    end

    % Iterate through each address where Data Store Memory blocks are being
    % rescoped, and move the blocks to their corresponding address
    allKeys = keys(addressMap);
    for i = 1:length(allKeys)
        %disable link for subsystem if necessary
        if ~strcmp(get_param(allKeys{i}, 'type'), 'block_diagram')
            if linkedBlocksEnabled
                try
                    linkStatus = get_param(allKeys{i}, 'LinkStatus');
                    if strcmp(linkStatus, 'resolved')
                        set_param(allKeys{i}, 'LinkStatus', 'inactive');
                    elseif strcmp(linkStatus, 'implicit')
                        %if a subsystem higher in the hierarchy is linked find
                        %it and make link inactive
                        flag = 1;
                        linkedSys = allKeys{i};
                        while flag
                            linkedSys = get_param(linkedSys, 'parent');
                            linkStatus = get_param(linkedSys, 'LinkStatus');
                            if strcmp(linkStatus, 'resolved')
                                set_param(linkedSys, 'LinkStatus', 'inactive');
                                flag = 0;
                            end
                        end
                    end
                catch
                    % Catches the case when the system indicated in allKeys{i}
                    % is the top level block diagram, which doesn't have the
                    % parameter 'LinkStatus'
                    continue
                end
            end
        end

        % Setup for moving Data Store Memory blocks to the top of the model
        start = 30;
        top = 30;
        numDS = length(addressMap(allKeys{i}));
        rowNum = ceil(numDS/10);
        colNum = 10;

        % Move down all blocks and lines in the model
        mdlLines = find_system(allKeys{i}, 'Searchdepth', 1, 'FollowLinks', 'on', ...
            'LookUnderMasks', 'All', 'FindAll', 'on', 'Type', 'line');
        allBlocks = find_system(allKeys{i}, 'SearchDepth', 1);
        allBlocks = setdiff(allBlocks, allKeys{i});
        annotations = find_system(allKeys{i}, 'FindAll', 'on', ...
            'SearchDepth', 1, 'type', 'annotation');

        % Move all lines downwards
        for zm = 1:length(mdlLines)
            lPint = get_param(mdlLines(zm), 'Points');
            xPint = lPint(:, 1); % First position integer
            yPint = lPint(:, 2); % Second position integer
            yPint = yPint + (50 * rowNum) + 30;
            newPoint = [xPint yPint];
            set_param(mdlLines(zm), 'Points', newPoint);
        end

        % Move all blocks downwards
        for z = 1:length(allBlocks)
            bPosition = get_param(allBlocks{z}, 'Position'); % Block position
            bPosition(1) = bPosition(1);
            bPosition(2) = bPosition(2) + (50 * rowNum) + 30;
            bPosition(3) = bPosition(3);
            bPosition(4) = bPosition(4) + (50 * rowNum) + 30;
            set_param(allBlocks{z}, 'Position', bPosition);
        end

        % Move all annotations downwards
        for gg = 1:length(annotations)
            bPosition = get_param(annotations(gg), 'Position'); % Annotations position
            bPosition(1) = bPosition(1);
            bPosition(2) = bPosition(2) + (50 * rowNum) + 30;
            set_param(annotations(gg), 'Position', bPosition);
        end

        % Get the list of Data Stores Memory blocks being rescoped to this address
        DSCell = addressMap(allKeys{i});

        % For each Data Store in the list
        for DSM = 1:numDS
            % Get the parameters for its position
            if (ceil(DSM/10) > 1)
                top = 30 + (50 * (ceil(DSM/10)) - 1);
                if (mod(DSM, 10) == 1)
                    start = 30;
                end
            end

            % Get parameters for the new block
            name = get_param(DSCell{DSM}, 'Name');

            % Create new rescoped Data Store Memory block. If a block with
            % 'Name' parameter already exists, add a number suffix
            flag = true;
            n = 1;
            oldName = name;
            while flag
                try
                    % Try adding the block in new location
                    rescopedDSMem = add_block(DSCell{DSM}, [allKeys{i} '/' name]);
                    flag = false;
                catch E
                    if strcmp(E.identifier, 'Simulink:Commands:AddBlockCantAdd')
                        endNum = regexp(oldName, '[1-9]+$', 'match');
                        if isempty(endNum)
                            name = [oldName num2str(n)];
                            n = n + 1;
                        else
                            name = oldName(1:end-length(endNum{1}));
                            name = [name num2str(n + str2num(endNum{1}))];
                            n = n + 1;
                        end
                    end
                end
            end

            % Notify user if 'Name' parameter of a rescoped block was changed
            if ~strcmp(oldName, name)
                msg = ['Data Store Memory block with name "' removeNewline(oldName) ...
                '" already exists at location ' removeNewline(allKeys{i}) '.' char(10) ...
                'The rescoped block has been renamed to "' removeNewline(name) '".'];
                warning(msg);
            end

            % Remove old block
            delete_block(DSCell{DSM});

            % Adjust position of the newly rescoped Data Store Memory block
            rsDSMemPos = get_param(rescopedDSMem, 'Position');
            newPos(1) = start;
            newPos(2) = top;
            newPos(3) = start + rsDSMemPos(3) - rsDSMemPos(1);
            newPos(4) = top + rsDSMemPos(4) - rsDSMemPos(2);
            start = newPos(3) + 20;
            set_param([allKeys{i} '/' name], 'Position', newPos);
            newPos = [];
        end
    end

    % Create log file to document the operation
    rescopeDocumenter(memToRescope, initialAddress, toRescopeAddress, model);
end

function val = getDataStoreRescopeConfig(parameter, default)
    val = default;
    filePath = mfilename('fullpath');
    name = mfilename;
    filePath = filePath(1:end-length(name));
    fileName = [filePath 'config.txt'];
    file = fopen(fileName);
    line = fgetl(file);
    paramPattern = ['^' parameter ':[ ]*[0-9]'];
    while ischar(line)
        match = regexp(line, paramPattern, 'match');
        if ~isempty(match)
            val = match{1};
            val = val(end);
            break
        end
        line = fgetl(file);
    end
    fclose(file);
end