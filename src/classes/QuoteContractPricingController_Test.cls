@isTest
public class QuoteContractPricingController_Test {

    private static Configuration_Settings__c orgDefaults;


    static testmethod void testQuoteContractPricing() {

        orgDefaults = TestUtility.setupConfigurationSettings();

        //Creating Test Data
        Account acc = TestUtility.newAccount('Test Account', '12345');
        insert acc;

        Opportunity opp = TestUtility.newOpportunity('Test Opportunity', acc.Id, System.Today(), 'Target', 'Omitted');
        insert opp;

        Product2 testProd = TestUtility.newProduct('Test Product');
        insert testProd;

        SBQQ__Quote__c testQuote = TestUtility.newQuote(acc.Id, opp.Id);
        
        insert testQuote;

        testQuote.SBQQ__Primary__c = false;
        update testQuote;
        
        SBQQ__Quote__c sq=[select id,name from SBQQ__Quote__c where id=: testQuote.Id];
        List<SBQQ__QuoteLine__c> testQuoteLine = new List<SBQQ__QuoteLine__c> ();
        set<SBQQ__QuoteLine__c> quoteLineset = new set<SBQQ__QuoteLine__c> ();
        for (Integer i = 0; i< 10; i++)
        quoteLineset.add(TestUtility.newQuoteLine(testQuote.Id, testProd.Id, 10.0, 1.0));

        testQuoteLine.addall(quoteLineset);
        insert testQuoteLine;

        Contract testContract = new Contract();
        testContract.AccountId = acc.Id;
        testContract.StartDate = Date.today()-20;
       // testContract.EndDate = Date.today()+5;
        testContract.ContractTerm = 12;
        insert testContract;


        List<Customer_Eligible_Contract__c> testCECList = new List<Customer_Eligible_Contract__c> ();
        for (Integer i = 0; i< 3; i++) {
            Customer_Eligible_Contract__c testCEC = new Customer_Eligible_Contract__c();
            testCEC.Customer_Account__c = acc.Id;
            testCEC.Contract__c = testContract.Id;
            testCEC.Precedence_Value__c = i;
            testCEC.Effective_Date__c=system.today()-10;
            testCEC.Expiration_Date__c=system.today()+10;
            testCECList.add(testCEC);
        }
        insert testCECList;

        Agreed_Price__c testAgreedPrice = new Agreed_Price__c();
        testAgreedPrice.Contract__c = testContract.Id;
        testAgreedPrice.Price__c = 25.00;
        testAgreedPrice.Product__c = testProd.Id;
        testAgreedPrice.Start_Date__c = Date.today()-1;
        testAgreedPrice.End_Date__c = Date.today() + 1095;
        insert testAgreedPrice;

        List<Contract_Agreed_Price__c> testCAPList = new List<Contract_Agreed_Price__c> ();
        for (Customer_Eligible_Contract__c cec : testCECList) {
            Contract_Agreed_Price__c testCAP = new Contract_Agreed_Price__c();
            testCAP.Customer_Eligible_Contract__c = cec.Id;
            testCAP.Agreed_Price__c = testAgreedPrice.Id;
            testCAPList.add(testCAP);
        }
        insert testCAPList;

        Test.startTest();

        QuoteContractPricingController thisQCP = new QuoteContractPricingController();
        thisQCP.quoteName = sq.Name;
        thisQCP.getContractAgreedPriceList();
        //System.assert(thisQCP.DefaultContractAgreedPriceList.size()> 0);
        //System.assert(thisQCP.ContractAgreedPriceList.size()> 0);

        Test.stopTest();

    }
}