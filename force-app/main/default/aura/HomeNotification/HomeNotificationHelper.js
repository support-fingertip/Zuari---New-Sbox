({
    
    getFollowUpDetails: function(component, event, helper) {
        var pageNumber = component.get("v.FollwupcurrentPage");
        var pageSize = component.get("v.FollwuppageSize");
        var action = component.get("c.getFollowUpInformation");
        action.setParams({
            'pageNumber': pageNumber,
            'pageSize': pageSize
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state == "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.DuefollowUpDetails",JSON.parse(JSON.stringify(result.FollowupldList)));
                result.FollowupldList.forEach(ele => {
                    
                    var scheduledTime = new Date(
                    ele.Scheduled_Date__c
                    ).toLocaleTimeString("en-US");
                    ele.Scheduled_Date__c = scheduledTime;
                });
                component.set("v.followUpDetails", result.FollowupldList);
                component.set("v.FollwupLeadsCount", result.FollowupCount); 
                component.set("v.isFollwupPreviousDisabled", pageNumber === 1);
                component.set("v.isFollwupNextDisabled", result.FollowupldList.length < pageSize);
                
                var todaycount= component.get('v.SiteVisitsLeadsCount') + component.get('v.FollwupLeadsCount');
                var tabLabel = component.find("Agenda").get("v.label");
                var miss = "Today's Agends("+todaycount+")";
                tabLabel[0].set("v.value", miss);
                
                var fwLabel = component.find("Followups").get("v.label");
                var fwlb = "Today's Followups("+component.get('v.FollwupLeadsCount')+")";
                fwLabel[0].set("v.value", fwlb);
                
            }
        });
        $A.enqueueAction(action);
    },
    getreassignedLeads: function(component, event, helper) {
        var pageNumber = component.get("v.leadcurrentPage");
        var pageSize = component.get("v.leadpageSize");
        var action = component.get("c.getReassignedLeads");
        action.setParams({
            'pageNumber': pageNumber,
            'pageSize': pageSize
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state == "SUCCESS") {
                //alert('sUccess' + JSON.stringify(response.getReturnValue()));
                var result = response.getReturnValue();
                //alert('lsd' + JSON.stringify(result.noActivityldList));
                component.set("v.leadDetails", result.noActivityldList);
                component.set("v.leadPreviousDisabled", pageNumber === 1);
                component.set("v.leadNextDisabled", result.noActivityldList.length < pageSize);
                
            }
        });
        $A.enqueueAction(action);
    },
    getSiteVisitDetails: function(component, event, helper) {
        var pageNumber = component.get("v.SiteVisitcurrentPage");
        var pageSize = component.get("v.SiteVisitpageSize");
        let action = component.get("c.getSiteVistInformation");
        action.setParams({
            pageNumber: pageNumber,
            pageSize: pageSize
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            
            if (state == "SUCCESS") {
                var result = response.getReturnValue();
             //   console.log(JSON.stringify(result.SiteVisitldList));
             //   alert(JSON.stringify(result.SiteVisitldList))
            //    console.log(result.Noofsitevisits);
                component.set("v.DuesiteVisitDetails",JSON.parse(JSON.stringify(result.SiteVisitldList)));
               // console.log('FOL modfif=====>');
              //  console.log(component.get("v.DuesiteVisitDetails"));
                
                result.SiteVisitldList.forEach(ele => {
                    var scheduledTime = new Date(
                    ele.Scheduled_Date__c
                    ).toLocaleTimeString("en-US");
                    ele.Scheduled_Date__c = scheduledTime;
                });
             //   console.log('siteVisitDetails '+component.get("v.siteVisitDetails"));
             //   console.log('todayssitevistCount '+component.get("v.todayssitevistCount"));
                
                //console.log(ele);
                // var scheduledTime = new Date(ele.Date__c).toLocaleTimeString("en-US");
                //ele.Date__c = scheduledTime;
                component.set("v.siteVisitDetails", result.SiteVisitldList);
                component.set("v.SiteVisitsLeadsCount", result.Noofsitevisits);
                //component.set("v.SitevisitrecordList", records.SiteVisitldList);
                component.set("v.isSiteVisitPreviousDisabled", pageNumber === 1);
                component.set("v.isSiteVisitNextDisabled", result.SiteVisitldList.length < pageSize);
                
                
                
                //component.set("v.todayssitevistCount", result.SiteVisitLeadsCount); 
                var todaycount= component.get('v.SiteVisitsLeadsCount') + component.get('v.FollwupLeadsCount');
                var tabLabel = component.find("Agenda").get("v.label");
                var miss = "Today's Agenda("+todaycount+")";
                tabLabel[0].set("v.value", miss);
              //  console.log('#5')
                var tabLabel2 = component.find("Sitevisits").get("v.label");
                var miss2 = "Today Site Visit Scheduled("+component.get('v.SiteVisitsLeadsCount')+")";
                tabLabel2[0].set("v.value", miss2);
                
            }
        });
        $A.enqueueAction(action);
    },
    getPendingFollowUpDetails: function(component, event, helper) {
        let action = component.get("c.getPendingFollowUpInformation");
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state == "SUCCESS") {
                let result = response.getReturnValue();
                let check=[];
                result.forEach(ele => {
                    
                    var scheduledTime = new Date(
                    ele.Scheduled_Date__c
                    ).toLocaleTimeString("en-US");
                    ele.Scheduled_Date__c = scheduledTime;
                });
                component.set("v.pendingFollowUpDetails", result);
                component.set("v.pendingFollowupCount", result.length); 
                var pendingcount= component.get('v.pendingsitevistCount') + component.get('v.pendingFollowupCount');;
                var tabLabel = component.find("pending").get("v.label");
                var miss = "Pending items("+pendingcount+")";
                tabLabel[0].set("v.value", miss);
            }
        });
        $A.enqueueAction(action);
    },
    getPendingSiteVisitDetails: function(component, event, helper) {
        let action = component.get("c.getPendingSiteVistInformation");
        action.setCallback(this, function(response) {
            let state = response.getState();
            
            if (state == "SUCCESS") {
                let result = response.getReturnValue();
                result.forEach(ele => {
                //    console.log(ele);
                    var scheduledTime = new Date(ele.Date__c).toLocaleTimeString("en-US");
                    ele.Date__c = scheduledTime;
                });
                    component.set("v.pendingSiteVisitDetails", result);
                    component.set("v.pendingsitevistCount", result.length);
                    var pendingcount= component.get('v.pendingsitevistCount') + component.get('v.pendingFollowupCount');;
                    var tabLabel = component.find("pending").get("v.label");
                    var miss = "Pending items("+pendingcount+")";
                    tabLabel[0].set("v.value", miss);
                }
                });
                    $A.enqueueAction(action);
                },
                    getMissedTaskDetails: function(component, event, helper) {
                        let action = component.get("c.getMissedCallTask");
                        
                        action.setCallback(this, function(response) {
                            let state = response.getState();
                            
                            if (state == "SUCCESS") {
                                let result = response.getReturnValue();
                                // JSON.stringify()
                                // alert(JSON.stringify(result)+'=='+state)
                              //  console.log(result);
                                component.set("v.MissedTask", result);
                                var tabLabel = component.find("missedCalls").get("v.label");
                                var miss = "Missed calls("+result.length+")";
                                tabLabel[0].set("v.value", miss);
                                
                            }
                        });
                        $A.enqueueAction(action);
                    },          
                    updateSvDetails:function(component, event,status,updateValue,helper) {
                        var conductedDate=component.get("v.conductedDate");
                        var svrating = component.get("v.siteVisitRating");
                        
                        var comments= component.get("v.updateValue");

                        
                        //alert(conductedDate);
                        if(conductedDate!=null && conductedDate!='')
                            conductedDate= new Date(conductedDate).toLocaleString('en-GB');
                        var svrecID = component.get("v.SvleadRecID");
           
                        
                        let action = component.get("c.updateSvDetils");
                        action.setParams({ 
                            recID:svrecID,
                            svStatus: status,
                            updateValue: updateValue,
                            siterating: svrating,
                            conducatedDate: conductedDate
                            
                        });
                        action.setCallback(this, function(response) {
                            let state = response.getState();
                            if (state == "SUCCESS") {
                                let result = response.getReturnValue();
                                if(result!=null)
                                { 
                                    helper.displayMessage(component,"Site Visit Updated successfully", "SUCCESS");
                                    $A.get('e.force:refreshView').fire();
                                }
                                else
                                {
                                    helper.displayMessage(component,"Something went wrong. Message-", "error");
                                }
                            }
                        });
                        $A.enqueueAction(action);
                        
                    },
    UpdateflsDetails: function(component, event, status, updateValue, helper) {
        var svrecID1 = component.get("v.FlsleadRecId");
        
        var expected = component.get("v.expectedFollowUp");
        var nextDate = component.get("v.nextFollowUpDate");
        
        let action = component.get("c.updateFollowupDetails");
        action.setParams({
            recID: svrecID1,
            FLStatus: status,
            comments: updateValue,
            expectedFollowUp: expected,
            nextFollowUpDate: nextDate
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                helper.displayMessage(component, "Follow-Up Updated successfully", "SUCCESS");
                $A.get('e.force:refreshView').fire();
            } else {
                let errs = response.getError();
                console.error(errs);
                helper.displayMessage(
                    component,
                    (errs && errs[0] && errs[0].message) ? errs[0].message : "Something went wrong",
                    "error"
                );
            }
        });
        
        $A.enqueueAction(action);
    },

                    loadRecords: function (component, event, helper){
                        var pageNumber = component.get("v.currentPage");
                        var pageSize = component.get("v.pageSize");
                        
                        // Fetch records using Apex controller and update recordList attribute
                        var action = component.get("c.todaysLeads");
                        //alert(action);
                        action.setParams({
                            pageNumber: pageNumber,
                            pageSize: pageSize
                        });
                        action.setCallback(this, function (response) {
                            var state = response.getState();
                            //alert('Response state: ' + state);
                            if (state === "SUCCESS") {
                                var records = response.getReturnValue();
                                component.set("v.recordList", records.ldListtodays);
                                //alert(JSON.stringify(records.ldListtodays));
                                component.set("v.Todayscount", records.todaysldCount);
                                component.set("v.reengagedleads", records.ldreengagedleads);
                                //alert('Response state: ' + records.ldListtodays);
                                component.set("v.isPreviousDisabled", pageNumber === 1);
                                component.set("v.isNextDisabled", records.ldListtodays.length < pageSize);
                            }
                        });
                        $A.enqueueAction(action);
                    },
                    loadNoActivityRecords: function (component, event, helper) {
                        var pageNumber = component.get("v.NoActivitycurrentPage");
                        var pageSize = component.get("v.NoActivitypageSize");
                        
                        // Fetch records using Apex controller and update recordList attribute
                        var action = component.get("c.getnoactivityleads");
                        //alert(action);
                        action.setParams({
                            pageNumber: pageNumber,
                            pageSize: pageSize
                        });
                        action.setCallback(this, function (response) {
                            var state = response.getState();
                            //alert('Response state: ' + state);
                            if (state === "SUCCESS") {
                                var records = response.getReturnValue();
                                component.set("v.noactivitylist", records.noActivityldList);
                                if(records!=null && records!=''){
                                    component.set("v.NoActivityLeadsCount", records.noActivityCount); 
                                }
                                
                                
                                component.set("v.isNoActivityPreviousDisabled", pageNumber === 1);
                                component.set("v.isNoActivityNextDisabled", records.noActivityldList.length < pageSize);
                            }
                        });
                        $A.enqueueAction(action);
                    },
                    
                    getNoFollwpLeads: function (component, event, helper) {
                        var pageNumber = component.get("v.NofollowupcurrentPage");
                        var pageSize = component.get("v.NofollowuppageSize");
                        
                        // Fetch records using Apex controller and update recordList attribute
                        var action = component.get("c.getNoFollowUpLeads");
                        //alert(action);
                        action.setParams({
                            pageNumber: pageNumber,
                            pageSize: pageSize
                        });
                        action.setCallback(this, function (response) {
                            var state = response.getState();
                            //alert('Response state: ' + state);
                            if (state === "SUCCESS") {
                                var records = response.getReturnValue();
                                component.set("v.nofollowuplist", records.noActivityldList);
                                if(records!=null && records!=''){
                                    component.set("v.NofollowupLeadsCount", records.noActivityCount); 
                                }
                                
                                
                                component.set("v.isNofollowupPreviousDisabled", pageNumber === 1);
                                component.set("v.isNofollowupNextDisabled", records.noActivityldList.length < pageSize);
                            }
                        });
                        $A.enqueueAction(action);
                    },
                    
                    previousPage: function (component, event, helper) {
                        var currentPage = component.get("v.currentPage");
                        component.set("v.currentPage", currentPage - 1);
                        this.loadRecords(component);
                    }, 
                    nextPage: function (component, event, helper) {
                        var currentPage = component.get("v.currentPage");
                        component.set("v.currentPage", currentPage + 1);
                        this.loadRecords(component);
                    },
                    //previousPage: function (component) {
                    //   var currentPage = component.get("v.currentPage");
                    //component.set("v.FollwupcurrentPage", currentPage - 1);
                    // this.getFollowUpDetails(component);
                    //  }, 
                    //nextPage: function (component) {
                    //   var currentPage = component.get("v.currentPage");
                    //   component.set("v.currentPage", currentPage + 1);
                    //  this.loadRecords(component);
                    // },
                    calculateGreeting : function(userName) {
                        var greeting = "";
                        var currentHour = new Date().getHours();
                        
                        if (currentHour >= 5 && currentHour < 12) {
                            greeting = "Good morning, " + userName + "!";
                        } else if (currentHour >= 12 && currentHour < 18) {
                            greeting = "Good afternoon, " + userName + "!";
                        } else {
                            greeting = "Good evening, " + userName + "!";
                        }
                        
                        return greeting;
                    },
                    displayMessage : function(component,message,type){
                         
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": type,
                            "message": message
                        });
                        toastEvent.fire();
                    },
                    renderEveryMin :function(component, event, helper){
                        window.setTimeout(
                            $A.getCallback(function() {    
                              //  console.log('setTimeOut');
                                self.doneRendering(component, event);
                            }), 2000
                        );  
                        
                        //execute callApexMethod() again after 5 sec each
                        var self=  this; 
                        
                        window.setInterval(
                            $A.getCallback(function() {    
                             //   console.log('setInterval');
                                self.doneRendering(component, event);
                            }), 30000
                        );  
                        
                    },
                    doneRendering: function(cmp, event,helper){
                      //  console.log('here');
                        var Followup = cmp.get("v.DuefollowUpDetails");
                        var sv = cmp.get("v.DuesiteVisitDetails");
                      //  console.log(sv);
                        var today = new Date();
                        var curTime=today;
                        var indexList;
                       // console.log(Followup.length);
                        //Followup Render
                        if(Followup != undefined && Followup.length != undefined){
                            if(Followup.length>0)
                        {	indexList=[];
                         Followup.forEach((e,index)=>{
                             var fDate= new Date(e.Scheduled_Date__c);
                             if( fDate.getTime()< curTime.valueOf() )
                             indexList.push(index);
                         });
                         
                         var changeID=(cmp.find('OverTimeFollow'));
                         
                         if(changeID!=undefined && changeID.length==undefined && indexList.length>0)
                         {
                             $A.util.addClass(changeID,'overDue');     
                         }	
                         else if(changeID.length>0){
                             
                             changeID.forEach((e,index)=>{
                                 if(indexList.includes(index)){
                                 $A.util.addClass(e,'overDue'); 
                             }
                                              
                                              });
                             
                         }
                        }
                        }
                        
                        if(sv != undefined && sv.length != undefined){
                            //SV Render 
                        if(sv.length>0)
                        {
                            indexList=[];
                            sv.forEach((e,index)=>{ 
                                var svDate= new Date(e.Date__c);
                                if(svDate.getTime() < curTime.valueOf() )
                                indexList.push(index);
                            });
                            
                            var changeSV=(cmp.find('OverTimeSV')); 
                            if(changeSV!=undefined && changeSV.length!=undefined){
                                if(changeSV!=undefined && changeSV.length==undefined && indexList.length>0)
                                {
                                    $A.util.addClass(changeSV,'overDue');     
                                }
                                else if(changeSV.length>0 )
                                {
                                    
                                    changeSV.forEach((e,index)=>{        
                                        if(indexList.includes(index))
                                        $A.util.addClass(e,'overDue'); 
                                    }); 
                                }
                            }
                            
                            
                            
                        }
                        }
                        
                    },
                    bookingRecords: function (component, event, helper) {
                        var pageNumber = component.get("v.BookingcurrentPage");
                        var pageSize = component.get("v.BookingpageSize");
                        
                        // Fetch records using Apex controller and update recordList attribute
                        var action = component.get("c.todaysBookings");
                        //alert(action);
                        action.setParams({
                            pageNumber: pageNumber,
                            pageSize: pageSize
                        });
                        action.setCallback(this, function (response) {
                            var state = response.getState();
                            //alert('Response state: ' + state);
                            if (state === "SUCCESS") {
                                var records = response.getReturnValue();
                                component.set("v.bookingrecordList", records.ldListbooking);
                                component.set("v.BookingLeadCount", records.Noofbooking);
                                //alert('Response state: ' + records.ldListtodays);
                                component.set("v.isBookingPreviousDisabled", pageNumber === 1);
                                component.set("v.isBookingNextDisabled", response.getReturnValue().length < pageSize);
                            }
                        });
                        $A.enqueueAction(action);
                    },
                    
                    
                });