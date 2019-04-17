@isTest
private class test_QuoteExtController {
public static contact con;
 public static void CreateData() {
  TestUtility.setupConfigurationSettings();
   TestUtility.insertCustSetting('sitelocTrigger');
     //TestUtility.insertCustSetting('OpportunityTrigger');
  // Create Account(s)
  List < Account > accList = new List < Account > ();
  for (Integer i = 0; i <= 3; i++) {
   String accName = '1234567' + string.valueOf(i);
   accList.add(TestUtility.newAccount(accName, accName));
  }

  Integer k = 0;
  for (Account acc: accList) {
   acc.Oracle_Party_Id__c = String.valueOf(k);
   k++;
  }

  insert accList;
     
  Account custAcc = TestUtility.newAccount('Test Customer Account','');
  custAcc.Type = 'Dealer';   
  insert custAcc;
     
  Con = TestUtility.newContact('Firstname ','Lastname ', custAcc.id);
  con.Phone = '+(999) 999-9999';   
  insert con;   

  //Create Site Locations
  /*List < Site_Location__c > siteList = new List < Site_Location__c > ();
  for (Integer i = 0; i <= 3; i++) {
   String siteName = 'SiteLocation' + string.valueOf(i);
   siteList.add(new Site_Location__c(Name = siteName, Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = accLIst.get(i).id, Active__c = true));
  }

  insert siteList;

  //Create Site Locations inactive
  List < Site_Location__c > siteList1 = new List < Site_Location__c > ();
  for (Integer i = 0; i <= 3; i++) {
   String siteName = 'SiteLocation1' + string.valueOf(i);
   siteList1.add(new Site_Location__c(Name = siteName, Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = accLIst.get(i).id, Active__c = true));
  }

  insert siteList1;*/
  List < Site_Location__c > siteList = new List < Site_Location__c > ();
  Site_Location__c billTo = TestUtility.newSiteLocation('billToSite', accLIst.get(0).id, 'siteName');
  billTo.Bill_To__c = true;
      billTo.Ship_To__c = false;
  billTo.Active__c = false;
  siteList.add(billTo);
  //insert billTo;

  Site_Location__c shipTo = TestUtility.newSiteLocation('shipToSite', accLIst.get(0).id, 'siteName');
  shipTo.Ship_To__c = true;
       shipTo.Deliver_To__c = false;
  shipTo.Active__c = false;
  siteList.add(shipTo);
  //insert shipTo;

  Site_Location__c deliverTo = TestUtility.newSiteLocation('deliverToSite', accLIst.get(0).id, 'siteName');
  deliverTo.Deliver_To__c = true;
  deliverTo.Active__c = false;
  siteList.add(deliverTo);
  insert siteList;

  //Id pricebookId = Test.getStandardPricebookId();
  //Create Products
  List < Product2 > prodList = new List < Product2 > ();
  for (Integer i = 0; i <= 2; i++) {
   String prodName = 'Product ' + string.valueOf(i);
   prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = false));
  }

  insert prodList;

  PriceBook2 priceBook = new PriceBook2();
  pricebook.name = 'Test PriceBook';

  insert pricebook;

  //Create Price Book Entries
  List < PricebookEntry > priceentires = new List < PricebookEntry > ();

  for (Integer i = 0; i <= 2; i++) {
   priceentires.add(new PricebookEntry(Pricebook2Id = pricebook.Id, Product2Id = prodList.get(i).id, UnitPrice = 2000.00, IsActive = true));
  }

  //insert priceentires;

  //Create Contract(s) for each Account
  List < Contract > contractList = new List < Contract > ();
  for (Integer i = 0; i <= 2; i++) {
   String conName = 'Test Contract ' + string.valueOf(i);
   contractList.add(new Contract(StartDate = system.today().addDays(-5), Accountid = accList.get(i).id, Contract_End_Date__c = system.today().addYears(10)));
  }

  insert contractList;

  Trigger_Switch__c ts = new Trigger_Switch__c();
  ts.Name = 'ContractTrigger';
  ts.Active__c = true;

  insert ts;

  //Create Pricing Agreement Lines for each Contract
  List < Agreed_Price__c > agree_price_lines = new List < Agreed_Price__c > ();

  for (Contract con: contractList) {
   for (Integer i = 0; i <= 2; i++) {
    agree_price_lines.add(new Agreed_Price__c(Active__c = true, Contract__c = con.id, Start_Date__c = system.today().addDays(-5), End_Date__c = system.today().addDays(10), Price__c = 2000.00, Product__c = prodList.get(i).id));
   }
   con.Status = 'Activated';
  }

  insert agree_price_lines;

  update contractList;

  //insert agree_price_lines;

  system.debug(agree_price_lines);

  //Create Relationship/Predence for an Account (Custom Agreement Relationship)
  List < Customer_Eligible_Contract__c > eligible = new List < Customer_Eligible_Contract__c > ();
  for (Integer i = 0; i <= 2; i++) {
   eligible.add(new Customer_Eligible_Contract__c(Selected__c = true, Contract__c = contractList.get(i).id, Effective_Date__c = system.today(), Expiration_Date__c = system.today().addYears(1), Customer_Account__c = accList.get(0).id, Precedence_Value__c = i));
  }

  insert eligible;

  List < Customer_Eligible_Contract__c > cecs = new List < Customer_Eligible_Contract__c > ([Select id, Contract__c, Agreement_Active__c, Tier__c from Customer_Eligible_Contract__c]);
  system.debug(cecs);

  Trigger_Switch__c ts1 = new Trigger_Switch__c();
  ts1.Name = 'OpportunityTrigger';
  ts1.Active__c = true;

  insert ts1;

  list < opportunity > testopp = new List < opportunity > ();

  //Create Opp for BSH Sales
  Opportunity newopp = new Opportunity();
  newOpp.AccountId = accList.get(0).id;
  newOpp.Dealer__c = custAcc.id;
  newOpp.StageName = 'Target';
  newOpp.CloseDate = System.today();
  newOpp.Name = 'OppTest';
  newOpp.Pricebook2Id = pricebook.Id;
  newOpp.RecordTypeId = GlobalUtility.getRecordTypeId('Opportunity', 'B_SH_Sales_Open_Opportunity');

  /*insert newOpp;*/
  testopp.add(newopp);

  //Create Opp
  // Surgical 
  Opportunity newOpp1 = new Opportunity();
  newOpp1.AccountId = accList.get(0).id;
  newOpp.Dealer__c = custAcc.id;
  newOpp1.StageName = 'Target';
  newOpp1.CloseDate = System.today();
  newOpp1.Name = 'OppTest';
  newOpp1.Pricebook2Id = pricebook.Id;
  newOpp1.RecordTypeId = GlobalUtility.getRecordTypeId('Opportunity', 'Surgical_Open_Opportunity');


  // insert newOpp1;
  testopp.add(newopp1);

  //Create Opp
  // Service Contract
  Opportunity newOpp2 = new Opportunity();
  newOpp2.AccountId = accList.get(0).id;
  newOpp.Dealer__c = custAcc.id;
  newOpp2.StageName = 'Target';
  newOpp2.CloseDate = System.today();
  newOpp2.Name = 'OppTest';
  newOpp2.Pricebook2Id = pricebook.Id;
  newOpp2.RecordTypeId = GlobalUtility.getRecordTypeId('Opportunity', 'B_SH_Service_Contract_Opportunity');

  //insert newOpp2;
  testopp.add(newopp2);

  //Create Opp
  // Surgical 
  Opportunity newOpp3 = new Opportunity();
  newOpp3.AccountId = accList.get(0).id;
  newOpp.Dealer__c = custAcc.id;
  newOpp3.StageName = 'Target';
  newOpp3.CloseDate = System.today();
  newOpp3.Name = 'OppTest';
  newOpp3.Pricebook2Id = pricebook.Id;
  newOpp3.RecordTypeId = GlobalUtility.getRecordTypeId('Opportunity', 'Medical_Aesthetics_Capital_Sales_Opportunity');


  // insert newOpp3;
  testopp.add(newOpp3);
     
  Opportunity newOpp4 = new Opportunity();
  newOpp4.AccountId = accList.get(0).id;
  newOpp4.Dealer__c = custAcc.id;
  newOpp4.StageName = 'Target';
  newOpp4.CloseDate = System.today();
  newOpp4.Name = 'OppTest';
  newOpp4.Pricebook2Id = pricebook.Id;
  newOpp4.RecordTypeId = GlobalUtility.getRecordTypeId('Opportunity', 'Medical_Aesthetics_Svc_Contract_Opportunity');


  // insert newOpp4;
  testopp.add(newOpp4);

  //insert testopp;
     
     //testopp[3].LPS_Contact__c = con.id;
     //update testopp;
     
  Opportunity newOpp5 = new Opportunity();
  newOpp5.AccountId = accList.get(0).id;
  newOpp5.Dealer__c = custAcc.id;
  newOpp5.StageName = 'Target';
  newOpp5.CloseDate = System.today();
  newOpp5.Name = 'OppTest';
  newOpp5.Pricebook2Id = pricebook.Id;
  newOpp5.Type = 'New Business';   
  newOpp5.RecordTypeId = GlobalUtility.getRecordTypeId('Opportunity', 'Diagnostic_Lab_Open_Opportunity');


  // insert newOpp5;
  testopp.add(newOpp5);

  insert testopp;
     
     testopp[3].LPS_Contact__c = con.id;
     update testopp;


  List < SBQQ__Quote__c > quoteList = new List < SBQQ__Quote__c > ();

  //Create Quote/Quote Lines
  SBQQ__Quote__c q = new SBQQ__Quote__c(Quote_Name__c = 'QuoteExtTest Quote', Order_Type__c = 'DANBURY SYSTEM ORDER', Operating_Unit__c = 'HOLX_US_OU',
   SBQQ__Account__c = accList.get(0).id,
   SBQQ__Opportunity2__c = testOpp[0].id,
   SBQQ__PriceBook__c = pricebook.Id, Bill_To_Account__c = accList.get(1).id, Deliver_To_Account__c = accList.get(2).id, Ship_To_Account__c = accList.get(3).id, FOB__c = null, SBQQ__PaymentTerms__c = null, Payment_Terms_Freight__c = null, Marketing_Program__c = 'Equipment Purchase');
  q.BillTo_Site__c = billTo.Id;
  q.ShipTo_Site__c = shipTo.Id;
  q.DeliverTo_Site__c = deliverTo.Id;
  q.Dealer__c = custAcc.id;   
  // Added this line to fix the validation rule "Surgical_ContractTerm_Req" issue 
  q.SBQQ__SubscriptionTerm__c = 4;
  q.SBQQ__Primary__c = false;
  q.ApprovalStatus__c = 'Executed';   

  quoteList.add(q);

  //Create Quote/Quote Lines 1 
  SBQQ__Quote__c q1 = new SBQQ__Quote__c(Quote_Name__c = 'QuoteExtTest Quote 1', Order_Type__c = 'DANBURY SYSTEM ORDER', Operating_Unit__c = 'HOLX_US_OU', SBQQ__Account__c = accList.get(0).id, SBQQ__Opportunity2__c = newOpp1.id, SBQQ__PriceBook__c = pricebook.Id, Bill_To_Account__c = accList.get(1).id, Deliver_To_Account__c = accList.get(2).id, Ship_To_Account__c = accList.get(3).id, FOB__c = null, SBQQ__PaymentTerms__c = null, Payment_Terms_Freight__c = null, Marketing_Program__c = 'Equipment Purchase',
   BillTo_Site__c = billTo.id, ShipTo_Site__c = shipTo.id,
   DeliverTo_Site__c = deliverTo.id);
   // Added this line to fix the validation rule "Surgical_ContractTerm_Req" issue  
   q1.SBQQ__SubscriptionTerm__c = 4;
     q1.Dealer__c = custAcc.id;
     q1.SBQQ__Primary__c = false;
     q1.Order_Type__c = 'MAR ORDER';
     

  quoteList.add(q1);

  //Create Quote/Quote Lines
  SBQQ__Quote__c q2 = new SBQQ__Quote__c(Quote_Name__c = 'QuoteExtTest Quote 2',
   Order_Type__c = 'DANBURY SYSTEM ORDER',
   Operating_Unit__c = 'HOLX_US_OU',
   SBQQ__Account__c = accList.get(0).id,
   SBQQ__Opportunity2__c = newOpp2.id,
   SBQQ__PriceBook__c = pricebook.Id,
   Bill_To_Account__c = accList[1].id,
   Deliver_To_Account__c = accList[2].id,
   Ship_To_Account__c = accList[3].id,
   FOB__c = null, SBQQ__PaymentTerms__c = null, Payment_Terms_Freight__c = null, Marketing_Program__c = 'Equipment Purchase');
  q2.BillTo_Site__c = billTo.Id;
  q2.ShipTo_Site__c = shipTo.Id;
  q2.DeliverTo_Site__c = deliverTo.Id;
  // Added this line to fix the validation rule "Surgical_ContractTerm_Req" issue   
  q2.SBQQ__SubscriptionTerm__c = 4;
     q2.Dealer__c = custAcc.id;
     q2.SBQQ__Primary__c = false; 
     

  quoteList.add(q2);

  //Create Quote/Quote Lines 1 
  SBQQ__Quote__c q3 = new SBQQ__Quote__c(Quote_Name__c = 'QuoteExtTest Quote 3', Order_Type__c = 'MAR ORDER', Operating_Unit__c = 'HOLX_US_OU', SBQQ__Account__c = accList.get(0).id, SBQQ__Opportunity2__c = newOpp3.id, SBQQ__PriceBook__c = pricebook.Id, Bill_To_Account__c = accList.get(1).id, Deliver_To_Account__c = accList.get(2).id, Ship_To_Account__c = accList.get(3).id, FOB__c = null, SBQQ__PaymentTerms__c = null, Payment_Terms_Freight__c = null, Marketing_Program__c = 'Equipment Purchase',
   BillTo_Site__c = billTo.id, ShipTo_Site__c = shipTo.id,
   DeliverTo_Site__c = deliverTo.id);
   q3.SBQQ__SubscriptionTerm__c = 4;
     q3.Dealer__c = custAcc.id;
     q3.SBQQ__Primary__c = true; 

  quoteList.add(q3);

     
 //Create Quote/Quote Lines 1 
  SBQQ__Quote__c q4 = new SBQQ__Quote__c(Quote_Name__c = 'QuoteExtTest Quote 4', Order_Type__c = 'MAR ORDER', Operating_Unit__c = 'HOLX_US_OU', SBQQ__Account__c = accList.get(0).id, SBQQ__Opportunity2__c = newOpp4.id, SBQQ__PriceBook__c = pricebook.Id, Bill_To_Account__c = accList.get(1).id, Deliver_To_Account__c = accList.get(2).id, Ship_To_Account__c = accList.get(3).id, FOB__c = null, SBQQ__PaymentTerms__c = null, Payment_Terms_Freight__c = null, Marketing_Program__c = 'Equipment Purchase',
   BillTo_Site__c = billTo.id, ShipTo_Site__c = shipTo.id,
   DeliverTo_Site__c = deliverTo.id);
   q4.SBQQ__SubscriptionTerm__c = 4;
     q4.Dealer__c = custAcc.id;
     q4.SBQQ__Primary__c = false; 

  quoteList.add(q4);
  //insert q2;
  SBQQ__Quote__c q5 = new SBQQ__Quote__c(Quote_Name__c = 'QuoteExtTest Quote 5', Order_Type__c = 'MAR ORDER', Operating_Unit__c = 'HOLX_US_OU', SBQQ__Account__c = accList.get(0).id, SBQQ__Opportunity2__c = newOpp5.id, SBQQ__PriceBook__c = pricebook.Id, Bill_To_Account__c = accList.get(1).id, Deliver_To_Account__c = accList.get(2).id, Ship_To_Account__c = accList.get(3).id, FOB__c = null, SBQQ__PaymentTerms__c = null, Payment_Terms_Freight__c = null, Marketing_Program__c = 'Equipment Purchase',
   BillTo_Site__c = billTo.id, ShipTo_Site__c = shipTo.id,
   DeliverTo_Site__c = deliverTo.id);
   q5.SBQQ__SubscriptionTerm__c = 4;
     q5.Dealer__c = custAcc.id;
     q5.SBQQ__Primary__c = false; 

  quoteList.add(q5);
  //insert q1;

  insert quoteList;
    //quoteList[3].SBQQ__Primary__c = false;
     //update quoteList;

  List < SBQQ__QuoteLine__c > quoteLines = new List < SBQQ__QuoteLine__c > ();
     Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();

  for (Integer i = 0; i <= 2; i++) {
   quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, Account__c = accList.get(0).id, Include_In_Order__c = true,
    SBQQ__Product__c = prodList.get(i).Id, SBQQ__ListPrice__c = 100,
    SBQQ__Quantity__c = 1,
    SBQQ__Optional__c = false,
    Bill_To_Account__c = accList.get(1).id,
    Deliver_To_Account__c = accList.get(2).id,
    Ship_To_Account__c = accList.get(3).id,Tier__c = 1));
  }

  //insert quoteLines;
  quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }

  /* Create Payment Schedule */
  List < Payment_Schedule__c > paymentschedule = new List < Payment_Schedule__c > ();

  for (Integer i = 0; i <= 2; i++) {
   paymentschedule.add(new Payment_Schedule__c(Quote__c = q.id, Payment_Total__c = 999999999, Payment_Amount__c = 0, Payment_Start_Date__c = system.today()));
  }

  insert paymentschedule;
  system.debug(paymentschedule);

  quoteLines = [Select id, SBQQ__Product__c, SBQQ__ListPrice__c, SBQQ__OriginalPrice__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = : quoteList[0].id];
  system.debug(quoteLines);

  List < SBQQ__QuoteLine__c > quoteLines1 = new List < SBQQ__QuoteLine__c > ();

  for (Integer i = 0; i <= 2; i++) {
   quoteLines1.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[1].Id, Account__c = accList.get(0).id, Include_In_Order__c = true, Tier__c = 2,
    SBQQ__Product__c = prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c = 1, Bill_To_Account__c = accList.get(1).id, Deliver_To_Account__c = accList.get(2).id, Ship_To_Account__c = accList.get(3).id));
  }

  //insert quoteLines1;
  quotelineMap.putAll(quoteLines1);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }

  List < SBQQ__QuoteLine__c > quoteLines2 = new List < SBQQ__QuoteLine__c > ();

  for (Integer i = 0; i <= 1; i++) {
   quoteLines2.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[2].Id,
    Account__c = accList.get(0).id,
    Include_In_Order__c = true,
    SBQQ__Product__c = prodList.get(i).Id,
    SBQQ__ListPrice__c = 100,
    SBQQ__Quantity__c = 1,
    Bill_To_Account__c = accList.get(1).id,
    Deliver_To_Account__c = accList.get(2).id,
    Ship_To_Account__c = accList.get(3).id,Tier__c = 0));
  }

  //insert quoteLines2;
  quotelineMap.putAll(quoteLines2);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }

 }


 @isTest static void test_method_one() {
  ApexPages.Standardcontroller sc;
  
  Test.startTest(); 
  CreateData();
  
   
  SBQQ__Quote__c thisQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'QuoteExtTest Quote' LIMIT 1];

  thisQuote.Marketing_Program__c = 'Loaner/Evaluation Agreement';
  thisQuote.Loaner_Eval_Period__c = null;
  thisQuote.Shipping_Method_Code__c = null;
  thisQuote.FOB__c = null;
  thisQuote.Payment_Terms_Freight__c = ' ';
  //thisQuote.ApprovalStatus__c = 'Executed';   
  //Test.startTest(); 
  update thisQuote;
  
  
  ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
  QuoteExtController qecp = new QuoteExtController(stdcontroller);
     
  qecp.validateQuote();
  qecp.backToQuote();
  qecp.onSubmit();
  qecp.QuoteQuery = thisQuote;   
  System.assertEquals(False, qecp.validateQuote());
  system.assertNotEquals(qecp.onRecall(), null);
  system.assertEquals(qecp.onPreview(), null);
  Test.stopTest(); 
 }


