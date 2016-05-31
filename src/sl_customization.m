%% Register custom menu function to beginning of Simulink Editor's context menu
function sl_customization(cm)
  cm.addCustomMenuFcn('Simulink:PreContextMenu', @getMcMasterTool);
  cm.addCustomFilterFcn('McMasterTool:RescopeSelected', @RescopeFilter);
  cm.addCustomFilterFcn('McMasterTool:RescopeNonSelected', @RescopeFilter);
end

%% Define the custom menu function
function schemaFcns = getMcMasterTool(callbackInfo)
    schemaFcns = {@getRescopeContainer}; 
end

%% Define Data Store Rescope submenu
function schema = getRescopeContainer(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Data Store Rescope';
    schema.childrenFcns = {@getRescopeAll, @getRescopeSel, @getRescopeNon};
end

%% Define Rescope All menu item
function schema = getRescopeAll(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Rescope All';
    schema.userdata = 'rescopeAll';
    schema.callback = @RescopeAllCallback;
end

function RescopeAllCallback(callbackInfo)
    dataStoreRescope(bdroot, {});
end

%% Define Rescope Selected menu item
function schema = getRescopeSel(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Rescope Selected';
    schema.tag = 'McMasterTool:RescopeSelected';
    schema.userdata = 'rescopeSelected';
    schema.callback = @RescopeSelCallback;
end

function RescopeSelCallback(callbackInfo)
    rescopeSelected(bdroot, gcbs)
end

% Define Rescope Non-Selected menu item
function schema = getRescopeNon(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Rescope Non-Selected';
    schema.tag = 'McMasterTool:RescopeNonSelected';
    schema.userdata = 'rescopeNonSelected';
    schema.callback = @RescopeNonCallback;
end

function RescopeNonCallback(callbackInfo)
    dataStoreRescope(bdroot, gcbs);
end

% Grey out menu options for Rescope Selected and Rescope Non-selected when 
% the currently selected block is not a Data Store block
function state = RescopeFilter(callbackInfo)
    if (strcmp(get_param(gcb, 'BlockType'), 'DataStoreRead') || ...
        strcmp(get_param(gcb, 'BlockType'), 'DataStoreWrite') || ...
        strcmp(get_param(gcb, 'BlockType'), 'DataStoreMemory')) && ...
        strcmp(get_param(gcb, 'Selected'), 'on')
            state = 'Enabled';
    else
            state = 'Disabled';
    end
end
