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
    /* This method is called in init Handler */
    loadEmailcommunicationlist: function(component, event, helper){
        helper.onLoad(component, event);
    },
    /* This method is called in init Handler ,To Addresses are directly brought 
     through the MetaData dynamically by invoking EXTRACTPICKLISTVALUES in EMAILCOMMUNICATION CLASS */
    loadPicklistValues:function(component, event, helper){
        var action=component.get("c.extractPicklistValues");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // if storeResponse size is 0 ,display no record found message on screen.
                console.log(response.getReturnValue());
                component.set("v.PicklistValues",response.getReturnValue());
            }
            
        });
        $A.enqueueAction(action);
    },
    /* SEARCH function is called to Perform Search Criteria on the EmailCommunication Object. */
    Search: function(component, event, helper) {
        /*searchcaseval is used to sort the emails as Assigned, UnAssigned, All */
        var searchcaseval = component.find("searchId").get("v.value");
        /* dateVal stores the To Date which is used for searching the Relavent Dates */
        var dateVal=component.find("expdate").get("v.value");
        /* srcValue is used to Sort the Email Communication Records based on the To Address */
        var srcValue = component.find("searchKey").get("v.value");
        /* datefVal is used to store the From Date value which is given in the From Date field */
        var datefVal=component.find("frmdate").get("v.value");
        /*nameval is used to search based on fromname and from address */
        var nameval=component.find("searchfrom").get("v.value");
        console.log(srcValue);
        if ((searchcaseval==''||searchcaseval==null)&&(dateVal==''|| dateVal==null)&&(datefVal==''|| datefVal==null)&&(nameval==''|| nameval == null)&&(srcValue==''||srcValue==null))
        {
            helper.onLoad(component, event);
        } else {
            console.log(dateVal);
            console.log(datefVal);
            console.log("in else");
            component.set("v.flag2",true);
            if(datefVal !=''  && dateVal !=''){
                console.log("in if");
                if(datefVal>dateVal)
                {
                    alert("Please enter a valid todate");
                    component.set('v.enterdate',null);
                }
                else
                {
                    console.log('in 2nd else');
                    helper.SearchHelper(component, event);
                }
            }else{
                helper.SearchHelper(component, event);
            }
        }
        
    },
    /* OKAY function is used to set the v.deleted Attribute to false. To close the Modal box */
    okay:function(component,event,helper){
        component.set("v.deleted", false);
    },
    /*DELETE function is invoked when we click on DELETE button to delete Email Communication Record */     
    delete:function(component,event,helper){
    var idx = [];
    idx=event.target.id;
    console.log(idx);
    if(confirm("This communication will be permanently deleted.  Do you want to continue ?"))
    {
    component.set("v.deleted", true);
    var action=component.get("c.deleteRecords");
    action.setParams({
    'lstRecordId':idx
});		
action.setCallback(this, function(response) {
    var state = response.getState();
    if (state === "SUCCESS") {
        // helper.onLoad(component, event);
        var a=component.get('c.Search');
        $A.enqueueAction(a);
        // if storeResponse size is 0 ,display no record found message on screen.
    }
});
$A.enqueueAction(action);
}

},
    /*RECORDURL function is invoked when clicked on both Subject and Reassign button,
    to Redirect page to that particular Email communication Record */
    recordurl:function(component,event,helper){
        
        var idx=event.target.id;
        var str=document.referrer+idx;
        console.log(str);
        window.location=str; 
    },
        /*SETPREVIOUS function is invoked when clicked on previous Button in Pagination */
        setPrevious:function(component,event,helper){
            component.set("v.flag2",false);
            var pagination=component.get("v.pagination");
            if(pagination != 0){
                pagination -= 20;
            }else{
                pagination = 0; 
            }
            component.set("v.pagination",pagination);
            var searchcaseval = component.find("searchId").get("v.value");
            var dateVal=component.find("expdate").get("v.value");
            var srcValue = component.find("searchKey").get("v.value");
            var datefVal=component.find("frmdate").get("v.value");
            var nameval=component.find("searchfrom").get("v.value");
            if ((searchcaseval==''||searchcaseval==null)&&(datefVal==''|| datefVal==null)&&(dateVal==''|| dateVal==null)&&(nameval==''|| nameval == null)&&(srcValue==''||srcValue==null))
            {
                helper.onLoad(component, event);
            }  
            else
            {
                helper.SearchHelper (component, event);
            }
        },
            /*SETNEXT function is invoked when clicked on NEXT Button in Pagination */
            setNext:function(component,event,helper){
                component.set("v.flag2",false);
                var flag=component.get("v.flag2");
                console.log(flag);
                var pagination=component.get("v.pagination");
                var Account_totalcount=component.get("v.objClassController.totalsearch");
                console.log(Account_totalcount);
                if(pagination < Account_totalcount){
                    pagination += 20;
                }else{
                    pagination = Account_totalcount;
                }
                component.set("v.pagination",pagination);
                console.log(pagination);
                var searchcaseval = component.find("searchId").get("v.value");
                var dateVal=component.find("expdate").get("v.value");
                var srcValue = component.find("searchKey").get("v.value");
                var datefVal=component.find("frmdate").get("v.value");
                var nameval=component.find("searchfrom").get("v.value");
                if ((searchcaseval==''||searchcaseval==null)&&(datefVal==''|| datefVal==null)&&(dateVal==''|| dateVal==null)&&(nameval==''|| nameval == null)&&(srcValue==''||srcValue==null))
                {
                    helper.onLoad(component, event);
                }  
                else
                {
                    helper.SearchHelper (component, event);
                }
            }, 
                /*RESET function is used to 
    Clear the enter Search Fields and displays all the Data of Email Communication Record */
            Reset:function(component,event,helper){
                component.set("v.searchname","");
                component.set("v.searchKeyword","");
                component.set("v.enterdate","");
                component.set("v.fromdate","");
                component.set("v.searchKey","None");
                helper.onLoad(component,event);
                event.preventDefault();
            }

})