@isTest static void test_method_two() {
  ApexPages.Standardcontroller sc;
  Test.StartTest();
  CreateData();

  SBQQ__Quote__c thisQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'QuoteExtTest Quote 1'
   LIMIT 1
  ];

  thisQuote.Marketing_Program__c = 'Loaner/Evaluation Agreement';
  thisQuote.Loaner_Eval_Period__c = null;
  thisQuote.Shipping_Method_Code__c = null;
  thisQuote.FOB__c = null;
  thisQuote.Payment_Terms_Freight__c = null;
  thisQuote.ship_date__c = null;
  thisQuote.Requested_Date__c = null;

  thisQuote.BillTo_Site__c = null;
  thisQuote.ShipTo_Site__c = null;
  thisQuote.Ship_To_Account__c = null;
  thisQuote.Bill_To_Account__c = null;

  //Test.StartTest();
  update thisQuote;

  ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
  QuoteExtController qecp = new QuoteExtController(stdcontroller);
  qecp.validateQuote();
  System.assertEquals(False, qecp.validateQuote());

  /* test for non active bill to */

  Site_Location__c billto = [Select id, Bill_To__c, Ship_To__c, Deliver_To__c, Active__c from Site_Location__c where name = 'billToSite'];
  billto.Active__c = false;
  Billto.bill_to__c = true;
  Billto.ship_to__c = true;
  Billto.Deliver_To__c = true;

  update billto;

  thisQuote.BillTo_Site__c = billto.id;
  thisQuote.ShipTo_Site__c = billto.id;
  thisQuote.DeliverTo_Site__c = billto.id;

  update thisQuote;

  ApexPages.StandardController stdcontroller1 = new ApexPages.StandardController(thisQuote);
  QuoteExtController qecp1 = new QuoteExtController(stdcontroller1);
  qecp1.validateQuote();
  System.assertEquals(False, qecp.validateQuote());

  /* test for active site  and bill to site usage yes 

  billto.Active__c = true;
  Billto.bill_to__c = true;

  update billto;

  ApexPages.StandardController stdcontroller2 = new ApexPages.StandardController(thisQuote);
  QuoteExtController qecp2 = new QuoteExtController(stdcontroller2);
  qecp2.validateQuote();

  /* test for active ship to 

  billto.Active__c = false;
  Billto.ship_to__c = true;

  update billto;

  ApexPages.StandardController stdcontroller3 = new ApexPages.StandardController(thisQuote);
  QuoteExtController qecp3 = new QuoteExtController(stdcontroller3);
  qecp3.validateQuote();
  System.assertEquals(False, qecp.validateQuote());

  /* test for active deliver to to 

  billto.Active__c = false;
  Billto.Deliver_To__c = true;

  update billto;

  ApexPages.StandardController stdcontroller4 = new ApexPages.StandardController(thisQuote);
  QuoteExtController qecp4 = new QuoteExtController(stdcontroller4);
  qecp4.validateQuote();
  //System.assertEquals(False, qecp.validateQuote());

   test for active deliver to to 

  billto.Active__c = false;
  Billto.Ship_To__c = true;

  update billto;

  ApexPages.StandardController stdcontroller5 = new ApexPages.StandardController(thisQuote);
  QuoteExtController qecp5 = new QuoteExtController(stdcontroller5);
  qecp5.validateQuote();

  System.assertEquals(False, qecp.validateQuote());*/

  Test.StopTest();

 }

 @isTest static void test_method_three() {
  ApexPages.Standardcontroller sc;
  Test.StartTest();
  CreateData();

  SBQQ__Quote__c thisQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'QuoteExtTest Quote 2'
   LIMIT 1
  ];

  //thisQuote.Marketing_Program__c = 'None';
  thisQuote.Loaner_Eval_Period__c = null;
  thisQuote.Shipping_Method_Code__c = null;
  thisQuote.FOB__c = null;
  thisQuote.Payment_Terms_Freight__c = null;
  thisQuote.ship_date__c = null;
  thisQuote.Requested_Date__c = null;
  thisQuote.BillTo_Site__c = null;
  thisQuote.ShipTo_Site__c = null;
  thisQuote.Ship_To_Account__c = null;
  thisQuote.Bill_To_Account__c = null;
  thisQuote.Contract_Auto_Assigned__c = false;
  thisQuote.ApprovalStatus__c = 'Executed';   

  //Test.StartTest();
  update thisQuote;
  Test.StopTest();

  ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
  QuoteExtController qecp = new QuoteExtController(stdcontroller);
  qecp.validateQuote();
  qecp.onRecall();
  qecp.onSubmit();

  System.assertEquals(False, qecp.validateQuote());
 }

 @isTest static void test_method_four() {
  ApexPages.Standardcontroller sc;
  CreateData();
  Test.StartTest();
  
  Profile adminProfile = [select id, name from Profile where  name = 'Medical Aesthetics Enablement Admin' LIMIT 1];
        User usr = new User(firstname= 'Test',
                  lastname='XXXX',
                  Alias='Test',
                  email = 'test1234@test.com',
                  username= 'test1234xxx@test.com', 
                  profileId= adminProfile.id, 
                  emailencodingkey='UTF-8',
                  languagelocalekey='en_US',
                  localesidkey='en_US',
                  Operating_Unit__c = 'HOLX_US_OU',          
                  timezonesidkey='America/Los_Angeles');
        insert usr;

  

  System.runAs(usr) {

    

    SBQQ__Quote__c thisQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'QuoteExtTest Quote 3'
     LIMIT 1
    ];

    thisQuote.Marketing_Program__c = 'None';
    thisQuote.Loaner_Eval_Period__c = null;
    thisQuote.Shipping_Method_Code__c = null;
    thisQuote.FOB__c = null;
    thisQuote.Payment_Terms_Freight__c = null;
    thisQuote.ship_date__c = null;
    thisQuote.Requested_Date__c = null;
    thisQuote.BillTo_Site__c = null;
    thisQuote.ShipTo_Site__c = null;
    thisQuote.Ship_To_Account__c = null;
    thisQuote.Bill_To_Account__c = null;

    //Test.StartTest();
    
  
  update thisQuote;
  Test.StopTest();

  ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
  QuoteExtController qecp = new QuoteExtController(stdcontroller);
  qecp.validateQuote();

  System.assertEquals(False, qecp.validateQuote());

  }
 }
