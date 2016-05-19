% Register custom menu function at the end of Simulink Editor's context menu
function sl_customization(cm)
  cm.addCustomMenuFcn('Simulink:ContextMenu', @getMcMasterTool);
  cm.addCustomFilterFcn('McMasterTool:RescopeSelected', @RescopeFilter);
  cm.addCustomFilterFcn('McMasterTool:RescopeNonSelected', @RescopeFilter);
end

% Define the custom menu function
function schemaFcns = getMcMasterTool(callbackInfo)
    schemaFcns = {@getRescopeContainer}; 
end

% Define Push-Down submenu
function schema = getRescopeContainer(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Data Store Rescope';
    schema.childrenFcns = {@getRescopeAll, @getRescopeSel, @getRescopeNon};
end

% Define Push All menu item
function schema = getRescopeAll(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Rescope All';
    schema.userdata = 'rescopeall';
    schema.callback = @RescopeAllCallback;
end

function RescopeAllCallback(callbackInfo)
    DataStoreRescope(gts, {});
end

% Define Push Selected menu item
function schema = getRescopeSel(callbackInfo)
    schema = sl_action_schema;
    schema.tag = 'McMasterTool:RescopeSelected';
    schema.label = 'Rescope Selected';
    schema.userdata = 'rescopeselected';
    schema.callback = @RescopeSelCallback;
end

function RescopeSelCallback(callbackInfo)
    RescopeSelected(gts, gcbs)
end

% Define Push Non-Selected menu item
function schema = getRescopeNon(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Rescope Non-Selected';
    schema.tag = 'McMasterTool:RescopeNonSelected';
    schema.userdata = 'rescopenonselected';
    schema.callback = @RescopeNonCallback;
end

function RescopeNonCallback(callbackInfo)
    DataStoreRescope(gts, gcbs);
end

%greys out menu options for Rescope Selected and Rescope Non-selected
%when the currently selected block isn't a data store block
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
