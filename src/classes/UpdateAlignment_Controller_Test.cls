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
public class UpdateAlignment_Controller_Test {
private static List<Lead> Leadlist = new List<Lead>();
@istest static void Create_Test_leadRecord(){
        Test.startTest();
            TestUtility.insertCustSetting('UpdateAlignment');
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
              Leadlist.add(Lead1);
              Leadlist.add(Lead2);
              Database.SaveResult[] srListinst = Database.insert(Leadlist, false);
          
                      for(Lead L:[Select Company,LastName,CurrencyIsoCode,Status,Phone,Product_of_Interest__c,TAV4__Alignment__c from Lead]){
                        // compare the product of interest from lead and Alignment objects.
                       if(ProductofInterest.containsKey(L.Product_of_Interest__c))
                       {     //map the Alignmentid to TAV4__Alignment__c (Alignment lookup).
                          L.TAV4__Alignment__c=ProductofInterest.get(L.Product_of_Interest__c);
                       }
                         system.assertEquals(L.TAV4__Alignment__c,ProductofInterest.get(L.Product_of_Interest__c));
                    }
                    // update Testlead              
                    Database.SaveResult[] srListupdt = Database.update(Leadlist, false);
                    Test.stopTest();
       
    }//End of test method
    
}//End of test class