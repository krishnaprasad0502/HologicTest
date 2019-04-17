/*------------------------------------------------------------
Author:         Amarendra Nagireddy
Company:        AppsAssociates 
Description:    Display case record types based on current user access
                User can select record type before creating case from asset or account
Class Name:     CaseRecordTypeController          
Test Class:     CaseRecordTypeController_Test

History:
<Date>          <Authors Name>          <Brief Description of Change>
04/18/2017      Amarendra Nagireddy      Initial Creation(US-0002746) to accommodate the functionality related to US-0002765
05/22/2017      Amarendra Nagireddy      Consolidated code for the case creation process from Account/Asset as part of US-0002746, US-0002765
                                         Modified method name from 'goback()' to 'Cancel()'
------------------------------------------------------------*/
public with sharing class CaseRecordTypeController {
    //Global Variable declaration
    public String selectedrecordtype { get; set; }
    Public List<SelectOption> caserecordtypes {set;get;}
    public String objname {set;get;}
    public id aid {set;get;}
    /*------------------------------------------------------------
    Author:       Amarendra Nagireddy
    Company:      AppsAssociates 
    Description:  get all the case record types and add to SelectOption to diplay on visualforce page. 
    Inputs:       N/A
    Returns:      
    History:
    <Date>          <Authors Name>           <Brief Description of Change>
    04/18/2017      Amarendra Nagireddy       Initial Creation(US-0002746) to accommodate the functionality related to US-0002765
    05/22/2017      Amarendra Nagireddy       Consolidated code to select case record type on Account/Asset as part of US-0002765 & US-0002746
    ------------------------------------------------------------*/
public CaseRecordTypeController()
{
        
       // 05/22/2017-(Amarendra Nagireddy)- Getting object type, record id from page parameters
       Objname=apexPages.currentPage().getParameters().get('objname');
       aid=apexPages.currentPage().getParameters().get('aid');
       caserecordtypes= new List<SelectOption>();
       //Get all the case record types available 
       Schema.DescribeSObjectResult d = Schema.SObjectType.Case; 
       List<Schema.RecordTypeInfo> recordtypeinfo=d.getRecordTypeInfos();
       for(Schema.RecordTypeInfo getinfo:recordtypeinfo)
       {
         //If the current user has access to record type add to selectoptions 
               if(getinfo.isAvailable())
               {
                caserecordtypes.add(new SelectOption(getinfo.getRecordTypeId(),getinfo.getName()));
               }
               
        }       
}//End of Constructor
    /*------------------------------------------------------------
    Author:       Amarendra Nagireddy
    Company:      AppsAssociates 
    Description:  Redirect to case creation page after selecting record type based on Account id/Asset id 
    Inputs:       N/A
    Returns:      pagereference
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    04/18/2017      Amarendra Nagireddy         Initial Creation(US-0002746) to accommodate the functionality related to US-0002765
    05/22/2017      Amarendra Nagireddy         Consolidated code to redirect to case creation page after selecting record type based on object type, record id as part of US-0002765, US-0002505
            
    ------------------------------------------------------------*/    
public pagereference continueredirect()
{
        
              
        //05/22/2017(Amarendra Nagireddy)-redirect to next page based on object type, record id
        PageReference orderPage = new PageReference('/apex/createCaseOnAsset?RecordType='+selectedrecordtype+'&ent=Case&aid='+aid+'&objname='+objname);
        orderPage.setRedirect(true);
        return orderPage;
     
       
        
}//End of continueredirect method
    /*------------------------------------------------------------
    Author:       Amarendra Nagireddy
    Company:      AppsAssociates 
    Description:  Redirecting back to Account/Asset 
    Inputs:       N/A
    Returns:      PageReference
    History:
    <Date>          <Authors Name>            <Brief Description of Change>
    04/18/2017      Amarendra Nagireddy          Initial Creation(US-0002746) to accommodate the functionality related to US-0002765
    05/22/2017      Amarendra Nagireddy          Consolidated code to redirect to account/asset detail page,As part of US-0002765, US-0002746
                                                 Modified method name from 'goback()' to 'Cancel()' 
    ------------------------------------------------------------*/    
    //5/22/2017(Amarendra Nagireddy)-Modified method name from 'goback()' to 'Cancel()'
public PageReference Cancel() {
   
        //05/22/2017(Amarendra Nagireddy)-redirect to previous page based on object type, record id
         PageReference orderPage = new PageReference('/'+aid);
    
         return orderPage;
       
        
    }//End of goback method
}//End of class