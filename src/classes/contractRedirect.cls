/*---------------------------------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Controller Extension for ContractRedirectPage to pass additional URL parameters to autopopulate fields on Contract.

Test Class:   Test_contractRedirect 

History:
<Date>      <Authors Name>    <Brief Description of Change>
10/04/2016   Mani Sundaresan    Initial Creation
------------------------------------------------------------------------------------------------------------------------------------------------*/
public class contractRedirect {

    public contractRedirect(ApexPages.StandardController controller) {
    
    }
    
    public PageReference pageRedirect(){
        
        String operatingUnit = [SELECT Operating_Unit__c from User where Id = :UserInfo.getUserId()].Operating_Unit__c;
        PageReference pageref = new PageReference('/800/e?retURL=%2F800%2Fo&00N6100000Gixt4='+operatingUnit+'&nooverride=1');
        pageref.setredirect(true);
        return pageref;
    }

}