({
    navigateToInspectionPage: function(component, event, helper) {
        // Navigate to a custom component page
        var navService = component.find("navigation");
        var pageReference = {
            "type": "standard__component",
            "attributes": {
                "componentName": "c__SnagListComponent"  // Replace with your component's name
            }
        };
        navService.navigate(pageReference);
    }
})