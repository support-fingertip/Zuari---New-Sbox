public without sharing class SwappingUnitController {
    @AuraEnabled
    public static List<Block__c> getblocks(string project){
        system.debug('Allocated Project: ' + project);
        List<Project__c> projt = [Select id from Project__c where Project__c=:project];
        List<Block__c> blocklist =[select id,Name from Block__c where Project__c=:projt[0].id];
			system.debug(blocklist.size());
        return blocklist; 
    }
    @AuraEnabled
    public static List<Plot__c> getPlots(string recId){
        Booking__c book = [select id,name,project__c/*,Block__r.Name*/ from Booking__c where Id=:recId];
 
        List<Plot__c> plotList = new List<Plot__c>();
        plotList = [select Id, Name, Project__r.Name,Project__r.Project_Type__c, Plot_Number__c, Project__r.Project__c,Plot_Type__c, Clubhouse_Charges__c, /*Two_Car_Parking_Back_to_Back__c,Two_Car_Parking_Side_by_Side__c,Development_Charge__c,East_North_Charges__c,Corner_Charges__c,Corner_charges_for_Villa__c,Fixed_Land__c,Fixed_Land_Charges__c,Park_Facing__c,Forest_Facing__cCorpus_Fund_for_Villas__c,Terrace_Area__c,BESCOM_Deposit_Rs__c,Sale_Area__c,Maintenance_Deposite__c,Apartment_No__c,Stamps_Duty__c,Mutation__c,Block1__c,Single_Car_Parking__c,Extra_Land__c*/
                    Plot_Size__c, Unit_Facing_Direction__c, BHK_Type__c, Basic_Price__c, Club_House__c, Infrastructure_Charges_per_sqft__c, Corpus_Fund__c,
                    Floor_Rise__c, Super_built_up_area__c, Carpet_Area__c, GST1__c, Block__c, Built_up_area__c, Plot_Land_Area__c, Maintenance_Charge__c, Premium_Charge__c, Legal_Charges__c, Floor__c,Flat_No__c,amenities_charges__c,Tower__c,Piped_Gas__c from Plot__c where Project__r.Project__c =: book.Project__c and Status__c = 'Available'];
        system.debug('plotList: ' + plotList);
        return plotList;
        }
     @AuraEnabled
    public static String getType(string recId){
        list<Lead> clist=[select id ,Allocated_Project__c from Lead where id =:recId limit 1];
        return clist[0].Allocated_Project__c;
    }
    @AuraEnabled
    public static String saveOppPlot(Quote__c oppPlot, String prevBooking){
        system.debug('oppPlot:' + oppPlot);
        try{
            Booking__c book = [select id,name,Quote__r.Tower__c,Project1__r.Maintenance_Charge_Rate__c,Quote__r.Property_Type__c,Project1__r.Clubhouse_Charges__c,Quote__r.Payment_Plan__c,Quote__r.RecordTypeId,Quote__r.GST__c,Quote__r.With_GST__c,Quote__r.GST_for_Aggrement_Value__c,Quote__r.GST_For_Other_Charges__c,SLead__c,Swap_Unit__c,Swap_Quote__c,Quote__c,Payment_Type__c from Booking__c where Id=:prevBooking];
            List<Payment_schedule__c> psyList = [Select id,name,Quote__c,S_No__c,Master_Payment_Schedule__c,Payment_Percent__c,Last_Payment_Schedule__c from Payment_schedule__c where Quote__c =: book.Quote__c];
            Plot__c unitRec = [
                SELECT Id, Name, Clubhouse_Charges__c,Water_Electricity_Charges__c,Legal_Documentation_Charges__c,Premium_Charges_on_Facing__c,East_Facing_Charges__c,Car_Parking__c,Corner_Charges__c,ORR_View_Charges__c,Garden_View_Charges__c,Floor_Rise_Charges_Rate__c,Road_View_Charges__c,PLC_Charges__c,Super_Built_up_Area__c,Plot_Type__c, Infrastructure_Charges_per_sqft__c, Rate_per_sqft__c
                FROM Plot__c
                WHERE Id = :oppPlot.Unit__c
                LIMIT 1
            ];
            oppPlot.SLead__c = book.SLead__c;
            oppPlot.Quote_status__c = 'Converted';
            oppPlot.Quote_date__c = system.today();
            oppPlot.Clubhouse_Charges__c = unitRec.Clubhouse_Charges__c;
            oppPlot.Super_Built_UpArea__c = unitRec.Super_Built_up_Area__c;
            oppPlot.Rate_per_sqft__c = unitRec.Rate_per_sqft__c;
            oppPlot.Floor_Rise_Charges_Rate__c = unitRec.Floor_Rise_Charges_Rate__c;
            oppPlot.Payment_Type__c = book.Payment_Type__c;
            oppPlot.Property_Type__c = book.Quote__r.Property_Type__c;
            oppPlot.Clubhouse_Charges__c =book.Project1__r.Clubhouse_Charges__c;
            oppPlot.GST__c = book.Quote__r.GST__c;
            oppPlot.With_GST__c = book.Quote__r.With_GST__c;
            oppPlot.GST_for_Aggrement_Value__c = book.Quote__r.GST_for_Aggrement_Value__c;
            oppPlot.GST_For_Other_Charges__c = book.Quote__r.GST_For_Other_Charges__c;
            oppPlot.Payment_Plan__c = book.Quote__r.Payment_Plan__c;
            oppPlot.RecordTypeId = book.Quote__r.RecordTypeId;
            oppPlot.Plot_Type__c = unitRec.Plot_Type__c;
            oppPlot.Infrastructure_Charges_per_sqft__c = unitRec.Infrastructure_Charges_per_sqft__c;
            oppPlot.Maintenance_Charge__c = book.Project1__r.Maintenance_Charge_Rate__c;
            oppPlot.PLC_Charges__c = unitRec.PLC_Charges__c;
            oppPlot.Road_View_Charges__c = unitRec.Road_View_Charges__c;
            oppPlot.Garden_View_Charges__c = unitRec.Garden_View_Charges__c;
            oppPlot.ORR_View_Charges__c = unitRec.ORR_View_Charges__c;
            oppPlot.Facing_charges__c = unitRec.East_Facing_Charges__c;
            oppPlot.Tower__c = book.Quote__r.Tower__c;
            oppPlot.Corner_Charges__c = unitRec.Corner_Charges__c;
            oppPlot.Car_Parking__c = unitRec.Car_Parking__c;
            oppPlot.Legal_Documentation_Charges__c = unitRec.Legal_Documentation_Charges__c;
            oppPlot.Water_Electricity_Rate__c = unitRec.Water_Electricity_Charges__c;
            insert oppPlot;
            List<Payment_schedule__c> newPaylist = new List<Payment_schedule__c>();
            for(Payment_schedule__c pay : psyList){
                Payment_schedule__c pays = pay.clone(false,false,false,false);
                pays.Quote__c = oppPlot.Id;
                newPaylist.add(pays);
            }
            insert newPaylist;
            book.Swap_Unit__c = oppPlot.Unit__c;
            book.Swap_Quote__c = oppPlot.Id;
            update book;
            BookingController.bookingSwappingApproval(book.Id);
            system.debug('-------'+ oppPlot.Id);
            return oppPlot.id;
        }
        catch(DmlException ex){
            system.debug(ex.getMessage());
            return 'notc';
        }
    }
    @AuraEnabled
    public static void submitapproval(string quoteId){
        Quote__c qt = [SELECT Id,Name,Approval_status__c,GRAND_TOTAL__c,Project__c,Unit__c,Payment_Type__c,Quote_status__c FROM Quote__c WHERE Id=:quoteId limit 1];
        if(qt.id!=null){
            if(qt.Quote_status__c=='Drafted'){
                if(qt.Approval_status__c!='Approved' && qt.Approval_status__c!='Pending'){
                    List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setObjectId(quoteId);
                    requests.add(req);
                    Approval.ProcessResult[] processResults = Approval.process(requests);
                }
            }else{
                qt.Approval_status__c ='Approved';
                update qt;
            }
        }
        else{
        }
    }
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
    public static databox getPaymentSchedules(String Pay, String Project){
        List<Master_payment_schedule__c> mpsList = [select Id,Project__C,S_No__c,Tentative_TimeLine__c,Name,Payment_Percent__c,Amount__c,Completed_Date__c,Due_Date__c,Status__c from Master_payment_schedule__c where Project__r.Name =:Project ORDER BY S_No__c ASC];
        databox db = new databox();
        List<Payment_schedule__c> schdules = new List<Payment_schedule__c>();
        List<Master_payment_schedule__c> Master;
        string paymentType;
        if(Pay =='Standard'){
            system.debug('Pay : '+ Pay);
            system.debug('Project : '+ Project);
            Master=[select id,Project__C,S_No__c,Name,Tentative_TimeLine__c,Payment_Percent__c,Completed_Date__c,Due_Date__c,Status__c from Master_payment_schedule__c where Project__r.Name =:Project ORDER BY S_No__c ASC];
            system.debug('Master : '+ Master);
            //system.debug(Master[0]);
            for(Master_payment_schedule__c mps : Master){
                system.debug('Inside Master Payment For Loop');
                Payment_schedule__c ps = new Payment_schedule__c();
                ps.Master_Payment_Schedule__c = mps.Id;
                ps.Payment_percent__c = mps.Payment_Percent__c;
                ps.Name = mps.Name;
                ps.status__c=mps.Status__c;
                ps.S_No__c = mps.S_No__c;
                ps.Tentative_TimeLine__c = mps.Tentative_TimeLine__c;
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
                    if(ps.Received_Amount__c ==null){
                        ps.Received_Amount__c=0;
                    }
                    if(ps.Recived_Per__c ==null){
                        ps.Recived_Per__c=0;
                    }
                    db.RecivedAmountTotal +=ps.Received_Amount__c;
                    system.debug('ps.Payment_percent__c'+ps.Payment_percent__c);
                    system.debug('db.totalPercent'+db.totalPercent);
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
        List<Quote__c> quo = [Select id,name,Payment_Type__c from Quote__c where id=:quoteid];
        if(quo[0].Payment_Type__c=='Standard')
        {
            for(Payment_schedule__c pay : payList){
                Payment_schedule__c ps = new Payment_schedule__c();
                ps.Name = pay.Name;
                ps.Payment_Percent__c = pay.Payment_Percent__c;
                ps.Payment_Due_Date__c = pay.Payment_Due_Date__c;
                ps.Amount__c = pay.Amount__c;
                ps.Master_Payment_Schedule__c = pay.Master_Payment_Schedule__c;
                ps.S_No__c = pay.S_No__c;
                ps.Quote__c = quoteid;
                schduleList.add(ps);
            }
        }else if(quo[0].Payment_Type__c=='Custom'){
            for(Payment_schedule__c pay : payList)
            {
                system.debug(pay);
                Payment_schedule__c ps = new Payment_schedule__c();
                ps = pay;
                ps.quote__c = quoteid;
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
        schdules = [SELECT Id,Name,Payment_percent__c,Recived_Per__c,Amount__c,S_No__c,status__c,Booking__c,Quote__c,Quote__r.Grand_Total__c,Quote__r.project__c,Quote__r.unit__r.Name,Received_Amount__c,Amount1__c FROM Payment_schedule__c WHERE Quote__c =:Quoteid  ORDER BY S_No__c ASC];
        Quote__c qt = [SELECT Id,Grand_Total__c,Plot_Type__c,project__c,Payment_Type__c,unit__r.Name,Block_Lookup__r.Name FROM Quote__c WHERE Id=:Quoteid LIMIT 1];
        db.grandTotal = qt.Grand_Total__c;
        db.projectName = qt.project__c;
        paymentType = qt.Payment_Type__c;
        db.flatNumber =qt.unit__r.Name;
        db.blockName=qt.Block_Lookup__r.Name;
        system.debug(db.blockName +'-------------------');
        return db;
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
    @AuraEnabled
    public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> picklistValues = new List<String>();
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType != null) {
            Schema.DescribeFieldResult fieldDescribe = objectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
            if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST) {
                List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
                for (Schema.PicklistEntry picklistEntry : picklistEntries) {
                    picklistValues.add(picklistEntry.getLabel());
                }
            }
        }
        return picklistValues;
    }

}