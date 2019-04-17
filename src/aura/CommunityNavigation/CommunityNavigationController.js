({
    init: function (component) {
        //Set default values
        component.set('v.updatedCount', 12);
        component.set('v.selectedItem', 'reports_recent');
        component.set('v.currentContent', 'reports_recent');
        
        var action1 = component.get("c.fetchConfigData");
        
        action1.setCallback(this,function(response){
			component.set("v.configSetting",response.getReturnValue());
		});
        
        $A.enqueueAction(action1);
        if(component.get('v.MenuType') == 'Knowledgebase'){
            var forumAction = component.get("c.getForumId");
            forumAction.setParams({ 
                assetId : component.get("v.recordId")
            });
            forumAction.setCallback(this,function(response){
                if(response.getReturnValue()!= null){
                    component.set("v.forumUrl",component.get("v.configSetting").SiteURL__c+'/s/topic/'+ response.getReturnValue());
                }else{
                    component.set("v.forumUrl",component.get("v.configSetting").SiteURL__c+'/s/discussionforum/');
                }
                
            });
            $A.enqueueAction(forumAction);
        }
                            
        // Fetch Data Category
        //  Quicklinks for system detail Page	US-0006454 
        var recId = component.get("v.recordId");
        component.set('v.recorddetailId','?recorddetailid='+recId);
            if (recId != undefined && recId != '')
            {
               if (recId.substring(0, 3) === '02i' )
               {
                   var datacategoryfetch = component.get("c.getDataCategory");
                   datacategoryfetch.setParams({ 
                       AssetId : component.get("v.recordId")
                   });
                   datacategoryfetch.setCallback(this,function(response){
                       component.set("v.DataCategory",'&category=' +response.getReturnValue()); 
                       component.set("v.downloadsCategoryUrl",'?category=' +response.getReturnValue());
                   });
                   $A.enqueueAction(datacategoryfetch);
               }
            }
        
        //FetchRecords
        var action = component.get("c.FetchRecords");
        action.setParams({ 
			Type : component.get("v.MenuType"),
		});
        action.setCallback(this,function(response){
			component.set("v.ReturnedRecords",response.getReturnValue());
            var recId = component.get("v.recordId");
            if (recId != undefined && recId != '')
            {
               if (recId.substring(0, 3) === '02i' )
               {
               		component.set("v.recordIdParameter", '&Id=' + recId); 
                    component.set("v.isAssetDetailPage", true); 
               }
            }
            //console.log('MenuType:'+ component.get("v.MenuType") + ' RecordID: ' +  component.get("v.recordIdParameter") + ' isAssetDetailPage:' +  component.get("v.isAssetDetailPage"));
		});
        
        var address=component.get('c.getCurrentUser'); 
        address.setCallback(this, function(response) { 
            component.set("v.userInfo", response.getReturnValue()); 
            if((component.get("v.userInfo.Profile.Name") != $A.get("$Label.c.Community_Profile_Delegated_Admin")) && component.get('v.MenuType') == 'ADMINISTRATION'){
                component.set('v.navclassname', 'hidenavigation');
            }
            
        });
        var address2 = component.get('c.isOfflineHours'); 
        address2.setCallback(this, function(response) { 
            
            component.set("v.isOnlineHours", response.getReturnValue());  
        });
        var options = [];
        
        var action2 = component.get("c.generateTechSupportSkillOptions");
        action2.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var arr = response.getReturnValue() ;
                arr.forEach(function(element) {
                    options.push({ value: element.chatButtonId, label: element.skillLabel });
                });
                component.set("v.technicalSupportOptions", options);
            }
        }); 
        $A.enqueueAction(address);
		$A.enqueueAction(action);
        $A.enqueueAction(action2);
        $A.enqueueAction(address2);
    },

    handleSelect: function(component, event, helper) {
        var selected = event.getParam('name');
        if (selected === 'reports_updated') {
            component.set('v.updatedCount', 0);
        }
        component.set('v.currentContent', selected);
    },
    	
    // for Display Model,set the "isOpen" attribute to "true"
    openModel: function(component, event, helper) {
		component.set("v.isOpen", true);
	},
	
    // for Hide/Close Model,set the "isOpen" attribute to "Fasle" 
	closeModel: function(component, event, helper) {
		component.set("v.isOpen", false);
	},
    showLiveChat : function(component, event, helper) {
        component.set("v.showLiveChat",true);
    },
    hideLiveChat : function(component, event, helper) {
        component.set("v.showLiveChat",false);
        component.set("v.isButtonVisible",false);
        //var cmpTarget = component.find('live-chat-section');
       // $A.util.toggleClass(cmpTarget, "slds-fade-in-open");
        //$A.util.removeClass(cmpTarget, 'slds-modal__container');
    },
    handleRadioClick : function(component, event, helper) {       
        component.set("v.isButtonVisible",false);
        var selected = event.currentTarget.value ;
        console.log('Picklist value is'+ selected);
        component.set("v.selectedTechnicalSkill",selected);   
        if(component.get("v.selectedTechnicalSkill") == 'Technical Support') {
            component.set("v.isTechnicalSupportSelected",true); 
        }else{
            component.set("v.isTechnicalSupportSelected",false); 
        }
        if(selected != 'Technical Support'){
            try{
                var action = component.get("c.returnChatButtonId");
                action.setParams({
                    "skillType" : selected
                });
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    
                    if (state === "SUCCESS") {
                        component.set("v.inptText",response.getReturnValue());  
                        console.log('Button code iis'+ response.getReturnValue());
                        var d = new Date();
                        var n = d.getTime();   
                        var buttonCode = component.get("v.inptText");
                        console.log('vutton is '+ buttonCode);
                        component.set("v.isButtonVisible",true); 
                        component.set("v.ifmsrc", component.get("v.configSetting.SiteURL__c")+'/apex/webchat?t='+ n +'&buttonCode='+buttonCode);   
                        
                    } 
                });
                
                $A.enqueueAction(action);  
                
            }catch(e){
                console.log(e);
            }
        }
        console.log('Slected radio is:'+ selected);
          
    },
    handleSelectChange : function(component, event, helper) { 
        component.set("v.isButtonVisible",false);
        var selectedOption = component.find("select1");
        var selected = selectedOption.get("v.value");
        component.set("v.selectedTechnicalSkill",selected);   
        
        component.set("v.inptText",selected);
        var d = new Date();
        var n = d.getTime();   
        var buttonCode = component.get("v.inptText");
        component.set("v.isButtonVisible",true);
        component.set("v.ifmsrc", component.get("v.configSetting.SiteURL__c")+'/apex/webchat?t='+ n +'&buttonCode='+buttonCode);            
    },
    //Invokes SubmitNewCase component
    InvokeComponent: function(component, event, helper) {
        console.log('Test - Ignore');
        component.set("v.isOpen", true);
        var ctarget = event.currentTarget;
        var id_str = ctarget.dataset.value;
        var res = id_str.split("#");
        var assetRecordId = component.get("v.recordId");
        var Value1 = res[1];
        var Value2 = res[2];
        var Value3 = res[3];
        var Subject = res[4];
        // Added var Title to get LinkName to set default priority for Submit an Issue to Sev 2
        // Default the Priority for Submit an Issue to 'Sev 2' US-0006454
        var Title = res[5];
        console.log("assetRecordId",assetRecordId);
        $A.createComponent("c:SubmitNewCase",{
				"aura:id" : "CaseComp",
            	"CaseType" : Value1,
            	"CaseSubType" : Value2,
            	"CasePriority" : Value3,
            	"CaseSubject": Subject,
            	"assetRecordId" : assetRecordId,
            	"CaseTitle" : Title
            }, function(newCmp,status,errorMessage) {
                console.log("newCmp",newCmp);
                if (component.isValid()) {
                    console.log("status",status);
					if(status == "ERROR") {
						console.log('Error Message--',errorMessage);
					}
                    
					component.set("v.comp", newCmp);
				}
            }   
        );
    },
  	//Invokes SubmitDisposableProductNewCase component
	InvokeDisposableProductComponent: function(component, event, helper) {
        console.log('Test Disposable - Ignore');
        component.set("v.isOpen", true);
        var ctarget = event.currentTarget;
        var id_str = ctarget.dataset.value;
        var res = id_str.split("#");
        var assetRecordId = component.get("v.recordId");
        var Value1 = res[1];
        var Value2 = res[2];
        var Value3 = res[3];
        var Subject = res[4];
        // Added var Title to get LinkName to set default priority for Submit an Issue to Sev 2
        // Default the Priority for Submit an Issue to 'Sev 2' US-0006454
        var Title = res[5];
        console.log("assetRecordId",assetRecordId);
        $A.createComponent("c:DisposableProductIssueForm",{
				"aura:id" : "CaseComp",
            	"CaseType" : Value1,
            	"CaseSubType" : Value2,
            	"CasePriority" : Value3,
            	"CaseSubject": Subject,
            	"assetRecordId" : assetRecordId,
            	"CaseTitle" : Title
            }, function(newCmp,status,errorMessage) {
                console.log("newCmp1::",newCmp);
                if (component.isValid()) {
                    console.log("status",status);
					if(status == "ERROR") {
						console.log('Error Message--',errorMessage);
					}
                    
					component.set("v.comp", newCmp);
				}
            }   
        );
    },
    //Handles the close Modal event, which helps in closing the case creation pop up.
    handleComponentEvent : function(component, event, helper) {
    	component.set("v.isOpen", false);
    }    
})