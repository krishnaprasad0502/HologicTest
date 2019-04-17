/*----------------------------------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Test class to validate WaypointAssignment page and waypointAssignment extension controller
        Tests Excecuted:
        
         init - verifies that the test data gets created successfully
        
        
        
 History:
<Date>      <Authors Name>    <Brief Description of Change>
12/04/2018  Mani Sundaresan    Initial Creation
-------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
private class waypointAssignment_Test{
    
    static PageReference pageRef;
    static waypointAssignment wpa;
    static waypointAssignment wpa1;
    static List<Swarm_Zone__c> swarmZoneList = new List<Swarm_Zone__c>();
    static List<Swarm_Waypoint__c> waypointInserts = new List<Swarm_Waypoint__c>();
    static List<User> userList = new List<User>();
    static List<PermissionSetAssignment> permAssList = new List<PermissionSetAssignment>();
    static List<Swarm_Zone_Team__c> swarmTeamList = new List<Swarm_Zone_Team__c>();
    static Swarm_Zone__c sz;
    static Swarm_Zone__c sz1;
    static Swarm_Zone__c sz2;
    
    static{
        TestUtility.insertCustSetting('SwarmWaypointTrigger');
    }
    
    private static void init(){
    
        //User Creation
        Profile p = [SELECT Id FROM Profile WHERE Name='Medical Aesthetics Sales User'];
         
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='TestingUser1@testorg.com');
        
        User u1 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='TestingUser2@testorg.com');
        
        userList.add(u);
        userList.add(u1);
        
        insert userList;
        
        //PermissionSet ps = [SELECT ID From PermissionSet WHERE Name = 'Medical_Aesthetics_Slingshot_User'];
        //for(User us : userList){
           // permAssList.add(new PermissionSetAssignment(AssigneeId = us.id, PermissionSetId = ps.Id));    
        //}
        //insert permAssList;
        
        
        
        //Create Swarm Territory record
        Swarm_Territory__c swarmTerr = new Swarm_Territory__c(Name = 'Test',Territory_Code__c = 'Test');
        insert swarmTerr;
        
        //for(Integer i=0; i<2; i++){
            //Swarm_Zone__c sz = new Swarm_Zone__c(Name='FY19 Test Week 10', Swarm_Territory__c = swarmTerr.id, Start_Call_Date__c = date.today(), Start_Optimal_Date__c = date.today().addYears(1), Zone__c = 'Week 10', Fiscal_Year__c = 'FY19');
            //swarmZoneList.add(sz);
        //}
        //insert swarmZoneList;
        sz = new Swarm_Zone__c(Name='FY19 Test Week 10', Swarm_Territory__c = swarmTerr.id, Start_Call_Date__c = date.today(), Start_Optimal_Date__c = date.today().addYears(1), Zone__c = 'Week 10', Fiscal_Year__c = 'FY19');
        insert sz;
        
        sz1 = new Swarm_Zone__c(Name='FY19 Test Week 11', Swarm_Territory__c = swarmTerr.id, Zone__c = 'Week 10', Fiscal_Year__c = 'FY19'); 
        insert sz1;
        
        for(Integer i=0 ; i<2; i++){
            Swarm_Zone_Team__c szt = new Swarm_Zone_Team__c(User__c = userList[0].Id, Day_Monday__c = 50, Day_Tuesday__c = 50, Day_Wednesday__c = 50, Day_Thursday__c = 50, Day_Friday__c = 50, Swarm_Zone__c = sz.Id);
            swarmTeamList.add(szt);
        }
        insert swarmTeamList;
        
        for(Integer i = 0; i < 10; i++){
            Swarm_Waypoint__c swpt = new Swarm_Waypoint__c( Swarm_Zone__c = sz.Id, Target_Call_Date__c = date.today(), Status__c = 'Open', Look_Forward_Date__c = date.today().addMonths(4), Zone__c= 'Week 10');
            waypointInserts.add(swpt);
        }
        insert waypointInserts;
        
    }
    
    static testMethod void distribute(){
    
        init();
        
        pageRef = Page.WaypointAssignment;
        
        Test.setCurrentPage(pageRef);
        System.currentPageReference().getParameters().put('index', String.valueOf(swarmTeamList.size()));

        
        ApexPages.StandardController con = new ApexPages.StandardController(sz);
        wpa = new waypointAssignment(con);
        
        Test.startTest();
        wpa.addRow();
        wpa.waypointDistribution();
        
        wpa.sztId = swarmTeamList[1].Id;
        wpa.delRow();
        
        Test.stopTest();
    }
    
    static testMethod void validation(){
        init();
        
        pageRef = Page.WaypointAssignment;
        
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController con = new ApexPages.StandardController(sz);
        wpa = new waypointAssignment(con);
        
        Test.startTest();
        wpa.waypointDistribution();
        
        wpa.addRow();
        wpa.waypointDistribution();
        
        ApexPages.StandardController con1 = new ApexPages.StandardController(sz1);
        wpa1 = new waypointAssignment(con1);
        
        wpa1.waypointDistribution();
        
        wpa1.addRow();
        wpa1.waypointDistribution();
        
        waypointInserts.clear();
        for(Integer i = 0; i < 10; i++){
            Swarm_Waypoint__c swpt = new Swarm_Waypoint__c( Swarm_Zone__c = sz1.Id, Target_Call_Date__c = date.today(), Status__c = 'Open', Look_Forward_Date__c = date.today().addMonths(4), Zone__c= 'Week 10');
            waypointInserts.add(swpt);
        }
        insert waypointInserts;
        
        ApexPages.StandardController con2 = new ApexPages.StandardController(sz1);
        wpa1 = new waypointAssignment(con2);
        
        wpa1.addRow();
        wpa1.szt[0].Day_Monday__c = 100;
        wpa1.szt[0].Day_Tuesday__c = 100; 
        wpa1.szt[0].Day_Wednesday__c = 100;
        wpa1.szt[0].Day_Thursday__c = 100;
        wpa1.szt[0].Day_Friday__c = 100;
        
        wpa1.waypointDistribution();
        
        
        Test.stopTest();
    }
}