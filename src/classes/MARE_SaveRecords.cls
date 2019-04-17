public class MARE_SaveRecords implements Queueable
{
    public final string MAREJobId;
    public final list<string> recordIds;
    public integer startOrderNumber;
    
    public MARE_SaveRecords (string jobId, list<string> rIds, integer sOrderNumber)
    {
        MAREJobId = jobId;
        recordIds = rIds;
        startOrderNumber = sOrderNumber;
    }
    
    public void execute(QueueableContext context)
    {    
        Async_MARE_Job__c MAREJob = new Async_MARE_Job__c ();
        
        for (Async_MARE_Job__c amj : [SELECT Id, Name, Swarm_Name__c, Swarm_Territory__c, Job_Status__c, MARE_Job_Id__c, Submitted_By__c, Cluster__c FROM Async_MARE_Job__c WHERE Id =:MAREJobId])
        {
            MAREJob = amj;
        }
        
        map<string, Lead> LeadMap = new map<string, Lead>();
        
        for (Lead l : [SELECT Id, Name, MALatitude__c, MALongitude__c FROM Lead WHERE Id IN :recordIds])
        {
            LeadMap.put(l.Id, l);
        }
        
        map<string, Contact> ContactMap = new map<string, Contact>();
        
        for (Contact c : [SELECT Id, Name, Account.MALatitude__c, Account.MALongitude__c FROM Contact WHERE Id IN :recordIds])
        {
            ContactMap.put(c.Id, c);
        }
        
        map<string, CampaignMember> CampaignMemberMap = new map<string, CampaignMember>();
        
        for (CampaignMember cm : [SELECT Id, Name, MALatitude__c, MALongitude__c, ContactId, LeadId FROM CampaignMember WHERE Id IN :recordIds])
        {
            CampaignMemberMap.put(cm.Id, cm);
        }
        
        list<Swarm_Waypoint__c> WayPointsToCreate = new list<Swarm_Waypoint__c>();
        list<string> RemainingRecordIds = new list<string>();
        integer RemainingRecordsStartNumber;
        
        for (integer x = 0; x < recordIds.size(); x++)
        {            
            if (WayPointsToCreate.size() < 1000)
            {
                Swarm_Waypoint__c newWaypoint = new Swarm_Waypoint__c();
                newWaypoint.Swarm_Name__c = MAREJob.Swarm_Name__c;
                newWaypoint.Swarm_Territory__c = MAREJob.Swarm_Territory__c;
                newWaypoint.Order__c = startOrderNumber;
                newWaypoint.Cluster__c = MAREJob.Cluster__c;
                newWaypoint.Async_MARE_Job__c = MAREJob.Id;
                
                if (recordIds[x].startsWith('00Q'))
                {
                    // Lead
                    
                    newWaypoint.Lead__c = recordIds[x];
                    newWaypoint.Latitude__c = LeadMap.get(recordIds[x]).MALatitude__c;
                    newWaypoint.Longitude__c = LeadMap.get(recordIds[x]).MALongitude__c;
                }
                else if (recordIds[x].startsWith('003'))
                {
                    // Contact
                    newWaypoint.Contact__c = recordIds[x];
                    newWaypoint.Latitude__c = ContactMap.get(recordIds[x]).Account.MALatitude__c;
                    newWaypoint.Longitude__c = ContactMap.get(recordIds[x]).Account.MALongitude__c;                
                }
                else if (recordIds[x].startsWith('00v'))
                {
                    // Campaign Member
                    
                    if (CampaignMemberMap.get(recordIds[x]).ContactId != null)
                    {
                        newWaypoint.Contact__c = CampaignMemberMap.get(recordIds[x]).ContactId;
                    }
                    else if (CampaignMemberMap.get(recordIds[x]).LeadId != null)
                    {
                        newWaypoint.Lead__c = CampaignMemberMap.get(recordIds[x]).LeadId;
                    }
                    
                    newWaypoint.Latitude__c = CampaignMemberMap.get(recordIds[x]).MALatitude__c;
                    newWaypoint.Longitude__c = CampaignMemberMap.get(recordIds[x]).MALongitude__c;                  
                }            
            
                WayPointsToCreate.add(newWaypoint);
                startOrderNumber++;
            }
            else
            {
                RemainingRecordIds.add(recordIds[x]);
                
                if (RemainingRecordsStartNumber == null)
                {
                    RemainingRecordsStartNumber = startOrderNumber;
                }                
            }
        }
        
        if (RemainingRecordIds.size() > 0)
        {
            System.enqueueJob(new MARE_SaveRecords(MAREJob.Id, RemainingRecordIds, RemainingRecordsStartNumber ));
        }

        insert WayPointsToCreate; 
        
        if (RemainingRecordIds.size() == 0)
        {
            // Create MA Marker Layer
            
            string baseObjectId;
            
            for (sma__MABaseObject__c baseObject : [SELECT Id FROM sma__MABaseObject__c WHERE Name = 'Swarm_Waypoint__c'])
            {
                baseObjectId = baseObject.Id;   
            }  
                    
            map<string, object> ProximityOptions = new map<string, object> {
                'opacity' => '0.60',
                'border' => '#16325C',
                'fill' => '#3083D3',
                'measurementType' => 'MILES',
                'selectType' => 'circle',
                'radius' => '',
                'affectVisibility' => 'true',
                'hideMarkers' => false,
                'enabled' => false 
            };  
            
            map<string, object> AdvancedOptions = new map<string, object> {
                'layerSubType' => null,
                'layerTypeOptions' => '{}',
                'waypointsAfter' => null,
                'waypointsBefore' => null,
                'markerLabelBackgroundColor' => '#16325C',
                'markerLabelTextColor' => '#FFFFFF',
                'heatmapGradient' => '[\"#000000\",\"#0000FF\",\"#00FFFF\",\"#00FF00\",\"#FFFF00\",\"#FF0000\"]',
                'heatmapMaxIntensity' => '5',
                'heatmapOpacity' => '0.80',
                'heatmapRadius' => '15',
                'heatmapDissipating' => true,
                'heatmapWeightedValue' => 'None',
                'otherthreshold' => '',
                'automaticassign' => false,
                'defaultRenderArea' => 'EntireMap',
                'defaultRenderMode' => 'Markers',
                'defaultLiveTab' => 'info',
                'defaultTab' => 'info',
                'aggregateType' => '',
                'markerShapeValue' => null,
                'markerShapeType' => 'dynamic',
                'address' => '',
                'selectType' => 'MILES',
                'distance' => '',
                'enableProxLimit' => false,
                'enableLimit' => false
            };          
            
            map<string, object> ActivityFilter = new map<string, object> {
                'operator' => 'AND',
                'event' => 'all',
                'task' => 'all'
            };
            
            map<integer, string> ColorHexMap = new map<integer, string>{
                1 => '#6aa84f',
                2 => '#a61c00',
                3 => '#e69138',
                4 => '#6aa84f',
                5 => '#3c78d8',
                6 => '#674ea7',
                7 => '#a64d79',
                8 => '#3d85c6',
                9 => '#45818e',
                10 => '#f1c232', 
                11 => '#cc0000',
                12 => '#d5a6bd',
                13 => '#9fc5e8',
                14 => '#a2c4c9',
                15 => '#ffe599', 
                16 => '#ea9999',
                17 => '#b4a7d6',
                18 => '#a4c2f4',
                19 => '#b6d7a8',
                20 => '#f9cb9c'        
            };

            list<map<string, string>> ColorAssignmentList = new list<map<string, string>>();
            
            for (integer x = 1; x <= 20; x++)
            {
                map<string, string> AssignmentMap = new map<string, string>{
                    'operator' => 'currency',
                    'comparevalue' => string.valueOf(x),
                    'toVal' => string.valueOf(x),
                    'value' => ColorHexMap.get(x)
                };
                ColorAssignmentList.add(AssignmentMap);
            }
            
            map<string, string> OtherAssignmentMap = new map<string, string>{
                'operator' => 'currency',
                    'comparevalue' => '<Other>',
                    'toVal' => '<Other>',
                    'value' => '#4c1130'
                    }; 
                        
            ColorAssignmentList.add(OtherAssignmentMap);  
            
            sma__MASavedQry__c newSavedQry = new sma__MASavedQry__c();
            newSavedQry.Name = MAREJob.Swarm_Name__c;           
            newSavedQry.sma__BaseObject__c = baseObjectId;
            newSavedQry.sma__Query__c = 'FROM Swarm_Waypoint__c WHERE Id != \'\' AND Async_MARE_Job__c = \'' + MAREJob.Id + '\'';     
            newSavedQry.sma__ColorAssignmentType__c = 'Dynamic-Label';
            newSavedQry.sma__OwnerFilterId__c = 'All';
            newSavedQry.sma__ActivityFilter__c = JSON.serialize(ActivityFilter);
            newSavedQry.sma__ProximityOptions__c = JSON.serialize(ProximityOptions);  
            newSavedQry.sma__RowLimit__c = 250000;
            newSavedQry.sma__AdvancedOptions__c = JSON.serialize(AdvancedOptions);
            newSavedQry.sma__RowOrder__c = 'Order__c'; 
            newSavedQry.sma__RowOrderDirection__c = 'asc';
            newSavedQry.sma__Tooltip1__c = 'Order__c';
            newSavedQry.sma__Tooltip2__c = 'Lead__r.Name';
            newSavedQry.sma__Tooltip3__c = 'Lead__r.Phone';
            newSavedQry.sma__Tooltip4__c = 'Lead__r.Email';
            newSavedQry.sma__Tooltip5__c = 'Contact__r.Name';
            newSavedQry.sma__Tooltip6__c = 'Contact__r.Phone';
            newSavedQry.sma__Tooltip7__c = 'Contact__r.Email';            
            newSavedQry.sma__Tooltip8__c = 'Swarm_Name__c';
            newSavedQry.sma__ColorsAssignedDynamically__c = true;
            newSavedQry.sma__OrgWide__c = true;
            newSavedQry.sma__PicklistField__c = 'Cluster__c';            
            newSavedQry.sma__ColorAssignment__c = JSON.serialize(ColorAssignmentList);
            newSavedQry.sma__ColorsAssignedDynamically__c = true;
            insert newSavedQry;
            
            sma__MASavedQryComponent__c newSavedQryComponent = new sma__MASavedQryComponent__c();
            newSavedQryComponent.sma__MASavedQry__c = newSavedQry.Id;
            newSavedQryComponent.sma__BaseObject__c = 'Swarm_Waypoint__c';
            newSavedQryComponent.sma__Type__c = 'Filter';
            newSavedQryComponent.sma__Index__c = 0;
            newSavedQryComponent.sma__Field__c = 'Async_MARE_Job__c';
            newSavedQryComponent.sma__Operator__c = 'equals';
            newSavedQryComponent.sma__Value__c = MAREJob.Id;                
            
            insert newSavedQryComponent;         
        
        
            // Send Email
            
            if (!Test.isRunningTest())
            {
                list<string> EmailAddresses = new list<string>();
                
                for (User u : [SELECT Email FROM User WHERE Id = :MAREJob.Submitted_By__c])
                {
                    EmailAddresses.add(u.Email);
                }
            
                //EmailAddresses.add('jlevy@mapanything.com');

                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.ToAddresses = EmailAddresses;
                message.Subject = 'MARE Solution for Swarm: ' + MAREJob.Swarm_Name__c + ' is finished.';
                message.PlainTextBody = 'The solution for your MARE Job is complete and the Swarm Waypoint records have been saved.';
                
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                Messaging.SendEmailResult[] rslts = Messaging.sendEmail(messages); 
            } 
            
            // Update MARE Job
            
            MAREJob.Job_Status__c = 'Completed';
            MAREJob.Completed_DateTime__c = Datetime.now();
            update MAREJob;         
        }            
    }
}