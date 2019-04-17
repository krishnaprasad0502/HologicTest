@isTest
public class Test_ContractAgreedPrice {

    @testSetup public static void testSetup() {
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('AgreedPriceTrigger');
        TestUtility.insertCustSetting('ContractTrigger');
        TestUtility.insertCustSetting('CustomerEligibleContractTrigger');
        QuoteContractPricingSetup__c qcp = new QuoteContractPricingSetup__c();
        qcp.Name = 'BSH_Items__c';
        qcp.Active__c = true;
        insert qcp;

        Account acc1 = TestUtility.newAccount('Account1', 'Account1');
        Account acc2 = TestUtility.newAccount('Account2', 'Account2');
        insert acc1;
        insert acc2;

        // Creating Contract1
        Contract c1 = new Contract();
        c1.AccountId = acc1.Id;
        c1.Contract_End_Date__c = Date.Today().addDays(- 1);
        c1.Automatic_Renewal__c = False;
        c1.Contract_Source__c = 'TestSource';
        c1.Agreed_Price_Groups_Exist__c = true;
        c1.number_of_times_Auto_Renewed__c = 2;
        insert c1;

        //Inserting CEC for the Contract C1
        Customer_Eligible_Contract__c cec1 = new Customer_Eligible_Contract__c();
        cec1.Customer_Account__c = acc1.Id;
        cec1.Precedence_Value__c = 1;
        cec1.Selected__c = true;
        cec1.Contract_Activated__c = true;
        cec1.Contract__c = c1.Id;
        insert cec1;

        //Inserting Agreed Pricing for the Contract C1
        Agreed_Price__c ap1 = new Agreed_Price__c();
        ap1.Contract__c = c1.id;
        ap1.Price__c = 23;
        ap1.Active__c = true;
        insert ap1;

        // Creating Contract2        
        Contract c2 = new Contract();
        c2.AccountId = acc2.Id;
        c2.Contract_End_Date__c = Date.Today().addDays(- 1);
        c2.Automatic_Renewal__c = False;
        c2.Contract_Source__c = 'TestSource';
        c2.Agreed_Price_Groups_Exist__c = true;
        c2.number_of_times_Auto_Renewed__c = 2;
        insert c2;
    }

    @isTest public static void testContract() {
        List<Contract> conList = new List<Contract> ();
        Contract con1 = [select Id, Status from Contract where Account.Name = 'Account1'];
        Contract con2 = [select Id, Status from Contract where Account.Name = 'Account2'];
        con1.Status = 'Activated';
        con2.Status = 'Expired';
        conList.add(con1);
        conList.add(con2);

        Test.startTest();
        update conList;
        Test.stopTest();

    }

    @isTest public static void testCECUpdate() {

        List<Customer_Eligible_Contract__c> cecList = [select Id, Selected__c, Contract__c from Customer_Eligible_Contract__c];
        System.debug('cecList: ' + cecList[0]);
        cecList[0].Selected__c = false;

        Test.startTest();
        update cecList[0];
        Test.stopTest();
    }

    @isTest public static void testAPUpdate() {

        List<Agreed_Price__c> apList = [select Id, Active__c, Contract__c, Contract__r.BSH_Items__c from Agreed_Price__c];
        System.debug('apList: ' + apList[0]);
        apList[0].Active__c = false;

        Test.startTest();
        update apList[0];
        Test.stopTest();
    }

    @isTest public static void testCECInsert() {

        List<Customer_Eligible_Contract__c> cecList = [select Id, Customer_Account__c, Precedence_Value__c, Selected__c, Contract__c, Contract_Activated__c
                                                       from Customer_Eligible_Contract__c];
        Customer_Eligible_Contract__c cecInsert = new Customer_Eligible_Contract__c();
        cecInsert = cecList[0].clone();

        Test.startTest();
        insert cecInsert;
        Test.stopTest();
    }

    @isTest public static void testAPInsert() {

        List<Agreed_Price__c> apList = [select Id, Active__c, Price__c, Contract__c, Contract__r.BSH_Items__c
                                        from Agreed_Price__c];

        Agreed_Price__c apInsert = new Agreed_Price__c();
        apInsert = apList[0].clone();

        Test.startTest();
        insert apInsert;
        Test.stopTest();
    }
}