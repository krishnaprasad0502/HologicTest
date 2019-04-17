({
	doInit : function(component) {
        var imgurl = $A.get('$Resource.Community_Login_Image');
		component.set("v.heroImageUrl",imgurl);
       var address1 = component.get('c.fetchConfigData'); 
       address1.setCallback(this, function(response) { 
           component.set("v.configSetting", response.getReturnValue());   
           console.log('&&&&'+ response.getReturnValue());
           var imageurl ;
           if($A.get("$Browser.isIPad") || $A.get("$Browser.isTablet")){
              imageurl = component.get("v.configSetting.Base_URL__c")+component.get("v.configSetting").LoginImage_Tablet__c ; 
               component.set("v.height",'height:300px;') ;
           }
           /*Commented by Nomita on 16 Nov. Check imgurl at the top. Getting the image via script instead of code to improve image load performance.
             else {
              imageurl = component.get("v.configSetting.Base_URL__c")+component.get("v.configSetting").LoginImage_Web__c ; 
              component.set("v.height",'height:300px;') ;
           }*/
           component.set("v.backGroundStyle",imageurl) ;
           console.log('&&&&'+ component.get("v.backGroundStyle"));
           
       });
        
       $A.enqueueAction(address1);
	}
})