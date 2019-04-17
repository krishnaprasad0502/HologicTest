/*------------------------------------------------------------
Author:         Dave Mansell
Company:        Salesforce.com
Description:    Case_Summary__c Trigger functions
Test Class:     CaseSummaryTriggerActions_Test

History:
<Date>        <Authors Name>      <Brief Description of Change>
04/19/2018    Dave Mansell      Initial Creation (US-0004058)
01/28/2019    Vinay N           Modified to handle the special characters on ContentString while inserting ContentNote to resolve ContentNote- HTML Tags compatibility error (US-0006563)
------------------------------------------------------------*/
public without sharing class CaseSummaryTriggerActions {
    
    public static Set<Id> alreadyUpdatedSummaries   {get;set;}
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Loops through all fields on Case Summary, checks for change, if so, creates note on case
    Inputs:             List of records, Map of old records
    Returns:            N/A
    Test Class(es):     CaseSummaryTriggerActions_Test.testCreateNotesOnCases
    ------------------------------------------------------------*/
    public static void createNotesOnCases(List<Case_Summary__c> caseSummaries, Map<Id, Case_Summary__c> oldMap){
        //Define fields we want to track
        Set<String> fieldNamesToTrack = new Set<String>();
        for(Case_Summary_Field__mdt csf : [
            SELECT DeveloperName
              FROM Case_Summary_Field__mdt
             WHERE Track_Changes__c = true
        ]){
            fieldNamesToTrack.add(csf.DeveloperName.toLowerCase() + '__c');
        }
        
        List<ContentNote> notesToInsert = new List<ContentNote>();
        Map<Id, List<ContentNote>> noteListsByCaseId = new Map<Id, List<ContentNote>>();
        Map<String, Schema.SObjectField> csFieldMap = Case_Summary__c.sObjectType.getDescribe().fields.getMap();
        
        //Loop through case summaries
        if(alreadyUpdatedSummaries == null){
            alreadyUpdatedSummaries = new Set<Id>();
        }
        for(Case_Summary__c summary : caseSummaries){
            alreadyUpdatedSummaries.add(summary.Id);
            Case_Summary__c old = oldMap.get(summary.Id);
            List<ContentNote> notesForCase = new List<ContentNote>();
            //Loop through fields
            for(String csFieldName : csFieldMap.keySet()){
                if(fieldNamesToTrack.contains(csFieldName)){
                    //Check for change from non-null value
                    if(old != null && old.get(csFieldName) != null && summary.get(csFieldName) != old.get(csFieldName)){
                        //If change found, create note
                        Schema.SObjectField csField = csFieldMap.get(csFieldName);
                        ContentNote nte = new ContentNote();
                        nte.Title = csField.getDescribe().getLabel() + ' Updated';
                        String contentString = 
                            'Old Value: ' + old.get(csFieldName) + '\n' +
                            'New Value: ' + summary.get(csFieldName);
                        nte.Content = Blob.valueOf(contentString.escapeHTML3());
                        notesForCase.add(nte);
                        notesToInsert.add(nte);
                    }
                }
            }
            if(notesForCase.size() > 0){
                noteListsByCaseId.put(summary.Case__c, notesForCase);
            }
        }
        
        //Insert notes
        if(notesToInsert.size() > 0){
            insert notesToInsert;
            
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for(Id caseId : noteListsByCaseId.keySet()){
                for(ContentNote nte : noteListsByCaseId.get(caseId)){
                    ContentDocumentLink link = new ContentDocumentLink();
                    link.ContentDocumentId = nte.Id;
                    link.LinkedEntityId = caseId;
                    link.ShareType = 'I';
                    links.add(link);
                }
            }
            insert links;
        }
    }

    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Generates integration string when case summary is updated
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     CaseSummaryTriggerActions_Test.testUpdateAgileIntegrationString
    ------------------------------------------------------------*/
    public static void updateAgileIntegrationString(List<Case_Summary__c> caseSummaries){
        List<Case_Summary_Field__mdt> csfs = [
            SELECT MasterLabel, Extended_Label__c, DeveloperName
              FROM Case_Summary_Field__mdt
             WHERE Include_in_Agile_String__c = true
             ORDER BY MasterLabel ASC
        ];
        
        //Gather Case IDs
        Set<Id> standardCaseIds = new Set<Id>();
        Set<Id> legacyCaseIds = new Set<Id>();
        for(Case_Summary__c cs : caseSummaries){
            standardCaseIds.add(cs.Case__c);
            if(cs.Include_History__c == true){
                legacyCaseIds.add(cs.Case__c);
            }
        }
        
        Map<Id, List<Detail>> detailsByCaseId = new Map<Id, List<Detail>>();
        if(standardCaseIds.size() > 0){
            //Add note details
            Map<Id, ContentDocumentLink> cdLinksByNoteId = new Map<Id, ContentDocumentLink>();
            for(ContentDocumentLink cdLink : [
                SELECT Id
                      ,ContentDocumentId
                      ,LinkedEntityId
                  FROM ContentDocumentLink
                 WHERE LinkedEntityId IN :standardCaseIds
            ]){
                cdLinksByNoteId.put(cdLink.ContentDocumentId, cdLink);
            }
            for(ContentNote nte : [
                SELECT Id
                      ,CreatedBy.Name
                      ,CreatedDate
                      ,Title
                      ,Content
                  FROM ContentNote
                 WHERE Id IN :cdLinksByNoteId.keySet()
            ]){
                Id caseId = cdLinksByNoteId.get(nte.Id).LinkedEntityId;
                List<Detail> detailList = detailsByCaseId.get(caseId);
                if(detailList == null){
                    detailList = new List<Detail>();
                }
                Detail det = new Detail(
                    true,
                    nte.CreatedBy.Name,
                    nte.CreatedDate.format('yyyy-MM-dd HH:mm:ss'),
                    nte.Title,
                    nte.Content.toString()
                );
                detailList.add(det);
                detailsByCaseId.put(caseId, detailList);
            }
        }
        if(legacyCaseIds.size() > 0){
            //Add Task details
            for(Case cas : [
                SELECT Id
                      ,(SELECT Id
                              ,WhatId
                              ,CreatedBy.Name
                              ,CreatedDate
                              ,Note_Type__c
                              ,Description
                          FROM ActivityHistories)
                  FROM Case
                 WHERE Id IN :legacyCaseIds
            ]){
                for(ActivityHistory tsk : cas.ActivityHistories){
                    List<Detail> detailList = detailsByCaseId.get(tsk.WhatId);
                    if(detailList == null){
                        detailList = new List<Detail>();
                    }
                    Detail det = new Detail(
                        false,
                        tsk.CreatedBy.Name,
                        tsk.CreatedDate.format('yyyy-MM-dd HH:mm:ss'),
                        tsk.Note_Type__c,
                        tsk.Description
                    );
                    detailList.add(det);
                    detailsByCaseId.put(tsk.WhatId, detailList);
                }
            }
            
            //Add WOLI details
            for(WorkOrderLineItem woli : [
                SELECT Id
                      ,Case__c
                      ,CreatedBy.Name
                      ,CreatedDate
                      ,Note_Type__c
                      ,Description
                  FROM WorkOrderLineItem
                 WHERE Case__c IN :legacyCaseIds
            ]){
                List<Detail> detailList = detailsByCaseId.get(woli.Case__c);
                if(detailList == null){
                    detailList = new List<Detail>();
                }
                Detail det = new Detail(
                    false,
                    woli.CreatedBy.Name,
                    woli.CreatedDate.format('yyyy-MM-dd HH:mm:ss'),
                    woli.Note_Type__c,
                    woli.Description
                );
                detailList.add(det);
                detailsByCaseId.put(woli.Case__c, detailList);
            }
        }
        
        for(Case_Summary__c caseSummary : caseSummaries){
            //Initiate string array
            List<String> summaryStrings = new List<String>();
            List<String> changeStrings = new List<String>();
            
            //Loop through custom metadata field map, adding values
            for(Case_Summary_Field__mdt csf : csfs){
                Object value = caseSummary.get(csf.DeveloperName + '__c');
                if(value != null && String.valueOf(value) != 'false'){
                    summaryStrings.add(csf.Extended_Label__c + ' ' + String.valueOf(value));
                }
            }
            
            List<Detail> detailList = detailsByCaseId.get(caseSummary.Case__c);
            if(detailList != null){
                //Sort the detail list by date
                Map<String, List<Detail>> detailsByDateString = new Map<String, List<Detail>>();
                for(Detail det : detailList){
                    List<Detail> subList = detailsByDateString.get(det.createdDate);
                    if(subList == null){
                        subList = new List<Detail>();
                    }
                    subList.add(det);
                    detailsByDateString.put(det.createdDate, subList);
                }
                List<String> sortedDateStrings = new List<String>(detailsByDateString.keySet());
                sortedDateStrings.sort();
                List<Detail> sortedList = new List<Detail>();
                for(String dateString : sortedDateStrings){
                    sortedList.addAll(detailsByDateString.get(dateString));
                }
                
                //Add details to concatString
                for(Detail det : sortedList){
                    if(det.isNote){
                        if(
                            (det.body.contains('Old Value: ') && det.body.contains('New Value: ')) ||
                            det.title == 'Service Order Created' ||
                            det.title == 'Work Order Closed' ||
                            det.title == 'Email Sent'
                        ){
                            changeStrings.add('\n');
                            changeStrings.add(det.title);
                            changeStrings.add(det.createdDate + ' by ' + det.username + '\n' + det.body);
                        } else {
                            summaryStrings.add('\n');
                            summaryStrings.add(det.title);
                            summaryStrings.add(det.createdDate + ' by ' + det.username + '\n' + det.body);
                        }
                    } else {
                        summaryStrings.add('\n');
                        summaryStrings.add('Entered by: '   + det.username);
                        summaryStrings.add('On: '           + det.createdDate);
                        summaryStrings.add('Type: '         + det.title);
                        summaryStrings.add('Note: '         + det.body);
                    }
                }
            }
            
            caseSummary.Audit_Trail__c = String.join(changeStrings, '\n');
            caseSummary.Quality_Integration_String__c =
                String.join(summaryStrings, '\n')
                      .replaceAll('</p>'            ,'\n')
                      .replaceAll('_BR_ENCODED_'    ,'\n')
                      .replaceAll('\\<.*?\\>', '')
            ;
        }
    }
    
    private class Detail {
        private Boolean isNote          {get;set;}
        private String username         {get;set;}
        private String createdDate      {get;set;}
        private String title            {get;set;}
        private String body             {get;set;}
        
        private Detail(Boolean isNote, String username, String createdDate, String title, String body){
            this.isNote = isNote;
            this.username = username;
            this.createdDate = createdDate;
            this.title = title;
            this.body = body;
        }
    }
}