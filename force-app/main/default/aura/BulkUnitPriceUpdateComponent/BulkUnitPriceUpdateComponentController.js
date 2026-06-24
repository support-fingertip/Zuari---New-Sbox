({
    doInit : function(component, event, helper) {
        helper.getPicklistValues(component, event);
        helper.getPicklistValues2(component, event);
        helper.getUnitStatus(component, event);

        component.set('v.mycolumns3', [
            {label: 'Unit Name', fieldName: 'Name', type: 'text', sortable: true, initialWidth: 180},
            {label: 'BHK Type', fieldName: 'BHK_Type__c', type: 'text', sortable: true, initialWidth: 130},
            {label: 'Wing', fieldName: 'Wing__c', type: 'text', sortable: true, initialWidth: 120},
            {label: 'Status', fieldName: 'Status__c', type: 'text', sortable: true, initialWidth: 130},
        ]);

        var action = component.get("c.getuserdetails");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.users', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    closeModal : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    handleOnChange: function(component, event, helper) {
        var bhktype = component.find("bhkPicklist").get("v.value");
        var wingValue = component.find("wingPicklist").get("v.value");
        var unitstatusValue = component.find("unitStatusPicklist").get("v.value");
        component.set("v.bhkType", bhktype);
        component.set("v.wingValue", wingValue);
        component.set("v.unitStatus", unitstatusValue);
        
        // Reset selections when filters change
        component.set('v.selectedRowsCount4', 0);
        component.set('v.selectedUsers', []);
        component.set('v.selectedRows', []);

        helper.getFilteredUnit(component, event, helper, unitstatusValue);
    },

    fetchbeats : function(component, event, helper) {
        component.set('v.showupcoming', false);
        if(component.get('v.SEId') != null && component.get('v.SEId') != ''){
            component.set('v.spinner', true);
            var action = component.get("c.getupcominbeats");
            action.setParams({'uId': component.get('v.SEId')});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.mydata3", response.getReturnValue());
                    component.set('v.showupcoming', true);
                    component.set('v.spinner', false);
                }
            });
            $A.enqueueAction(action);
        }
    },

    handleRowAction3: function (component, event, helper) {
        component.set('v.spinner', true);
        var row = event.getParam('row');
        component.set('v.beatId', row.Id);
        var action = component.get("c.getvisitList");
        action.setParams({'BeatId': row.Id});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.mydata4', response.getReturnValue());
                component.set('v.showrecent', true);
                component.set('v.spinner', false);
            }
        });
        $A.enqueueAction(action);
    },

    docancel2: function (component, event, helper) {
        helper.doCancel(component, event, helper);
    },

    updateSelectedText4: function (component, event) {
        var selectedRows = event.getParam('selectedRows');
        component.set('v.selectedRowsCount4', selectedRows.length);
        component.set('v.selectedUsers', selectedRows);
    },

    changeBeatOwner: function (component, event, helper) {
        var project = component.find("enter-search").get("v.value");
        component.set('v.searchText2', project);

        if(component.get('v.searchText2') != null && 
           component.get('v.searchText2') != '' && 
           component.get('v.searchText2') != undefined && 
           component.get('v.searchText2') > 0) {

            component.set('v.spinner', true);
            var action = component.get("c.updateOwner");
            action.setParams({
                'contacts': component.get('v.selectedUsers'),
                'price': project
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set('v.mydata3', response.getReturnValue());
                    component.set('v.selectedUsers', []);
                    component.set('v.selectedRows', []);
                    component.set('v.selectedRowsCount4', 0);
                    component.set('v.spinner', false);
                    helper.doCancel(component, event, helper);
                    helper.showToast("Unit Price changed successfully!", "success");
                    $A.get("e.force:closeQuickAction").fire();
                }
            });
            $A.enqueueAction(action);
        } else {
            helper.showToast("Please enter a valid Unit Price", "error");
        }
    },

    searchText : function(component, event, helper) {
        var routes = component.get('v.users');
        var searchText = component.get('v.searchText');
        var matchroutes = [];
        if(searchText != ''){
            for(var i = 0; i < routes.length; i++){
                if(routes[i].Name.toLowerCase().indexOf(searchText.toLowerCase()) != -1){
                    matchroutes.push(routes[i]);
                }
            }
            if(matchroutes.length > 0){
                component.set('v.matchUsers', matchroutes);
            }
        } else {
            component.set('v.matchUsers', []);
        }
    },

    searchText2 : function(component, event, helper) {
        var routes = component.get('v.users');
        var searchText = component.get('v.searchText2');
        var matchroutes = [];
        if(searchText != ''){
            for(var i = 0; i < routes.length; i++){
                if(routes[i].Name.toLowerCase().indexOf(searchText.toLowerCase()) != -1){
                    matchroutes.push(routes[i]);
                }
            }
            if(matchroutes.length > 0){
                component.set('v.matchUsers2', matchroutes);
            }
        } else {
            component.set('v.matchUsers2', []);
        }
    },

    update: function(component, event, helper) {
        component.set('v.userId', event.currentTarget.dataset.id);
        component.set('v.showUsers', true);
        var rdi = component.get('v.userId');
        var routes = component.get('v.matchUsers');
        for(var i = 0; i < routes.length; i++){
            if(routes[i].Id === rdi){
                component.set('v.searchText', routes[i].Name);
                break;
            }
        }
        component.set('v.matchUsers', []);
        if(component.get('v.userId') != null && component.get('v.userId') != ''){
            component.set('v.spinner', true);
            component.set('v.showFilter', true);
            helper.getFilteredLead(component, event, helper);
        }
    },

    update2: function(component, event, helper) {
        component.set('v.NextUserId', event.currentTarget.dataset.id);
        var rdi = component.get('v.NextUserId');
        var routes = component.get('v.matchUsers2');
        for(var i = 0; i < routes.length; i++){
            if(routes[i].Id === rdi){
                component.set('v.searchText2', routes[i].Name);
                break;
            }
        }
        component.set('v.matchUsers2', []);
    },
})