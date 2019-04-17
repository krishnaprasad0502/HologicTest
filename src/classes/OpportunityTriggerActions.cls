/*------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Trigger framework for Opportunity object
Test Class:    Test_OpportunityTrigger

History:
<Date>      <Authors Name>    <Brief Description of Change>
11/04/2016  Mani Sundaresan    Initial Creation
11/28/2016  Mani Sundaresan    Assign Territories based on Oppty Owner (HD-1812) 
5/1/2017    Rich Varga         Add validations from HD-4288  HJD-4025
5/10/2017   Rich Varga         Add addl validations for Quote and  Quote Line bill and ship values HD-4387
5/18/2017   Rich Varga         Add validations for Site_Readiness__c for Dexa and Non Dexa  Products  HD-3360
9/06/2017   Kasmoor Reddy      Added the method to update or insert profile data records(US-3316)
02-10-17    krishna            update Install Involved on opportunity baseed on install case required on quote related product HD - 5074
1-11-18     Rich Varga         update install involved to only be set to True if install case required HD-7999
05/08/2018  Mani Sundaresan    Assign Pricebook and Currency based on Account's country(US-4158)
17/09/2018  KRISHNA             Need remove the check which check the quote lines against the custom setting of QuoteLine validations on Opportunity(US-0004745)    
17/09/2018  KRISHNA             Modify Opportunty Trigger actions  to add check that account record type needs to equals  Customer US-0005589
17-09-2018  Kasmoor Reddy       Modified to check the null pointer condition whether the account is having billing country or not.
01-10-2018  Kasmoor Reddy       Modified to check the opportunitylineitem size for an opportunity as part of US-5520.
01/02/2019  Mani Sundaresan     Added validation logic for Unify Admin (US6422)
01/28/2019  Mani Sundaresan    Update Profile Data with Pipeline Prod details on oppty closure
02/26/2019  Vinay Nallakadi     Added a new validation method to validate Growth Mapping Fields, Method name ValidationForGrowthMappingFields(US-0006699)
------------------------------------------------------------*/
public with sharing class OpportunityTriggerActions{
    public static void validateQuote(List<Opportunity> opptyList){
    
         List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
         /*Rich Varga*/
         /*All quotes BS%H Sales Oppty regradless of Quote Type*/
         /* HD-4387 */
         
         List<SBQQ__Quote__c> allquoteList = new List<SBQQ__Quote__c>();
         List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
         
         /* Rich Varga */
         /* All Quote Lines for All Quotes list*/
         /* HD=4387 */
         
         List<SBQQ__QuoteLine__c> allqlList = new List<SBQQ__QuoteLine__c>();
         
         List<String> quoteTypeList = new List<String>();
         List<String> quoteLineGroupList = new List<String>();
         Set<Id> opptySet = new Set<Id>();
         Map<Id,Integer> qlCountMap = new Map<Id,Integer>();
         Map<Id,Integer> qlnonquote = new Map<Id,Integer>();
         /* Rich Varga */
         Map<Id,Integer> qlnobill    = new Map<Id,Integer>();
        
         
         for(Quote_Validation_on_Opportunity__c qvo : Quote_Validation_on_Opportunity__c.getAll().values())
             quoteTypeList.add(qvo.Quote_Type__c);
         
         for(QuoteLine_validations_on_Opportunity__c qlvo : QuoteLine_validations_on_Opportunity__c.getAll().values())
             quoteLineGroupList.add(qlvo.Quote_Line_Group__c);
         
         for(Opportunity o : opptyList){
             if(o.RecordTypeId == Record_Type_IDs__c.getInstance().Opportunity_B_SH_Sales_Oppty__c && o.StageName == 'Deliver' && o.SBQQ__PrimaryQuote__c != null)
                 opptySet.add(o.Id);
         }
         
         System.debug('opptySet:'+opptySet);
         System.debug('vargasetL'+opptySet.size());
         
             
         /* Rich Varga Apps Associates */
         /* Added Oracle Customer Number from Account on primary quote  */
         /* HD-4288 */
         
         /* Rich Varga Apps Associates */
         /* Add addl ship to and bill to fields from Account for validations */
         /* HD=4387 */
             
         if(opptySet.size() > 0){
             quoteList = [SELECT Id, Quote_Type__c, Bill_To_Account__c, 
             BillTo_Site__c,
             ship_To_Account__c, ShipTo_Site__c,
             SBQQ__Account__r.Oracle_Customer_Number__c,
             BillTo_Site__r.Active__c,BillTo_Site__r.Bill_To__c,
             ShipTo_Site__r.Active__c,ShipTo_Site__r.Ship_To__c,SBQQ__Account__r.RecordTypeId
                           from  SBQQ__Quote__c where SBQQ__Opportunity2__c IN :opptySet AND SBQQ__Primary__c = True AND (Quote_Type__c NOT IN :quoteTypeList)];    
             
             /* Rich Varga Apps Associates */
             /* HD-4387 */
             /* List of all quotes regradless of quote type */
             /* This will be used to validate non quotable */
             
             allquoteList = [SELECT Id, Quote_Type__c, Bill_To_Account__c, 
             BillTo_Site__c,
             ship_To_Account__c, ShipTo_Site__c,
             SBQQ__Account__r.Oracle_Customer_Number__c,
             BillTo_Site__r.Active__c,BillTo_Site__r.Bill_To__c,
             ShipTo_Site__r.Active__c,ShipTo_Site__r.Ship_To__c
                          from  SBQQ__Quote__c where SBQQ__Opportunity2__c IN :opptySet AND SBQQ__Primary__c = True];    
        
        
         }
         
         
        
         
         
         /* Rich Varga Apps Associates */
         /* Add field quotable__c */
         /* HD-4025 */
         // KRISHNA  Need remove the check which check the quote lines against the custom setting of QuoteLine validations on Opportunity(US-0004745) 
         /*if(quoteList.size() > 0){
             qlList = [SELECT Id, Tier__c, SBQQ__Group__c, SBQQ__Group__r.Name, SBQQ__Quote__c, Quotable__c, 
              /* Added Rich Varga Test */
              /* Added bill to and ship to field for validation */
               /* Bill_To_Account__c, BillTo_Site__c, BillTo_Site__r.Active__c,BillTo_Site__r.Bill_To__c,
                Ship_To_Account__c, ShipTo_Site__c, ShipTo_Site__r.Active__c,ShipTo_Site__r.Ship_To__c               
                
             from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteList AND (SBQQ__Group__r.Name NOT IN :quoteLineGroupList)];   
         }*/
         
         
         if(quoteList.size() > 0){
             qlList = [SELECT Id, Tier__c, SBQQ__Group__c, SBQQ__Group__r.Name, SBQQ__Quote__c, Quotable__c, 
              /* Added Rich Varga Test */
              /* Added bill to and ship to field for validation */
                Bill_To_Account__c, BillTo_Site__c, BillTo_Site__r.Active__c,BillTo_Site__r.Bill_To__c,
                Ship_To_Account__c, ShipTo_Site__c, ShipTo_Site__r.Active__c,ShipTo_Site__r.Ship_To__c               
                
             from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteList ];   
         }
         
         /* Rich Varga Apps Assoicates */
         /* This list contains all Quotes regradless of quote type */
         /* This list will be used for checking non quotable lines */
         /* this test will be for all BS&H quotes regardless of quote type */
         /* HD--4387 */
         
         
         if(allquoteList.size() > 0){
             allqlList = [SELECT Id, Tier__c, SBQQ__Group__c, SBQQ__Group__r.Name, SBQQ__Quote__c, Quotable__c, 
              /* Added Rich Varga Test */
              /* Added bill to and ship to field for validation */
                Bill_To_Account__c, BillTo_Site__c, BillTo_Site__r.Active__c,BillTo_Site__r.Bill_To__c,
                Ship_To_Account__c, ShipTo_Site__c, ShipTo_Site__r.Active__c,ShipTo_Site__r.Ship_To__c               
                
             from SBQQ__QuoteLine__c where SBQQ__Quote__c = :allquoteList ];   
         }
         
         
         System.debug('QuoteLine List:'+allqlList);
         
         
          /* Rich Varga Apps Associates */
         /*  Add counter of non quotable lines */
          /* HD-4025 */
         
         
         if(qlList.size() > 0){
             for(SBQQ__Quote__c quote : quoteList){
                 Integer count = 0;
                 /* Rich Varga */
                 Integer nonbill  = 0;
                 for(SBQQ__QuoteLine__c ql : qlList){
                     if(quote.Id == ql.SBQQ__Quote__c)
                         count++;
                     /* Rich Varga Apps Associates */
                     /* HD-4387 */
                     /* Check if Bill to Account is null */
                     /* Check if Bill to Site is null */
                     /* Check if Bill to Site is active */
                     /* Check if Bill to Site usage is active */
                       /* Check if Ship to Account is null */
                     /* Check if Ship to Site is null */
                     /* Check if Ship to Site is active */
                     /* Check if Ship to Site usage is active */
                                          
                     if(quote.Id == ql.SBQQ__Quote__c && ql.Bill_To_Account__c == null)
                        nonbill++;
                     if(quote.Id == ql.SBQQ__Quote__c && ql.BillTo_Site__c == null)
                        nonbill++;
                     if(quote.Id == ql.SBQQ__Quote__c && !ql.BillTo_Site__r.Active__c)
                        nonbill++;
                     if(quote.Id == ql.SBQQ__Quote__c && !ql.BillTo_Site__r.Bill_To__c)
                        nonbill++;
                      if(quote.Id == ql.SBQQ__Quote__c && ql.Ship_To_Account__c == null)
                        nonbill++;
                     if(quote.Id == ql.SBQQ__Quote__c && ql.ShipTo_Site__c == null)
                        nonbill++;
                     if(quote.Id == ql.SBQQ__Quote__c && !ql.ShipTo_Site__r.Active__c)
                        nonbill++;
                     if(quote.Id == ql.SBQQ__Quote__c && !ql.ShipTo_Site__r.Ship_To__c)
                        nonbill++;     
                        
                        
                        
                 }
                 qlCountMap.put(quote.Id,count);
                /* Rich Varga Apps Associates */
                /* HD=4387 */
                
                 qlnobill.put(quote.Id,nonbill);
                 
             }
         }
         
      
           
      /* Rich Varga Apps Associates */
      /* Check the all quote list and lines */
      /* for any lines where Quotable is set to false */
     /* HD-4387 */ 
     
         if(allqlList.size() > 0){
             for(SBQQ__Quote__c quote : allquoteList){
                 Integer nonquotelines = 0;
                              /* Rich Varga */
                 for(SBQQ__QuoteLine__c ql : allqlList){
                    if(quote.Id == ql.SBQQ__Quote__c && ql.Quotable__c != TRUE)
                        nonquotelines++;
                        
                        
                        
                 }
                 /* Rich Varga */
                 qlnonquote.put(quote.id,nonquotelines);
                 
                      
                
                 
             }
         }
      
       
      
      
         System.debug('QuoteLine List:'+qlCountMap);
         System.debug('Nonquote:'+qlnonquote);
         
         
        
       
         
         
         /* Rich Varga Apps Associates */
         /* Add addl check for Bill to Site Active */
         /* Add addl check for Bill to Site Active usage */
         /* Add addl check for Ship to Site Active */
         /* Add addl check for Ship to Site Active usage */
         /* HD-4387 */
         
         
         if( (quoteList.size() > 0 && qlCountMap.size() > 0) ||  (allquotelist.size() > 0 )){
             for(Opportunity opp : opptyList)
             {
                 for(SBQQ__Quote__c quote : quoteList){
                     if(qlCountMap.get(quote.Id) != 0 || qlCountMap.get(quote.Id) != null)
                     {
                         if(quote.Bill_To_Account__c == null || quote.Ship_To_Account__c == null || quote.BillTo_Site__c == null ||  quote.ShipTo_Site__c == null || !quote.BillTo_Site__r.Active__c || !quote.BillTo_Site__r.Bill_To__c  || !quote.ShipTo_Site__r.Active__c || !quote.ShipTo_Site__r.Ship_To__c)
                             opp.addError('Ensure that Bill To Account, Ship To Account, Bill To Site and Ship To Site values are populated and/or active on the Primary Quote prior to Delivery');
                             
           /* Rich Varga Apps  Associates */
           /* HD-4288 */
                            //Modify Opportunty Trigger actions  to add check that account record type needs to equals  Customer US-0005589   
                            //if (quote.SBQQ__Account__r.Oracle_Customer_Number__c == null ||  (quote.SBQQ__Account__r.Oracle_Customer_Number__c == ''  )  )           
                             if (quote.SBQQ__Account__r.Oracle_Customer_Number__c == null ||  (quote.SBQQ__Account__r.Oracle_Customer_Number__c == ''  )  || (quote.SBQQ__Account__r.RecordTypeId  == GlobalUtility.getRecordTypeId('Account', 'Prospect')))     
                              opp.addError('Account on the primary quote does not have an Oracle Customer Number or is a Prospect Account. Contact CDQ through the CDQ Update Request action in the Account Profile');
                                           
                         /* Rich Varga */
         
                        if(qlnobill.get(opp.SBQQ__PrimaryQuote__c) != 0 )
                       opp.addError('Ensure that Bill To Account, Ship To Account, Bill To Site and Ship To Site values are populated and/or active on the all Quote Lines prior to Delivery');         
               
                    
                    
                    
                     }
                                 }
                                 
         /* Rich Varga Apps Associates */
         /*  Added error messagea if non quoteable lines on a quote */
         /* HD-4025 */
         /* Modified for HD-4387 */
         /* This check will be for BS&H opportunities regradless of quote type*/
         
         
            if(qlnonquote.get(opp.SBQQ__PrimaryQuote__c) != 0 )
                       opp.addError('Primary Quote has non quoteable items');
                     
                    
      
                
         }
         
         
        
         
         
         
    }
    }
   
   
   
    
    public static void assignOwnerTerritory(List<Opportunity> opptyList, Map<Id, Opportunity> oldOppty){
    
        Set<Id> ownerIdSet = new Set<Id>();
        Record_Type_IDs__c rtids = Record_Type_IDs__c.getOrgDefaults();
        Id SalesOpenOppty = rtids.Opportunity_B_SH_Sales_Oppty__c;
        Id MammopadOppty = rtids.Opportunity_B_SH_Mammopad_Oppty__c;
        
        List<UserTerritory2Association> userTerrList = new List<UserTerritory2Association>();
        
        for(Opportunity opp : opptyList){
            System.debug('1st condition:'+opp.OwnerId);
            System.debug('3rd condition: '+oldOppty.get(opp.Id).OwnerId);
            System.debug('2nd condition:'+SalesOpenOppty);
            System.debug('4th condition: '+opp.RecordTypeId);
            if(opp.OwnerId != oldOppty.get(opp.Id).OwnerId && (SalesOpenOppty == opp.RecordTypeId || MammopadOppty == opp.RecordTypeId))
                ownerIdSet.add(opp.OwnerId);
        }
        
        if(ownerIdSet.size() > 0)
            userTerrList = [SELECT Territory2Id, UserId from UserTerritory2Association where UserId IN :ownerIdSet AND IsActive = True];
    
        if(userTerrList.size() > 0){
            for(Opportunity opp : opptyList){
                for(UserTerritory2Association ut2a : userTerrList){
                    if(opp.OwnerId == ut2a.UserId)
                        opp.Territory2Id = ut2a.Territory2Id;
                }
            }
        }
        
    
    }
    
    public static void mandatorySiteContact(List<Opportunity> opptyList, Map<Id, Opportunity> oldOppty){
        // instance of the Quote Line object
        //List<SBQQ__QuoteLine__c> quoteList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteListNonDXA = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteListDXA = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteListUnify = new List<SBQQ__QuoteLine__c>();
        List<Id> opptyIdList = new List<Id>();
        
        List<String> dxaProductList = new List<String>();
        List<String> nonDXAProductList = new List<String>();
        List<String> unifyProductList = new List<String>();
        
        
        for(Opportunity__c opp : Opportunity__c.getAll().values()){
            if(opp.Product_Names__c != null)
                dxaProductList.add(opp.Product_Names__c+'%');
            if(opp.Non_DXA_Product_Names__c != null)
                nonDXAProductList.add(opp.Non_DXA_Product_Names__c+'%');
            if(opp.Unify_Products__c != null)
                unifyProductList.add(opp.Unify_Products__c);        
        }
        
        System.debug('dxa:'+dxaProductList);
        System.debug('nonDxa:'+nonDXAProductList);
        System.debug('unifyProdList:'+unifyProductList);
        
        for(Opportunity opp : opptyList){
          //Commented due to code merge from Prod to DEV on 04/25/5018.
         //opp.Install_Involved__c  = false;
            if(opp.StageName != oldOppty.get(opp.Id).StageName && opp.StageName == 'Deliver'){
                opptyIdList.add(opp.Id);
            }
        }
        
        System.debug('opptyIdList:'+opptyIdList);
        
        if(opptyList.size() > 0)
            quoteListNonDXA = [SELECT Id,SBQQ__Product__r.Install_Case_Required__c, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Primary__c, SBQQ__ProductName__c, SBQQ__Quote__r.SBQQ__Opportunity2__c from SBQQ__QuoteLine__c where SBQQ__Quote__r.SBQQ__Opportunity2__c IN :opptyList AND SBQQ__ProductName__c LIKE :nonDXAProductList AND SBQQ__Quote__r.SBQQ__Primary__c = True];
        
        
        System.debug('quoteListnondxa:'+quoteListNonDXA);
         System.debug('quoteListnondxasize:'+quoteListNonDXA.size());
        
        
        if(opptyList.size() > 0 && quoteListNonDXA.size() == 0)
            quoteListDXA = [SELECT Id,SBQQ__Product__r.Install_Case_Required__c,  SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Primary__c, SBQQ__ProductName__c, SBQQ__Quote__r.SBQQ__Opportunity2__c from SBQQ__QuoteLine__c where SBQQ__Quote__r.SBQQ__Opportunity2__c IN :opptyList AND SBQQ__ProductName__c LIKE :dxaProductList AND SBQQ__Quote__r.SBQQ__Primary__c = True];    
            //system.debug('quoteListDXA:'+quoteListDXA');
            System.debug('quoteListDXA:'+quoteListDXA);
         
         if(opptyList.size() > 0 && unifyProductList.size() > 0)
             quoteListUnify = [SELECT Id,SBQQ__Product__r.Install_Case_Required__c,  SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Primary__c, SBQQ__ProductName__c, SBQQ__Quote__r.SBQQ__Opportunity2__c from SBQQ__QuoteLine__c where SBQQ__Quote__r.SBQQ__Opportunity2__c IN :opptyList AND SBQQ__ProductName__c LIKE :unifyProductList AND SBQQ__Quote__r.SBQQ__Primary__c = True];    
         
         /* Rich Varga */
         
        if(quoteListNonDXA.size() > 0){
            for(Opportunity opp : opptyList){
                Boolean isValid = false;
                Boolean isValid2 = false;
                 
                
              
             
                
                
                for(SBQQ__QuoteLine__c quote : quoteListNonDXA)
                {
                    System.debug('Yo yo non dxa');
                    if(opp.StageName != oldOppty.get(opp.Id).StageName && opp.StageName == 'Deliver' && opp.Id == quote.SBQQ__Quote__r.SBQQ__Opportunity2__c
                             && 
                   
                     (opp.Additional_Primary_Contact__c == null || opp.Purchasing_Agent_CFO__c == null || opp.IT_PACS_Administrator__c == null || opp.Mammography_MRI_Manager__c == null))
                     {
                        System.debug('Yo yo2');    
                        isValid = true;
                    }
                    
                    /* Rich Varga  Apps Associates */
                    /* 5-18-17 */
                    /* Added second test for Site Readiness separate for contact check */
                    /* HD-3360*/
                    
                    if(opp.StageName != oldOppty.get(opp.Id).StageName && opp.StageName == 'Deliver' && opp.Id == quote.SBQQ__Quote__r.SBQQ__Opportunity2__c
                             &&  opp.Site_Readiness__c== null )
                     /* Rich Varga */
                    /* 5-18-17 */
                   
                     {
                        System.debug('Yo yo2 site test');    
                        isValid2 = true;
                    }
                    /*krishna  Apps Associates */
                    /* 02-10-17 */
                    /* check install case required or not on quote product */
                    /* HD - 5074*/
                     if( opp.Id == quote.SBQQ__Quote__r.SBQQ__Opportunity2__c && quote.SBQQ__Product__r.Install_Case_Required__c){
                        opp.Install_Involved__c = true;
                    
                    }                         
                
                }
               
                
                if(isValid)
                    opp.addError('Please select Additional/Primary Contact, Purchasing Agent/CFO, IT/PACS Administrator , Mammography/MRI Manager using Site Contacts button');
                    
                    if(isValid2)
                    opp.addError('Please select Site Readiness');
                    
                    
           }
        }
        else if(quoteListDXA.size()>0){
            for(Opportunity opp : opptyList){
                Boolean isValid = false;
                Boolean isvalid2 = false;
               
             
              
              
               
                for(SBQQ__QuoteLine__c quote : quoteListDXA)
                {
                    System.debug('Yo yo dxa');
                    if(opp.StageName != oldOppty.get(opp.Id).StageName && opp.StageName == 'Deliver' && 
                    opp.Id == quote.SBQQ__Quote__r.SBQQ__Opportunity2__c && 
                    (opp.Site_Readiness__c== null || opp.Additional_Primary_Contact__c == null || opp.Purchasing_Agent_CFO__c == null))
                    {
                        System.debug('Yo yo3 dxa');    
                        isValid = true;
                    }
                    
                     /* Rich Varga  Apps Associates */
                    /* 5-18-17 */
                    /* Added second test for Site Readiness separate for contact check */
                    /* HD-3360*/
                    
                    if(opp.StageName != oldOppty.get(opp.Id).StageName && opp.StageName == 'Deliver' && 
                    opp.Id == quote.SBQQ__Quote__r.SBQQ__Opportunity2__c && 
                    opp.Site_Readiness__c== null )
                                        
                    
                    {
                        System.debug('Yo yo3 dxa site');    
                        isValid2= true;
                    }
                     /*krishna  Apps Associates */
                    /* 02-10-17 */
                    /* check install case required or not on quote product */
                    /* HD - 5074*/
                    if( opp.Id == quote.SBQQ__Quote__r.SBQQ__Opportunity2__c && quote.SBQQ__Product__r.Install_Case_Required__c){
                        opp.Install_Involved__c = true;
                    }
                                       
                }
                
                
                if(isValid)
                    opp.addError('Please select Additional/Primary Contact , Purchasing Agent/CFO using Select Site Contacts button');
                
                 if(isValid2)
                    opp.addError('Please select Site Readiness');
                    
            
            }
        
        }
        if(quoteListUnify.size() > 0){
            for(Opportunity opp : opptyList){
                for(SBQQ__QuoteLine__c quote : quoteListUnify)
                {
                    if(opp.StageName != oldOppty.get(opp.Id).StageName && opp.StageName == 'Deliver' && opp.Id == quote.SBQQ__Quote__r.SBQQ__Opportunity2__c && opp.Unifi_Administrator__c == null)
                    {
                        opp.addError('Please add a Unifi Administrator using the Select Site Contacts button');   
                    }
                }
            }
            
        }
    }
    
    /*------------------------------------------------------------
    Author:         krishna prasad
    Company:        Apps Associates
    Description:    Update Install Involved checkbox on Opportunity
    Inputs:         The list of Opportunity to modify
    oldWOLIs:       Map of Opportunity containing old values
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    
    03/08/2018      Krishna     Update Install Involved checkbox on Opportunity (US-0004310) 
    ------------------------------------------------------------*/

    public static void updateInstallInvoved(List<Opportunity> opptyList, Map<Id, Opportunity> oldOppty){
    
    
        //List<String> ProductList = new List<String>();
        List<SBQQ__QuoteLine__c> quoteList = new List<SBQQ__QuoteLine__c>();
        
       //if(ProductList.size() > 0){
            quoteList = [SELECT Id,SBQQ__Product__r.Install_Case_Required__c, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Primary__c, SBQQ__ProductName__c, SBQQ__Quote__r.SBQQ__Opportunity2__c from SBQQ__QuoteLine__c where SBQQ__Quote__r.SBQQ__Opportunity2__c IN :opptyList AND SBQQ__Quote__r.SBQQ__Primary__c = True];
            System.debug('quoteList :::'+quoteList );
            for(Opportunity opp : opptyList){
                 opp.Install_Involved__c = false;
                for(SBQQ__QuoteLine__c quote : quoteList)
                {
                    if( opp.Id == quote.SBQQ__Quote__r.SBQQ__Opportunity2__c && quote.SBQQ__Product__r.Install_Case_Required__c ){
                        opp.Install_Involved__c = true;
                      
                        
                    }
                }
            }
        //}
    }
    /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Method which updates or insert the profile data records based on the 
                 values opportunity assay type and assay test name
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    09/06/2017     Kasmoor Reddy       Initial Creation (US3316)
-----------------------------------------------------------------------------------*/
    public static void UpdateandInsertprofiledata(List<Opportunity> opptyList, Map<Id, Opportunity> oldOppty){
    //Variable declarations
    List<Profile_Data__c> DataProfiles = new List<Profile_Data__c>();
    List<Profile_Data__c> CompDataProfiles = new List<Profile_Data__c>();
    List<Profile_Data__c> AllDataProfiles = new List<Profile_Data__c>();
    List<Profile_Data__c> InsrtupdateDataProfiles = new List<Profile_Data__c>();
    String OppStage;
    String OppoldStage;    
    String OppAssaytype;
    String OppCompAssaytype;
    String OppCompAssaytypename;
    Decimal OppCompAssaytypevolume;
    Decimal Oppvolume;    
    id Oppid;
    id Oppaccountid;
    id Oppaccountsiteid;    
    String OppAssaytestname;    
    id ProfileRecordID = GlobalUtility.getRecordTypeId('Profile_Data__c', 'Profile_Data');
        //assiging all opportunity field values into variables
        for(Opportunity opp : opptyList){
            OppStage = opp.StageName;
            OppAssaytype = opp.Assay_Type__c;
            OppCompAssaytype = opp.Competitive_Assay_Type__c;
            OppCompAssaytypename = opp.Competitive_Assay_Test_Name__c;
            OppCompAssaytypevolume = opp.Remaining_Competitive_Assay_Volume__c;
            Oppid = opp.Id;
            Oppaccountid = opp.AccountId;
            Oppaccountsiteid = opp.Account_Site__c;
            Oppvolume = opp.Assay_Volume__c;
            OppAssaytestname = opp.Assay_Test_Name__c;
            //Enter into loop if old opp value is not null
            if(oldOppty != null){
                Opportunity oldopp = (opportunity)Trigger.oldMap.get(opp.Id);
                OppoldStage = oldopp.StageName;
            }
            
        }
        //Enter into the loop if opportunity staganame is confirm in after insert and update of opportunity
        if(OppStage == 'Confirm' && (OppoldStage != 'Confirm' || OppoldStage == null)){
            //getting all the profile data records related to opportunity account.  
            AllDataProfiles = [Select Id,Assay_Type__c,Opportunity__c,RecordTypeId,Account__c,Assay_Test_Name__c,Volume__c from Profile_Data__c where (Account__c =: Oppaccountsiteid and Assay_Type__c =: OppAssaytype and Assay_Test_Name__c =: OppAssaytestname and RecordTypeId =: ProfileRecordID) OR (Account__c =: Oppaccountsiteid and Assay_Type__c =: OppCompAssaytype and Assay_Test_Name__c =: OppCompAssaytypename and RecordTypeId =: ProfileRecordID)];
            system.debug('AllDataProfiles------'+AllDataProfiles);
            for(Profile_Data__c prodata:AllDataProfiles){
                if(prodata.Assay_Type__c == OppAssaytype && prodata.Assay_Test_Name__c == OppAssaytestname){
                    DataProfiles.add(prodata);
                }
                if(prodata.Assay_Type__c == OppCompAssaytype && prodata.Assay_Test_Name__c == OppCompAssaytypename ){
                    CompDataProfiles.add(prodata);
                }
            }
            //if profiledata list not empty then updating or inserting hologic assay type profile data
            if(DataProfiles.size()>0){
              for(Profile_Data__c pd:DataProfiles){
                  pd.Opportunity__c = Oppid;
                  pd.Frequency__c = 'Weekly';
            if(pd.Volume__c == null) pd.Volume__c = 0;
                  pd.Volume__c += Oppvolume;
                  InsrtupdateDataProfiles.add(pd);
              }
              
          }else{
                    Profile_Data__c AP = new Profile_Data__c();
                    AP.RecordtypeId = ProfileRecordID;
                    AP.Division__c = 'Diagnostics | Physician';
                    AP.Type__c = 'Physician Assay Volume';
                    AP.Assay_Type__c = OppAssaytype;
                    AP.Assay_Test_Name__c = OppAssaytestname;
                    AP.Volume__c = Oppvolume;
                    AP.Account__c = Oppaccountsiteid;
                    AP.Opportunity__c = Oppid;
                    AP.Frequency__c = 'Weekly';
                    InsrtupdateDataProfiles.add(AP);
                    
                    
          }
            //if profiledata list not empty then updating or inserting competetive assay type profile data
            if(CompDataProfiles.size()>0){
                if(OppCompAssaytypevolume == 0){
                    Database.delete(CompDataProfiles);
                }else{
                    for(Profile_Data__c pd1:CompDataProfiles){
                        pd1.Volume__c = OppCompAssaytypevolume;
                        pd1.Opportunity__c = Oppid;
                        pd1.Frequency__c = 'Weekly';
                        InsrtupdateDataProfiles.add(pd1);
                    }
                    
                }
            }else{
                if(OppCompAssaytypevolume > 0){
                          Profile_Data__c AP = new Profile_Data__c();
                            AP.RecordtypeId = ProfileRecordID;
                            AP.Division__c = 'Diagnostics | Physician';
                            AP.Type__c = 'Physician Assay Volume';
                            AP.Assay_Type__c = OppCompAssaytype;
                            AP.Assay_Test_Name__c = OppCompAssaytypename;
                            AP.Volume__c = OppCompAssaytypevolume;
                            AP.Account__c = Oppaccountsiteid;
                            AP.Opportunity__c = Oppid;
                            AP.Frequency__c = 'Weekly';
                            InsrtupdateDataProfiles.add(AP);
                              
                }
                
            }
            //if dataprofile data list is having records to be inserted/updated then enter the loop
            if(InsrtupdateDataProfiles.size()>0){
                 Database.UpsertResult [] lcr = Database.upsert(InsrtupdateDataProfiles,false);
                    for(Integer index = 0; index < lcr.size(); index++){
                        if(!lcr[index].isSuccess() && lcr.size() < index && AllDataProfiles.size() < index){
                            AllDataProfiles[index].addError('Failed to create/update the Profile data records: '+lcr[index].getErrors()[0].getMessage());
                        }
                }
 
                
            }
            
                   
        }
    }
    
    //Method to update account with pb, currency details based on configuration & Custom settings as Account Configuration
    /*public static void updatePricebookdetails(List<Opportunity> opptyList, Map<Id, Opportunity> oldOppty){
        
        if(opptyList == null || opptyList.isEmpty())
        {
            return;
        }
        
        Map<Id, Id> opptyToAccIds = new Map<Id, Id>();
        for(Opportunity oppty : opptyList)
        {
            if(oppty.AccountId != null)
            {
                opptyToAccIds.put(oppty.Id, oppty.AccountId);
            }
        }
        
        List<Id> accIds = opptyToAccIds.values();
        Map<Id, String> idToCountry = new Map<Id, String>();
        for(Account a : [SELECT Id, BillingCountry From Account Where Id IN :accIds])
        {
            if(a.BillingCountry == null) continue;
            idToCountry.put(a.Id, a.BillingCountry);
        }
        
        if(AccountConfiguration__c.getAll() != null)
        {
            Set<String> pbNames = new Set<String>();
            Set<String> recNames = new Set<String>();
            Map<String, String> recNameToPbName = new Map<String, String>();
            Map<String, String> recNameToCurr = new Map<String, String>();
            for (AccountConfiguration__c  item : AccountConfiguration__c.getAll().values()) {
                pbNames.add(item.Pricebook_Name__c);
                recNameToPbName.put(item.Record_Type_Name__c, item.Pricebook_Name__c);    
                recNameToCurr.put(item.Record_Type_Name__c, item.Currency__c );
            }
        
        
            Map<String, Id> pbNameToId = new Map<String, Id>();
            Map<Id, String> recIdToName = new Map<Id, String>();
            for(Pricebook2 pb : [Select Id, Name FROM Pricebook2 where name in :pbNames])
            {
                pbNameToId.put(pb.Name, pb.Id);
            }
            
            if(recNameToPbName.keySet() == null) return;
            for(String recName : recNameToPbName.keySet())
            {
                Id recTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(recName).getRecordTypeId();
                if(recTypeId == null) continue;
                recIdToName.put(recTypeId, recName);
            }
            
            for(Opportunity oppty : opptyList)
            {
                if(oppty.AccountId != null)
                {
                    String country = idToCountry.get(oppty.AccountId);
                    if(country == null || !country.equalsIgnoreCase('Canada')) continue;
                }
                if(oppty.RecordTypeId != null && recIdToName.keySet().contains(oppty.RecordTypeId))
                {
                    String recName = recIdToName.get(oppty.RecordTypeId);
                    String pbName = recNameToPbName.get(recName);
                    oppty.Pricebook2Id = pbNameToId.get(pbName);
                    oppty.CurrencyIsoCode = recNameToCurr.get(recName);
                }
            }
        }
        
    }*/

    /*-----------------------------------------------------------------------------
    Author:      Mani Sundaresan
    Description: Method to update the Pricebook and currency based on Account's country
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    05/08/2018     Mani Sundaresan      Initial Creation (US4158)
    -----------------------------------------------------------------------------------*/
    public static void updatePricebookInfo(List<Opportunity> opptyList, Map<Id, Opportunity> oldOppty){

        //Variable Declaration Section
        List<Id> accountIdList = new List<Id>();
        List<OpportunityLineItem> oppitemlist = new List<OpportunityLineItem>();
        Map<Id, String> accMap = new Map<Id, String>();
        //Get the values from the Account Configuration custom settings
        List<AccountConfiguration__c> accConfig = AccountConfiguration__c.getall().values();
        String pricebook = (Id)Configuration_Settings__c.getOrgDefaults().Sales_Pricebook_USD__c; 
        
        //fetch the account ids related to the oppty
        for(Opportunity opp : opptyList){
            System.debug('oldOppty:'+oldOppty);
            if(opp.AccountId != null)
                accountIdList.add(opp.AccountId);       
        }
        System.debug('AccountIdList:'+accountIdList);
        
        //Query BillingCountry values from accounts
        if(accountIdList.size() > 0)
            for(Account acc : [SELECT Id, BillingCountry from Account where Id IN :accountIdList])  
                accMap.put(acc.Id, acc.BillingCountry);
        
        System.debug('accMap:'+accMap);
        
        Boolean isUSPriceBook = false;

        //Assign Pricebook2Id and Currency on Oppty based on Account Configuration custom setting values
        if(accMap.size() > 0){
            system.debug('Enter if loop');
            for(Opportunity opp : opptyList){
                oppitemlist = [select id,Name from OpportunityLineItem where OpportunityId =: opp.id];
                system.debug('oppitemlist---'+oppitemlist.size());
                
                for(AccountConfiguration__c ac : accConfig){
                system.debug('opp.RecordTypeId:::'+opp.RecordTypeId);
                system.debug('ac.RecordTypeId__c:::'+ac.RecordTypeId__c);
                    system.debug('ac.Country__c:::'+ac.Country__c);
                    //09-17-2018-- Added by Kasmoor Reddy as part of US-5488
                    if(accMap.get(opp.AccountId) != null && accMap.get(opp.AccountId) != ''){
                        if(opp.RecordTypeId == ac.RecordTypeId__c && accMap.get(opp.AccountId).equalsIgnoreCase(ac.Country__c)){
                            system.debug('Enter if loop');
                            opp.Pricebook2Id = ac.PricebookId__c;
                            opp.CurrencyIsoCode = ac.Currency__c;
                            isUSPriceBook = true;
                        
                    }
                  }
                }
                system.debug('isUSPriceBook:::'+isUSPriceBook);
                    if(!isUSPriceBook){
                      //10-01-2018 -- Added if condition by Kasmoor Reddy as part of US-5520  
                       if(oppitemlist.Size() == 0){ 
                            system.debug('enter the if loop');
                            opp.Pricebook2Id = (Id)Configuration_Settings__c.getOrgDefaults().Sales_Pricebook_USD__c; 
                            system.debug('++++ID returned'+opp.Pricebook2Id);
                            opp.currencyIsoCode = 'USD';
                    }    
                
                }  
                System.debug('Opportunity PriceBook Id:'+opp.Pricebook2Id);
                System.debug('Opportunity Currency:'+opp.CurrencyIsoCode);
            
        
       } 
        
    }
    }

    /*-----------------------------------------------------------------------------
    Author:      Mani Sundaresan
    Description: Method to update the Profile Data with Pipeline Product data when the oppty is closed
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    01/28/2019     Mani Sundaresan      Initial Creation ()
    -----------------------------------------------------------------------------------*/
    public static void updateProfileData(List<Opportunity> opptyList, Map<Id, Opportunity> oldOppty){

        Record_Type_IDs__c recordTypeIds = Record_Type_IDs__c.getOrgDefaults();
        ID RECORD_TYPE_ID_INTL_DIAGNOSTIC_SALES = recordTypeIds.Opportunity_Intl_Diagnostics_Sales__c;
        ID RECORD_TYPE_ID_PROFILE_DATA_LAB_LANDSCAPE = recordTypeIds.Profile_Data_Lab_Landscape__c;
        ID RECORD_TYPE_ID_PIPELINE_PROD_INTL_DIAG = recordTypeIds.Pipeline_Prod_Intl_Diagnostics__c;
        Set<Id> opptyIdSet = new Set<Id>();
        Set<Id> pipelineProdSet = new Set<Id>();
        Set<Pipeline_Products__c> pipeProdSet = new Set<Pipeline_Products__c>();
        List<Pipeline_Products__c> pipelineProdList = new List<Pipeline_Products__c>();
        List<Profile_Data__c> profDataList = new List<Profile_Data__c>();
        List<Profile_Data__c> finalProfDataList = new List<Profile_Data__c>();
        List<Pipeline_Products__c> finalPipelineProdList = new List<Pipeline_Products__c>();
        Profile_Data__c pd;
        
        for(Opportunity opp : opptyList){
            Opportunity oldOpp = oldOppty != null && oldOppty.containsKey(opp.Id) ? oldOppty.get(opp.Id) : null;
            if((opp.StageName == 'Closed Won' || opp.StageName == 'Closed Lost') && opp.RecordTypeId == RECORD_TYPE_ID_INTL_DIAGNOSTIC_SALES && opp.StageName != oldOpp.StageName)
                opptyIdSet.add(opp.Id);
        }

        System.debug('opptyIdSet:'+opptyIdSet);

        if(opptyIdSet.size() > 0)
            pipelineProdList = [SELECT Id, Profile_Data__c, Profile__c, RecordTypeId, Volume__c, Price__c, CurrencyIsoCode, Test_Supplier__c, Instrument_Supplier__c, Instrument_Model__c, Opportunity__r.Contract_End_Date__c, Opportunity__r.AccountId, Account_Site__c, Division__c, Opportunity__c  FROM Pipeline_Products__c WHERE Opportunity__c IN :opptyIdSet and RecordTypeId = :RECORD_TYPE_ID_PIPELINE_PROD_INTL_DIAG];
        
        System.debug('pipelineProdList:'+pipelineProdList);

        if(pipelineProdList.size() > 0)
            for(Pipeline_Products__c pp : pipelineProdList){
                if(pp.Profile_Data__c != null){
                    pd = new Profile_Data__c(Division__c = pp.Division__c, Id = pp.Profile_Data__c, Profile__c = pp.Profile__c, Volume__c = pp.Volume__c, Price__c = pp.Price__c, CurrencyIsoCode = pp.CurrencyIsoCode, Test_Supplier__c = pp.Test_Supplier__c, Instrument_Supplier__c = pp.Instrument_Supplier__c, Instrument_Model__c = pp.Instrument_Model__c, Contract_End_Date__c = pp.Opportunity__r.Contract_End_Date__c, Pipeline_Product_Id__c = pp.Id, Opportunity__c = pp.Opportunity__c);
                }
                else if(pp.Profile_Data__c == null){
                    pd = new Profile_Data__c(RecordtypeId = RECORD_TYPE_ID_PROFILE_DATA_LAB_LANDSCAPE, Division__c = pp.Division__c, Profile__c = pp.Profile__c, Volume__c = pp.Volume__c, Price__c = pp.Price__c, CurrencyIsoCode = pp.CurrencyIsoCode, Test_Supplier__c = pp.Test_Supplier__c, Instrument_Supplier__c = pp.Instrument_Supplier__c, Instrument_Model__c = pp.Instrument_Model__c, Contract_End_Date__c = pp.Opportunity__r.Contract_End_Date__c, Account__c = pp.Opportunity__r.AccountId, Account_Site__c = pp.Account_Site__c, Pipeline_Product_Id__c = pp.Id, Opportunity__c = pp.Opportunity__c);
                    pipelineProdSet.add(pp.Id);
                }
                profDataList.add(pd);
            }

        if(profDataList.size() > 0)
            upsert profDataList; 
        
        if(pipelineProdSet.size() > 0)
            finalProfDataList = [SELECT Id, Pipeline_Product_Id__c  from Profile_Data__c where Pipeline_Product_Id__c IN :pipelineProdSet];

       System.debug('finalProfDataList:'+finalProfDataList);
       
       if(finalProfDataList.size() > 0)
            for(Profile_Data__c pd1 : finalProfDataList){
                Pipeline_Products__c pp = new Pipeline_Products__c(Id = pd1.Pipeline_Product_Id__c, Profile_Data__c = pd1.Id);
                pipeProdSet.add(pp);
            }
        
        System.debug('finalPipelineProdList:'+finalPipelineProdList);
        
        finalPipelineProdList = new List<Pipeline_Products__c>();
        
        if(pipeProdSet.size() > 0){
            finalPipelineProdList.addAll(pipeProdSet);
            update finalPipelineProdList;
        }

    }
    
/*
   ==========================================================================================
   Validation for GrowthMapping fields on Opportunity (US-0006699)
   ==========================================================================================
    
   public static void ValidationForGrowthMappingFields(List<Opportunity> opptyList,Map<Id, Opportunity> oldOppty)
{
    //get RecordType Id from Custom Setting
    Record_Type_IDs__c recordTypeIds = Record_Type_IDs__c.getOrgDefaults();
    ID RECORD_TYPE_ID_INTL_BREASTHEALTH_SALES = recordTypeIds.Opportunity_Intl_Breast_Health_Sales__c ;
    ID RECORD_TYPE_ID_INTL_DIAGNOSTICS_SALES = recordTypeIds.Opportunity_Intl_Diagnostics_Sales__c ;
    ID RECORD_TYPE_ID_INTL_MA_SALES = recordTypeIds.Opportunity_Intl_MA_Sales__c ;
    ID RECORD_TYPE_ID_INTL_PERINATAL_SALES = recordTypeIds.Opportunity_Intl_Perinatal_Sales__c ;
    ID RECORD_TYPE_ID_INTL_SURGICAL_SALES = recordTypeIds.Opportunity_Intl_Surgical_Sales__c ;
    //Skip this if Validation Exception custom setting value is not true for the current user profile.
    //Validation_Rule_Exception__c orgDefaults = Validation_Rule_Exception__c.getOrgDefaults();
    system.debug(GlobalUtility.CheckValidationRules('Opportunity_validations__c'));
  if(GlobalUtility.CheckValidationRules('Opportunity_validations__c')){
       return;
    }     
    for(Opportunity opp : opptyList){
        System.debug('oldOppty:'+oldOppty);
        System.debug('opp.recordtypeid:'+opp.recordtypeid);
        if(( opp.recordtypeid==RECORD_TYPE_ID_INTL_DIAGNOSTICS_SALES || opp.recordtypeid==RECORD_TYPE_ID_INTL_PERINATAL_SALES) && ((Opp.Aware_of_Hologic__c =='1' && (Opp.Hologic_personnel_known__c =='1' || Opp.Creditable_player__c =='1' || Opp.Info_shared__c =='1' || Opp.Value_offering_understood__c =='1' ||Opp.Hologic_proactively_supported__c =='1' || Opp.Have_commercial_knowledge__c =='1' || Opp.Tender_specs_fit_Hologic_solutions__c =='1' || Opp.Contract_signed__c =='1' || Opp.Hologic_advocated_externally__c =='1' || Opp.Reference_site__c =='1' || Opp.Contractual_obligations_fulfilled__c =='1' ))|| (Opp.Hologic_personnel_known__c =='1' &&( Opp.Creditable_player__c =='1'  || Opp.Info_shared__c =='1' || Opp.Value_offering_understood__c =='1' || Opp.Hologic_proactively_supported__c =='1' || Opp.Have_commercial_knowledge__c =='1' || Opp.Tender_specs_fit_Hologic_solutions__c =='1' || Opp.Contract_signed__c =='1' ||Opp.Hologic_advocated_externally__c =='1' ||Opp.Reference_site__c =='1' ||Opp.Contractual_obligations_fulfilled__c =='1' ))||(Opp.Creditable_player__c =='1' && (Opp.Info_shared__c =='1' ||Opp.Value_offering_understood__c =='1' ||Opp.Hologic_proactively_supported__c =='1' ||Opp.Have_commercial_knowledge__c =='1' ||Opp.Tender_specs_fit_Hologic_solutions__c =='1' ||Opp.Contract_signed__c =='1' ||Opp.Hologic_advocated_externally__c =='1' ||Opp.Reference_site__c =='1' ||Opp.Contractual_obligations_fulfilled__c =='1') )||(Opp.Info_shared__c =='1' && (Opp.Value_offering_understood__c =='1' ||Opp.Hologic_proactively_supported__c =='1' ||Opp.Have_commercial_knowledge__c =='1' ||Opp.Tender_specs_fit_Hologic_solutions__c =='1' ||Opp.Contract_signed__c =='1' ||Opp.Hologic_advocated_externally__c =='1' ||Opp.Reference_site__c =='1' ||Opp.Contractual_obligations_fulfilled__c =='1')) ||(Opp.Value_offering_understood__c =='1' && (  Opp.Hologic_proactively_supported__c =='1' ||Opp.Have_commercial_knowledge__c =='1' ||Opp.Tender_specs_fit_Hologic_solutions__c =='1' ||Opp.Contract_signed__c =='1' ||Opp.Hologic_advocated_externally__c =='1' ||Opp.Reference_site__c =='1' ||Opp.Contractual_obligations_fulfilled__c =='1')) ||(Opp.Hologic_proactively_supported__c =='1' &&(   Opp.Have_commercial_knowledge__c =='1' ||Opp.Tender_specs_fit_Hologic_solutions__c =='1' ||Opp.Contract_signed__c =='1' ||Opp.Hologic_advocated_externally__c =='1' ||Opp.Reference_site__c =='1' ||Opp.Contractual_obligations_fulfilled__c =='1' ))||(Opp.Have_commercial_knowledge__c =='1' && ( Opp.Tender_specs_fit_Hologic_solutions__c =='1' ||Opp.Contract_signed__c =='1' ||Opp.Hologic_advocated_externally__c =='1' ||Opp.Reference_site__c =='1' ||Opp.Contractual_obligations_fulfilled__c =='1')) ||(Opp.Tender_specs_fit_Hologic_solutions__c =='1' && (Opp.Contract_signed__c =='1' ||Opp.Hologic_advocated_externally__c =='1' ||Opp.Reference_site__c =='1' ||Opp.Contractual_obligations_fulfilled__c =='1')) ||(Opp.Contract_signed__c =='1' && (Opp.Hologic_advocated_externally__c =='1' ||Opp.Reference_site__c =='1' ||Opp.Contractual_obligations_fulfilled__c =='1')) ||(Opp.Hologic_advocated_externally__c =='1' && ( Opp.Reference_site__c =='1' ||Opp.Contractual_obligations_fulfilled__c =='1')) ||(Opp.Reference_site__c =='1' && Opp.Contractual_obligations_fulfilled__c =='1') ||(Opp.Aware_of_Hologic__c =='2' && (Opp.Hologic_personnel_known__c =='2' || Opp.Creditable_player__c =='2' || Opp.Info_shared__c =='2' || Opp.Value_offering_understood__c =='2' ||Opp.Hologic_proactively_supported__c =='2' ||Opp.Have_commercial_knowledge__c =='2' ||Opp.Tender_specs_fit_Hologic_solutions__c =='2' ||Opp.Contract_signed__c =='2' ||Opp.Hologic_advocated_externally__c =='2' ||Opp.Reference_site__c =='2' ||Opp.Contractual_obligations_fulfilled__c =='2' ))||(Opp.Hologic_personnel_known__c =='2' &&( Opp.Creditable_player__c =='2'  ||Opp.Info_shared__c =='2' ||Opp.Value_offering_understood__c =='2' ||Opp.Hologic_proactively_supported__c =='2' ||Opp.Have_commercial_knowledge__c =='2' ||Opp.Tender_specs_fit_Hologic_solutions__c =='2' ||Opp.Contract_signed__c =='2' ||Opp.Hologic_advocated_externally__c =='2' ||Opp.Reference_site__c =='2' ||Opp.Contractual_obligations_fulfilled__c =='2' )) ||(Opp.Creditable_player__c =='2' && (Opp.Info_shared__c =='2' ||Opp.Value_offering_understood__c =='2' ||Opp.Hologic_proactively_supported__c =='2' ||Opp.Have_commercial_knowledge__c =='2' ||Opp.Tender_specs_fit_Hologic_solutions__c =='2' ||Opp.Contract_signed__c =='2' ||Opp.Hologic_advocated_externally__c =='2' ||Opp.Reference_site__c =='2' ||Opp.Contractual_obligations_fulfilled__c =='2') )|| (Opp.Info_shared__c =='2' && ( Opp.Value_offering_understood__c =='2' ||Opp.Hologic_proactively_supported__c =='2' ||Opp.Have_commercial_knowledge__c =='2' ||Opp.Tender_specs_fit_Hologic_solutions__c =='2' ||Opp.Contract_signed__c =='2' ||Opp.Hologic_advocated_externally__c =='2' ||Opp.Reference_site__c =='2' ||Opp.Contractual_obligations_fulfilled__c =='2')) || (Opp.Value_offering_understood__c =='2' && (  Opp.Hologic_proactively_supported__c =='2' ||Opp.Have_commercial_knowledge__c =='2' ||Opp.Tender_specs_fit_Hologic_solutions__c =='2' ||Opp.Contract_signed__c =='2' ||Opp.Hologic_advocated_externally__c =='2' ||Opp.Reference_site__c =='2' ||Opp.Contractual_obligations_fulfilled__c =='2')) ||(Opp.Hologic_proactively_supported__c =='2' &&( Opp.Have_commercial_knowledge__c =='2' ||Opp.Tender_specs_fit_Hologic_solutions__c =='2' ||Opp.Contract_signed__c =='2' ||Opp.Hologic_advocated_externally__c =='2' ||Opp.Reference_site__c =='2' ||Opp.Contractual_obligations_fulfilled__c =='2' ))||(Opp.Have_commercial_knowledge__c =='2' && (Opp.Tender_specs_fit_Hologic_solutions__c =='2' ||Opp.Contract_signed__c =='2' ||Opp.Hologic_advocated_externally__c =='2' ||Opp.Reference_site__c =='2' ||Opp.Contractual_obligations_fulfilled__c =='2')) ||(Opp.Tender_specs_fit_Hologic_solutions__c =='2' && (Opp.Contract_signed__c =='2' ||Opp.Hologic_advocated_externally__c =='2' ||Opp.Reference_site__c =='2' ||Opp.Contractual_obligations_fulfilled__c =='2')) ||(Opp.Contract_signed__c =='2' && (Opp.Hologic_advocated_externally__c =='2' ||Opp.Reference_site__c =='2' ||Opp.Contractual_obligations_fulfilled__c =='2')) ||(Opp.Hologic_advocated_externally__c =='2' && ( Opp.Reference_site__c =='2' ||Opp.Contractual_obligations_fulfilled__c =='2')) ||(Opp.Reference_site__c =='2' && Opp.Contractual_obligations_fulfilled__c =='2') ||(opp.Aware_of_Hologic_products_and_services__c =='1' && ( opp.Value_offering_understood_CSS__c=='1' ||opp.Hologic_proactively_supported_CSS__c=='1' ||Opp.Have_technical_knowledge__c=='1' ||Opp.Hologic_advocated_externally_CSS__c=='1' ||Opp.Contract_signed_CSS__c=='1' ||Opp.Contractual_obligations_fulfilled__c=='1'))  ||(Opp.Value_offering_understood_CSS__c=='1' && (Opp.Hologic_proactively_supported_CSS__c=='1' ||Opp.Have_technical_knowledge__c=='1' ||Opp.Contract_signed_CSS__c=='1' ||Opp.Contractual_obligations_fulfilled__c=='1' ||Opp.Hologic_advocated_externally_CSS__c=='1')) ||(Opp.Hologic_proactively_supported_CSS__c =='1' && (Opp.Have_technical_knowledge__c=='1' ||Opp.Contract_signed_CSS__c=='1' ||Opp.Contractual_obligations_fulfilled__c=='1' ||Opp.Hologic_advocated_externally_CSS__c=='1')) ||(Opp.Have_technical_knowledge__c=='1' &&(Opp.Contract_signed_CSS__c=='1' ||Opp.Contractual_obligations_fulfilled__c=='1' ||Opp.Hologic_advocated_externally_CSS__c=='1'))||(Opp.Hologic_advocated_externally_CSS__c=='1' &&(Opp.Contract_signed_CSS__c=='1' ||Opp.Contractual_obligations_fulfilled__c=='1' ))||(Opp.Contract_signed_CSS__c=='1' && opp.Contractual_obligations_fulfilled__c=='1' ) || (opp.Aware_of_Hologic_products_and_services__c =='2' && ( opp.Value_offering_understood_CSS__c=='2' ||opp.Hologic_proactively_supported_CSS__c=='2' ||Opp.Have_technical_knowledge__c=='2' ||Opp.Hologic_advocated_externally_CSS__c=='2' ||Opp.Contract_signed_CSS__c=='2' ||Opp.Contractual_obligations_fulfilled__c=='2'))  || (Opp.Value_offering_understood_CSS__c=='2' && (Opp.Hologic_proactively_supported_CSS__c=='2' ||Opp.Have_technical_knowledge__c=='2' ||Opp.Contract_signed_CSS__c=='2' ||Opp.Contractual_obligations_fulfilled__c=='2' ||Opp.Hologic_advocated_externally_CSS__c=='2')) ||(Opp.Hologic_proactively_supported_CSS__c =='2' && (Opp.Have_technical_knowledge__c=='2' ||Opp.Contract_signed_CSS__c=='2' ||Opp.Contractual_obligations_fulfilled__c=='2' ||Opp.Hologic_advocated_externally_CSS__c=='2')) || (Opp.Have_technical_knowledge__c=='2' &&(  Opp.Contract_signed_CSS__c=='2' ||Opp.Contractual_obligations_fulfilled__c=='2' ||Opp.Hologic_advocated_externally_CSS__c=='2'))|| (Opp.Hologic_advocated_externally_CSS__c=='2' &&(        Opp.Contract_signed_CSS__c=='2' ||Opp.Contractual_obligations_fulfilled__c=='2' ))||(Opp.Contract_signed_CSS__c=='2' && opp.Contractual_obligations_fulfilled__c=='2' ) )  )
            
        {
            opp.addError('You can only pick a the value of 1 or 2 once in the growth mapping, please adjust to highlight your next SMART Objective area');               
        }
    }
    
}*/
    
}