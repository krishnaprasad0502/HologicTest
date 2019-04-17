/*------------------------------------------------------------
Author:          Kasmoor Reddy
Company:         AppsAssociates 
Description:     Populate the Alignment label value from Lead Alignment (custom metadata) based on the product of interest value selected in Lead.
Class Name:      LeadTriggerActions
Trigger:         updateAlignment
Test Class:      LeadTriggerActions_Test
History:
<Date>           <Authors Name>      <Brief Description of Change>
06/08/2017       Kasmoor Reddy       Initial Creation (US2676)
06/16/2017       Kasmoor Reddy       Added the email functionality to send an emails when no metadata found. 
01/14/2019       Mani Sundaresan     Introduce logic to handle lead creation from CVent system (US-0006523)   
------------------------------------------------------------*/
public class LeadTriggerActions
{
    private static Record_Type_IDs__c recordTypeIds = Record_Type_IDs__c.getOrgDefaults();        
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: In this method we are updating the alignment on lead object based on the product 
                 of intrest value while inserting and updating the lead record.  
    Returns:     N/A
      
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    06/08/2017      Kasmoor Reddy              Initial Creation (US2676)
    06/16/2017      Kasmoor Reddy              Added the email functionality to send an emails when no metadata found.
 -----------------------------------------------------------------------------------*/ 
public static void BeforeinsertLeadActions(list<lead>newlead)
      { 
          list<Lead_Alignment__mdt> LAM = new list<Lead_Alignment__mdt>();
          // set To collect user selected "product of interest"
          set<string>productofinterest=new set<string>();
          //Set to collect LeadId  
           id Leadid;
             // it has list of new Records
             for(lead pro:newlead)
             {     
                //Add product of interest. 
                productofinterest.add(pro.Product_of_Interest__c);
                 //leadid=pro.id;
             }
              //used to collect the Product Of Interest and AlignmentId. 
              map<string,id> Alignmentlabel=new map<string,id>();
              if(productofinterest.size()>0){
              //Query on Lead_Alignment__mdt To get the Lead_Alignment__mdt values.
                 LAM=[SELECT id,Alignment_ID__c,Alignment_Label__c,Product_of_Interest__c FROM Lead_Alignment__mdt where Product_of_Interest__c =:productofinterest];
              } 
          
              if(LAM.size()>0){
                  // iterate all the Lead_Alignment__mdt records.
                  for(Lead_Alignment__mdt LA:LAM)
                  {    
                      if(LA.Alignment_ID__c!=null)
                      {
                          //Add product of interest and Alignmentid to Alignmentlabel .
                          Alignmentlabel.put(LA.Product_of_Interest__c,LA.Alignment_ID__c);
                      }
                  }
              } 
                //Create a  list to hold the emails we'll send
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                
                 // It has list of new Records What your trying to insert.
                 for(Lead L:newlead)
                 {   
                     leadid=L.id;
                     system.debug('leadid'+leadid);
                     // used to compare the Lead_Alignment__mdt of productinterest value and lead of productinterest value.
                     if(Alignmentlabel.containsKey(L.Product_of_Interest__c))
                     {   
                         // map the Alignmentid to TAV4__Alignment__c i.e(lookup)
                         L.TAV4__Alignment__c=Alignmentlabel.get(L.Product_of_Interest__c);
                     } else{
                         if(leadid != null){
                         
                         // Create a new Email
                          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                         //Set list of people who should get the email
                          List<String> sendTo = new List<String>();
                         if(system.label.Update_Alignment_Emailid != null){
                          //"Update_Elignment_Emailid" is a Custom Label, Which holds the "Emailids".
                                 sendTo.add(system.label.Update_Alignment_Emailid);
                                 // Set Html Body
                                 String link ='<html><body>Hi,<Br/><Br/> There is no valid metadata component for the product of interest assigned to the lead. <Br/>To view the lead details, Please <a href="' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + Leadid + '" target="_blank">click here</a> </body></html>';
                                 mail.setToAddresses(sendTo);
                                 mail.setSubject('Invalid AlignmentId for the Selected Product of Interest');
                                 mail.setHtmlBody(link);
                                 mails.add(mail);
                         }
                     }
                    }
                 }
                 
                 if(mails.size() > 0)
                      Messaging.sendEmail(mails);
      }
      
    /*-----------------------------------------------------------------------------
    Author:      Mani Sundaresan
    Company:     Hologic
    Description: In this method we are updating the Country and State picklist field on lead when 
                 created from CVent system  
    Returns:     N/A
      
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    01/14/2019      Mani Sundaresan     Introduce logic to handle lead creation from CVent system (US-0006523)   
    -----------------------------------------------------------------------------------*/ 
      
      public static void cventCounty(list<lead> newlead){
          for(Lead le : newlead){
              System.debug('cvent country:'+le.CVent_Country__c);
              System.debug('cvent state:'+le.CVent_State_Province__c);
              System.debug('lead country:'+le.CountryCode);
              System.debug('lead state:'+le.State);
              
              if(le.CVent_Country__c != null && le.CVent_Country__c == 'USA'){
                  le.Country = 'United States';
                  le.CountryCode = 'US';
                  le.State = le.CVent_State_Province__c;
                  le.RecordTypeId = recordTypeIds.Lead_MA_RecordType__c;
              }
              else if(le.CVent_Country__c != null && le.CVent_Country__c != 'Puerto Rico'){
                  le.Country = 'United States';
                  le.CountryCode = 'US';
                  le.State = 'Puerto Rico';
                  le.RecordTypeId = recordTypeIds.Lead_MA_RecordType__c;
              }
              else if(le.CVent_Country__c != null && (le.CVent_Country__c != 'USA' && le.CVent_Country__c != 'Puerto Rico')){
                  le.Country = le.CVent_Country__c;
                  le.State = le.CVent_State_Province__c;
                  le.RecordTypeId = recordTypeIds.Lead_MA_RecordType__c;
              }
                  
          }
          
      }
     
    
}