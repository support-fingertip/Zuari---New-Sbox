/**
 * @description Service class for managing Support Ticket lifecycle including creation, escalation, and auto-closure.
 * This class handles the initial assignment of support tickets to Relationship Managers (RM) and manages
 * the automated escalation workflow through a 3-tier hierarchy: RM -> Sourcing Head -> Head of Sales & Marketing.
 * Tickets are automatically closed after 60 days from creation unless resolved earlier.
 * 
 * Key Features:
 * - Validates required fields on ticket creation (Sourcing RM, Sourcing Head, Head of Sales & Marketing)
 * - Assigns tickets to the RM immediately upon creation
 * - Sets baseline status and escalation tracking information
 * - Daily job that escalates tickets after 7 days of inactivity at each level
 * - Auto-closes tickets after 60 days from creation
 * 
 * @author Praveen Kumar
 * @date 17-02-2026
 * @lastModified Y Tejaswini
 * modifiedDate 23-02-2026 
 */
public with sharing class SupportTicketService {

    private static final Integer ESCALATION_DAYS = 7;
    private static final Integer AUTO_CLOSE_DAYS  = 60;
    private static final String  LEVEL_RM         = 'RM';
    private static final String  LEVEL_SH         = 'Sourcing Head';
    private static final String  LEVEL_HOSM       = 'HOSM';
    private static final String  STATUS_CLOSE      = 'Close';
    private static final String  CLOSURE_MESSAGE   = 'Ticket auto-closed after 60 days with no resolution.';

    /**
     * @description Trigger handler for before insert event on Support_Ticket__c records.
     * Validates required supporting user fields and initializes ticket with default values.
     * - Assigns ticket to the Sourcing RM immediately
     * - Sets initial status to 'In Progress'
     * - Sets escalation level to 'RM'
     * - Calculates auto-close date as 60 days from creation
     * 
     * @param tickets List of Support_Ticket__c records being inserted
     * @throws DmlException if required fields (Sourcing_RM__c, Sourcing_Head__c, Head_of_Sales_and_Marketing__c) are null
     */
    public static void onBeforeInsert(List<Support_Ticket__c> tickets) {
        Date today = Date.today();

        for (Support_Ticket__c t : tickets) {

            // Hard validation - required hierarchy must be populated
            if (t.Sourcing_RM__c == null || t.Sourcing_Head__c == null || t.Head_of_Sales_and_Marketing__c == null) {
                t.addError('Sourcing RM, Sourcing Head, and Head of Sales & Marketing must be populated.');
                continue;
            }

            // Assign ticket to RM immediately on creation
            t.OwnerId = t.Sourcing_RM__c;

            // Set default status if not already provided
            if (String.isBlank(t.Ticket_Status__c)) {
                t.Ticket_Status__c = 'In Progress';
            }

            // Initialise escalation tracking
            t.Escalation_Level__c  = LEVEL_RM;
            t.Last_Escalated_On__c = System.now();

            // Set auto-close date: 60 days from today
            t.Auto_Close_On__c = today.addDays(AUTO_CLOSE_DAYS);
        }
    }

    /**
     * @description Scheduled daily job that processes support ticket escalations and auto-closures.
     * 
     * Escalation Flow (triggers after 7 days of inactivity at each level):
     * - Level RM           : Owner changes to Sourcing Head, level becomes 'Sourcing Head'
     * - Level Sourcing Head : Owner changes to Head of Sales & Marketing, level becomes 'HOSM'
     * - Level HOSM         : No further escalation; ticket remains until auto-close date
     * 
     * Auto-Closure:
     * - Any open ticket that has reached or passed its Auto_Close_On__c date is closed automatically
     */
    public static void processEscalations() {

        List<Support_Ticket__c> openTickets = [
            SELECT Id, OwnerId, CreatedDate, Ticket_Status__c,
                   Sourcing_RM__c, Sourcing_Head__c, Head_of_Sales_and_Marketing__c,
                   Escalation_Level__c, Last_Escalated_On__c, Auto_Close_On__c
            FROM Support_Ticket__c
            WHERE Ticket_Status__c NOT IN ('Issue Resolved', 'Close')
            AND   IsDeleted = false
            LIMIT 10000
        ];

        if (openTickets.isEmpty()) return;

        Date     today = Date.today();
        DateTime nowDt = System.now();

        List<Support_Ticket__c> toUpdate = new List<Support_Ticket__c>();

        for (Support_Ticket__c t : openTickets) {

            // Derive auto-close date: prefer field value, fall back to CreatedDate + 60
            Date autoCloseDate = (t.Auto_Close_On__c != null)
                ? t.Auto_Close_On__c
                : Date.newInstance(t.CreatedDate.year(), t.CreatedDate.month(), t.CreatedDate.day()).addDays(AUTO_CLOSE_DAYS);

            // Auto-close if the close date has been reached or passed
            if (today > autoCloseDate) {
                toUpdate.add(new Support_Ticket__c(
                    Id              = t.Id,
                    Ticket_Status__c  = STATUS_CLOSE,
                    Closure_Message__c = CLOSURE_MESSAGE
                ));
                continue;
            }

            // Calculate days elapsed since last escalation (or creation if never escalated)
            DateTime lastEsc        = (t.Last_Escalated_On__c != null) ? t.Last_Escalated_On__c : t.CreatedDate;
            Integer  daysSinceLastEsc = Integer.valueOf(
                Math.floor((nowDt.getTime() - lastEsc.getTime()) / (1000.0 * 60 * 60 * 24))
            );

            // Only escalate if 7+ days have passed since last escalation or creation
            if (daysSinceLastEsc < ESCALATION_DAYS) continue;

            String level = t.Escalation_Level__c;

            // Escalation chain: RM -> Sourcing Head -> HOSM (no further escalation beyond HOSM)
            if (level == null || level == LEVEL_RM) {
                toUpdate.add(new Support_Ticket__c(
                    Id                 = t.Id,
                    OwnerId            = t.Sourcing_Head__c,
                    Escalation_Level__c = LEVEL_SH,
                    Last_Escalated_On__c = nowDt
                ));
            } else if (level == LEVEL_SH) {
                toUpdate.add(new Support_Ticket__c(
                    Id                 = t.Id,
                    OwnerId            = t.Head_of_Sales_and_Marketing__c,
                    Escalation_Level__c = LEVEL_HOSM,
                    Last_Escalated_On__c = nowDt
                ));
            }
            // level == HOSM: no further escalation, ticket remains until auto-close
        }

        if (!toUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(toUpdate, false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'SupportTicketService.processEscalations update error: ' + err.getMessage());
                    }
                }
            }
        }
    }
}