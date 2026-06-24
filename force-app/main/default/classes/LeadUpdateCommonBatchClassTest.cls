@isTest
public class LeadUpdateCommonBatchClassTest {
    
    @isTest
    public static void notes()
    {
        Lead ld = new Lead();
        ld.LastName = 'test';
        ld.Last_Note__c = 'test';
        ld.Phone = '1234567890';
        ld.Company = 'testcompany';
        ld.TL_RHS_Review__c = 'ewyuew';
        insert ld;
        
       LeadUpdateCommonBatchClass leadBatch = new LeadUpdateCommonBatchClass();
       database.executeBatch(leadBatch,200);
    }
    
}