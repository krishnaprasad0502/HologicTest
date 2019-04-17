({
	doInit : function(component) {
		var imgurl = $A.get('$Resource.Community_Hero_Image');
		component.set("v.heroImageUrl",imgurl);
        component.set("v.height",'height:340px;') ;
       	var address1 = component.get('c.fetchConfigData'); 
       	address1.setCallback(this, function(response) { 
           component.set("v.configSetting", response.getReturnValue());   
           console.log('&&&&'+ response.getReturnValue());
           var imageurl ;
           if($A.get("$Browser.isIPad") || $A.get("$Browser.isTablet")){
              imageurl = component.get("v.configSetting.Base_URL__c")+component.get("v.configSetting").HeroImageUrl_Tablet__c ; 
               component.set("v.height",'height:340px;') ;
           }
           component.set("v.backGroundStyle",imageurl) ;
           console.log('&&&&'+ component.get("v.backGroundStyle"));
           
       });
        
       $A.enqueueAction(address1);
	}
})