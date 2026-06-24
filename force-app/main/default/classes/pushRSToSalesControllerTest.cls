@IsTest
public class pushRSToSalesControllerTest {

    @IsTest
    static void testPushRSToSalesFlow() {

        Map<String, Id> rtMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Related_Source__c']) {
            rtMap.put(rt.Name, rt.Id);
        }

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User salesUser = new User(
            FirstName = 'Sales',
            LastName = 'Receiver',
            Email = 'salesreceiver@test.com',
            Username = 'salesreceiver' + System.currentTimeMillis() + '@test.com',
            Alias = 'srx',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert salesUser;

        Related_Source__c rsDM = new Related_Source__c(
            RecordTypeId = rtMap.get('Pre Sales'),
            Lead_status1__c = 'Pre-Sales New Enquiry',
            No_Of_Times_Unqualified__c = 0,
            Source_Type__c = 'Digital Marketing',
            OwnerId = UserInfo.getUserId()
        );
        insert rsDM;

        Related_Source__c rsCP = new Related_Source__c(
            RecordTypeId = rtMap.get('Pre Sales'),
            Lead_status1__c = 'Pre-Sales New Enquiry',
            No_Of_Times_Unqualified__c = 0,
            Source_Type__c = 'Channel partner',
            OwnerId = UserInfo.getUserId()
        );
        insert rsCP;

        Test.startTest();
        pushRSToSalesController.getSalesUsersForRS(rsDM.Id);
        pushRSToSalesController.getSalesUsersForRS(rsCP.Id);
        String returnedId = pushRSToSalesController.moveRSToSales(
            rsDM.Id, salesUser.Id, 'Handover notes for sales team.'
        );
        Test.stopTest();

        Related_Source__c updated = [
            SELECT Id, OwnerId, RecordTypeId, Lead_status1__c, Lead_Transfer_Note__c,
                   Transfered_By__c, Transfered_On__c, Lead_Transfered__c, IsPushed__c
            FROM Related_Source__c
            WHERE Id = :rsDM.Id
        ];

        System.assertEquals(rsDM.Id, returnedId, 'Method should return the updated record Id');
        System.assertEquals(salesUser.Id, updated.OwnerId, 'Owner should be the selected sales user');
        System.assertEquals(rtMap.get('Sales'), updated.RecordTypeId, 'Record type should switch to Sales');
       // System.assertEquals('New sales enquiry', updated.Lead_status1__c, 'Status should be New sales enquiry');
        System.assertEquals('Handover notes for sales team.', updated.Lead_Transfer_Note__c, 'Transfer note should be persisted');
        System.assertEquals(UserInfo.getUserId(), updated.Transfered_By__c, 'Transfered_By should be running user');
        System.assertEquals(true, updated.Lead_Transfered__c, 'Lead_Transfered should be true');
        System.assertEquals(true, updated.IsPushed__c, 'IsPushed should be true');
        System.assertNotEquals(null, updated.Transfered_On__c, 'Transfered_On should be set');
    }
}