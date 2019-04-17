/*******************************************************************************
Author:         KRISHNA PRASAD
Company:        APPS ASSOCIATES 
Description:    EMAIL COMMUNICATION SEARCH PAGE
Component Name:     Emailcommunication _component         
Contoller:     Email Communication 

History:
<Date>          <Authors Name>          <Brief Description of Change>
20/1/2018       KRISHNA PRASAD          Initial Creation(US-0003622)
*********************************************************************************/
({
    //ONLOAD function is invoked from the javascript controller loadEmailcommunicationlist
    onLoad : function(component, event) {
       var action = component.get('c.searchkeyword');
        action.setParams({
            'Pagination':component.get("v.pagination")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                 console.log('testRESSSS'+storeResponse);
                var storeResponse = response.getReturnValue();
                 console.log('testRESSSS'+storeResponse);
                component.set("v.Account_totalcount",storeResponse);
                component.set('v.objClassController', response.getReturnValue());
              
       }
        });
     
  
       $A.enqueueAction(action);
    },
    /*SEARCHHELPER function is invoked during the PAGINATION, SEARCH FROM THE JAVASCRIPT CONTROLLER*/
    SearchHelper : function(component, event) {
        var flag=component.get("v.flag2");
        var page=component.get("v.pagination") ;
        var name=component.get("v.searchname");
        var fromdate=component.get("v.fromdate");
        var toaddress=component.get("v.enterdate");
       console.log(toaddress);
        var value=0;
        if(flag==true)
                {
                component.set("v.pagination",0);
                }
       var action=component.get("c.searchkeyword");
        action.setParams({
            'enterdate':component.get("v.enterdate"),
           'fromdate':component.get("v.fromdate"),
            'searchcase':component.get("v.searchKeyword"),
            'searchname':name,
            'Pagination':component.get("v.pagination"),
            'listid':component.get("v.checkedid"),
            'toaddress':component.get("v.searchKey")
        });		
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
             // if storeResponse size is 0 ,display no record found message on screen.
                if (storeResponse.length == 0) {
                    component.set("v.Message", true);
                } else {
                    component.set("v.Message", false);
                }
                console.log('testRESSSS'+storeResponse);
              component.set("v.totalrecords",storeResponse);
            
              
                component.set('v.objClassController', response.getReturnValue());
        } 
        });
      	 $A.enqueueAction(action);
    },
})