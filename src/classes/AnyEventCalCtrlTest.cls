@isTest(seeAllData=true)
public class AnyEventCalCtrlTest {
    static testMethod void getEventsTest() {
        AnyEventCalCtrl.getEvents('Event', 'Subject', 'StartDateTime', 'EndDateTime', 'Description', 'OwnerId', true);
        //AnyEventCalCtrl.getEvents('Event', 'Subject', 'StartDateTime', 'EndDateTime', 'Description', 'OwnerId', false);
    }
    static testMethod void upsertEventsTest() {
        AnyEventCalCtrl.upsertEvents('{"title":"dasdsad","startDateTime":"2017-04-26T17:00:00-07:00","endDateTime":"2017-04-26T19:00:00-07:00","description":"asdasd"}', 'Event', 'Subject', 'StartDateTime', 'EndDateTime', 'Description', 'OwnerId');
        AnyEventCalCtrl.upsertEvents('{"id":"sadad","title":"dasdsad","startDateTime":"2017-04-26T17:00:00-07:00","endDateTime":"2017-04-26T19:00:00-07:00","description":"asdasd"}', 'Event', 'Subject', 'StartDateTime', 'EndDateTime', 'Description', 'OwnerId');
    }
    static testMethod void deleteEventTest() {
        AnyEventCalCtrl.deleteEvent('00U41000006bFIA', 'Event', 'Subject', 'StartDateTime', 'EndDateTime', 'Description', 'OwnerId');
    }
    static testMethod void crudSecurityTest() {
        AnyEventCalCtrl.isAccessible('Event');
        AnyEventCalCtrl.isAccessible('Event','Subject');
        AnyEventCalCtrl.isCreateable('Event');
        AnyEventCalCtrl.isDeletable('Event');
    }
    static testMethod void getOptimalDate(){
        //TestUtility.insertCustSetting('SwarmWaypointTrigger');
        List<Swarm_Waypoint__c> waypointInserts = new List<Swarm_Waypoint__c>();
        
        //Create Swarm Territory record
        Swarm_Territory__c swarmTerr = new Swarm_Territory__c(Name = 'Test',Territory_Code__c = 'Test');
        insert swarmTerr;
        
        List<Swarm_Zone__c> swarmZoneList = new List<Swarm_Zone__c>();
        for(Integer i=0; i<2; i++){
            Swarm_Zone__c sz = new Swarm_Zone__c(Name='FY19 Test Week 10', Swarm_Territory__c = swarmTerr.id, Start_Call_Date__c = date.today(), Start_Optimal_Date__c = date.today().addYears(1), Zone__c = 'Week 10', Fiscal_Year__c = 'FY19');
            swarmZoneList.add(sz);
        }
        insert swarmZoneList;
        for(Integer i = 0; i < 10; i++){
            Swarm_Waypoint__c swpt = new Swarm_Waypoint__c( Swarm_Zone__c = swarmZoneList[0].Id, Target_Call_Date__c = date.today(), Status__c = 'Open', Look_Forward_Date__c = date.today().addMonths(4), Zone__c= 'Week 10');
            waypointInserts.add(swpt);
        }
        Test.startTest();
        insert waypointInserts;
        AnyEventCalCtrl.getOptimalDate(waypointInserts[0].Id);    
        Test.stopTest();
    }
}