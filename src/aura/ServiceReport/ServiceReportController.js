({
   doInit: function(component, event, helper) {
      // the function that reads the url parameters
      helper.readURLParameter(component);      
      var stepNumber = component.get("v.stepNumber");
      // Set the "isOpen" attribute to "true"
      component.set("v.isOpen", true);
      helper.setStepDetails(component,stepNumber, false);      
   },
 
   closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isOpen", false);
     
   },
 
   goBack: function(component, event, helper) {
       var stepNumber = component.get("v.stepNumber");
       stepNumber = stepNumber - 1;
       component.set("v.stepNumber", stepNumber);
       helper.setStepDetails(component,stepNumber, true);      
   },
   nextStep: function(component, event, helper) {
       var stepNumber = component.get("v.stepNumber");
       stepNumber = stepNumber + 1;
       component.set("v.stepNumber", stepNumber);
       component.set("v.numOfRows", 0);
       helper.setStepDetails(component, stepNumber, false);
      
   },
    downloadDocument : function(component, event, helper){
      var sendDataProc = component.get("v.sendData");
      //var accountResult = JSON.parse (JSON.stringify(component.get("v.Step1Result")));
      //var accountList = accountResult.accountList;
      var dataToSend = {
         "finalassetdata" :  component.get("v.Step3ResultJSON")
      }; //this is data you want to send for PDF generation
      //var dataToSend =  component.get("v.Step3ResultJSON");
      //invoke vf page js method
      sendDataProc(dataToSend, function(){
                  //handle callback
      });
 	}, 
    handleSelectAllAssets: function(component, event, helper) {
      var assetResult = JSON.parse (JSON.stringify(component.get("v.Step1Result")));
      var assets = assetResult.assetWrapper;
      var i;
      var allSelected = component.get("v.isSelectAllAssets");
        for(i=0;i<assets.length;i++){
            assets[i].selected = allSelected;
        }
        //Set back component.set to make it relect on UI...
        component.set("v.Step1Result",assetResult);
   },
    applyFilter: function(component, event, helper){
        helper.setStepDetails(component, component.get("v.stepNumber"), false);
    },
    onCheckboxChange : function(component, event, helper) {
        //Gets the checkbox group based on the checkbox id
		var availableCheckboxes = component.find('checkAccount');
        var resetCheckboxValue  = false;
        if (Array.isArray(availableCheckboxes)) {
            //If more than one checkbox available then individually resets each checkbox
            availableCheckboxes.forEach(function(checkbox) {
                checkbox.set('v.value', resetCheckboxValue);
            }); 
        } else {
            //if only one checkbox available then it will be unchecked
            availableCheckboxes.set('v.value', resetCheckboxValue);
        }
        //mark the current checkbox selection as checked
        event.getSource().set("v.value",true);
	}, 
    handleSelectAllCases: function(component, event, helper) {
      var caseResult = JSON.parse (JSON.stringify(component.get("v.Step2Result")));
      var cases = caseResult.caseWrapper;
      var i;
      var allSelected = component.get("v.isSelectAllCases");
        for(i=0;i<cases.length;i++){
            cases[i].selected = allSelected;
        }
        //Set back component.set to make it relect on UI...
        component.set("v.Step2Result",caseResult);
   },
    applyServiceAppointmentFilter: function(component, event, helper){
        helper.setStepDetails(component, component.get("v.stepNumber"), false);
    },
    handleAssetSearch: function(component, event, helper){
         helper.setStepDetails(component, component.get("v.stepNumber"), false);
    }, 
    /*Gets invoked on Enter Key Pressed in Searchbox*/
    onAssetSearchKeyUp: function(component, event, helper){
        //checks for "enter" key
        var vc = event.getParam('keyCode') ;
        console.log('Key ' + vc);
        if (event.getParam('keyCode')===13) {
            helper.setStepDetails(component, component.get("v.stepNumber"), false);
        }
    }
    
})