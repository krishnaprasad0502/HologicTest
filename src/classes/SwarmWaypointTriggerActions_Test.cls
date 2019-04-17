/*------------------------------------------------------------
Author:         Ken Taylor
Company:        Hologic, Inc.
Description:    Test class to validate SwarmWaypointTriggerActinos
Tests Excecuted:

insertSwarmWaypoint - verify that on insert of Account, the BillingStreet are parsed out into the custom 1-4 fields
History:
<Date>          <Authors Name>      <Brief Description of Change>
11/28/2018      Ken Taylor          Initial Creation
------------------------------------------------------------*/
@isTest
private class SwarmWaypointTriggerActions_Test {
    
    static testMethod void insertSwarmWaypoint() {
        
        TestUtility.insertCustSetting('SwarmWaypointTrigger');
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
        Test.stopTest();
    }
    
    static testMethod void updateSwarmWaypoint(){
        
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('SwarmWaypointTrigger');
        List<Swarm_Waypoint__c> waypointInserts = new List<Swarm_Waypoint__c>();
        
        //Create Lead Record
        Lead swarmLead = TestUtility.newLead('TestLead', 'Lead1', 'USD', '1111111111', 'Open','');
        insert swarmLead;
        
        //Create Contact Record
        
        Account swarmAcc = TestUtility.newAccount('Test Account', '', '111 test street',null,GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert swarmAcc;
        
        Contact swarmCon = TestUtility.newContact('Test','Contact', swarmAcc.Id);
        insert swarmCon;
        
        
        //Create Swarm Territory record
        Swarm_Territory__c swarmTerr = new Swarm_Territory__c(Name = 'Test',Territory_Code__c = 'Test');
        insert swarmTerr;
        
        List<Swarm_Zone__c> swarmZoneList = new List<Swarm_Zone__c>();
        for(Integer i=0; i<2; i++){
            Swarm_Zone__c sz = new Swarm_Zone__c(Name='FY19 Test Week 10', Swarm_Territory__c = swarmTerr.id, Start_Call_Date__c = date.today(), Start_Optimal_Date__c = date.today().addYears(1), Zone__c = 'Week 10', Fiscal_Year__c = 'FY19');
            swarmZoneList.add(sz);
        }
        insert swarmZoneList;
        for(Integer i = 0; i < 1; i++){
            Swarm_Waypoint__c swpt = new Swarm_Waypoint__c( Swarm_Zone__c = swarmZoneList[0].Id, Target_Call_Date__c = date.today(), Status__c = 'Open', Look_Forward_Date__c = date.today().addMonths(4), Zone__c= 'Week 10', Lead__c=swarmLead.Id, Contact__c=swarmCon.Id);
            waypointInserts.add(swpt);
        }
        Test.startTest();
        insert waypointInserts;
        
        for(Swarm_Waypoint__c swp : [SELECT Id, Do_Not_Call__c, Status__c from Swarm_Waypoint__c where Id IN :waypointInserts]){
            swp.Do_Not_Call__c = true;
            swp.Status__c = 'Not Ready / Interested';
        }
        update waypointInserts;
        Test.stopTest();
        
    }
    
    static testMethod void deleteSwarmWaypoint(){
        
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('SwarmWaypointTrigger');
        
        //Create Lead Record
        Lead swarmLead = TestUtility.newLead('TestLead', 'Lead1', 'USD', '1111111111', 'Open','');
        insert swarmLead;
        
        //Create Contact Record
        
        Account swarmAcc = TestUtility.newAccount('Test Account', '', '111 test street',null,GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert swarmAcc;
        
        Contact swarmCon = TestUtility.newContact('Test','Contact', swarmAcc.Id);
        insert swarmCon;
        
        List<Swarm_Waypoint__c> waypointInserts = new List<Swarm_Waypoint__c>();
        List<Swarm_Waypoint__c> waypointDeletes = new List<Swarm_Waypoint__c>();
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
        Swarm_Waypoint__c swpt = new Swarm_Waypoint__c( Swarm_Zone__c = swarmZoneList[1].Id, Target_Call_Date__c = date.today(), Status__c = 'Open', Look_Forward_Date__c = date.today().addMonths(4), Zone__c= 'Week 10', Lead__c=swarmLead.Id, Contact__c = swarmCon.Id);        
        waypointInserts.add(swpt);
        Test.startTest();
        insert waypointInserts;
        
        for(Integer i=0; i<2; i++)
            waypointDeletes.add(waypointInserts[i]);
        
        waypointDeletes.add(swpt);
        
        delete waypointDeletes;
        
        
        Test.stopTest();    
    }
}