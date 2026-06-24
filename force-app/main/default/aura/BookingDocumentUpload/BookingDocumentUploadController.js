({
    doInit : function(component, event, helper) {
        helper.setupDocTypes(component);
        helper.setupColumns(component);
        helper.fetchDocuments(component);
    },

    refresh : function(component, event, helper) {
        helper.fetchDocuments(component);
    },

    onDocChange : function(component, event, helper) {
        helper.fetchDocuments(component);
    },

    openPreview : function(component, event, helper) {
        var docId = event.currentTarget.dataset.id;

        var navEvt = $A.get("e.force:navigateToURL");
        navEvt.setParams({
            "url": "/lightning/r/ContentDocument/" + docId + "/view"
        });
        navEvt.fire();
    }
});