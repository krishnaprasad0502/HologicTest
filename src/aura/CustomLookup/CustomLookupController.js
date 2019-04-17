({
    doInit : function(component,event,helper){
        var CaseTitle = component.get("v.CaseTitle");
        console.log('CaseTitle>>>>'+CaseTitle);
        
        if(CaseTitle == 'Disposable Product Issues' && component.get('v.objectAPIName') == 'Product2'){
            var selectedRecordName = component.get("v.selectedRecordName");
        	console.log('selectedRecordName>>>>>'+selectedRecordName);
            if( selectedRecordName != undefined)
            {
                var forclose = component.find("lookup-pill");
                $A.util.addClass(forclose, 'slds-show');
                $A.util.removeClass(forclose, 'slds-hide');
                
                var forclose = component.find("searchRes");
                $A.util.addClass(forclose, 'slds-is-close');
                $A.util.removeClass(forclose, 'slds-is-open');
                
                var lookUpTarget = component.find("lookupField");
                $A.util.addClass(lookUpTarget, 'slds-hide');
                $A.util.removeClass(lookUpTarget, 'slds-show'); 
            }
        } else if (CaseTitle == '' || CaseTitle == null || CaseTitle == undefined){
            console.log('objectAPIName>>>>>'+component.get('v.objectAPIName'));
            component.set("v.disableInput",false);
            if(selectedRecordName == undefined){
                var pillTarget = component.find("lookup-pill");
                var lookUpTarget = component.find("lookupField");
                
                $A.util.addClass(pillTarget, 'slds-hide');
                $A.util.removeClass(pillTarget, 'slds-show');
                
                $A.util.addClass(lookUpTarget, 'slds-show');
                $A.util.removeClass(lookUpTarget, 'slds-hide');
                
                component.set("v.SearchKeyWord",null);
                component.set("v.listOfSearchRecords", null );
                component.set("v.selectedRecord", {} ); 
            }
        }
    },
    
   onfocus : function(component,event,helper){
       console.log('############################### Custom Lookup : Focus ###############################');
       $A.util.addClass(component.find("mySpinner"), "slds-show");
        var forOpen = component.find("searchRes");
            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');
        // Get Default 5 Records order by createdDate DESC  
         var getInputkeyWord = '';
         helper.searchHelper(component,event,getInputkeyWord);
    },
    onblur : function(component,event,helper){  
        console.log('############################### Custom Lookup : blur ###############################');
        component.set("v.listOfSearchRecords", null );
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },
    keyPressController : function(component, event, helper) {
        console.log('############################### Custom Lookup : keypress ###############################');
       // get the search Input keyword   
         var getInputkeyWord = component.get("v.SearchKeyWord");
       // check if getInputKeyWord size id more then 0 then open the lookup result List and 
       // call the helper 
       // else close the lookup result List part.   
        if( getInputkeyWord.length > 0 ){
             var forOpen = component.find("searchRes");
               $A.util.addClass(forOpen, 'slds-is-open');
               $A.util.removeClass(forOpen, 'slds-is-close');
            helper.searchHelper(component,event,getInputkeyWord);
        }
        else{  
             component.set("v.listOfSearchRecords", null ); 
             var forclose = component.find("searchRes");
               $A.util.addClass(forclose, 'slds-is-close');
               $A.util.removeClass(forclose, 'slds-is-open');
          }
	},
    
  // function for clear the Record Selaction 
    clear :function(component,event,heplper){
    	console.log('############################### Custom Lookup : Clear ###############################');
        var pillTarget = component.find("lookup-pill");
        var lookUpTarget = component.find("lookupField");  
    	component.set("v.selectedRecordName","");
    	component.set("v.selectedRecordId","");
    	component.set("v.AssetAccountId","");
    	component.set("v.customerAccountName","");//customerAccountName
    	component.set("v.customerAccountId","");//customerAccountId
    	component.set("v.SerialNumber","");//SerialNumber
    	component.set("v.Status","");//Status
    	component.set("v.CommunityProductDesc","");//CommunityProductDesc
    	component.set("v.InstallLocationLabel","");//InstallLocationLabel
    	component.set("v.selectedRecordName","");
    	component.set("v.selectedRecordId","");
    	component.set("v.CommunityProductDesc","");
    	component.set("v.disableInput",false);
    	
    	$A.util.addClass(pillTarget, 'slds-hide');
        $A.util.removeClass(pillTarget, 'slds-show');
        
        console.log('TEST1234');
        console.log('TEST1234');
        
        $A.util.addClass(lookUpTarget, 'slds-show');
        $A.util.removeClass(lookUpTarget, 'slds-hide');
         
         component.set("v.SearchKeyWord",null);
         component.set("v.listOfSearchRecords", null );
         component.set("v.selectedRecord", {} );   
    },
    
  // This function call when the end User Select any record from the result list.   
    handleComponentEvent : function(component, event, helper) {
    	console.log('############################### Custom Lookup : Handle Component Event ###############################');
    	console.log(event.getParam("recordByEvent"));
    	var selectedAccountGetFromEvent = event.getParam("recordByEvent");
    	
    	if(component.get('v.objectAPIName') == 'Asset'){
    		if(selectedAccountGetFromEvent.Id != null && selectedAccountGetFromEvent.Id != '' && selectedAccountGetFromEvent.Id != undefined){
        		var cAccount = selectedAccountGetFromEvent.Customer_Account__r;
        		//var accountName = cAccount.Name;
        		//component.set("v.customerAccountName",selectedAccountGetFromEvent.Customer_Account__r.Name);//customerAccountName
        		//console.log('CAccount Name: '+selectedAccountGetFromEvent.Customer_Account__r.Name);
        		component.set("v.customerAccount",cAccount);
        		component.set("v.customerAccountId",cAccount.Id);//customerAccountId
        	}
        	var str = selectedAccountGetFromEvent.Install_Location_Label__c;
            if(str != undefined ){
            	str = str.replace(/<br>/g,',');
            }
	    	component.set("v.selectedRecordName",selectedAccountGetFromEvent.SerialNumber);
	    	//component.set("v.customerAccountId",selectedAccountGetFromEvent.Customer_Account__c);//customerAccountId
	    	component.set("v.SerialNumber",selectedAccountGetFromEvent.SerialNumber);//SerialNumber
	    	component.set("v.Status",selectedAccountGetFromEvent.status);//Status
	    	component.set("v.CommunityProductDesc",selectedAccountGetFromEvent.Community_Product_Description__c);//CommunityProductDesc
	    	component.set("v.InstallLocationLabel",str);//InstallLocationLabel
	    	component.set("v.AssetAccountId",selectedAccountGetFromEvent.AccountId);
	    	component.set("v.selectedRecordId",selectedAccountGetFromEvent.Id);
	    }else if(component.get('v.objectAPIName') == 'Product2'){
	    	component.set("v.selectedRecordName",selectedAccountGetFromEvent.Name);
	    	component.set("v.selectedRecordId",selectedAccountGetFromEvent.Id);
	    	component.set("v.CommunityProductDesc",selectedAccountGetFromEvent.Community_Product_Description__c);
	    }	
    	
        var forclose = component.find("lookup-pill");
           $A.util.addClass(forclose, 'slds-show');
        console.log('TEST123');
           $A.util.removeClass(forclose, 'slds-hide');
        console.log('TEST123');
		
        var forclose = component.find("searchRes");
           $A.util.addClass(forclose, 'slds-is-close');
           $A.util.removeClass(forclose, 'slds-is-open');
      
        var lookUpTarget = component.find("lookupField");
            $A.util.addClass(lookUpTarget, 'slds-hide');
            $A.util.removeClass(lookUpTarget, 'slds-show');  
      
    },
})