({
    doInit: function(component, event, helper) {
         component.set("v.fromQucickAction", true);
        helper.onInit(component, event, helper);
        helper.readCallDetails(component, event, helper);
        
        const empApi = component.find("empApi");
        empApi.setDebugFlag(true);
        const replayId = -1;
        empApi
        .subscribe(
            "/event/CtitaskCreated__e",
            replayId,
            $A.getCallback(eventReceived => {
                helper.getDetails(
                component,
                event,
                helper,
                eventReceived.data.payload
                );
            })
                )
                .then(subscription => {});
                
                empApi
                .subscribe(
                "/event/CtiNotification__e",
                replayId,
                $A.getCallback(eventReceived => {
                helper.getCallDetails(
                component,
                event,
                helper,
                eventReceived.data.payload
                );
            })
                )
                .then(subscription => {});
                
                
                helper.getInitialValues(component, event, helper);
                
            },
                
                handleClear: function(component, event, helper) {
                    component.set("v.selectedPhone", "");
                },
                
                handleCall: function(component, event, helper) {
                    component.set("v.isdisabled",true);
                    var phone = component.get("v.selectedPhone");
                    //var subject = component.get("v.subject");
                    component.set("v.callcomplete", false);
                    console.log("phone!!!!!!!!!" + phone);
                    if (phone != undefined && phone.trim() != "") {
                        helper.callNumber(component, event, helper); 
                    } else {
                        helper.displayMessage(
                            component,
                            "Please select Phone number to make a call.",
                            "error"
                        );
                    }
                },
                
                refresh: function(component, event, helper) {
                    helper.onInit(component, event, helper);
                },
                saveCall: function(component, event, helper) {
                  //  helper.saveCall(component, event, helper);
                },
                handleError: function (cmp, event, helper) {
                    var error = event.getParams();
                    // Get the error message
                    let errorMessage = event.getParam("message");
                    // alert(errorMessage);
                    if(errorMessage.includes('resource does not exist') || errorMessage.includes('do not have the level of access') || errorMessage.includes('insufficient access')){
                        cmp.set('v.spinner',false);
                        var navEvent = $A.get("e.force:navigateToList");
                        navEvent.setParams({
                            "listViewId": '00B2w00000Pwpf1EAB',
                            "listViewName": null,
                            "scope": "Contact"
                        });
                        navEvent.fire();
                        $A.get("e.force:closeQuickAction").fire();
                    }else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "message": errorMessage,
                            "type":"Error"
                        });
                        toastEvent.fire();
                    }
                },
                handleLoad: function(component, event, helper) {
                    let record = component.get("v.LeadRecord");
                    console.log('record',+record);
                    if (record) {
                        component.set('v.leadStatus', record.Lead_status1__c);
                    }
                    component.set('v.spinner', false);
                },
                handleOnSubmit: function(component, event, helper) {
                    console.log('🔹 handleOnSubmit triggered');
                    
                    var status = component.get("v.leadStatus");
                  //  alert(status)
                    var followUpDate = component.get("v.followUpDate");
                    
                    console.log('Lead Status:', status);
                    console.log('Follow Up Date:', followUpDate);
                    if (status === 'Site Visit Schedule') {
                        component.set('v.isError', false);
                        console.log('Follow-up validation skipped for Site Visit Schedule');
                        return;
                    }
                    
                    // Statuses where Follow Up Date is NOT required
                    var excludedStatuses = [
                        'Rejected',
                        'Closed Lost',
                        'Request for Rejection',
                        'Unqualified'
                    ];
                    // Follow-Up required only when NOT excluded
                 // alert(excludedStatuses.includes(status));
                 
                    if (!excludedStatuses.includes(status)) {
                        if (!followUpDate) {
                            helper.displayMessage(
                                component,
                                'Follow Up Schedule Date is mandatory for selected status',
                                'error'
                            );
                            component.set('v.isError', true);
                            event.preventDefault(); // ⛔ stop save
                            return;
                        }
                        
                        // Past date validation
                        var today = new Date();
                        var selected = new Date(followUpDate);
                        
                        if (selected < today) {
                            helper.displayMessage(
                                component,
                                'Please select a future Follow Up Date',
                                'error'
                            );
                            component.set('v.isError', true);
                            event.preventDefault();
                            return;
                        }
                    }
                    
                    component.set('v.isError', false);
                    console.log('✅ Validation passed');
                },

                
                handleSuccess: function(component, event, helper) {
                    console.log('🔹 handleSuccess triggered');
                    
                    var isError = component.get('v.isError');
                    console.log('v.isError:', isError);
                    
                    if (!isError) {
                        // Get the response from the record edit form
                        var response = event.getParams().response;
                        console.log('Form response:', response);
                        
                        // Gather all parameters
                        var leadId = component.get("v.recordId");
                        var newNote = component.get("v.addNotes");
                        var isPrimary = component.get("v.isPrimary");
                        var isSecondary = component.get("v.isSecondary");
                        var followUpDate = component.get("v.followUpDate");
                        var siteVisitScheduledDate = component.get("v.siteVisitScheduled");
                        var followUpSubject = component.get("v.followUpSubject");
                        
                        console.log('Parameters for updateLastNote:', {
                            leadId,
                            newNote,
                            isPrimary,
                            isSecondary,
                            followUpDate,
                            followUpSubject,
                            siteVisitScheduledDate
                        });
                            
                            var action = component.get("c.updateLastNote");
                            action.setParams({
                            leadId: leadId,
                            newNote: newNote,
                            isPrimary: isPrimary,
                            isSecondary: isSecondary,
                            followUpDate: followUpDate,
                            followUpSubject: followUpSubject,
                            siteVisitScheduledDate: siteVisitScheduledDate
                        });
                        
                        action.setCallback(this, function(response) {
                            var state = response.getState();
                            console.log('Apex response state:', state);
                            
                            if (state === 'SUCCESS') {
                                helper.displayMessage(component, 'Comments Updated Successfully', "success");
                            } else {
                                var errors = response.getError();
                                console.error('Apex error:', errors);
                                helper.displayMessage(component, (errors && errors[0] && errors[0].message) || 'Something Went Wrong', "error");
                            }
                            
                            $A.get("e.force:closeQuickAction").fire();
                        });
                        
                        $A.enqueueAction(action);
                        $A.get('e.force:refreshView').fire();
                    }
                },

                
                onLeadChange : function(component, event, helper){
                    component.set('v.spinner',true);
                   // component.set('v.leadStatus',event.getParam('value'));
                  //  var ss = component.get('v.leadStatus');
                   // alert(ss);
                    //alert(component.get('v.leadStatus'));
                    var status = component.find('leadStatus').get('v.value');
                    component.set('v.leadStatus',status);
                  
                     console.log('status==> ', status);
                     var excludedStatuses = [
                        'Rejected',
                        'Closed Lost',
                        'Request for Rejection',
                        'Unqualified'
                    ];
                    // Follow-Up required only when NOT excluded
                    component.set("v.isFollowUpRequired", !excludedStatuses.includes(status));
                      var ccc = component.get("v.isFollowUpRequired");
                     if(status == 'Rejected' || status == 'Closed Lost' || status == 'Unqualified' || status == 'Request for Rejection' ){
                        
                        component.set('v.isClosedOrUnqualified',true);
                    }
                    if(status == 'Site Visit Scheduled' || status == 'Site Visit Conducted'){
                      //  alert('Status cannot be changed for site visit');
                        component.set('v.showSave',false);
                    }
                    else{
                        component.set('v.showSave',true);
                    }
                    //alert(component.get('v.leadStatus'));
                    var leadStatus1 = event.getParam('value');
                    component.set('v.spinner',false);
                },
                close : function(component, event, helper){
                    $A.get("e.force:closeQuickAction").fire();
                }
            });