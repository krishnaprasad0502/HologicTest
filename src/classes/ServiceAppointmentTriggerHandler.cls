/*------------------------------------------------------------
Author          Rob Strickler
Company:        Salesforce
Description:    Service Appointment trigger actions:
                On Service Appointment creation, collect information from the related Work Order to populate fields
                On Service Appointment update, cascade Status change back to related Work Order
Related:        ServiceAppointmentTriggerHandler.cls
                ServiceAppointmentTriggerHandler_Test.cls

History:
<Date           <Authors Name       <Brief Description of Change>
04/23/2018      Rob Strickler       Initial Creation
09/01/2018      Krishna             Reason_for_Cancellation__c validation for WO's
04/16/2019      Krishna             (US-0006815)Implement status mapping via metadata 
------------------------------------------------------------*/

public without sharing class ServiceAppointmentTriggerHandler {
    
    public static Boolean alreadyRan        {get;set;}
    
    public static void updateFieldValues(List<ServiceAppointment> sas){
        //Collect WO Ids
        Map<Id, WorkOrder> wosById = new Map<Id, WorkOrder>();
        Map<Id, WorkType> workTypesById = new Map<Id, WorkType>();
        for(ServiceAppointment sa : sas){
            if(sa.ParentRecordId != null){
                wosById.put(sa.ParentRecordId, null);
            }
        }
        wosById = new Map<Id, WorkOrder>([
            SELECT Id
                  ,City
                  ,Street
                  ,State
                  ,StateCode
                  ,PostalCode
                  ,CountryCode
                  ,ContactId
                  ,WorkTypeId
                  ,WorkType.Name
                  ,Account_Name__c
                  ,AccountId
                  ,Account.ParentId
                  ,Account.Parent.Name
              FROM WorkOrder
             WHERE Id IN :wosById.keySet()
        ]);
        
        //Update fields on SAs
        for(ServiceAppointment sa : sas){
            WorkOrder wo = wosById.get(sa.ParentRecordId);
            
            if(wo != null){
                sa.Related_Work_Order__c    = wo.Id;
                sa.City                     = wo.City;
                sa.Street                   = wo.Street;
                sa.StateCode                = wo.StateCode;
                sa.PostalCode               = wo.PostalCode;
                sa.CountryCode              = wo.CountryCode;
                sa.ContactId                = wo.ContactId;
                
                List<String> ganttLabelArray = new List<String>();
                if(wo.City != null && wo.State != null){
                    ganttLabelArray.add(wo.City + ', ' + wo.State);
                }
                if(wo.WorkTypeId != null){
                    ganttLabelArray.add(wo.WorkType.Name);
                }
                if(wo.Account_Name__c != null){
                    ganttLabelArray.add(wo.Account_Name__c);
                }
                if(wo.AccountId != null && wo.Account.ParentId != null){
                    ganttLabelArray.add(wo.Account.Parent.Name);
                }
                sa.FSL__GanttLabel__c = String.join(ganttLabelArray, '; ');
            }
            
            if(sa.Status == 'Dispatched' && sa.Date_Time_Dispatched__c == null) {
                sa.Date_Time_Dispatched__c = System.Now();
            }
        }
    }
    
    public static void updateWorkOrders(List<ServiceAppointment> sas, Map<Id, ServiceAppointment> oldMap){
        Map<Id, ServiceAppointment> validSAsById = new Map<Id, ServiceAppointment>();
        Map<Id, WorkOrder> wosById = new Map<Id, WorkOrder>();
        for(ServiceAppointment sa : sas){
            ServiceAppointment old = oldMap.get(sa.Id);
            if(sa.Status != old.Status || sa.OwnerId != old.OwnerId){
                wosById.put(sa.ParentRecordId, null);
                validSAsById.put(sa.Id, sa);
            }
        }
        
        wosById = new Map<Id, WorkOrder>([
            SELECT Id,Reason_for_Cancellation__c
              FROM WorkOrder
             WHERE Id IN :wosById.keySet()
        ]);
        //04/16/2019        Krishna             (US-0006815)Implement status mapping via metadata 
        Map<string,string> saStatusMap = new Map<string,string>();
    list<WoSa_Status__mdt> saStatusListDteails = new list<WoSa_Status__mdt>([SELECT ID, Object_id__c, SA_Status__c,WO_Status__c FROM WoSa_Status__mdt where Object_id__c='08p' ]);
        system.debug('saStatusListDteails::::'+ saStatusListDteails);
        if(saStatusListDteails.size()>0)
        for(WoSa_Status__mdt saStatusDetail :saStatusListDteails){
           system.debug('saStatusListDteails::::'+ saStatusListDteails);
            saStatusMap.put(saStatusDetail.SA_Status__c,saStatusDetail.WO_Status__c);
        }
    system.debug('saStatusMap::::'+ saStatusMap);
        
        for(ServiceAppointment sa : validSAsById.values()){
            WorkOrder wo = wosById.get(sa.ParentRecordId);
            ServiceAppointment old = oldMap.get(sa.Id);
            
            if (wo != null) {
                if(sa.OwnerId != old.OwnerId){
                    wo.OwnerId = sa.OwnerId;
                }
                if(sa.Status != old.Status){
                    
                /*
                //Krishna - US-0006198  09/01/2018   Reason_for_Cancellation__c validation for WO's
                    if( (sa.Status == 'Canceled' ||sa.Status == 'Re-opened') && String.isBlank(wo.Reason_for_Cancellation__c)) {                       
                        sa.adderror('Please enter information in the Reason for Cancellation/Re-open field for this Work Order');                        
                    } else if(sa.Status == 'Completed') {
                        wo.Status = 'Completed';
                        wo.Completed_Date__c = sa.ActualEndTime;
                    } else if(sa.Status == 'None') {
                        wo.Status = 'New';
                    } else if(sa.Status == 'Confirmed') {
                        wo.Status = 'Confirmed';
                    } else if(sa.Status == 'Scheduled') {
                        wo.Status = 'Assigned';
                    } else if(sa.Status == 'Dispatched') {
                        wo.Status = 'Assigned';
                    } else if(sa.Status == 'In Progress') {
                        wo.Status = 'In-Progress';
                    } else if(sa.Status == 'Cannot Complete') {
                        wo.Status = 'Incomplete';
                    } else if(sa.Status == 'Canceled') {
                        wo.Status = 'Cancelled';
                        //wo.Reason_for_Cancellation__c = 'Cancellation set by cancelled Service Appointment';
                    } else if(sa.Status == 'Rejected') {
                        wo.Status = 'Rejected';
                    } else if(sa.Status == 'Re-opened') {
                        wo.Status = 'Re-opened';
                    }
                }*/
                   
                //Krishna - US-0006198  09/01/2018   Reason_for_Cancellation__c validation for WO's
                    if( (sa.Status == 'Canceled' ||sa.Status == 'Re-opened') && String.isBlank(wo.Reason_for_Cancellation__c)) {                        
                        sa.adderror('Please enter information in the Reason for Cancellation/Re-open field for this Work Order');                        
                    }  else  {
                        //04/16/2019        Krishna             (US-0006815)Implement status mapping via metadata 
                        if(saStatusMap.containsKey(sa.status)){
                            wo.Status=saStatusMap.get(sa.Status);   
                            if(wo.Status == 'Completed') {
                                wo.Status = 'Completed';
                                wo.Completed_Date__c = sa.ActualEndTime;
                            }
                        }
                    
                    }
                }
            }
        }
        //Temporarily turn off the WO trigger to prevent infinite loop
        /*Trigger_Switch__c woSwitch = Trigger_Switch__c.getValues('WorkOrderTrigger');
        Boolean switchWasOn = woSwitch.Active__c;
        if(switchWasOn){
            woSwitch.Active__c = false;
            update woSwitch;
        }*/
        
        update wosById.values();
        
        /*if(switchWasOn){
            woSwitch.Active__c = true;
            update woSwitch;
        }*/
    }
    
    public static void checkToReassignAndNotify(List<ServiceAppointment> sas, Map<Id, ServiceAppointment> oldMap){
        Map<Id, ServiceResource> servResourcesById = new Map<Id, ServiceResource>();
        for(ServiceAppointment sa : sas){
            ServiceAppointment old = oldMap.get(sa.Id);
            if(sa.Reassigned_Resource__c != old.Reassigned_Resource__c && sa.Reassigned_Resource__c != null){
                servResourcesById.put(sa.Reassigned_Resource__c, null);
            }
        }
    
        if(servResourcesById.isEmpty()){
            return;
        }
        
        servResourcesById = new Map<Id, ServiceResource>([
            SELECT Id
                  ,RelatedRecordId
              FROM ServiceResource
             WHERE Id IN :servResourcesById.keySet()
        ]);
        
        for(ServiceAppointment sa : sas){
            ServiceAppointment old = oldMap.get(sa.Id);
            if(old.Reassigned_Resource__c != sa.Reassigned_Resource__c && sa.Reassigned_Resource__c != null){
                sa.OwnerId = servResourcesById.get(sa.Reassigned_Resource__c).RelatedRecordId;
                if(old.OwnerId != null){
                    createNewOwnershipChatterPost(sa.Id, old.OwnerId, sa.OwnerId);
                }
            }
        }
    }

    public static ConnectApi.FeedElement createNewOwnershipChatterPost(Id saId, Id oldOwnerId, Id newOwnerId){
        //Create post
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
    
        //Add content
        ConnectApi.MentionSegmentInput mentionSegmentFrom = new ConnectApi.MentionSegmentInput();
        mentionSegmentFrom.Id = oldOwnerId;
        messageInput.messageSegments.add(mentionSegmentFrom);
    
        ConnectApi.TextSegmentInput textSegment0 = new ConnectApi.TextSegmentInput();
        textSegment0.text = ' has reassigned this SA to ';
        messageInput.messageSegments.add(textSegment0);
    
        ConnectApi.MentionSegmentInput mentionSegmentTo = new ConnectApi.MentionSegmentInput();
        mentionSegmentTo.Id = newOwnerId;
        messageInput.messageSegments.add(mentionSegmentTo);
    
        ConnectApi.TextSegmentInput textSegment2 = new ConnectApi.TextSegmentInput();
        textSegment2.text = '.';
        messageInput.messageSegments.add(textSegment2);
        
        //Bring it all together
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        input.feedElementType = ConnectApi.FeedElementType.FeedItem;
        input.subjectId = saId;
        
        //Post it
        ConnectApi.FeedElement feedElement;
        if(!Test.isRunningTest()){
            feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), input);
        }
        return feedElement;
    }
    
    public static void checkToSetWODateValues(List<ServiceAppointment> sas, Map<Id, ServiceAppointment> oldMap){
        List<ServiceAppointment> validSAs = new List<ServiceAppointment>();
        for(ServiceAppointment sa : sas){
            ServiceAppointment old = oldMap.get(sa.Id);
            if(sa.SchedStartTime        != old.SchedStartTime ||
               sa.SchedEndTime          != old.SchedEndTime ||
               sa.ActualStartTime       != old.ActualStartTime ||
               sa.ActualEndTime         != old.ActualEndTime ||
               sa.Related_Work_Order__c != old.Related_Work_Order__c){
                validSAs.add(sa);
            }
        }
        
        if(validSAs.size() > 0){
            setWODateValues(validSAs);
        }
    }
    
    public static void setWODateValues(List<ServiceAppointment> sas){
        Map<Id, ServiceAppointment> sasByWOId = new Map<Id, ServiceAppointment>();
        for(ServiceAppointment sa : sas){
            if(sa.Related_Work_Order__c != null){
                sasByWOId.put(sa.Related_Work_Order__c, sa);
            }
        }
        
        List<WorkOrder> wos = [
            SELECT Id
              FROM WorkOrder
             WHERE Id IN :sasByWOId.keySet()
        ];
        
        for(WorkOrder wo : wos){
            ServiceAppointment sa = sasByWOId.get(wo.Id);
            
            if(sa.SchedStartTime != null && sa.ActualStartTime == null){
                wo.StartDate = sa.SchedStartTime;
            } else if(sa.ActualStartTime != null){
                wo.StartDate = sa.ActualStartTime;
            }
            
            if(sa.SchedEndTime != null && sa.ActualEndTime == null){
                wo.EndDate = sa.SchedEndTime;
            } else if(sa.ActualEndTime != null){
                wo.EndDate = sa.ActualEndTime;
            }
        }
        
        update wos;
    }
}