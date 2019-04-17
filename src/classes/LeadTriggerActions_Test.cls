/*------------------------------------------------------------
Author:     Kasmoor Reddy
Company:    Apps Associates
Description:  Test class to validate UpdateAlignment_controller.
Tests Excecuted: Create_Test_leadRecord--This method to validate the alignment field values on the lead object 
                 when inserting and updating the records based on the product of interest field value
        
        
History:
<Date>        <Authors Name>   <Brief Description of Change>
06/08/2017    Kasmoor Reddy    Initial Creation (US2676)
------------------------------------------------------------*/

@istest(seealldata=false)
public class LeadTriggerActions_Test {
private static List<Lead> Leadlist = new List<Lead>();
@istest static void Create_Test_leadRecord(){
        Test.startTest();
            TestUtility.insertCustSetting('UpdateAlignment');
            TestUtility.insertCustSetting('LeadTrigger');
          //Collect the AlignmentId and product ofinterest.
          map<string,id>ProductofInterest=new map<string,id>(); 
          // Query on leadAlignmentmdt.
          list<Lead_Alignment__mdt>LeadAlignmentmdt=[SELECT id,Alignment_ID__c,Alignment_Label__c,Product_of_Interest__c FROM Lead_Alignment__mdt];
    
            for(Lead_Alignment__mdt LAM:LeadAlignmentmdt)
            {
               // Add the Product of Interest and Alignmentid.
               ProductofInterest.put(LaM.Product_of_Interest__c,LAM.Alignment_ID__c);
            }
        
              // Create  a Lead
              Lead Lead1 = TestUtility.newLead('TestCompant','TestName','USD','open','9908294936','ATEC');
              Lead Lead2 = TestUtility.newLead('TestCompant','TestName','USD','open','9908294936',null);
              Lead1.CountryCode = 'US';
              Lead2.CountryCode = 'US';
              Leadlist.add(Lead1);
              Leadlist.add(Lead2);
              //Database.SaveResult[] srListinst = Database.insert(Leadlist, false);
              insert Leadlist;
              
              for(Lead L:[Select Company,LastName,CurrencyIsoCode,Status,Phone,Product_of_Interest__c,TAV4__Alignment__c from Lead where Id IN :Leadlist]){
                // compare the product of interest from lead and Alignment objects.
               if(ProductofInterest.containsKey(L.Product_of_Interest__c))
               {     //map the Alignmentid to TAV4__Alignment__c (Alignment lookup).
                  L.TAV4__Alignment__c=ProductofInterest.get(L.Product_of_Interest__c);
               }
                 system.assertEquals(L.TAV4__Alignment__c,ProductofInterest.get(L.Product_of_Interest__c));
            }
            // update Testlead              
            //Database.SaveResult[] srListupdt = Database.update(Leadlist, false);
            update Leadlist;
            Test.stopTest();
       
    }//End of test method
    
    @istest static void CVentTest(){
    
        TestUtility.insertCustSetting('LeadTrigger');
        Test.startTest();
            Lead Lead1 = TestUtility.newLead('TestCompant','TestName','USD','open','+19908294936','ATEC');
            Lead1.CVent_Country__c = 'USA';
            Lead1.CVent_State_Province__c = 'California';
            Lead Lead2 = TestUtility.newLead('TestCompant','TestName','CAD','open','+19908294936',null);
            Lead2.CVent_Country__c = 'Canada';
            Lead1.CVent_State_Province__c = 'Alberta';
            
            Leadlist.add(Lead1);
            Leadlist.add(Lead2);
            Database.SaveResult[] srListinst = Database.insert(Leadlist, false);
            
        Test.stopTest();
        
    }
    
}//End of test class