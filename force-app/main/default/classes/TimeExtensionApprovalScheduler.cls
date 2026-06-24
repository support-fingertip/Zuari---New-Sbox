public class TimeExtensionApprovalScheduler implements Schedulable {
    public void execute(SchedulableContext context) {

        List<Booking__c> bookingsToRequestExtension = [
            SELECT Id, Stage__c, Agreement_Status__c, Booking_Approval_Time__c, 
                   Time_Extension_Requested__c, Time_Extension_Approval_Status__c
            FROM Booking__c
            WHERE Stage__c = 'Agreement'
            AND Agreement_Status__c = 'Not Scheduled'
            AND Booking_Approval_Time__c != NULL
            AND Time_Extension_Requested__c = false
        ];

        List<Booking__c> updatedBookings = new List<Booking__c>();
        List<ProcessInstance> processInstances = new List<ProcessInstance>();

        for (Booking__c booking : bookingsToRequestExtension) {

            Date approvalDate = Date.valueOf(booking.Booking_Approval_Time__c); // Convert DateTime to Date
            
            if (approvalDate != null && approvalDate.addDays(30) <= Date.today()) {
                
                booking.Time_Extension_Requested__c = true;
                booking.Time_Extension_Approval_Status__c = 'Pending'; 

                updatedBookings.add(booking);
                
                ProcessInstance approvalProcess = new ProcessInstance(
                    TargetObjectId = booking.Id, 
                    Status = 'Draft'
                );
                processInstances.add(approvalProcess);
            }
        }

        if (!updatedBookings.isEmpty()) {
            update updatedBookings;
            System.debug('Time extension requests are created for ' + updatedBookings.size() + ' bookings.');
        }

        if (!processInstances.isEmpty()) {
            insert processInstances;
            System.debug('Approval process initiated for ' + processInstances.size() + ' bookings.');
        } else {
            System.debug('No bookings needed a time extension.');
        }
    }
}