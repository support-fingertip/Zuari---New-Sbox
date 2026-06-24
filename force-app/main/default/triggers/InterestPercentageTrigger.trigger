trigger InterestPercentageTrigger on Interest_Percentage__c (before insert, after Update) {
    if(Trigger.IsAfter && Trigger.IsUpdate){
        
        //Collect all Booking
        For( Interest_Percentage__c Ip : Trigger.New){
            if(ip.Interest_Rate__c != null && ip.Interest_Rate__c != Trigger.OldMap.get(Ip.Id).Interest_Rate__c){
                   InterestCalculatorHandler.createInterestLineItems(Date.today(), Ip.Interest_Rate__c);
       
                
}
        }
    }
}