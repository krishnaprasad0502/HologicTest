/*------------------------------------------------------------
  Author:         Ken Taylor
  Company:        Hologic
  Description:    Trigger Actions for the Swarm Waypoint object
  Test Class:     SwarmWaypoint_Test
 
  History:
  <Date>          <Authors Name>      <Brief Description of Change>
  11/15/2018      Ken Taylor          Initial Creation ()
  11/28/2018      Mani Sundaresan     Added logic to update the waypoint count on Zone
  03/14/2019      Mani Sundaresan     Added logic to update the related Lead with Waypoint Details
  03/18/2019      Mani Sundaresan      Added logic to update the related Contact with Waypoint Details
  ------------------------------------------------------------*/
public class SwarmWaypointTriggerActions {

    /*------------------------------------------------------------
      Author:         Ken Taylor
      Company:        Hologic
      Description:    Updates the swarm zone on the swarm waypoint based on the zone populated on the record.
      Runs after insert, after update
      Inputs:         Swarm_Waypoints - The list of Swarm Waypoints to modify
      Returns:        N/A
     
      History:
      <Date>          <Authors Name>      <Brief Description of Change>
      11/15/2018      Ken Taylor          Initial Creation ()
      ------------------------------------------------------------*/
    public static void updateSwarmZone(List<Swarm_Waypoint__c> waypoint, Map<Id, Swarm_Waypoint__c> oldMap) {

        List<Swarm_Waypoint__c> waypointList = [SELECT Id, Fiscal_Year__c, Zone__c, Swarm_Territory__r.Territory_Code__c FROM Swarm_Waypoint__c WHERE Zone__c<> null AND Id IN :waypoint];

        List<Swarm_Zone__c> waypointzoneList = [SELECT Id, Name, Zone__c from Swarm_Zone__c];

        List<Swarm_Waypoint__c> waypointUpdate = new List<Swarm_Waypoint__c> ();

        Map<String, Swarm_Zone__c> sZoneByName = new Map<String, Swarm_Zone__c> ();

        for (Swarm_Zone__c zone : waypointzoneList) {
            sZoneByName.put(zone.Name, zone);
        }

        String SwarmZone = null;

        //String currentFiscalYear = [SELECT FiscalYearSettings.Name FROM Period WHERE Type = 'Year' AND StartDate <= TODAY AND EndDate >= TODAY].FiscalYearSettings.Name;

        // bulkify the processing 

        for (Swarm_Waypoint__c wpt : waypointList) {

            //get the old value to make sure it does not run recursively
            Swarm_Waypoint__c oldwpt;
            if (oldMap != null)
            oldwpt = oldMap.get(wpt.id);
            else
            oldwpt = null;

            System.Debug('SwarmZoneList: ' + wpt.zone__c);

            // compare and fire when the zone is updated
            if (oldwpt == null || oldwpt.zone__c != wpt.zone__c) {

                //define the value of the zone based on the selected zone and the current zone, this will only fire when the zone includes the name of the queue
                SwarmZone = wpt.Fiscal_Year__c + ' ' + wpt.Swarm_Territory__r.Territory_Code__c + ' ' + wpt.Zone__c;

                if (Test.isRunningTest())
                SwarmZone = 'FY19' + ' ' + 'Test' + ' ' + wpt.Zone__c;

                System.debug('SwarmZone: ' + SwarmZone);
                System.debug(sZoneByName);
                System.Debug('SwarmZoneList: ' + sZoneByName.get(SwarmZone));

                if (sZoneByName.get(SwarmZone) != null) {
                    wpt.Swarm_Zone__c = String.valueOf(sZoneByName.get(SwarmZone).Id);
                    wpt.Swarm_Zone_Team__c = null;
                    wpt.Target_Call_Date__c = null;
                    wpt.Look_Forward_Date__c = null;
                    wpt.Optimal_Date__c = null;
                    wpt.Optimal_Time__c = null;
                    wpt.Optimal_Date_Time__c = null;
                }
                waypointUpdate.add(wpt);
            }
        }
        update waypointUpdate;
    }

