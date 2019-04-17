/*----------------------------------------------------------------------------------------------------------------------------------------------
Author:     Gerald Ricciardi
Company:    Apps Associates
Description:  Test class to validate AgreedPricesController controller
        Tests Excecuted:
        
         init - loads the test data and gets agreed prices for the account
               
History:
<Date>      <Authors Name>    <Brief Description of Change>
08/01/2017  Gerald Ricciardi    Initial Creation
-------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest 
public class Test_AgreedPricesController {
    
    static testMethod void init() {
        
        TestUtility.setupConfigurationSettings();
        
        // Create Account(s)
        List < Account > accList = new List < Account > ();
        for (Integer i = 0; i <= 3; i++) {
            String accName = '1234567' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }

        insert accList;
        
        
        //Create Products
        List < Product2 > prodList = new List < Product2 > ();
        for (Integer i = 0; i <= 5; i++) {
            String prodName = 'Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true));
        }
        System.debug('prodList'+prodList.size());
        insert prodList;
        
        PriceBook2 priceBook = new PriceBook2();
        pricebook.name = 'Test PriceBook';
        
        insert pricebook;
        
        //Create Price Book Entries
        List < PricebookEntry > priceentires = new List < PricebookEntry > ();
        
        for (Integer i = 0; i <= 5; i++) {
            priceentires.add(new PricebookEntry(Pricebook2Id = pricebook.Id, Product2Id = prodList.get(i).id, UnitPrice = 2000.00, IsActive = true));
        }
        System.debug('priceentires'+priceentires.size());
        insert priceentires;
        
        //Create Contract(s) for each Account
        List < Contract > contractList = new List < Contract > ();
        for (Integer i = 0; i <= 3; i++) {
            String conName = 'Test Contract ' + string.valueOf(i);
            contractList.add(new Contract(StartDate = system.today().addDays(-5), Accountid = accList.get(i).id, Contract_End_Date__c = system.today().addYears(10)));
        }
        System.debug('contractList'+contractList.size());
        insert contractList;
        
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'ContractTrigger';
        ts.Active__c = true;
        
        insert ts;
        
        //Create Pricing Agreement Lines for each Contract
        List < Agreed_Price__c > agree_price_lines = new List < Agreed_Price__c > ();
        List < Customer_Eligible_Contract__c > eligible = new List < Customer_Eligible_Contract__c > ();
        Integer Count = 0;
        for (Contract con: contractList) {
            
            agree_price_lines.add(new Agreed_Price__c(Active__c = true, Contract__c = con.id, Division__c = 'Surgical', Start_Date__c = system.today().addDays(-5), End_Date__c = system.today().addDays(10), Price__c = 2000.00, Product__c = prodList.get(count).id));
            System.debug('in agreed price loop');
            
            eligible.add(new Customer_Eligible_Contract__c(Selected__c = true, Contract__c = con.id, Effective_Date__c = system.today(), Expiration_Date__c = system.today().addYears(1), Customer_Account__c = accList.get(0).id, Precedence_Value__c = count));
            count++;
            con.Status = 'Activated';
        }
        
        insert agree_price_lines;
        //System.debug('insert agreed price'+agree_price_lines.size());
        
        insert eligible;
        
        update contractList;
        
        update agree_price_lines;
        
        List < Customer_Eligible_Contract__c > cecs = new List < Customer_Eligible_Contract__c > ([Select id, Contract__c, Agreement_Active__c, Tier__c from Customer_Eligible_Contract__c]);
        //system.debug(cecs);
        //system.debug('cecs'+cecs.size());
            
        Test.StartTest(); 
        Account sampleAccount = [SELECT Id, Name FROM Account where Id IN :accList LIMIT 1]; 
        //System.debug('sampleAccountId'+sampleAccount.Id);
        
        List<Agreed_Price__c> agreedPrices = AgreedPricesController.getAgreedPrices(sampleAccount.Id);
        System.assertEquals(4,agreedPrices.size());
        
        Test.StopTest();
        
    }
}