({
    closePanel: function(component) {
        var overlayLib = component.find('overlayLib');
        overlayLib.notifyClose();
    },

    refreshRecord: function(component, recordId) {
        var navService = component.find("navService");
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        };
        event.preventDefault();
        navService.navigate(pageReference);
    }
})