    /*------------------------------------------------------------
      Author:         Mani Sundaresan
      Company:        Hologic
      Description:    Updates the waypoint count on Zone when a waypoint is created, reassigned or deleted.
      Runs after insert, after update, after delete
      Inputs:         Swarm_Waypoints - The list of Swarm Waypoints
      Returns:        N/A
     
      History:
      <Date>          <Authors Name>      <Brief Description of Change>
      11/28/2018      Mani Sundaresan        Initial Creation ()
      ------------------------------------------------------------*/
    public static void updateWaypointCount(List<Swarm_Waypoint__c> waypoint, Map<Id, Swarm_Waypoint__c> oldMap) {

        Set<Id> zoneIdSet = new Set<Id> ();
        List<Swarm_Zone__c> zoneList = new List<Swarm_Zone__c> ();
        List<Swarm_Zone__c> finalZoneList = new List<Swarm_Zone__c> ();

        if (waypoint != null) {
            for (Swarm_Waypoint__c swp : waypoint) {
                if(oldMap == null && swp.Swarm_Zone__c != null)
                    zoneIdSet.add(swp.Swarm_Zone__c);
                else if (oldMap != null && swp.Swarm_Zone__c != oldMap.get(swp.Id).Swarm_Zone__c && swp.Swarm_Zone__c != null) {
                    zoneIdSet.add(oldMap.get(swp.id).Swarm_Zone__c);
                }
            }
        }
        else if (oldMap != null)
            for (Swarm_Waypoint__c swp : oldMap.values())
                zoneIdSet.add(oldMap.get(swp.id).Swarm_Zone__c);

        System.debug('zoneIdSet:' + zoneIdSet);
        if (zoneIdSet.size() > 0)
        zoneList = [SELECT Id, Num_of_Waypoints__c, (SELECT Id from Swarm_Waypoints__r) from Swarm_Zone__c where Id IN :zoneIdSet];

        if (zoneList.size() > 0)
        for (Swarm_Zone__c swz : zoneList) {
            if (swz.getSObjects('Swarm_Waypoints__r') != null) {
                swz.Num_of_Waypoints__c = swz.getSObjects('Swarm_Waypoints__r').size();
            }
            else
            swz.Num_of_Waypoints__c = 0;
        }

        System.debug('zoneList:' + zoneList);

        if (zoneList.size() > 0)
        update zoneList;
    }

    /*------------------------------------------------------------
      Author:         Mani Sundaresan
      Company:        Hologic
      Description:    Updates the waypoint lead details when a waypoint is created, updated, deleted.
      Runs after insert, after update, after delete
      Inputs:         Swarm_Waypoints - The list of Swarm Waypoints
      Returns:        N/A
     
      History:
      <Date>          <Authors Name>      <Brief Description of Change>
      03/14/2019      Mani Sundaresan        Initial Creation ()
      ------------------------------------------------------------*/
    public static void updateWaypointDetails(List<Swarm_Waypoint__c> waypoint, Map<Id, Swarm_Waypoint__c> oldMap) {

        //Variable Declaration
        List<Contact> updateContactList = new List<Contact> ();
        List<Lead> updateLeadList = new List<Lead> ();
        Swarm_Waypoint__c oldSW = new Swarm_Waypoint__c();

        if (waypoint != null) {
            for (Swarm_Waypoint__c sw : waypoint) {
                if (oldMap != null)
                oldSW = oldMap.get(sw.Id);

                if (sw.Contact__c != null && (oldMap == null || (oldMap != null && (sw.Contact__c != oldSW.Contact__c || (sw.Do_Not_Call__c != oldSW.Do_Not_Call__c) || (sw.Phone__c != oldSW.Phone__c))))) {
                    Contact swContact = new Contact(Id = sw.Contact__c, Swarm_Waypoint__c = sw.Id, DoNotCall = sw.Do_Not_Call__c, Phone = sw.Phone__c);
                    
                    updateContactList.add(swContact);
                }

                if (sw.Lead__c != null && (oldMap == null || (oldMap != null && (sw.Lead__c != oldSW.Lead__c || sw.OwnerId != oldSW.OwnerId || ((sw.Status__c != oldSW.Status__c) && sw.Status__c != 'Open') || (sw.Do_Not_Call__c != oldSW.Do_Not_Call__c) || (sw.Phone__c != oldSW.Phone__c))))) {
                    Lead swLead = new Lead(Id = sw.Lead__c, Swarm_Waypoint__c = sw.Id, OwnerId = sw.OwnerId, DoNotCall = sw.Do_Not_Call__c, Phone = sw.Phone__c);
                    if (sw.Status__c == 'Not Ready / Interested') {
                        swLead.Status = 'Project Phoenix';
                        swLead.Project_Phoenix_Reason__c = sw.Status_Reason__c;
                    }
                    else {
                        swLead.Status = 'Contacted';
                    }
                    updateLeadList.add(swLead);
                }
            }
        }
        else if (waypoint == null && oldMap != null) {
            for (Swarm_Waypoint__c sw : oldMap.values()) {
                if (sw.Lead__c != null) {
                    Lead swLead = new Lead(Id = sw.Lead__c, Swarm_Waypoint__c = null);
                    updateLeadList.add(swLead);
                }
                if (sw.Contact__c != null) {
                    Contact swContact = new Contact(Id = sw.Contact__c, Swarm_Waypoint__c = null);
                    updateContactList.add(swContact);
                }

            }
        }
        if (updateLeadList.size() > 0)
        update updateLeadList;
        if (updateContactList.size() > 0)
        update updateContactList; 
 }
    
}