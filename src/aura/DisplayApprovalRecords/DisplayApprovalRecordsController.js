({
	init : function(component, event, helper) {
        var action = component.get('c.DisplayApprovalRecords');
         action.setParams({
            'Pagination':component.get("v.pagination")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                 console.log('testRESSSS'+storeResponse);
                var storeResponse = response.getReturnValue();
                console.log('testRESSSS'+storeResponse);
                component.set("v.objClassController",storeResponse);
              
                }
            if(component.get("v.objClassController.approvalRecords")=='')
            {
                console.log(component.get("v.objClassController.approvalRecords"));
                component.set("v.NoRecords",true);
            }
            else
            {
                component.set("v.NoRecords",false);
            }
        });
     
  
       $A.enqueueAction(action);
		
	},
    gotoComponenet:function(component,event,helper)
    {
       
        var idx=event.target.id;
       
    var quoteid = event.currentTarget.getAttribute("data-attriVal");
        console.log(quoteid);
        //var quoteid= component.find(idx).get("v.value");
        if(quoteid!=''&&quoteid!=null)
        {
             component.set("v.ApprovalId",idx);
          component.set("v.isVisble",true);

        }
        else
        {
            	component.set("v.message",true);
        }
              /* var idx=event.target.id;
      var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:EmailTemplateOfApprovalRecord",
            componentAttributes :{
             "recordId" :idx,
            }
        });
       
    evt.fire();*/
       
    },
    closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isVisble", false);
   },
     closeModel1: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.message", false);
   },
      
     /*RECORDURL function is invoked when clicked on both Subject and Reassign button,
    to Redirect page to that particular Email communication Record */
    recordurl:function(component,event,helper){
         var navEvt;  
        var idx=event.target.id;
         navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": idx,
                        
                    });
         navEvt.fire();

        /*var str=document.referrer+idx;
        console.log(str);
        window.location=str; */
    },
    /*set next is invoked when clicked on Previous button in Pagination*/
     setPrevious:function(component,event,helper){
          var pagination=component.get("v.pagination");
            if(pagination != 0){
                pagination -= 10;
            }else{
                pagination = 0; 
            }
          component.set("v.pagination",pagination);
                console.log(pagination);
        var action = component.get('c.DisplayApprovalRecords');
         action.setParams({
            'Pagination':pagination
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                 console.log('testRESSSS'+storeResponse);
                var storeResponse = response.getReturnValue();
                console.log('testRESSSS'+storeResponse);
                component.set("v.objClassController",storeResponse);
            }
        });
     
  
       $A.enqueueAction(action);
           
        },
            /*SETNEXT function is invoked when clicked on NEXT Button in Pagination */
            setNext:function(component,event,helper){
                var pagination=component.get("v.pagination");
                var Account_totalcount=component.get("v.objClassController.totalsearch");
                console.log(Account_totalcount);
                if(pagination < Account_totalcount){
                    pagination += 10;
                }else{
                    pagination = Account_totalcount;
                }
                component.set("v.pagination",pagination);
                console.log(pagination);
                 var action = component.get('c.DisplayApprovalRecords');
         action.setParams({
            'Pagination':pagination
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                 console.log('testRESSSS'+storeResponse);
                var storeResponse = response.getReturnValue();
                console.log('testRESSSS'+storeResponse);
        		component.set("v.objClassController",storeResponse);
            }
        });
     
  
       $A.enqueueAction(action);
                },
})