({
    doInit: function(component, event, helper) {
        var action = component.get("c.getProjects");
        // action.setParams({'recId':  component.get('v.recordId') });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var db = response.getReturnValue();
                component.set('v.projects', db);
                
                // Calculate totals after projects are set
                helper.calculateTotals(component);
            } else {
                console.error('Failed to retrieve projects with state: ' + state);
            }
        });
        
        $A.enqueueAction(action);
        
        
    helper.getPicklistValues(component, 'Plot__c', 'BHK_Type__c', 'bhkTypeOptions');
    helper.getPicklistValues(component, 'Plot__c', 'Status__c', 'statusOptions');
    helper.getPicklistValues(component, 'Plot__c', 'Wing__c', 'wingNames');
    },
    loadPlots: function(component, event, helper) {
        var target = event.currentTarget;
        var dataIndex = target.dataset.index;
        var record = target.dataset.id;
        
    helper.handleProjectChange(component, record); 
        var projectName = target.dataset.name;
        component.set("v.projectName",projectName||'');
        var action = component.get("c.getPlots");
        action.setParams({'Project':  record });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS") { 
                var db = response.getReturnValue();
                
                var bookedPlots = [];
                var notReleasedPlots = [];
                var soldPlots = [];
                var blockedPlots = [];
                var availablePlots = [];
                
                db.forEach(function(plot) {
                    switch(plot.Status__c) {
                        case 'Booked':
                            bookedPlots.push(plot);
                            break;
                        case 'NFS':
                            notReleasedPlots.push(plot);
                            break;
                        case 'Sold':
                            soldPlots.push(plot);
                            break;
                        case 'Blocked':
                            blockedPlots.push(plot);
                            break;
                        case 'Available':
                            availablePlots.push(plot);
                            break;
                    }
                });
                
                component.set('v.BookedPlots', bookedPlots);
                component.set('v.NotReleasedPlots', notReleasedPlots);
                component.set('v.SoldPlots', soldPlots);
                component.set('v.BlockedPlots', blockedPlots);
                component.set('v.AvailablePlots', availablePlots);
                component.set('v.showPlots', true);
                component.set('v.showProjects', false);
                component.set('v.Plots',db);
                component.set('v.filteredPlots',db);
            }
        });
        $A.enqueueAction(action);
    },
    navigatePlots: function(component, event, helper) {
        var plotId = event.currentTarget.dataset.id;
        console.log('plotId'+plotId);
        var navService = component.find("navService");
        var pageReference = {
            type: "standard__recordPage",
            attributes: {
                recordId: plotId,
                objectApiName: "Plot__c",
                actionName: "view"
            }
        };
        navService.navigate(pageReference);
    },
    
    handleCreateBooking:function(component, event, helper){
        var target = event.currentTarget;
        var record = target.dataset.id;
        component.set("v.unitId",record);
        component.set("v.showCreateBooking",true);
    },
    /*
      handleFilterChange1: function(component, event, helper) {
    // Get the updated filter values
    let filterBlock = component.get("v.filterBlock");
    let filterBHKType = component.get("v.filterBHKType");
    let filterStatus = component.get("v.filterStatus");
    let filterWing = component.get("v.filterWing");
    
    // If value is "All", treat it as empty (no filtering for this field)
    if (filterBlock === "All") filterBlock = "";
    if (filterBHKType === "All") filterBHKType = "";
    if (filterStatus === "All") filterStatus = "";
    if (filterWing === "All") filterWing = "";
    
    let allUnits = component.get("v.Plots"); 
    
    // Filter the units based on selected criteria
    let filteredUnits = allUnits.filter(function(unit) {
        // Start with assuming the unit passes all filters
        let blockMatch = true;
        let bhkTypeMatch = true;
        let statusMatch = true;
        let wingMatch = true;
        
        if (filterBlock && filterBlock !== "") {
            blockMatch = unit.Block_Name__c === filterBlock;
        }
        
        if (filterBHKType && filterBHKType !== "") {
            bhkTypeMatch = unit.BHK_Type__c === filterBHKType;
        }
        
        if (filterStatus && filterStatus !== "") {
            statusMatch = unit.Status__c === filterStatus;
        }
        if (filterWing && filterWing !== "") {
            wingMatch = unit.Wing__c === filterWing;
        }
        
        return blockMatch && bhkTypeMatch && statusMatch && wingMatch;
    });
    
    component.set("v.filteredPlots", filteredUnits);
},
    */
handleFilterChange: function(component, event, helper) {
    // Get all filter values including search text
    let filterBlock = component.get("v.filterBlock");
    let filterBHKType = component.get("v.filterBHKType");
    let filterStatus = component.get("v.filterStatus");
    let filterWing = component.get("v.filterWing");
    let searchText = component.get("v.searchText") || "";
    
    // If value is "All", treat it as empty (no filtering for this field)
    if (filterBlock === "All") filterBlock = "";
    if (filterBHKType === "All") filterBHKType = "";
    if (filterStatus === "All") filterStatus = "";
    if (filterWing === "All") filterWing = "";
    
    let allUnits = component.get("v.Plots"); 
    
    // Convert search text to lowercase for case-insensitive matching
    let searchTerm = searchText.toLowerCase();
    
    // Filter the units based on selected criteria
    let filteredUnits = allUnits.filter(function(unit) {
        // Start with assuming the unit passes all filters
        let blockMatch = true;
        let bhkTypeMatch = true;
        let statusMatch = true;
        let wingMatch = true;
        let searchMatch = true;
        
        // Apply block filter if specified
        if (filterBlock && filterBlock !== "") {
            blockMatch = unit.Block_Name__c === filterBlock;
        }
        
        // Apply BHK type filter if specified
        if (filterBHKType && filterBHKType !== "") {
            bhkTypeMatch = unit.BHK_Type__c === filterBHKType;
        }
        
        // Apply status filter if specified
        if (filterStatus && filterStatus !== "") {
            statusMatch = unit.Status__c === filterStatus;
        }
        
        // Apply wing filter if specified
        if (filterWing && filterWing !== "") {
            wingMatch = unit.Wing__c === filterWing;
        }
        
        // Apply search filter if text entered
        if (searchTerm !== "") {
            // Search in multiple fields (customize with your actual field names)
            let unitName = (unit.Name || "").toLowerCase();
            let unitNumber = (unit.Unit_Number__c || "").toLowerCase();
            let unitDescription = (unit.Description__c || "").toLowerCase();
            
            searchMatch = unitName.includes(searchTerm) || 
                         unitNumber.includes(searchTerm) || 
                         unitDescription.includes(searchTerm);
        }
        
        return blockMatch && bhkTypeMatch && statusMatch && wingMatch && searchMatch;
    });
    
    // Update the filtered units in the component
    component.set("v.filteredPlots", filteredUnits);
    
},
   handleSearchChange: function(component, event, helper) {
        var searchText = event.getSource().get("v.value");
        component.set("v.searchText", searchText);
        
        // Fire filter change event
        helper.fireFilterChangeEvent(component);
    }  
})