@isTest
private class test_PaymentScheduleControllers {
    
    @isTest static void test_method_one() {
        TestUtility.setupConfigurationSettings();        
          
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;        
        insert tsop;
        
        Account acct = TestUtility.newAccount('Payment Test Account', '123456789abcde');
        insert acct;

        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prod = new Product2(Name = 'test prod', IsActive = true, Quotable__c = true);
        insert prod;



        //Create Opp
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = acct.id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebookId;
        insert newOpp;

        //Create Quote/Quote Lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(SBQQ__Account__c=acct.id, Tax_Calculated__c =true, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId,SBQQ__StartDate__c=system.today(), SBQQ__EndDate__c=system.today().addMonths(48),SBQQ__SubscriptionTerm__c=48);
        q.Payment_Frequency__c = 'Annual';
        insert q;

        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod.Id ,  SBQQ__ListPrice__c = 100000, SBQQ__Quantity__c=1);
        insert ql;

        // Implement test code
        PageReference pageRef = Page.PaymentSchedule;
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(q);
        CreatePaymentScheduleController cont = new CreatePaymentScheduleController(sta_controller);
        cont.load();
        system.assertEquals(cont.theQuote.SBQQ__TargetCustomerAmount__c,100000);
        system.assertEquals(cont.payments.size(),1);
        system.assertNotEquals(cont.save(),null);
        cont.payments[0].payment.Payment_Total__c = 10000;
        //system.assertEquals(cont.save(), null);
        cont.updateTotals();
        system.assertEquals(cont.theQuote.SBQQ__TargetCustomerAmount__c,10000);
        cont.addPayment();
        system.assertEquals(cont.payments.size(),2);
        cont.save();
        cont.cancel();
        cont.deleteLine();
        cont.index=0;
        cont.deleteLine();
        system.assertEquals(cont.payments.size(),1);
        cont.addPayment();
        cont.load();
        system.assertEquals(cont.payments.size(),2);

        pageRef = Page.PaymentScheduleOutput;
        pageRef.getParameters().put('qid',q.Id);
        Test.setCurrentPage(pageRef);
        PaymentScheduleController psc = new PaymentScheduleController();
        system.assertEquals(psc.payments.size(),2);

         
    }

    @isTest static void test_method_two() {
        TestUtility.setupConfigurationSettings();        
          
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;        
        insert tsop;
        
        Account acct = TestUtility.newAccount('Payment Test Account', '123456789abcde');
        insert acct;

        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prod = new Product2(Name = 'test prod', IsActive = true, Quotable__c = true);
        insert prod;



        //Create Opp
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = acct.id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebookId;
        insert newOpp;

        //Create Quote/Quote Lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(SBQQ__Account__c=acct.id, Tax_Calculated__c =true, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId,SBQQ__StartDate__c=system.today(), SBQQ__EndDate__c=system.today().addMonths(48),SBQQ__SubscriptionTerm__c=48);
        q.Payment_Frequency__c = 'Semi-Annual';
        insert q;

        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod.Id ,  SBQQ__ListPrice__c = 100000, SBQQ__Quantity__c=1);
        insert ql;

        // Implement test code
        PageReference pageRef = Page.PaymentSchedule;
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(q);
        CreatePaymentScheduleController cont = new CreatePaymentScheduleController(sta_controller);
        cont.load();
        system.assertEquals(cont.theQuote.SBQQ__TargetCustomerAmount__c,100000);
        system.assertEquals(cont.payments.size(),1);
        system.assertNotEquals(cont.save(),null);
        cont.payments[0].payment.Payment_Total__c = 10000;
        //system.assertEquals(cont.save(), null);
        cont.updateTotals();
        system.assertEquals(cont.theQuote.SBQQ__TargetCustomerAmount__c,10000);
        cont.addPayment();
        system.assertEquals(cont.payments.size(),2);
        cont.save();
        cont.cancel();
        cont.deleteLine();
        cont.index=0;
        cont.deleteLine();
        system.assertEquals(cont.payments.size(),1);
        cont.addPayment();
        cont.load();
        system.assertEquals(cont.payments.size(),2);

        pageRef = Page.PaymentScheduleOutput;
        pageRef.getParameters().put('qid',q.Id);
        Test.setCurrentPage(pageRef);
        PaymentScheduleController psc = new PaymentScheduleController();
        system.assertEquals(psc.payments.size(),2);

         
    }
    
    
}