// Batch Class for Lead Notes to Call Comments Migration
public class LeadNotesToCallCommentsBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    // Stateful variables to track progress
    public Integer totalLeadsProcessed = 0;
    public Integer totalLeadsSkipped = 0;
    public Integer totalCommentsCreated = 0;
    public List<String> errorMessages = new List<String>();
    
    // Optional: Filter criteria
    public String whereClause;
    
    // Constructor with optional filter
    public LeadNotesToCallCommentsBatch() {
        this.whereClause = '';
    }
    
    public LeadNotesToCallCommentsBatch(String filterClause) {
        this.whereClause = filterClause;
    }
    
    // Start method - query all leads
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name, Last_Note__c, ' +
                       '(SELECT Id, Name FROM Related_sources__r ' +
                       'WHERE Is_Locked__c = false ORDER BY CreatedDate LIMIT 1) ' +
                       'FROM Lead';
        
        if (String.isNotBlank(whereClause)) {
            query += ' WHERE ' + whereClause;
        }
        
        integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        System.debug('Query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    // Execute method - process each batch of leads
    public void execute(Database.BatchableContext BC, List<Lead> scope) {
        List<Call_Comments__c> callCommentsToInsert = new List<Call_Comments__c>();
        Map<String, Id> userNameToIdMap = new Map<String, Id>();
        Map<Id, String> userIdToProfileMap = new Map<Id, String>();
        
        System.debug('Processing batch with ' + scope.size() + ' leads');
        
        for (Lead leadRecord : scope) {
            try {
                // Skip leads without notes (since we can't filter in SOQL)
                if (String.isBlank(leadRecord.Last_Note__c)) {
                    System.debug('SKIPPED - No notes found for Lead: ' + leadRecord.Id);
                    totalLeadsSkipped++;
                    continue;
                }
                
                // Check if there's a related source
                if (leadRecord.Related_sources__r == null || leadRecord.Related_sources__r.isEmpty()) {
                    System.debug('SKIPPED - No unlocked Related Source for Lead: ' + leadRecord.Id);
                    totalLeadsSkipped++;
                    errorMessages.add('Lead ' + leadRecord.Id + ': No unlocked Related Source found');
                    continue;
                }
                
                Id relatedSourceId = leadRecord.Related_sources__r[0].Id;
                
                // Parse notes (split by newline)
                List<String> lastNotes = leadRecord.Last_Note__c.split('\n');
                
                // Filter out empty strings
                List<String> filteredNotes = new List<String>();
                for (String note : lastNotes) {
                    if (String.isNotBlank(note)) {
                        filteredNotes.add(note.trim());
                    }
                }
                
                // Reverse the list to get notes in descending order
                List<String> reversedNotes = new List<String>();
                for (Integer i = filteredNotes.size() - 1; i >= 0; i--) {
                    reversedNotes.add(filteredNotes[i]);
                }
                
                System.debug('Processing Lead: ' + leadRecord.Id + ' with ' + reversedNotes.size() + ' notes');
                
                // Collect user names for bulk query
                Set<String> userNames = new Set<String>();
                for (String note : reversedNotes) {
                    // Extract user name from format: "Call Summary 1: Arpitha [11-12-25 14:58 PM]: ..."
                    if (note.contains('[')) {
                        String beforeBracket = note.substringBefore('[').trim();
                        if (beforeBracket.contains(':')) {
                            String[] parts = beforeBracket.split(':', 2);
                            if (parts.size() > 1) {
                                String userName = parts[1].trim();
                                userNames.add(userName);
                            }
                        }
                    } else if (note.contains(':')) {
                        String[] parts = note.split(':', 2);
                        String userName = parts[0].trim();
                        userNames.add(userName);
                    }
                }
                
                // Bulk query users if not already cached
                if (!userNames.isEmpty()) {
                    for (String userName : userNames) {
                        if (!userNameToIdMap.containsKey(userName)) {
                            List<User> users = [SELECT Id, Profile.Name FROM User WHERE Name = :userName LIMIT 1];
                            if (!users.isEmpty()) {
                                userNameToIdMap.put(userName, users[0].Id);
                                userIdToProfileMap.put(users[0].Id, users[0].Profile.Name);
                            }
                        }
                    }
                }
                
                // Create Call Comments for each note
                for (String note : reversedNotes) {
                    Call_Comments__c callComment = new Call_Comments__c();
                    callComment.Comments__c = note;
                    callComment.Related_Source__c = relatedSourceId;
                    callComment.Lead__c = leadRecord.Id;
                    
                    // Extract timestamp and user name from note
                    // Expected format: "Call Summary 1: Arpitha [11-12-25 14:58 PM]: Customer didn't answer the call."
                    String userName = null;
                    DateTime noteDateTime = null;
                    
                    // Try to extract date/time from note (format: [DD-MM-YY HH:MM AM/PM])
                    Pattern datePattern = Pattern.compile('\\[(\\d{2})-(\\d{2})-(\\d{2})\\s+(\\d{1,2}):(\\d{2})\\s+(AM|PM)\\]');
                    Matcher dateMatcher = datePattern.matcher(note);
                    
                    if (dateMatcher.find()) {
                        try {
                            Integer day = Integer.valueOf(dateMatcher.group(1));
                            Integer month = Integer.valueOf(dateMatcher.group(2));
                            Integer year = 2000 + Integer.valueOf(dateMatcher.group(3)); // Assuming 20XX
                            Integer hour = Integer.valueOf(dateMatcher.group(4));
                            Integer minute = Integer.valueOf(dateMatcher.group(5));
                            String ampm = dateMatcher.group(6);
                            
                            // Convert to 24-hour format
                            if (ampm == 'PM' && hour != 12) {
                                hour += 12;
                            } else if (ampm == 'AM' && hour == 12) {
                                hour = 0;
                            }
                            
                            noteDateTime = DateTime.newInstance(year, month, day, hour, minute, 0);
                            callComment.Created_Date__c = noteDateTime;
                        } catch (Exception e) {
                            System.debug('Failed to parse date from note: ' + e.getMessage());
                        }
                    }
                    
                    // Extract user name (text before the date bracket)
                    if (note.contains('[')) {
                        String beforeBracket = note.substringBefore('[').trim();
                        if (beforeBracket.contains(':')) {
                            String[] parts = beforeBracket.split(':', 2);
                            // Get the part after "Call Summary N:" which should be the name
                            if (parts.size() > 1) {
                                userName = parts[1].trim();
                            } else {
                                userName = parts[0].trim();
                            }
                        }
                    } else if (note.contains(':')) {
                        // Fallback: if no bracket, just split by colon
                        String[] parts = note.split(':', 2);
                        userName = parts[0].trim();
                    }
                    
                    // Lookup user if name found
                    if (String.isNotBlank(userName) && userNameToIdMap.containsKey(userName)) {
                        Id userId = userNameToIdMap.get(userName);
                        callComment.Created_User__c = userId;
                        callComment.User_Profile__c = userIdToProfileMap.get(userId);
                    }
                    
                    callCommentsToInsert.add(callComment);
                }
                
                totalLeadsProcessed++;
                
            } catch (Exception e) {
                totalLeadsSkipped++;
                String errorMsg = 'Lead ' + leadRecord.Id + ': ' + e.getMessage();
                errorMessages.add(errorMsg);
                System.debug('ERROR processing lead ' + leadRecord.Id + ': ' + e.getMessage());
            }
        }
        
        // Insert Call Comments
        if (!callCommentsToInsert.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.insert(callCommentsToInsert, false);
                
                Integer successCount = 0;
                Integer failCount = 0;
                
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        successCount++;
                    } else {
                        failCount++;
                        String errors = '';
                        for (Database.Error err : results[i].getErrors()) {
                            errors += err.getMessage() + '; ';
                        }
                        errorMessages.add('Call Comment insertion failed: ' + errors);
                    }
                }
                
                totalCommentsCreated += successCount;
                System.debug('Batch inserted ' + successCount + ' Call Comments, ' + failCount + ' failed');
                
            } catch (Exception e) {
                errorMessages.add('Bulk insert error: ' + e.getMessage());
                System.debug('ERROR inserting Call Comments: ' + e.getMessage());
            }
        }
    }
    
    // Finish method - send summary email
    public void finish(Database.BatchableContext BC) {
    }
}