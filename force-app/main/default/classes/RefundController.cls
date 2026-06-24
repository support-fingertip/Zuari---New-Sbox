public class RefundController {
    @AuraEnabled(cacheable=true)
    public static Demand_Raised__c getDemandDetails(Id demandId) {
        return [
            SELECT Id, Name, Grand_Total__c, Demand_Status__c, Booking__r.Name, 
            CreatedDate
            FROM Demand_Raised__c 
            WHERE Id = :demandId
            LIMIT 1
        ];
    }
    
    @AuraEnabled
    public static Id cancelDemandAndCreateRefund(Id demandId) {
        Demand_Raised__c demand = [
            SELECT Id, Grand_Total__c
            FROM Demand_Raised__c
            WHERE Id = :demandId
            LIMIT 1
        ];
        
        if (demand == null) {
            throw new AuraHandledException('Demand not found.');
        }
        
        // Create Refund
        Refund__c refund = new Refund__c();
        refund.Refund_Amount__c = demand.Grand_Total__c;
        refund.Reversed_Demand__c = demand.Id;
        refund.Refund_Type__c = 'Credit Note';
        insert refund;
        
        // Update Demand
        demand.Demand_Status__c = 'Demand Cancelled';
        update demand;
        
        // Return newly created refund record Id
        return refund.Id;
    }
}