function dataStoreRescope(model, dontmove)
% DATASTORERESCOPE Move Data Store Memory blocks in a model to their proper 
% scopes.
%
%   DATASTORERESCOPE(M, D) moves all Data Store Memory blocks in model M to
%    their proper scopes, except for those in D, where:
%		M is the Simulink model name (or top-level system name)
%		D is a cell array of Data Store Memory block path names
%
%	Example:
%	
%	dataStoreRescope(bdroot, {})	% rescope all Data Store Memory blocks
%									% in the current Simulink system

    % Check model argument M
    % 1) Ensure the model is open
    try
        assert(bdIsLoaded(model));
    catch
        disp(['Error using ' mfilename ':' char(10) ...
            'Invalid model argument M. Model may not be loaded or name is invalid.' char(10)])
        help(mfilename)
        return
    end
    
    % 2) Check that model M is unlocked
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
                'Invalid model name argument M.' char(10)])
            help(mfilename)
            return
        end
    end
    
    % Check that D is of type 'cell'
    try
        assert(iscell(dontmove));
    catch
        disp(['Error using ' mfilename ':' char(10) ...
                ' Invalid cell argument D.' char(10)])
        help(mfilename)
        return
    end
    
	% Find all Data Store Memory blocks in the model
	dataStoreMem = find_system(model, 'FollowLinks', 'on', 'LookUnderMasks', 'all', 'BlockType', 'DataStoreMemory');

	% Initial declarations
	dataStoresToIgnore = {};
	memToRescope = {};
	toRescopeAddress = {};
	initialAddress = {};

	% Remove data stores that are listed to not be rescoped from the list of data stores to examine
	for j = 1:length(dataStoreMem)
		for k = 1:length(dontmove)
			if strcmp(get_param(dataStoreMem{j}, 'DataStoreName'), get_param(dontmove{k}, 'DataStoreName'))
				dataStoresToIgnore = [dataStoresToIgnore dataStoreMem{j}];
			end
		end
	end
	dataStoreMem = setdiff(dataStoreMem, dataStoresToIgnore);

	% Main loop for finding the data store memory blocks to be rescoped, and their updated locations
	for i = 1:length(dataStoreMem)
		% Get initial location, name of the data store
		initialLocation = get_param(dataStoreMem{i}, 'parent');
        
        % Get other data store memory blocks that share the same name
		dataStoreName = get_param(dataStoreMem{i}, 'DataStoreName');
        memsWithSameName=find_system(initialLocation, 'BlockType', 'DataStoreMemory', 'DataStoreName', dataStoreName);
        memsWithSameName=setdiff(memsWithSameName, dataStoreMem{i});
        
        memSplit=regexp(initialLocation, '/', 'split');
        currentLowerBound=[];
        pushDownOnly=false;
        otherMemLevels={};
        
        %get bounds on the scope of the data store
        for j=1:length(memsWithSameName)
            otherMemLevel=get_param(memsWithSameName{j}, 'parent');
            otherMemSplit=regexp(otherMemLevel, '/', 'split');
            intersect=intersect(otherMemSplit, memSplit);
            if length(intersect)==length(otherMemLevel)
                pushDownOnly=true;
            elseif length(intersect)==length(memLevel)
                if length(otherMemLevel)<length(currentLowerBound)|| ...
                        isempty(currentLowerBound)
                    currentLowerBound=otherMemLevel;
                end
            else
                pushDownOnly=true;
                otherMemLevels{end+1}=otherMemLevel;
            end
        end
        
        
        % Get a list of data store read and write blocks
		dataStoreBlocks = find_system(model, 'FollowLinks', 'on', 'LookUnderMasks', 'all', 'DataStoreName', dataStoreName);
		dataStoreReadWrite = setdiff(dataStoreBlocks, dataStoreMem{i});

		% Find the lowest common ancestor of the data store read and write blocks.
        % Start by assuming the first data store read block is the lowest
        % common ancestor
        try
            lowestCommonAncestor = get_param(dataStoreReadWrite{1}, 'parent');
        catch E
            % If the data store memory has no associated reads or writes, 
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
            
            % Check if the data store read/write is in the scope of this
            % particular data store
            
            % If there's a data store memory block higher than the current
            % one in the subsystem hierarchy that shares a DataStoreName,
            % don't consider blocks that could be in that data store's
            % scope
            if pushDownOnly
                intersect=intersect(memSplit, dataStoreSubstrings);
                if (length(intersect)==length(dataStoreSubstrings)) || ...
                        ((length(intersect)<length(dataStoreSubstrings)) && ...
                        (length(intersect)<length(memSplit)))
                    flag=true;
                    for k=1:length(otherMemLevels)
                        otherMemSplit=regexp(otherMemLevels{k}, '/', 'split');
                        intersect=intersect(otherMemSplit, dataStoreSubstrings);
                        if length(intersect)==length(otherMemSplit)
                            flag=false;
                        end
                    end
                    if flag
                        warnstr=['Warning: Block ''%s'' is outside of the ' ...
                            'scope of all Data Store Memory blocks. There ' ...
                            'are multiple Data Store Memory blocks that ' ...
                            'share a ''DataStoreName'' parameter with the ' ...
                            'block. Please move the desired Data Store Memory ' ...
                            'block such that the read/write will be in its scope to ' ...
                            'root level, then run the tool again.'];
                        warning(warnstr, dataStoreReadWrite{j});
                    end
                    continue
                end
            end
            
            % If there's a data store memory block lower than the current
            % one in the subsystem hierarchy that shares a DataStoreName,
            % don't consider blocks in that data store memory's scope
            if ~isempty(currentLowerBound)
                intersect=intersect(dataStoreSubstrings, currentLowerBound);
                if length(intersect)==length(currentLowerBound)
                    continue
                end
            end
                      
            % Initialize variables for the lowest common ancestor while loop
			flag = 1;
			lowestCommonAncestor = '';
            k = 1;
            
			% Find the lowest common ancestor based on the block paths
			% between current lowest common ancestor and the current block
			while (flag == 1)
                try
                    if strcmp(LCASubstrings{k}, dataStoreSubstrings{k})
                        lowestCommonAncestor = [lowestCommonAncestor LCASubstrings{k} '/'];
                    else
                        flag = 0;
                    end
                catch
                    flag = 0;
                end
                k = k + 1;
            end
            if (lowestCommonAncestor(end) == '/')
                lowestCommonAncestor(end) = '';
            end
		end

		% Check if lowest common ancestor is in a referenced subsystem
		% (library subsystem) where data store memory blocks shouldn't be
		% rescoped
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

		% Check if data store memory lowest common ancestor is in the same
		% system as started. If it is, the block should not be rescoped
		dontmove = false;
		if strcmp(lowestCommonAncestor, initialLocation)
			dontmove = true;
		end

		% Note the block to push, its current location, and the address for
		% which the block is to be rescoped
		if (~dontmove)
			memToRescope{end+1}= dataStoreMem{i};
			initialAddress{end+1}= initialLocation;
			toRescopeAddress{end+1}= lowestCommonAncestor;
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

	% Iterate through each address where data store memory blocks are being 
	% rescoped, and move the blocks to their corresponding address
	allKeys = keys(addressMap);
	for i = 1:length(allKeys)
		% Setup for moving Data Store Memory blocks to the top of the model
		start = 30;
		top = 30;
    	numDS = length(addressMap(allKeys{i}));
		rowNum = ceil(numDS/10);
		colNum = 10;

		% Move down all blocks and lines in the model
		mdlLines = find_system(allKeys{i}, 'Searchdepth', 1, 'FollowLinks', 'on', 'LookUnderMasks', 'All', 'FindAll', 'on', 'Type', 'line');
    	allBlocks = find_system(allKeys{i}, 'SearchDepth', 1);
    	allBlocks = setdiff(allBlocks, allKeys{i});
    	annotations = find_system(allKeys{i}, 'FindAll', 'on', 'SearchDepth', 1, 'type', 'annotation');

    	% Move all lines downwards
		for zm = 1:length(mdlLines)
			lPint = get_param(mdlLines(zm), 'Points');
		 	xPint = lPint(:, 1); % First position integer
		 	yPint = lPint(:, 2); % Second position integer
		 	yPint = yPint+50*rowNum+30;
		 	newPoint = [xPint yPint];
		 	set_param(mdlLines(zm), 'Points', newPoint);
		end

		% Move all blocks downwards
		for z = 1:length(allBlocks)
			bPosition = get_param(allBlocks{z}, 'Position'); % Block position
			bPosition(1) = bPosition(1);
			bPosition(2) = bPosition(2)+50*rowNum+30;
			bPosition(3) = bPosition(3);
			bPosition(4) = bPosition(4)+50*rowNum+30;
			set_param(allBlocks{z}, 'Position', bPosition);
		end

		% Move all annotations downwards
		for gg = 1:length(annotations)
			bPosition = get_param(annotations(gg), 'Position'); % Annotations position
		 	bPosition(1) = bPosition(1);
		 	bPosition(2) = bPosition(2)+50*rowNum+30;
		 	set_param(annotations(gg), 'Position', bPosition);
        end
        
        % Get the list of Data Stores being rescoped to this address
		DSCell = addressMap(allKeys{i});
        
        % For each Data Store in the list
        for DSM = 1:numDS
            % Get the parameters for its position
            if (ceil(DSM/10) > 1)
                top = 30+50*(ceil(DSM/10)-1);
                if (mod(DSM, 10) == 1)
                    start = 30;
                end
            end
            
            % Get parameters for the new block
            name = get_param(DSCell{DSM}, 'Name');
            
            % Create new pushed data store memory block. If a block with
            % 'Name' parameter already exists, add a number to suffix it.
            flag = true;
            n = 1;
            oldName = name;
            while flag
                try
                    rescopedDSMem = add_block(DSCell{DSM}, [allKeys{i} '/' name]);
                    flag = false;
                catch E
                    if strcmp(E.identifier, 'Simulink:Commands:AddBlockCantAdd')
                        name = [oldName ' ' num2str(n)];
                        n = n + 1;
                    end
                end
            end
            
            % Display warning message if 'Name' parameter of a pushed block
            % was changed
            if ~strcmp(oldName, name)
               % Display names containing newlines with spaces instead
               oldName(oldName == char(10)) = ' ';
               
                disp(['Warning using ' mfilename ':' char(10) ...
                ' Data Store Memory block with name "' oldName ...
                '" already exists at ' allKeys{i} '. The rescoped block' ...
                ' has been renamed to "' name '".'])
            end
            
            % Remove old block
            delete_block(DSCell{DSM});
            
            % Adjust position of the newly rescoped DataStoreMemory block
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
    
    % Create logfile to document the operation
    rescopeDocumenter(memToRescope, initialAddress, toRescopeAddress, model);

end