/*@isTest static void test_method_five() {
    
  ApexPages.Standardcontroller sc;
  Test.StartTest();
  CreateData();

  SBQQ__Quote__c thisQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'QuoteExtTest Quote 4'
   LIMIT 1
  ];
  thisQuote.Marketing_Program__c = 'Loaner/Evaluation Agreement';
  thisQuote.Loaner_Eval_Period__c = null;
  thisQuote.Shipping_Method_Code__c = null;
  thisQuote.FOB__c = null;
  thisQuote.Payment_Terms_Freight__c = null;
  thisQuote.ship_date__c = null;
  thisQuote.Requested_Date__c = null;

  thisQuote.BillTo_Site__c = null;
  thisQuote.ShipTo_Site__c = null;
  thisQuote.Ship_To_Account__c = null;
  thisQuote.Bill_To_Account__c = null;

  Test.StartTest();
  update thisQuote;

  ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
  QuoteExtController qecp = new QuoteExtController(stdcontroller);
  qecp.validateQuote();
  System.assertEquals(False, qecp.validateQuote());

 

  Site_Location__c billto = [Select id, Bill_To__c, Ship_To__c, Deliver_To__c, Active__c from Site_Location__c where name = 'billToSite'];
  billto.Active__c = false;
  Billto.bill_to__c = true;
  Billto.ship_to__c = true;
  Billto.Deliver_To__c = true;

  update billto;

  thisQuote.BillTo_Site__c = billto.id;
  thisQuote.ShipTo_Site__c = billto.id;
  thisQuote.DeliverTo_Site__c = billto.id;

  update thisQuote;

  ApexPages.StandardController stdcontroller1 = new ApexPages.StandardController(thisQuote);
  QuoteExtController qecp1 = new QuoteExtController(stdcontroller1);
  qecp1.validateQuote();
  System.assertEquals(False, qecp1.validateQuote());
  qecp1.onSubmit();
  qecp1.backToQuote();  
  Test.StopTest();
  
    
 }*/
 
    @isTest static void test_method_six() {
  ApexPages.Standardcontroller sc;
  Test.StartTest();
  CreateData();

  SBQQ__Quote__c thisQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'QuoteExtTest Quote 5'
   LIMIT 1
  ];

  thisQuote.GMC_Approval_Level__c  = null;
  thisQuote.SBQQ__Notes__c   = null;
   thisQuote.Auto_Contract_Agreed_Price_Discounted__c    = true;     
  /*thisQuote.Shipping_Method_Code__c = null;
  thisQuote.FOB__c = null;
  thisQuote.Payment_Terms_Freight__c = null;
  thisQuote.ship_date__c = null;
  thisQuote.Requested_Date__c = null;
  thisQuote.BillTo_Site__c = null;
  thisQuote.ShipTo_Site__c = null;
  thisQuote.Ship_To_Account__c = null;
  thisQuote.Bill_To_Account__c = null;*/

  //Test.StartTest();
  update thisQuote;
  Test.StopTest();

  ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
  QuoteExtController qecp = new QuoteExtController(stdcontroller);
  qecp.validateQuote();
        qecp.backToQuote();
  qecp.onSubmit();
  qecp.QuoteQuery = thisQuote;  

  System.assertEquals(False, qecp.validateQuote());
  
 }
 @isTest static void test_method_no_lines() {
  ApexPages.Standardcontroller sc;
  
  //Test.startTest(); 
  //CreateData();
  
  TestUtility.setupConfigurationSettings();
  TestUtility.insertCustSetting('sitelocTrigger');
  // Create Account(s)
  List < Account > accList = new List < Account > ();
  for (Integer i = 0; i <= 3; i++) {
   String accName = '1234567' + string.valueOf(i);
   accList.add(TestUtility.newAccount(accName, accName));
  }

  Integer k = 0;
  for (Account acc: accList) {
   acc.Oracle_Party_Id__c = String.valueOf(k);
   k++;
  }

  insert accList;
  
  PriceBook2 priceBook = new PriceBook2();
  pricebook.name = 'Test PriceBook';

  insert pricebook;

  //list < opportunity > testopp = new List < opportunity > ();

  //Create Opp for BSH Sales
  Opportunity newopp = new Opportunity();
  newOpp.AccountId = accList.get(0).id;
  newOpp.StageName = 'Target';
  newOpp.CloseDate = System.today();
  newOpp.Name = 'OppTest';
  newOpp.Pricebook2Id = pricebook.Id;
  newOpp.RecordTypeId = GlobalUtility.getRecordTypeId('Opportunity', 'Diagnostic_Open_Opportunity');

  insert newOpp;
  //testopp.add(newopp);
  Test.startTest();
  Site_Location__c billTo = TestUtility.newSiteLocation('billToSite', accLIst.get(0).id, 'siteName');
  billTo.Bill_To__c = true;
  billTo.Active__c = false;

  insert billTo;

  Site_Location__c shipTo = TestUtility.newSiteLocation('shipToSite', accLIst.get(0).id, 'siteName');
  shipTo.Ship_To__c = true;
  shipTo.Active__c = false;

  insert shipTo;

  Site_Location__c deliverTo = TestUtility.newSiteLocation('deliverToSite', accLIst.get(0).id, 'siteName');
  deliverTo.Deliver_To__c = true;
  deliverTo.Active__c = false;

  insert deliverTo;

  SBQQ__Quote__c q = new SBQQ__Quote__c(Quote_Name__c = 'QuoteExtTest Quote 1', Order_Type__c = 'DANBURY SYSTEM ORDER', Operating_Unit__c = 'HOLX_US_OU', SBQQ__Account__c = accList.get(0).id, SBQQ__Opportunity2__c = newOpp.id, SBQQ__PriceBook__c = pricebook.Id, Bill_To_Account__c = accList.get(1).id, Deliver_To_Account__c = accList.get(2).id, Ship_To_Account__c = accList.get(3).id, FOB__c = null, SBQQ__PaymentTerms__c = null, Payment_Terms_Freight__c = null, Marketing_Program__c = 'Equipment Purchase',
  BillTo_Site__c = billTo.id, ShipTo_Site__c = shipTo.id,
  DeliverTo_Site__c = deliverTo.id);

  
  insert q;

  billTo.Bill_To__c = false;

  update billTo;

  shipTo.Ship_To__c = false;

  update shipTo;

  deliverTo.Deliver_To__c = false;

  update deliverTo;
   //Test.startTest();
  ApexPages.StandardController stdcontroller = new ApexPages.StandardController(q);
  QuoteExtController qecp = new QuoteExtController(stdcontroller);
     
  qecp.validateQuote();
  qecp.backToQuote();
  qecp.onSubmit();
  System.assertEquals(False, qecp.validateQuote());
  //system.assertNotEquals(qecp.onRecall(), null);
  system.assertEquals(qecp.onPreview(), null);
  Test.stopTest();
 }   
}