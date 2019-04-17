/*******************************************************************************
Author:         KASMOOR REDDY
Company:        APPS ASSOCIATES 
Description:    DisplayApprovalRecordsClass
History:
<Date>          <Authors Name>          <Brief Description of Change>
10/16/2018        KASMOOR REDDY              Initial Creation
*******************************************************************************/
@isTest
public class test_DisplayApprovalRecordsClass {
/*******************************************************************************
Author:         KASMOOR REDDY
Company:        APPS ASSOCIATES 
Description:    Test Method for DisplayApprovalRecordsClass
History:
<Date>          <Authors Name>          <Brief Description of Change>
10/16/2018        KASMOOR REDDY              Initial Creation
*******************************************************************************/
    @isTest
    static void testMethod1()
    {
        //create user
        User testUser = new User();
        List<Profile> userProfile = [SELECT Id FROM profile WHERE Name='Medical Aesthetics Sales User' LIMIT 1];
        testUser = TestUtility.newUser(userProfile[0].Id,'GetTaxIn');
        testUser.Operating_Unit__c = 'HOLX_US_OU';    
        insert testUser;
        system.runAs(testUser)
        {
            //create Account
            List<Account> accList=new List<Account>();
            for(Integer i=0; i<=3; i++){
                String accName='1234567' + string.valueOf(i);
                accList.add(TestUtility.newAccount(accName, accName));
            }
            insert accList;
            System.assertNotEquals(0,accList.size());
            
            //create Pricebook
            PriceBook2 pricebook = new Pricebook2(name='Test Pricebook');
            insert pricebook;
            System.assertEquals('Test Pricebook',pricebook.name);
            
            //Create Opp
            Opportunity newOpp = new Opportunity();
            newOpp.AccountId = accList.get(0).id;
            newOpp.StageName = 'Target';
            newOpp.CloseDate = System.today();
            newOpp.Name = 'OppTest';
            newOpp.Pricebook2Id = pricebook.Id;
            
            insert newOpp;
            System.assertEquals('OppTest',newOpp.Name);
            
            //Create Quote
            SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today());
            insert q;
            
            //Create Approval Records
            List<sbaa__Approval__c> sbaaList=new List<sbaa__Approval__c>();
            
            for(integer i=0;i<10;i++)
            {
                sbaa__Approval__c sba=new sbaa__Approval__c(Quote__c=q.id,sbaa__Status__c='Requested',sbaa__AssignedTo__c=testUser.id,sbaa__ApprovalStep__c=1,sbaa__RecordField__c='record');
                
                sbaaList.add(sba);
            }
            
            insert sbaaList;
            
            //call class methods
            test.startTest();
            //contructor
            DisplayApprovalRecordsClass dp=new DisplayApprovalRecordsClass();
            DisplayApprovalRecordsClass.DisplayApprovalRecords(1);
            DisplayApprovalRecordsClass.DisplayDetailsForOneRecord(sbaaList[0].id);
            test.stopTest();
        }
        
    }
    
}