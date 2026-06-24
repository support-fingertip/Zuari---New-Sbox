trigger MasterPaymentTrigger on Master_Payment_Schedule__c (before insert, before update, After update, After insert) {
    
    
    if (Trigger.isBefore) {
        if(Trigger.isinsert){
            Set<Id> projectIds = new Set<Id>();
            
            for (Master_Payment_Schedule__c mps : Trigger.new) {
                if (mps.Project__c != null) {
                    projectIds.add(mps.Project__c);
                }
            }
            
            Map<Id, Set<Decimal>> projectToSlNoMap = new Map<Id, Set<Decimal>>();
            Map<Id, Decimal> projectToTotalPercentageMap = new Map<Id, Decimal>();
            
            // Query existing child records for the Project__c objects in the current trigger context
            List<Master_Payment_Schedule__c> existingRecords = [SELECT Id, Project__c, S_No__c, Payment_Percent__c, Due_Date__c FROM Master_Payment_Schedule__c WHERE Project__c IN :projectIds ORDER BY S_No__c DESC];
            
            // Map to track the latest due date for each project
            Map<Id, Date> projectToLastDueDateMap = new Map<Id, Date>();
            
            for (Master_Payment_Schedule__c record : existingRecords) {
                // SL. No mapping
                if (!projectToSlNoMap.containsKey(record.Project__c)) {
                    projectToSlNoMap.put(record.Project__c, new Set<Decimal>());
                }
                projectToSlNoMap.get(record.Project__c).add(record.S_No__c);
                
                // Total percentage mapping
                if (!projectToTotalPercentageMap.containsKey(record.Project__c)) {
                    projectToTotalPercentageMap.put(record.Project__c, 0);
                }
                projectToTotalPercentageMap.put(record.Project__c, projectToTotalPercentageMap.get(record.Project__c) + record.Payment_Percent__c);
                
                if (!projectToLastDueDateMap.containsKey(record.Project__c)) {
                    projectToLastDueDateMap.put(record.Project__c, record.Due_Date__c);
                }
            }
            
            // Loop through the new and updated records to validate uniqueness of SL. No, total percentage, and due date
            for (Master_Payment_Schedule__c mps : Trigger.new) {
                if (mps.Project__c != null) {
                    // Validate that Due_Date__c is not less than the last due date in the same project
                    Date lastDueDate = projectToLastDueDateMap.get(mps.Project__c);
                    if (lastDueDate != null && mps.Due_Date__c < lastDueDate) {
                        mps.addError('Due Date cannot be earlier than the last scheduled payment for this project, which is ' + lastDueDate.format());
                    }
                    
                    // Get the existing SL. Nos and total percentage for this project (if any)
                    Set<Decimal> slNosForProject = projectToSlNoMap.get(mps.Project__c);
                    Decimal totalPercentage = projectToTotalPercentageMap.get(mps.Project__c) != null ? projectToTotalPercentageMap.get(mps.Project__c) : 0;
                    
                    if (slNosForProject == null) {
                        slNosForProject = new Set<Decimal>();
                    }
                    
                    // SL. No validation
                    if (Trigger.isUpdate && Trigger.oldMap.get(mps.Id).S_No__c == mps.S_No__c) {
                        // If SL. No hasn't changed, skip the uniqueness validation
                    } else if (slNosForProject.contains(mps.S_No__c)) {
                      //  mps.addError('SL. No must be unique for each project record.');
                    } else {
                        slNosForProject.add(mps.S_No__c);
                    }
                    
                    // Calculate new total percentage including the current record
                    if (Trigger.isUpdate) {
                        totalPercentage -= Trigger.oldMap.get(mps.Id).Payment_Percent__c;  // Subtract old percentage (on update)
                    }
                    totalPercentage += mps.Payment_Percent__c;
                    
                    // Total percentage validation
                    if (totalPercentage > 100) {
                     //   mps.addError('Total payment percentage for this project cannot exceed 100%.');
                    } else {
                        // Update the map with the new total percentage
                        projectToTotalPercentageMap.put(mps.Project__c, totalPercentage);
                    }
                }
            }
        }
        //For testing for Bulk Demand Raise code is commented on 7-01-2025
        /*if(Trigger.isUpdate){
Map<Decimal, Master_Payment_Schedule__c> slNoToRecordMap = new Map<Decimal, Master_Payment_Schedule__c>();
for (Master_Payment_Schedule__c mps : Trigger.new) {
if (Trigger.oldMap.get(mps.Id).Due_Date__c != mps.Due_Date__c) {
Decimal slNo = mps.S_No__c; 
slNoToRecordMap.put(slNo, mps);
}
}
for (Decimal slNo : slNoToRecordMap.keySet()) {
Master_Payment_Schedule__c currentRecord = slNoToRecordMap.get(slNo);
Decimal nextSlNo = slNo + 1;

List<Master_Payment_Schedule__c> nextRecord = [SELECT Due_Date__c FROM Master_Payment_Schedule__c WHERE S_No__c = :nextSlNo AND Project__c = :currentRecord.Project__c LIMIT 1];

if (nextRecord.size()>0) {
if (currentRecord.Due_Date__c > nextRecord[0].Due_Date__c) {
currentRecord.addError('Due Date cannot be greater than the next Master Payment Schedule due date (SL No. ' + nextSlNo + ').');
}
}
}
}*/
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        Map<String,Id> projectWithSchedule = new Map<String,Id>();
        list<id> completedMPSIds = new list<id>();
        for(Master_Payment_Schedule__c mps : Trigger.New){
            if(mps.Status__c == 'Completed' && mps.Status__c != Trigger.oldmap.get(mps.Id).Status__c){
                projectWithSchedule.put(mps.Project__c,mps.Id);
                completedMPSIds.add(mps.Id);
            }
        }
        
        List<Booking__c> booklist = [select id,name,ownerId,Is_Owner_Active__c from Booking__c where Project1__c in: projectWithSchedule.keySet()];
        if(booklist.size() >0){
            Set<String> userIds = new Set<String>();
            for(Booking__c book : booklist){
                if(book.Is_Owner_Active__c == true){
                    userIds.add(book.OwnerId);
                }
            }
            for(Master_Payment_Schedule__c mps : Trigger.New){
                system.debug(mps);
                if(mps.Status__c == 'Completed' && mps.Status__c != Trigger.oldmap.get(mps.Id).Status__c){
                    system.debug('test1');
                    if(mps.Is_Last_Master_Payment_Schedule__c == true){
                        system.debug('test2');
                        string Body = 'Last Payment Milestone '+mps.Name+' for '+mps.Project_Name__c+' has been completed';
                        BookingController.sendCustomNotification(userIds,'Master Payment Schedule Update',Body,mps.Id,'Master_Payment_Schedule_Notification');
                        
                    }else{
                        system.debug('test3');
                        string Body = 'Payment Milestone '+mps.Name+' for '+mps.Project_Name__c+' has been completed';
                        BookingController.sendCustomNotification(userIds,'Master Payment Schedule Update',Body,mps.Id,'Master_Payment_Schedule_Notification');
                    }
                    
                }
            }
            
        }
        if(!completedMPSIds.isEmpty()){
            
            // ===== NEW CODE: Update related Payment Schedule records to 'Completed' =====
            // When a Master Payment Schedule is marked as Completed, mark all related
            // Payment Schedule records (that aren't already Completed) as Completed too.
            List<Payment_Schedule__c> psToUpdate = new List<Payment_Schedule__c>();
            for(Payment_Schedule__c ps : [SELECT Id, Status__c 
                                          FROM Payment_Schedule__c 
                                          WHERE Master_Payment_Schedule__c IN :completedMPSIds 
                                          AND Status__c != 'Completed']){
                ps.Status__c = 'Completed';
                psToUpdate.add(ps);
            }
            if(!psToUpdate.isEmpty()){
                try{
                    update psToUpdate;
                }catch(DmlException e){
                    system.debug('Error updating related Payment Schedules: ' + e.getMessage());
                }
            }
            // ===== END NEW CODE =====
            
            MasterPaymentScheduleController.CompletetionOfMPS(completedMPSIds);
        }
    }
}