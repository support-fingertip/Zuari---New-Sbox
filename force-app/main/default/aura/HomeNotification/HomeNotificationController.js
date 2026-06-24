({
    doInit : function(component, event, helper) {
        helper.getFollowUpDetails(component, event, helper);
        helper.getSiteVisitDetails(component, event, helper);
        helper.getPendingFollowUpDetails(component, event, helper);
        helper.getPendingSiteVisitDetails(component, event, helper);
        helper.loadRecords(component);
        helper.getreassignedLeads(component, event, helper);
        helper.loadNoActivityRecords(component, event, helper);
        helper.getMissedTaskDetails(component, event);
        helper.renderEveryMin(component, event, helper);
        helper.loadRecords(component, event, helper);
        //helper.bookingRecords(component, event, helper);
        //helper.getNoFollwpLeads(component, event, helper);
        
    },
    onCallHandler:function(component, event, helper) {
        
        var leadRecordID=event.getSource().get("v.name");
       // alert(leadRecordID);
        component.set("v.leadRecID",leadRecordID);
        component.set("v.isCall",true);
       // helper.initiateCall(component);
        
        
    },
    onsvHandler:function(component, event, helper) {
        var svleadRecordID=event.getSource().get("v.name");
        //alert(svleadRecordID);
        component.set("v.SvleadRecID",svleadRecordID);
        component.set("v.isSv",true);   
    },
    onfollowupHandler:function(component, event, helper) {
        var flsleadRecordID=event.getSource().get("v.name");
        component.set("v.FlsleadRecId",flsleadRecordID);
        component.set("v.isfls",true);   
    },
    
    onChange: function(component,event,helper){
          alert('hi')
      
        component.set("v.isCancelled",false);
        component.set("v.isConducted",false);
        component.set("v.isReschedule",false);
        component.set("v.updateValue","");
        var StatusValue=component.find('StatusID').get('v.value');
        alert(StatusValue)
        if(StatusValue=='Cancelled')
            component.set("v.isCancelled",true);
        else if(StatusValue=='Completed')
            component.set("v.isConducted",true);
            else if(StatusValue=='Rescheduled')
                component.set("v.isReschedule",true);
    },
    onChange1: function(component, event, helper) {
        component.set("v.isScheduled1", false);
        component.set("v.isMissed1", false);
        component.set("v.isCompleted1", false);

        var status = component.find('StatusID1').get('v.value');

        if (status === 'Cancelled') {
            component.set("v.isScheduled1", true);
        } else if (status === 'Missed') {
            component.set("v.isMissed1", true);
        } else if (status === 'Completed') {
            component.set("v.isCompleted1", true);
        }

        if (status !== 'Completed') {
            component.set("v.expectedFollowUp", "");
            component.set("v.showNextFollowUp", false);
            component.set("v.nextFollowUpDate", null);
        } else {
            var ef = component.get("v.expectedFollowUp");
            component.set("v.showNextFollowUp", ef === "Continue Follow Up");
        }
    },

    onExpectedFollowUpChange: function(component, event, helper) {
        var val = event.getSource().get("v.value");
        component.set("v.expectedFollowUp", val);
        component.set("v.showNextFollowUp", val === "Continue Follow Up");

        if (val !== "Continue Follow Up") {
            component.set("v.nextFollowUpDate", null);
        }
    },

    validateNextFollowUpDate: function(component, event, helper) {
        try {
            var value = event.getSource().get("v.value");
            if (!value) return;

            var selected = new Date(value);
            var today = new Date();
            today.setHours(0, 0, 0, 0);

            if (selected < today) {
                event.getSource().setCustomValidity("Next Follow Up cannot be in the past.");
            } else {
                event.getSource().setCustomValidity("");
            }
            event.getSource().reportValidity();
        } catch (e) {
            console.error("validateNextFollowUpDate crashed:", e);
        }
    },

    onsitevisitHandler:function(component, event, helper) {
        var svleadRecordID=event.getSource().get("v.name");
        component.set("v.SvleadRecID",svleadRecordID);
        component.set("v.isSv",true); 
        
    
    },
    
    onChange:function(component,event,helper){
        component.set("v.isCancelled",false);
        component.set("v.isReschedule",false);
        
        var StatusValue=component.find('StatusID').get('v.value');
        
        if(StatusValue=='Cancelled')
            component.set("v.isCancelled",true);
        else if(StatusValue=='Rescheduled')
            component.set("v.isReschedule",true);
            else if(StatusValue=='Completed')
                component.set("v.isConducted",true);
    },
    UpdateSvStatus:function(component,event,helper){
        var StatusValue=component.find('StatusID').get('v.value');
        var UpdatedValue=component.get("v.updateValue");
        var completedDate=component.get("v.conductedDate");
        var siteVisitRating=component.get("v.siteVisitRating");
        
       
        if (StatusValue === "Cancelled" && UpdatedValue =='') {
  helper.displayMessage(component, "Cancel Reason is required when status is Cancelled", "error");
return;
}
        if (StatusValue === "Rescheduled") {
            if (!completedDate || completedDate === '') {
                helper.displayMessage(component, "Rescheduled Date is required", "error");
                return;
            }
            
            // Convert to Date object
            var selectedDate = new Date(completedDate);
            
            // Get today's date (remove time portion)
            var today = new Date();
            today.setHours(0, 0, 0, 0);
            
            // Check if selected date is today or before
            if (selectedDate <= today) {
                helper.displayMessage(component, "Please select a future date only", "error");
                return;
            }
        }
        if (StatusValue === "Completed" && siteVisitRating==''){
            helper.displayMessage(component, "Site Visit Rating is required ", "error");
return;
            
        } else if(StatusValue === "Completed" && completedDate =='') {
           
  helper.displayMessage(component, "Completed Date is required ", "error");
return;
        }else if (StatusValue === "Completed" && UpdatedValue =='') {
  helper.displayMessage(component, "Please enter the Comments ", "error");
            return;}
         

                              
        
       //alert(UpdatedValue)
        if((StatusValue=='Rescheduled') && UpdatedValue !='')
           UpdatedValue= new Date(UpdatedValue).toLocaleString('en-GB');
        if(StatusValue!='' )
        {
            helper.updateSvDetails(component, event,StatusValue,UpdatedValue,helper);
            var closeMethod = component.get('c.closeModel');
            
            $A.enqueueAction(closeMethod);
        }
    },
    UpdateflsStatus:function(component,event,helper){
        var StatusValue1=component.find('StatusID1').get('v.value');
        var UpdatedValue=component.get("v.updateValue1");
        // Check ONLY when status is Completed or Missed
        if (StatusValue1 === 'Completed' || StatusValue1 === 'Missed') {
            if (!UpdatedValue || UpdatedValue.trim() === '') {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "Error",
                    message: "Please fill Update Status for Completed or Missed.",
                    type: "error"
                });
                toastEvent.fire();
                return; // stop
            }
        }
        if(StatusValue1!='' && UpdatedValue != '')
        {
            helper.UpdateflsDetails(component, event,StatusValue1,UpdatedValue,helper);
            var closeMethod = component.get('c.closeModel');
            
            $A.enqueueAction(closeMethod);
            
        }
    },
    closeModel: function(component, event, helper) {
        component.set("v.isCall",false);
        component.set("v.isSv",false);
        component.set("v.isfls",false);
        component.set("v.isCancelled",false);
        component.set("v.isConducted",false);
        component.set("v.isReschedule",false);
        component.set("v.updateValue","");
        
        component.set("v.isScheduled1",false);
        component.set("v.isMissed1",false);
        component.set("v.isCompleted1",false);
        
        component.set("v.SvleadRecID","");
        component.set("v.FlsleadRecId","");
        component.set("v.leadRecID","");
    },
    onsvCallHandler:function(component, event, helper) {
        var leadRecordID=event.getSource().get("v.name");
        //alert(leadRecordID);
        component.set("v.leadRecID",leadRecordID);
        component.set("v.isCall",true);
        
    },
    FollwuppreviousPage: function (component, event, helper) {
        // Decrement current page and load previous records
        var currentPage = component.get("v.FollwupcurrentPage");
        component.set("v.FollwupcurrentPage", currentPage - 1);
        helper.getFollowUpDetails(component);
    },
    FollwupnextPage: function (component, event, helper) {
        // Increment current page and load next records
        var currentPage = component.get("v.FollwupcurrentPage");
        component.set("v.FollwupcurrentPage", currentPage + 1);
        helper.getFollowUpDetails(component);
    },
    SitevisitpreviousPage: function (component, event, helper) {
        // Decrement current page and load previous records
        var currentPage = component.get("v.SiteVisitcurrentPage");
        component.set("v.SiteVisitcurrentPage", currentPage - 1);
        helper.getSiteVisitDetails(component);
    },
    SitevisitnextPage: function (component, event, helper) {
        // Increment current page and load next records
        var currentPage = component.get("v.SiteVisitcurrentPage");
        component.set("v.SiteVisitcurrentPage", currentPage + 1);
        helper.getSiteVisitDetails(component);
    },
    
    previousPage: function (component, event, helper) {
        // Decrement current page and load previous records
        var currentPage = component.get("v.SiteVisitcurrentPage");
        component.set("v.SiteVisitcurrentPage", currentPage - 1);
        helper.getSiteVisitDetails(component);
    },
    nextPage: function (component, event, helper) {
        // Increment current page and load next records
        var currentPage = component.get("v.currentPage");
        component.set("v.currentPage", currentPage + 1);
        helper.loadRecords(component);
    },
    leadpreviousPage: function (component, event, helper) {
        // Decrement current page and load previous records
        var currentPage = component.get("v.currentPage");
        component.set("v.currentPage", currentPage - 1);
        helper.loadRecords(component);
    },
    /*NoActivitypreviousPage: function (component, event, helper) {
        // Decrement current page and load previous records
        var currentPage = component.get("v.NoActivitycurrentPage");
        component.set("v.NoActivitycurrentPage", currentPage - 1);
        helper.loadNoActivityRecords(component);
    },*/
    NoActivitynextPage: function (component, event, helper) {
        // Increment current page and load next records
        var currentPage = component.get("v.NofollowupcurrentPage");
        component.set("v.NofollowupcurrentPage", currentPage + 1);
        helper.getNoFollwpLeads(component);
    },
    NofollowuppreviousPage: function (component, event, helper) {
        // Decrement current page and load previous records
        var currentPage = component.get("v.NofollowupcurrentPage");
        component.set("v.NofollowupcurrentPage", currentPage - 1);
        helper.getNoFollwpLeads(component);
    },
    NofollowupnextPage: function (component, event, helper) {
        // Increment current page and load next records
        var currentPage = component.get("v.NoActivitycurrentPage");
        component.set("v.NoActivitycurrentPage", currentPage + 1);
        helper.getNoFollwpLeads(component);
    },
    BookingpreviousPage: function (component, event, helper) {
        // Decrement current page and load previous records
        var currentPage = component.get("v.BookingcurrentPage");
        component.set("v.BookingcurrentPage", currentPage - 1);
        helper.bookingRecords(component);
    },
    BookingnextPage: function (component, event, helper) {
        // Increment current page and load next records
        var currentPage = component.get("v.BookingcurrentPage");
        component.set("v.BookingcurrentPage", currentPage + 1);
        helper.bookingRecords(component);
    },
    navigateToLeadRecord: function(component, event, helper) {
        var recordId = event.currentTarget.getAttribute("value");
        var navigateEvent = $A.get("e.force:navigateToSObject");
        navigateEvent.setParams({
            "recordId": recordId,
            "slideDevName": "detail"
        });
        navigateEvent.fire();
    },
    addCustomerEvent: function(component, event, helper) {
        component.set('v.isModalOpen',true);
    },
    closeModal: function(component, event, helper) {
        // Close the modal by setting the isCall attribute to false
        component.set("v.isCall", false);
    },
    

})