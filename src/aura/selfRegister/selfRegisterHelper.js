({
    qsToEventMap: {
        'startURL'  : 'e.c:setStartUrl'
    },
    
    qsToEventMap2: {
        'expid'  : 'e.c:setExpId'
    },
    
    /*Creates new User and new Contact*/
    handleSelfRegister: function (component, event, helpler) {
        var accountId = component.get("v.accountId");
        var regConfirmUrl = component.get("v.regConfirmUrl");
        var includePassword = component.get("v.includePasswordField");
        var extraFields = JSON.stringify(component.get("v.extraFields"));
        var startUrl = component.get("v.startUrl");
        var firstname = component.get("v.FirstnameValue");
        var lastname = component.get("v.LastnameValue");
        var email = component.get("v.EmailValue");
        var password = component.get("v.PasswordValue");
        var confirmPassword = component.get("v.RePasswordValue");
        var JobTitle = component.get("v.JobTitleValue");
        var Company = component.get("v.CompanyValue");
        var MobilePhone = component.get("v.MobPhoneValue");
        var OfficePhone = component.get("v.OffPhoneValue");
        var BusinessStreetAddress = component.get("v.StreetValue");
        var City = component.get("v.CityValue");
        var State = component.get("v.selectedState");
        var Country = component.get("v.selectedCountry");
        var zip = component.get("v.ZipValue");
        startUrl = decodeURIComponent(startUrl);
        var newUserRegUrl = component.get("v.newusermessage");
        var productInterest = component.get("v.ProductInterest");
        var serialNumber = component.get("v.SerialNumber");
        var TimeZone = component.get("v.selectedZone");
        console.log('TimeZone>>>>>',TimeZone);
        var action = component.get("c.selfRegister");
        action.setParams({firstname:firstname,lastname:lastname,email:email,password:password, confirmPassword:confirmPassword, 
                          accountId:accountId, regConfirmUrl:regConfirmUrl, extraFields:extraFields, startUrl:startUrl, 
                          includePassword:includePassword, JobTitle:JobTitle, Company:Company, MobilePhone:MobilePhone, 
                          OfficePhone:OfficePhone, BusinessStreetAddress:BusinessStreetAddress, City:City, State:State,
                          Country:Country,zip:zip, newUserRegUrl: newUserRegUrl,
                          productInterest: productInterest, serialNumber: serialNumber, TimeZone: TimeZone });
        
          	action.setCallback(this, function(a){
          	var rtnValue = a.getReturnValue();
                console.log('rtnValue>>>>>>>>'+rtnValue);
                console.log('NOT NULL');
          	if (rtnValue !== null) {
                if(rtnValue == 'true'){
                    console.log('TRUE');
                    component.set("v.disablebutton",true);
                }else{
                    console.log('FALSE');
                    component.set("v.disablebutton",false);
                    component.set("v.errorMessage",rtnValue);
                    component.set("v.showError",true);
                }
          	}
		});
    	$A.enqueueAction(action);
    },
    
    /*gets values of extra fields set if declared*/
    getExtraFields : function (component, event, helpler) {
        var action = component.get("c.getExtraFields");
        action.setParam("extraFieldsFieldSet", component.get("v.extraFieldsFieldSet"));
        action.setCallback(this, function(a){
        var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.extraFields',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },
    
    setBrandingCookie: function (component, event, helpler) {        
        var expId = component.get("v.expid");
        if (expId) {
            var action = component.get("c.setExperienceId");
            action.setParams({expId:expId});
            action.setCallback(this, function(a){ });
            $A.enqueueAction(action);
        }
    },

    // Fetch Timezone 
    fetchTimeZone : function (component, fieldName)  {
        var action = component.get("c.getSelectOptions");
        action.setParams({
            "objObject": component.get("v.selfRegisterObj"),
            "fld": fieldName
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var allValues = response.getReturnValue();
                var custs = [];
                for(var key in allValues){
                    custs.push({
                        key:allValues[key],
                        value:key
                    });
                }
                component.set("v.TimeZoneValues", custs);
            }
        });
        $A.enqueueAction(action);
    }  
})