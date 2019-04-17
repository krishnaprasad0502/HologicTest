({
    
    //Schedule PM Future and Historic data US-0006345
    //Added One more drop down item "Site Tour" after login	
    //gotoSiteTourURL method will help to get URL for Site Tour from custom setting
    getCurrentUserData: function (component) {
        //alert('###val'+ component.get("v.userInfo")+ 'and'+ component.get("v.configSetting"));
        //console.log('###val'+ component.get("v.userInfo").ProfileId + 'and'+ component.get("v.configSetting").Guest_User_Profile_Id__c);
        /*if(component.get("v.userInfo").ProfileId == component.get("v.configSetting").Guest_User_Profile_Id__c ){
            component.set("v.showHeaderText", True); 
        }*/
    },
    gotoSiteTourURL: function (component) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var urlAddress = component.get("v.configSetting.Community_Site_Tour__c");
        urlEvent.setParams({
          "url": urlAddress
        });
        urlEvent.fire();
    },
    logoutURL1 : function (component) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var urlAddress = component.get("v.configSetting.SiteURL__c");
        urlEvent.setParams({
          "url": urlAddress +"/secur/logout.jsp"
        });
        urlEvent.fire();
    },
    gotoURL1 : function (component) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var urlAddress = component.get("v.configSetting.Knowledgebase__c");
        urlEvent.setParams({
          "url": urlAddress
        });
        urlEvent.fire();
    },
    gotoURL5 : function (component) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var siteUrl = component.get("v.configSetting.SiteURL__c"); 
        var urlAddress = component.get("v.configSetting.My_Systems__c");
        urlEvent.setParams({
          "url": urlAddress
        });
        urlEvent.fire();
    },
    gotoURL4 : function (component) {
        var urlEvent = $A.get("e.force:navigateToURL");
        //var siteUrl = component.get("v.configSetting.SiteURL__c"); 
        var urlAddress = component.get("v.configSetting.My_Service_Requests__c");
        urlEvent.setParams({
          "url": urlAddress
        });
        urlEvent.fire();
    },
    gotoURL3 : function (component) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var urlAddress = component.get("v.configSetting.Products__c");
        urlEvent.setParams({
          "url": urlAddress
        });
        urlEvent.fire();
    },
    gotoURL2 : function (component) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var urlAddress = component.get("v.configSetting.Documentation__c");
        urlEvent.setParams({
          "url": urlAddress
        });
        urlEvent.fire();
    },
    openMyProfileUrl : function (component) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var siteUrl = component.get("v.configSetting.SiteURL__c");
        //var urlAddress = siteUrl + component.get("v.configSetting.My_Profile__c")+component.get("v.userInfo.Id");	
        // My Profile related change US-0006454
        var urlAddress = siteUrl + component.get("v.configSetting.My_Profile__c");	
        urlEvent.setParams({
          "url": urlAddress
        });
        urlEvent.fire();
    },
    callSearch : function (component) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var searchString = component.get("v.search");;
        urlEvent.setParams({
          "url": "/global-search/"+ searchString 
        });
        urlEvent.fire();
    },    
    
})