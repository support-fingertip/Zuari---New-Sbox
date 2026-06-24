public with sharing class getQuoteData {

    public Quote__c qout { get; set; }
    public Id recId { get; set; }

    public Decimal totalPercent { get; set; }
    public Decimal totalAmount  { get; set; }
    public String projectLogoUrl { get; set; }

    public getQuoteData(ApexPages.StandardController controller) {

        // 1) Get record Id safely
        recId = controller != null ? controller.getId() : null;
        if (recId == null) {
            recId = ApexPages.currentPage().getParameters().get('id');
        }

        if (recId == null) {
            // Hard stop: you can't query without Id
            totalPercent = 0;
            totalAmount = 0;
            qout = null;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Quote Id is missing.'));
            return;
        }

        // 2) Fetch quote fields (null-safe later)
        Quote__c qt = [
            SELECT Id,
                   Clubhouse_Charges__c,
                   Total_Maintenance_Amount__c,
                   GST_On_Other_Charges_Actual__c,Unit__r.Project__r.Project_Logo_Url__c
            FROM Quote__c
            WHERE Id = :recId
            LIMIT 1
        ];

        // 3) Aggregate safely (query into list to avoid "no rows" issues)
        List<AggregateResult> aggs = [
            SELECT SUM(Payment_percent__c) perc,
                   SUM(Amount1__c) amt
            FROM Payment_Schedule__c
            WHERE Quote__c = :recId
            GROUP BY Quote__c
        ];

        Decimal perc = 0;
        Decimal amt  = 0;

        if (!aggs.isEmpty() && aggs[0] != null) {
            perc = (Decimal) aggs[0].get('perc');
            amt  = (Decimal) aggs[0].get('amt');
        }

        // 4) Convert nulls to zero (THIS is what fixes your error)
        perc = (perc == null) ? 0 : perc;
        amt  = (amt  == null) ? 0 : amt;

        Decimal clubhouse = (qt.Clubhouse_Charges__c == null) ? 0 : qt.Clubhouse_Charges__c;
        Decimal maint     = (qt.Total_Maintenance_Amount__c == null) ? 0 : qt.Total_Maintenance_Amount__c;
        Decimal gstOther  = (qt.GST_On_Other_Charges_Actual__c == null) ? 0 : qt.GST_On_Other_Charges_Actual__c;

        projectLogoUrl = qt.Unit__r.Project__r.Project_Logo_Url__c;
        totalPercent = perc;
        totalAmount  = amt + clubhouse + maint + gstOther;

        // 5) Fetch quote with child schedules
        qout = [
            SELECT Id,
                   (SELECT Id, Name, Payment_percent__c, Amount__c, S_No__c, Amount1__c,Is_Maintenance_Charges__c,Is_Infrastructure_Charges__c,Is_Clubhouse_Charges__c
                    FROM Payment_Schedules__r
                    ORDER BY S_No__c ASC)
            FROM Quote__c
            WHERE Id = :recId
            LIMIT 1
        ];
    }
}