/*------------------------------------------------------------
  Author:         Ken Taylor
  Company:        Salesforce.com
  Description:    Trigger framework for the Swarm Waypoint object
  Test Class:     SwarmWaypoint_Test
  <EOF>
  History:
  <Date>          <Authors Name>      <Brief Description of Change>
  11/15/2018      Ken Taylor          Initial Creation ()
  11/28/2018      Mani Sundaresan     Added logic to update the waypoint count on Zone
  ------------------------------------------------------------*/
trigger SwarmWaypointTrigger on Swarm_Waypoint__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    private static Boolean isActive = GlobalUtility.isTriggerActive('SwarmWaypointTrigger');

    if (isActive && Trigger.isBefore) {
        if (Trigger.isInsert) { }
        if (Trigger.isUpdate) { }
        if (Trigger.isDelete) { }
        if (Trigger.isUndelete) { }
    }

    if (isActive && Trigger.isAfter) {
        if (Trigger.isInsert) {
            SwarmWaypointTriggerActions.updateSwarmZone((List<Swarm_Waypoint__c>) Trigger.new, Trigger.oldMap);
            SwarmWaypointTriggerActions.updateWaypointCount(Trigger.new, null);
            SwarmWaypointTriggerActions.updateWaypointDetails(Trigger.new, null);

        }
        if (Trigger.isUpdate) {
            SwarmWaypointTriggerActions.updateSwarmZone((List<Swarm_Waypoint__c>) Trigger.new, Trigger.oldMap);
            SwarmWaypointTriggerActions.updateWaypointCount(Trigger.new, Trigger.oldMap);
            if(GlobalUtility.runOnce()){
                SwarmWaypointTriggerActions.updateWaypointDetails(Trigger.new, Trigger.oldMap);
            }
        }
        if (Trigger.isDelete) {
            SwarmWaypointTriggerActions.updateWaypointCount(Trigger.new, Trigger.oldMap);
            SwarmWaypointTriggerActions.updateWaypointDetails(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isUndelete) { }
    }
}