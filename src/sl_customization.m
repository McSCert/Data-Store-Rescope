% Register custom menu function at the end of Simulink Editor's context menu
function sl_customization(cm)
  cm.addCustomMenuFcn('Simulink:ContextMenu', @getMySLToolbox);
end

% Define the custom menu function
function schemaFcns = getMySLToolbox(callbackInfo) 
    schemaFcns = {@getPushdownContainer}; 
end

% Define Push-Down submenu
function schema = getPushdownContainer(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Push-Down';
    schema.childrenFcns = {@getPushAll, @getPushSel, @getPushNon, @getRepair};
end

% Define Push All menu item
function schema = getPushAll(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Push All';
    schema.userdata = 'pushall';
    schema.callback = @PushAllCallback;
end

function PushAllCallback(callbackInfo)
    PushDown(gts, {});
end

% Define Push Selected menu item
function schema = getPushSel(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Push Selected';
    schema.userdata = 'pushselected';
    schema.callback = @PushSelCallback;
end

function PushSelCallback(callbackInfo)
    PushSelected(gts, gcbs)
end

% Define Push Non-Selected menu item
function schema = getPushNon(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Push Non-Selected';
    schema.userdata = 'pushnonselected';
    schema.callback = @PushNonCallback;
end

function PushNonCallback(callbackInfo)
    PushDown(gts, gcbs);
end

% Define Repair Data Store menu item
function schema = getRepair(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Repair';
    schema.userdata = 'repairdatastore';
    schema.callback = @RepairCallback;
end

function RepairCallback(callbackInfo)
    RepairDataStore(gts, gcbs)
end