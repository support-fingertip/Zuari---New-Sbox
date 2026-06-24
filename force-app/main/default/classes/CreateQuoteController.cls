public Without Sharing class  CreateQuoteController {
    public class QuoteResponse {
        @AuraEnabled public String quoteId { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }
    }
    public class ProjectPlotWrapper {
        @AuraEnabled public String projectName { get; set; }
        @AuraEnabled public String projectType { get; set; }
        @AuraEnabled public List<Plot__c> plots { get; set; }
    }
    
    
    @AuraEnabled
    public static List<Payment_Plan__c> getPyamentPlan(string project){
        
        // list<Lead>clist=[select id ,Allocated_Project__c from Lead where id =:recId ];
        
        // string project=clist[0].Allocated_Project__c;
        
        return [select id, Name,Project__c,Active__c, Project__r.Project__c  from Payment_Plan__c where Active__c =true And Project__r.Project__c=:project];
        
    }
    
    @AuraEnabled
    public static List<Block__c> getBlock(string recId){
        system.debug('recId:' + recId);
        list<Related_Source__c>clist=[select id ,Allocated_Project__c from Related_Source__c where id =:recId ];
        string project=clist[0].Allocated_Project__c;
        system.debug('sdghvcdchdchdhcdhcdhhdhdhdhhdhd  '+project);
        List<Block__c> blocklist=new List<Block__c>();
        
        string obj='Block__c';
        blocklist = [select Id,Name,Project__r.Name,Project__c from Block__c where Project__r.Project__c =:project ];
        system.debug('recId:' + blocklist);
        return blocklist;
    }
    @AuraEnabled
    public static ProjectPlotWrapper getPlots(string recId){
        system.debug('recId:' + recId);
        Lead leadRecord = [select id, Allocated_Project__c from Lead where id =:recId limit 1];

        if (leadRecord.Allocated_Project__c == null) {
            system.debug('Lead has no Allocated Project');
            return new ProjectPlotWrapper();
        }
        string project = leadRecord.Allocated_Project__c;
        system.debug('Allocated Project: ' + project);

        // Get Project Type
        List<Project__c> projList = [SELECT Id, Project__c, Project_Type__c FROM Project__c WHERE Project__c =:project LIMIT 1];
        String projType = '';
        if (!projList.isEmpty()) {
            projType = projList[0].Project_Type__c;
        }

        ProjectPlotWrapper result = new ProjectPlotWrapper();
        result.projectName = project;
        result.projectType = projType;

        // For Apartments, don't load all plots upfront - user must select a block first
        if (projType == 'Apartments') {
            result.plots = new List<Plot__c>();
        } else {
            result.plots = [select Id, Name,PLC_Charges__c,GST1__c, Plot_Type__c,Infrastructure_Charges_per_sqft__c,Project__r.Name,Balcony_Area_Sq_ft__c,Project__c,Super_Built_up_Area__c,Plot_Land_Area__c,Carpet_Area__c,Block__c,BHK_Type__c,Rate_per_sqft__c,Clubhouse_Charges__c,Piped_Gas__c,Project__r.Franking_Shifting_Rate__c,
                        Block_Lookup__c,Water_Electricity_Charges__c,Legal_Charges__c,Generator_Charges__c, Wing__c,Car_Parking__c,Project__r.Project__c,Scheme__c,SitOut_Area_Sq_ft__c,Terrace_Area_Sq_ft__c,Project__r.Home_Automation__c,Tower__c,Floor__c,Mort_Non_Mortgage__c,Utility_in_SFT__c,Balcony_in_SFT__c,
                        Carpet_Area_in_SFT__c,UDS_in_Sqyards__c,SBA_in_SFT__c,Corner_Non_Corner__c,Flat_No__c,Corpus_Fund__c,Legal_Documentation_Charges__c,amenities_charges__c,Project__r.Maintenance_Charge_Rate__c,Project__r.Clubhouse_Charges__c,
                        Garden_Area_Sq_ft__c,W_E_Charges__c, Project__r.GST_on_Aggrement__c, Project__r.Project_Type__c,Project__r.GST_on_Other__c,Unit_Facing_Direction__c,Maintenance_Charge__c,Floor_Rise_Charge__c,Project__r.Guideline_Value_Charges__c,
                        Road_View_Charges__c,Corner_Charges__c,ORR_View_Charges__c,Garden_View_Charges__c,Premium_Charges_on_Facing__c,Corner__c from Plot__c where Project__r.Project__c=:project and Status__c = 'Available'];
        }

        system.debug('plotList: ' + result.plots);
        return result;
    }

    @AuraEnabled
    public static List<Plot__c> getPlotsByBlock(String blockId){
        system.debug('blockId: ' + blockId);
        return [select Id, Name,PLC_Charges__c,GST1__c, Plot_Type__c,Infrastructure_Charges_per_sqft__c,Project__r.Name,Balcony_Area_Sq_ft__c,Project__c,Super_Built_up_Area__c,Plot_Land_Area__c,Carpet_Area__c,Block__c,BHK_Type__c,Rate_per_sqft__c,Piped_Gas__c,Project__r.Franking_Shifting_Rate__c,
                    Block_Lookup__c,Water_Electricity_Charges__c,Legal_Charges__c,Generator_Charges__c, Wing__c,Car_Parking__c,Project__r.Project__c,Scheme__c,SitOut_Area_Sq_ft__c,Terrace_Area_Sq_ft__c,Project__r.Home_Automation__c,Tower__c,Floor__c,Mort_Non_Mortgage__c,Utility_in_SFT__c,Balcony_in_SFT__c,
                    Carpet_Area_in_SFT__c,UDS_in_Sqyards__c,SBA_in_SFT__c,Corner_Non_Corner__c,Flat_No__c,Corpus_Fund__c,Legal_Documentation_Charges__c,amenities_charges__c,Project__r.Maintenance_Charge_Rate__c,Project__r.Clubhouse_Charges__c,
                    Garden_Area_Sq_ft__c,W_E_Charges__c, Project__r.GST_on_Aggrement__c, Project__r.Project_Type__c,Project__r.GST_on_Other__c,Unit_Facing_Direction__c,Maintenance_Charge__c,Floor_Rise_Charge__c,Project__r.Guideline_Value_Charges__c,
                    Road_View_Charges__c,Corner_Charges__c,Clubhouse_Charges__c, ORR_View_Charges__c,Garden_View_Charges__c,Premium_Charges_on_Facing__c,Corner__c
                from Plot__c where Block_Lookup__c =:blockId and Status__c = 'Available'];
    }
    
    
    
    /*
@AuraEnabled
public static String saveOppPlot1(Quote__c oppPlot){
system.debug('oppPlot:' + oppPlot);
List<RecordType> recordType = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Quote__c'];
Map<String,Id> recordTypeNameToId = new Map<String,Id>();
for(RecordType recType : recordType){
recordTypeNameToId.put(recType.Name,recType.Id);
}
oppPlot.RecordTypeId = recordTypeNameToId.get(oppPlot.Property_Type__c);
oppPlot.Quote_status__c = 'Approved';
System.debug(oppPlot.RecordTypeId);
if (oppPlot.Id == null) {
insert oppPlot;
} 
else {
update oppPlot;
}

return oppPlot.id;

}
*/
    @AuraEnabled
    public static QuoteResponse saveOppPlot(Quote__c oppPlot) {
        System.debug('oppPlot:' + oppPlot);
        
        List<RecordType> recordTypeList = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE SObjectType = 'Quote__c'
        ];
        Map<String,Id> recordTypeNameToId = new Map<String,Id>();
        Map<Id,String> recordTypeIdToName = new Map<Id,String>();
        
        for (RecordType recType : recordTypeList) {
            recordTypeNameToId.put(recType.Name, recType.Id);
            recordTypeIdToName.put(recType.Id, recType.Name);
        }
        
        oppPlot.RecordTypeId = recordTypeNameToId.get(oppPlot.Property_Type__c);
       oppPlot.Quote_status__c = 'Approved';
        
        if (oppPlot.Id == null) {
            insert oppPlot;
        } else {
            update oppPlot;
        }
        
        QuoteResponse resp = new QuoteResponse();
        resp.quoteId = oppPlot.Id;
        resp.recordTypeName = recordTypeIdToName.get(oppPlot.RecordTypeId);
        
        return resp;
    }
    
    @AuraEnabled
    public static Void deleteQuote(String recId){
        Quote__c qt=[select id  from Quote__c where id =:recId ];
        List<Payment_schedule__c> pymlist = [select id from Payment_schedule__c where Id =:qt.Id];
        
        Delete pymlist;
        Delete qt;
        
    }
    /*
    @AuraEnabled
    public static Void callQuoteApproval(String recId){
        
        Quote__c q=[select id,OwnerId  from Quote__c where id =:recId ];
        // q.Quote_status__c = 'Approved';
        
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(q.Id);
        req.setSubmitterId(q.OwnerId);
        req.setProcessDefinitionNameOrId('Quote_Approval'); // Ensure this process exists
        req.setSkipEntryCriteria(false);
        approvalRequests.add(req);
        
        if (!approvalRequests.isEmpty()) {
            Approval.ProcessResult[] results = Approval.process(approvalRequests);
            
            // Error Handling - Log failed approval processes
            for (Approval.ProcessResult result : results) {
                if (!result.isSuccess()) {
                    System.debug('Approval submission failed: ' + result.getErrors());
                }
            }
        }
        
    }
    
@AuraEnabled
public static void submitapproval(string quoteId){
Quote__c qt = [SELECT Id,Name,Approval_status__c,GRAND_TOTAL__c,Project__c,Unit__c,Payment_Type__c,Quote_status__c FROM Quote__c WHERE Id=:quoteId limit 1];
if(qt.id!=null){
if(qt.Approval_status__c!='Approved' && qt.Approval_status__c!='Pending'){
List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
req.setObjectId(quoteId);
requests.add(req);
Approval.ProcessResult[] processResults = Approval.process(requests);
}


}

}
*/
    @AuraEnabled
    public static List<String> getPaymentTypePicklistValues() {
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Quote__c.Payment_Type__c.getDescribe();
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        return paymentTypeValues;
    }
    @AuraEnabled
    public static databox getUpdatedPaymentSchedules(String Pay, String Project){
        system.debug(Pay+'=='+ Project);
        databox db = new databox();
        List<Payment_schedule__c> schdules = new List<Payment_schedule__c>();
        list<Payment_Plan__c> pymntsch = [select id, Name,(select id,Status__c,Project__C,S_No__c,Name,Payment_Percent__c,Completed_Date__c,Include_Interest__c,Is_Clubhouse_Charges__c,
                                                        Is_Infrastructure_Charges__c,Is_Maintenance_Charges__c,SAC_HSN_Code__c   from Master_payment_schedules__r ORDER BY S_No__c ASC) from Payment_Plan__c where Id =: Pay ];
        system.debug(pymntsch);
        Map<string,List<Master_payment_schedule__c>> masters = new Map<string,List<Master_payment_schedule__c>>();
        for(Payment_Plan__c prj : pymntsch){
            if(prj.Master_payment_schedules__r.size()>0){
                masters.put(prj.Id, prj.Master_payment_schedules__r);
            }
        }
        if(pymntsch.size()>0){
            if(masters.containskey(pymntsch[0].Id)){
                System.debug(masters.containskey(pymntsch[0].Id));
                for(Master_payment_schedule__c mps : masters.get(pymntsch[0].Id)){
                    System.debug('hi'+ mps);
                    Payment_schedule__c ps = new Payment_schedule__c();
                    ps.Master_Payment_Schedule__c = mps.Id;
                    ps.Payment_percent__c = mps.Payment_Percent__c;
                    ps.Name = mps.Name;
                    ps.Is_Clubhouse_Charges__c = mps.Is_Clubhouse_Charges__c;
                    ps.Is_Infrastructure_Charges__c = mps.Is_Infrastructure_Charges__c;
                    ps.Is_Maintenance_Charges__c = mps.Is_Maintenance_Charges__c;
                    ps.SAC_HSN_Code__c = mps.SAC_HSN_Code__c;
                   ps.Include_Interest__c = mps.Include_Interest__c;
                    ps.status__c=mps.Status__c;
                    ps.S_No__c = mps.S_No__c;
                    
                    schdules.add(ps);
                    
                }
            }
            db.payList = schdules;
            db.paymentSum = 0.00;
            db.totalPercent = 0;  
            db.RecivedAmount=0;
            db.RecivedAmountTotal=0;
            db.RecivedPercent=0;
            db.scheduledAmount=0;
            db.projectName = Project;
            system.debug('inside');
            
        }  
        else{
            db.payList = schdules;
            db.paymentSum = 0.00;
            db.totalPercent = 0;
            db.RecivedAmount=0;
            db.RecivedAmountTotal=0;
            db.RecivedPercent=0;
            db.scheduledAmount=0;
            
        }
        
        
        
        List<Master_payment_schedule__c> Master;
        string paymentType;
        system.debug(db.paymentSum); 
        system.debug(db); 
        
        return db;
    }
    
    
    @AuraEnabled
    public static  databox getPaymentSchedules(String Pay, String Project){
        List<Master_payment_schedule__c> mpsList = [select Id,Project__C,S_No__c,Name,Payment_Percent__c,Amount__c,Completed_Date__c,Due_Date__c,Status__c from Master_payment_schedule__c where Project__r.Name =:Project ORDER BY S_No__c ASC];
        
        databox db = new databox();
        
        List<Payment_schedule__c> schdules = new List<Payment_schedule__c>();
        List<Master_payment_schedule__c> Master;
        string paymentType;
        
        if(Pay =='Standard'){
            system.debug('Pay : '+ Pay);
            system.debug('Project : '+ Project);
            //system.debug('blockId   '+blockId);
            Master=[select id,Project__C,S_No__c,Name,Payment_Percent__c,Completed_Date__c,Is_Clubhouse_Charges__c, Is_Infrastructure_Charges__c,
                    Is_Maintenance_Charges__c, Due_Date__c,Status__c from Master_payment_schedule__c where Project__r.Name =:Project  ORDER BY S_No__c ASC];
            system.debug('Master : '+ Master);
            //system.debug(Master[0]);
            
            for(Master_payment_schedule__c mps : Master){
                system.debug('Inside Master Payment For Loop');
                Payment_schedule__c ps = new Payment_schedule__c();
                ps.Master_Payment_Schedule__c = mps.Id;
                ps.Payment_percent__c = mps.Payment_Percent__c;
                ps.Name = mps.Name;
                ps.Is_Clubhouse_Charges__c = mps.Is_Clubhouse_Charges__c;
                ps.Is_Infrastructure_Charges__c = mps.Is_Infrastructure_Charges__c;
                ps.Is_Maintenance_Charges__c = mps.Is_Maintenance_Charges__c;
                ps.Include_Interest__c = mps.Include_Interest__c;
                ps.status__c=mps.Status__c;
                ps.S_No__c = mps.S_No__c;
                //  ps.Tentative_TimeLine__c = mps.Tentative_TimeLine__c;
                //ps.Amount__c = (db.grandTotal * mps.Payment_Percent__c)/100;
                
                system.debug(ps.Amount__c);
                //ps.Amount__c = ps.Amount__c.setScale(2);
                
                schdules.add(ps); 
            }
            //db.MasterpayList = Master;
            db.payList = schdules;
            db.paymentSum = 0.00;
            db.totalPercent = 0;  
            db.RecivedAmount=0;
            db.RecivedAmountTotal=0;
            db.RecivedPercent=0;
            db.scheduledAmount=0;
            system.debug('inside');
        }
        else 
        {
            db.payList = schdules;
            db.paymentSum = 0.00;
            db.totalPercent = 0;
            db.RecivedAmount=0;
            db.RecivedAmountTotal=0;
            db.RecivedPercent=0;
            db.scheduledAmount=0;
            
            
        } 
        if(schdules.size()>0 && Pay=='Custom'){
            
            
            for(Payment_schedule__c ps : schdules){
                system.debug(ps.Amount1__c);
                db.paymentSum=0.00;
                db.paymentSum += ps.Amount1__c;
                /* if(ps.Received_Amount__c ==null){
ps.Received_Amount__c=0;
}*/
                if(ps.Recived_Per__c ==null){
                    ps.Recived_Per__c=0;
                }
                /* db.RecivedAmountTotal +=ps.Received_Amount__c;
system.debug('ps.Payment_percent__c'+ps.Payment_percent__c);
system.debug('db.totalPercent'+db.totalPercent);*/
                
                db.totalPercent += ps.Payment_percent__c;
                system.debug('db.totalPercent'+db.totalPercent);
                
                //db.RecivedAmount +=ps.Received_Amount__c;
                
                
            }
        }
        if(db.payList.size()==0){
            db.payList = null;
        }
        system.debug(db.paymentSum); 
        system.debug(db); 
        
        return db;
        // return mpsList;
    }
    
    @AuraEnabled
    public static void deleteSchedule(string recId){
        DELETE [SELECT Id FROM Payment_schedule__c WHERE Id=:recId];
    }
    @AuraEnabled
    public static void insertSchedules(List<Payment_schedule__c> payList, decimal gt,string quoteid){
        String sObjName = Id.valueOf(quoteid).getSObjectType().getDescribe().getName();
        List<Payment_schedule__c> schduleList = new List<Payment_schedule__c>();
        list<booking__c>blist=new list<booking__C>();
        List<Quote__c> quo = [Select id,name,Payment_Type__c,Agreement_Value_Before_GST__c, Clubhouse_Charges__c,Total_Maintenance_Amount__c,GST_On_Other_Charges_Actual__c, Projects__r.Interest_Rate__c  from Quote__c where id=:quoteid limit 1];
        System.debug(quoteid);
        Decimal agreementValue = quo[0].Agreement_Value_Before_GST__c != null ? quo[0].Agreement_Value_Before_GST__c : 0;
        
        Decimal extraCharges = 0;
        extraCharges += quo[0].Clubhouse_Charges__c != null ? quo[0].Clubhouse_Charges__c : 0;
        extraCharges += quo[0].Total_Maintenance_Amount__c != null ? quo[0].Total_Maintenance_Amount__c : 0;
        extraCharges += quo[0].GST_On_Other_Charges_Actual__c != null ? quo[0].GST_On_Other_Charges_Actual__c : 0;
        
        if(quo[0].Payment_Type__c=='Standard')
        {
            
            /* for(Payment_schedule__c pay : payList){
Payment_schedule__c ps = new Payment_schedule__c();
ps.Name = pay.Name;
ps.Payment_Percent__c = pay.Payment_Percent__c;
ps.Payment_Due_Date__c = pay.Payment_Due_Date__c;
ps.Amount__c = pay.Amount__c;
ps.Master_Payment_Schedule__c = pay.Master_Payment_Schedule__c;
ps.S_No__c = pay.S_No__c;
ps.Quote__c = quoteid;
schduleList.add(ps);
}*/
            
            for (Integer i = 0; i < payList.size(); i++) {
                Payment_schedule__c pay = payList[i];
                Payment_schedule__c ps = new Payment_schedule__c();
                
                ps.Name = pay.Name;
                ps.Payment_Percent__c = pay.Payment_Percent__c;
                ps.Payment_Due_Date__c = pay.Payment_Due_Date__c;
                ps.Master_Payment_Schedule__c = pay.Master_Payment_Schedule__c;
                ps.Is_Infrastructure_Charges__c = pay.Is_Infrastructure_Charges__c;
                ps.Is_Maintenance_Charges__c = pay.Is_Maintenance_Charges__c;
                ps.Is_Clubhouse_Charges__c = pay.Is_Clubhouse_Charges__c;
                ps.S_No__c = pay.S_No__c;
                ps.Quote__c = quoteId;
                ps.Include_Interest__c=true;
               ps.Interest_Percent__c=  quo[0].Projects__r.Interest_Rate__c ;//update the interest Rate 
                if (pay.Payment_Percent__c != null) {
                    ps.Amount__c = (agreementValue * pay.Payment_Percent__c) / 100;
                }
                
                if (i == payList.size() - 1) {
                   // ps.Last_Payment_Schedule__c=true;
                    ps.Amount__c = (agreementValue * pay.Payment_Percent__c) / 100 + extraCharges;
                    System.debug(ps.Amount__c + '==='+ extraCharges);
                }
                
                schduleList.add(ps);
            }
        }
        
        
        else if(quo[0].Payment_Type__c=='Custom'){
            /*  for(Payment_schedule__c pay : payList)
{
system.debug(pay);
Payment_schedule__c ps = new Payment_schedule__c();
ps = pay;
ps.quote__c = quoteid;
schduleList.add(ps);
}
*/
            for (Integer i = 0; i < payList.size(); i++) {
                
                Payment_schedule__c pay = payList[i];
                Payment_schedule__c ps = new Payment_schedule__c();
                ps.Name = pay.Name;
                ps.Payment_Percent__c = pay.Payment_Percent__c;
                ps.Payment_Due_Date__c = pay.Payment_Due_Date__c;
                ps.S_No__c = pay.S_No__c;
                ps.Quote__c = quoteId;
                ps.Include_Interest__c=true;
               ps.Interest_Percent__c=  quo[0].Projects__r.Interest_Rate__c ;//update the interest Rate 
                
                if (pay.Payment_Percent__c != null) {
                    ps.Amount__c = (agreementValue * pay.Payment_Percent__c) / 100;
                }
                
                if (i == payList.size() - 1) {
                    ps.Amount__c = (agreementValue * pay.Payment_Percent__c) / 100 + extraCharges;
                 //   ps.Last_Payment_Schedule__c=true;
                }
                schduleList.add(ps);
            }
            
        }
        
        
        
        system.debug( 'schduleList :'+ schduleList);
        upsert schduleList;
        if(quo[0].Payment_Type__c=='Standard'){
            //  PaymentScheduleMerger1.handleRelatedPaymentSchedules(quo);
        }
        system.debug('success');
    }
    @AuraEnabled
    public static databox QuoteCreate(String Leadid,String Quoteid)
    {
        databox db = new databox();
        String sObjName = Id.valueOf(Quoteid).getSObjectType().getDescribe().getName();
        db.objectName = sObjName;
        List<Payment_schedule__c> schdules;
        string paymentType;
        schdules = [SELECT Id,Name,Payment_percent__c,Recived_Per__c,Amount__c,S_No__c,status__c,Booking__c,Quote__c,Quote__r.Grand_Total__c,Quote__r.project__c,Quote__r.unit__r.Name,Amount1__c FROM Payment_schedule__c WHERE Quote__c =:Quoteid  ORDER BY S_No__c ASC];
        Quote__c qt = [SELECT Id,Grand_Total__c,Plot_Type__c,project__c,Payment_Type__c,unit__r.Name FROM Quote__c WHERE Id=:Quoteid LIMIT 1];
        db.grandTotal = qt.Grand_Total__c;
        db.projectName = qt.project__c;
        paymentType = qt.Payment_Type__c;
        db.flatNumber =qt.unit__r.Name;
        //db.blockName=qt.Block_Lookup__r.Name;
        // system.debug(db.blockName +'-------------------');
        return db;
    }
    @AuraEnabled
    public static boolean quotationqquery(String Leadid){
        List<Quote__c> qt = [SELECT Id,Grand_Total__c,Plot_Type__c,Discount_Price__c,project__c,Payment_Type__c,unit__r.Name FROM Quote__c WHERE SLead__c=:Leadid ];
        integer Quotecount = qt.size();
        boolean ismultiplequotes = false;
        if(Quotecount == 0)
        {
            ismultiplequotes = false;
        }else{
            ismultiplequotes = true;
        }
        return ismultiplequotes;
    }
    public class databox{
        @AuraEnabled 
        public List<Payment_schedule__c> payList;
        @AuraEnabled
        public List<Master_payment_schedule__c> MasterpayList;
        @AuraEnabled
        public Decimal grandTotal;
        @AuraEnabled
        public Decimal paymentSum;
        @AuraEnabled
        public Decimal RecivedAmountTotal;
        @AuraEnabled
        public Decimal totalPercent;
        @AuraEnabled
        public Decimal RecivedAmount;
        @AuraEnabled
        public string objectName;
        @AuraEnabled
        public string projectName;
        @AuraEnabled
        public string flatNumber;
        @AuraEnabled
        public string blockName;
        @AuraEnabled
        public Decimal RecivedPercent;
        @AuraEnabled
        public Decimal ScheduledAmount;
        @AuraEnabled
        public Decimal TotalOutStandingDueAmount;
        @AuraEnabled
        public Decimal TotalPaidAmount;
    }
}