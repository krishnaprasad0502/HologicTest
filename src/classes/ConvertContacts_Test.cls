/*------------------------------------------------------------
Author:     Kasmoor Reddy
Company:    Apps Associates
Description:  Test class to validate ConvertContacts apex class
Tests Excecuted: TestConvertContacts--This method to validate the the contacts displayed 
                 on click of the button on Opportunity whose record type is Diagnostic Physician 
                 and then insert the selected records in Profile_Data__c object
        
        
History:
<Date>        <Authors Name>   <Brief Description of Change>
06/05/2017    Kasmoor Reddy    Initial Creation (US2752)
------------------------------------------------------------*/
@isTest(seealldata=false)
public class ConvertContacts_Test{
    //Variable declarations     
    private static Account Acc;
    private static Contact Con;
    private static Contact Con1;
    private static List<Contact> Contacts = new List<Contact>();
    private static Opportunity Opp;
    private static AccountContactRelation ACR;
    private List<Profile_Data__c> APD = new List<Profile_Data__c>();
    private boolean isSelected;
    private static List<ContactWrapper> lstConWr =new List<ContactWrapper>();
    private static Account siteAccount; 

    
    static testMethod void TestConvertContacts(){
        
        //Trigger switch for 'OpportunityTrigger'
       TestUtility.setupConfigurationSettings();
       TestUtility.insertCustSetting('OpportunityTrigger'); 
        
        //Insert Account
        Acc=TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert Acc;
        System.assertEquals('Customer Account', Acc.Name);
        boolean isSelected =True;
        
        //insert site account
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', '100 Shipping Street', Acc.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
		insert siteAccount;
        System.assertEquals('Site Account', siteAccount.Name);
        
        //Insert Contact
        Con = TestUtility.newContact('Firstname ','Lastname ', Acc.id);
        Insert Con;
        lstConWr.add(new ContactWrapper(con ,isSelected));
       
        Con1 = TestUtility.newContact('Firstname ','Lastname ', Acc.id);
        Insert Con1;
        lstConWr.add(new ContactWrapper(con1 ,isSelected));
 
        //Insert Opportunity
        Opp = TestUtility.newOpportunity('test Opp', Acc.id, System.today(), 'Qualify', null);
        insert Opp;
        System.assertEquals('test Opp', Opp.Name);
        
        //Page reference
        PageReference pageRef = Page.ConvertContacts;
        pageRef.getParameters().put('id',Opp.id);
        Test.setCurrentPage(pageRef);
        
        //Passing methods
        ApexPages.StandardController sc = new ApexPages.StandardController(Opp);
        ApexPages.currentPage().getParameters().put('OpportunityID',Opp.id);
        ConvertContacts CC = new ConvertContacts(sc);
        CC.lstSetController[0].isSelected=true;
        CustomIterable newcon= new CustomIterable(lstConWr);
        newcon.setPageSize = 1;
        //newcon.conlist = 0;
        //newcon.conwrap = 0;
        integer i = 0;
        Integer ps=newcon.setPageSize;
        Boolean next=newcon.hasNext();
        newcon.next();
        Boolean previous=newcon.hasPrevious();

        system.assertequals(CC.ContactIds.isEmpty(),True);
        CC.Nextpage();
        CC.Back();
        CC.save();
        system.assertequals(CC.Accprofiles.isEmpty(),false);
        CC.Next();
        CC.Previous();
        CC.hasNext =TRUE;
        CC.hasPrevious = true;
        newcon.hasPrevious();
        
       
    }//End of the testmethod.
}//End of the test class.