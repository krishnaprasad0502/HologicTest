({
	toggleMenu : function(component, event, helper) {
		var showMenu = component.get("v.showMenu");
        if(showMenu) {
            component.set("v.showMenu", false);
        }
        else {
            component.set("v.showMenu", true);
        }
	},
    scrollBottom :function(component, event, helper) {
		window.scrollTo(0, 1000);
	},
    
    doInit: function(component) {
        var pathName = (window.location.pathname) ;
        var address6=component.get('c.truncateString'); 
        address6.setParams({ 
			str : pathName
		});
        address6.setCallback(this, function(response) { 
            component.set("v.currentPageUrl",response.getReturnValue());
        });
        
        var address=component.get('c.getCurrentUser'); 
        address.setCallback(this, function(response) { 
            component.set("v.userInfo", response.getReturnValue()); 
        });
        
        var imgurl = $A.get('$Resource.Community_Logo_Image');
		component.set("v.logoImageUrl",imgurl); 
        
        var address1 = component.get('c.fetchConfigData'); 
        address1.setCallback(this, function(response) { 
            component.set("v.configSetting", response.getReturnValue()); 
            if(component.get("v.userInfo").ProfileId == component.get("v.configSetting").Guest_User_Profile_Id__c ){
                component.set("v.showHeaderText", "True"); 
            }
        });
        
        var address2 = component.get('c.isOfflineHours'); 
        address2.setCallback(this, function(response) { 
            
            component.set("v.isOnlineHours", response.getReturnValue());  
        });
        
        var options = [];
        
        var action = component.get("c.generateTechSupportSkillOptions");
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var arr = response.getReturnValue() ;
                arr.forEach(function(element) {
                    options.push({ value: element.chatButtonId, label: element.skillLabel });
                });
                component.set("v.technicalSupportOptions", options);
            }
        }); 
        $A.enqueueAction(address6);
        $A.enqueueAction(address);
        $A.enqueueAction(address1);
        $A.enqueueAction(address2);
        //$A.enqueueAction(action6);
        $A.enqueueAction(action);
        
        
        
    },
    
    logout : function(component, event, helper) {
        var siteURL = component.get("v.configSetting.SiteURL__c");
        window.location.replace(siteURL+"/secur/logout.jsp");
    },
	
    //Schedule PM Future and Historic data US-0006345
    //Added One more drop down item "Site Tour" after login	
    //gotoSiteTour method will help to get URL for Site Tour from custom setting
    
    gotoSiteTour : function(component, event, helper) {
        helper.gotoSiteTourURL(component);
    },
    gotoMenuURL1 : function(component, event, helper) {
        var urlAddress = component.get("v.configSetting.Knowledgebase__c");
        helper.gotoURL1(component);
    },
    gotoMenuURL2 : function(component, event, helper) {
        var urlAddress = component.get("v.configSetting.Documentation__c");
        helper.gotoURL2(component);
    },
    gotoMenuURL4 : function(component, event, helper) {
        var urlAddress = component.get("v.configSetting.My_Service_Requests__c");
        helper.gotoURL4(component);
    },
    gotoMenuURL3 : function(component, event, helper) {
        var urlAddress = component.get("v.configSetting.Products__c");
        helper.gotoURL3(component);
    },
    gotoMenuURL5 : function(component, event, helper) {
        var urlAddress = component.get("v.configSetting.SiteURL__c") + component.get("v.configSetting.My_Systems__c");
        helper.gotoURL5(component);
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
    openMyProfile : function(component, event, helper) {
        helper.openMyProfileUrl(component);
    },
    handleSearchClick : function(component, event, helper) {
        var showSearch = component.get("v.showSearch");
        if(showSearch) {
            component.set("v.showSearch", false);
        }
        else {
            component.set("v.showSearch", true);
        }
    },
    submitSearch: function(component, event, helper) {
        var search = component.get("v.search");
        if (event.keyCode === 13) {
            helper.callSearch(component);
        } 
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
    }
})