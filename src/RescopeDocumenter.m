function RescopeDocumenter(memToRescope, initialAddress, toRescopeAddress, model)
% RESCOPEDOCUMENTER Produces a logfile of the DataStoreResope operation.
%   RescopeDocumenter(memToRescope, initialAddress, toRescopeAddress, address)
%   uses several lists to produce documentation. The lists should all be of
%   the same length, with a length equal to the number of pushed data
%   stores. The parameter "memToRescope" is a list of rescoped data stores, the
%   parameter "initialAddress" is a list with initial addresses for the
%   blocks with the corresponding index in "memToRescope", and the parameter
%   "toRescopeAddress" is a list with the final addresses for the blocks with
%   the corresponding index in "memToRescope".

    % Get total numer of data stores and number of data stores rescoped
    totalNumDataStores = length(find_system(model, 'BlockType', 'DataStoreMemory'));
    numPushed = length(memToRescope);
    
    % Open logfile
    filename = [model '_PushDownLog.txt'];
    file = fopen(filename, 'wt');
    
    % Print overall statistics for the whole model
    fprintf(file, 'Total number of Data Store Memory blocks in model: %d\n', totalNumDataStores);
    fprintf(file, 'Total number of Data Store Memory blocks pushed down: %d\n', numPushed);
    fprintf(file, 'Percentage of Data Store Memory blocks pushed down: %d%%\n\n', round((numPushed/totalNumDataStores)*100));
    fprintf(file, 'List of Data Store Memory blocks pushed down:\n\n');

    % Log initial address and final address for each block being rescoped
    for doc = 1:length(memToRescope)
        if ~strcmp(initialAddress{doc}, toRescopeAddress{doc})
            fprintf(file, 'Block Name: %s\n', memToRescope{doc});
            fprintf(file, 'Initial Location: %s\n', initialAddress{doc});
            fprintf(file, 'New Location: %s\n\n', toRescopeAddress{doc});
        end
    end
    fclose(file);
end

