/*------------------------------------------------------------
Author:         Kasmoor Reddy
Company:        Apps Associates
Description:    Test class to validate SBQQ_QuoteTrigger
                Tests Excecuted:
                Testupdateprimaryquote-- verify whether the primary quote is updating on opportunity or not.
                
History:
<Date>          <Authors Name>      <Brief Description of Change>
09/28/2017       Kasmoor Reddy      Initial Creation (US3470)
------------------------------------------------------------*/
@isTest
public class SBQQ_QuoteTrigger_Test {
    private static Configuration_Settings__c orgDefaults;
    static testMethod void Testupdateprimaryquote_V1(){
        orgDefaults = TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        //Creating Test Data
        Account acc = TestUtility.newAccount('Test Account','12345');
        insert acc;
        System.assertEquals('Test Account', acc.Name);
        
        //insert opportunity
        List<Opportunity> lstoppts = new List<Opportunity>();
        Opportunity oppfrst = TestUtility.newOpportunity('Test Opportunity', acc.Id, System.Today(), 'Target', 'Omitted');
        lstoppts.add(oppfrst);
        Opportunity oppscnd = TestUtility.newOpportunity('Test Opportunity1', acc.Id, System.Today(), 'Target', 'Omitted');
        lstoppts.add(oppscnd);
        insert lstoppts;
        System.assertEquals(2, lstoppts.size());
        
        
        //insert quote
        SBQQ__Quote__c testQuote = TestUtility.newQuote(acc.Id, oppfrst.Id);
        testQuote.SBQQ__Primary__c = true;
        insert testQuote;
        System.assertEquals(true, testQuote.SBQQ__Primary__c);
        
        
        testQuote.SBQQ__Opportunity2__c = oppscnd.id;
        update testQuote;
        System.assertnotEquals(null, testQuote.SBQQ__Opportunity2__c);
        System.assertEquals(null, oppfrst.SBQQ__PrimaryQuote__c);
        
        
        testQuote.SBQQ__Opportunity2__c = null;
        update testQuote;
        System.assertEquals(null, testQuote.SBQQ__Opportunity2__c);
        System.assertEquals(null, oppscnd.SBQQ__PrimaryQuote__c);
        
       
                    
    }
    
    
}