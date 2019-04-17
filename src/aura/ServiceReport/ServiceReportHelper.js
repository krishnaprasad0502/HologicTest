({
    readURLParameter : function(component){
        //Note we are !!! not !!! reading page URL directly, its the URL of iframe in component - ServiceReportVFContainerCommComp
        var getUrlParameter = function getUrlParameter(sParam) {
            var sPageURL = decodeURIComponent(window.location.search.substring(1)),
                sURLVariables = sPageURL.split('&'),
                sParameterName,
                i;
            
            for (i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('=');
                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                }
            }
        };
        //Get paramter passed to URL 
        //ID can be of Account or Asset 
        //Possible Values for RecordType - Customer and Site
        var objectId = getUrlParameter('Id');
        var recordType = getUrlParameter('RecordType');
        var reportType = getUrlParameter('ReportType');
        
        component.set("v.id", objectId);
        component.set("v.recordType", recordType);
        component.set("v.reportType", reportType);        
        var ID = component.get("v.id");
        if (reportType == 'History'){
            component.set("v.reportTitle", 'Generate Service History Report');
            component.set("v.filterObject", 'Cases');
            //No ID passed and its Service History call so set the first and last step number
            if( ID == 'BLANK') { 
                component.set("v.stepNumber", 0); //Start with Account
                component.set("v.firstStepNumber", 0); //No back Button
                component.set("v.lastStepNumber", 3); //Last Step where Report will be generated and no next button
            }
            else
            {
               component.set("v.stepNumber", 2); //Start with Cases
               component.set("v.firstStepNumber", 2); //No back Button
               component.set("v.lastStepNumber", 3); //Case Selection and with next button for report generation
            }
        }
        else if (reportType == 'FieldService'){
            //In case of Field Service Report Sequence of steps from quick link on home page - Accounts -> Assets -> Service Appointments
            component.set("v.reportTitle", 'Generate Field Service Report (FSR)');
            component.set("v.filterObject", 'Service Appointments');
            if( ID == 'BLANK') {
                component.set("v.stepNumber", 0); //Start with Account
                component.set("v.firstStepNumber", 0); //No back Button
                component.set("v.lastStepNumber", 2); //Links to SA and no next button
            }
            else{ //In case of assets - we will skip 2 steps (Account and Asset selection)
                component.set("v.stepNumber", 2); //Start with Service Appointment
                component.set("v.firstStepNumber", 2); //No back Button
                component.set("v.lastStepNumber", 2); //Links to SA and no next button
            }
        }
    },
    setStepDetails : function( component, stepNumber, backPressed) {
        var singleAssetFetch = false;  
        component.set("v.validationError",'');
        switch (stepNumber)
        {
                //Account Selection
            case 0: 
                component.set("v.isOpen", true);
                component.set("v.isStep0", true);
                component.set("v.isStep1", false);
                component.set("v.isStep2", false);
                component.set("v.isStep3", false);
                component.set("v.stepTitle", 'Select Account'); 
                if (backPressed != true)
               		 this.getAccountData(component);
                 else {
                     component.set("v.numOfRows", component.get("v.numOfRowsAccount"));
                }
                break;
                //Asset Selection      
            case 1:
                component.set("v.isStep0", false);
                component.set("v.isStep1", true);
                component.set("v.isStep2", false);
                component.set("v.isStep3", false);
                component.set("v.stepTitle", 'Select Asset');
                if (backPressed != true)
                	this.getAssetData(component);
                else 
                    component.set("v.numOfRows", component.get("v.numOfRowsAsset"));
                    
                break;  
                //Cases Selection Or Service Orders list
            case 2:
                component.set("v.isStep0", false);
                component.set("v.isStep1", false);
                component.set("v.isStep2", true);
                component.set("v.isStep3", false);
                component.set("v.stepTitle", 'Filter & Select ' + component.get("v.filterObject") );
                if (backPressed != true)
                {
                var ID = component.get("v.id");                
                    if (component.get("v.reportType") == 'History'){
                        if (ID.substring(0, 3) !== '02i')
                        {
                            singleAssetFetch = false;
                            this.getCaseDetails(component, singleAssetFetch);
                        }
                        else
                        {
                            singleAssetFetch = true;
                            this.getCaseDetails(component, singleAssetFetch);
                        }
                        component.set("v.stepTitle", 'Filter & Select Closed Cases');
                    }
                else 
                    
                    if (component.get("v.reportType") == 'FieldService' && ID.substring(0, 3) !== '02i')
                    {
                        
                        singleAssetFetch = false;
                        this.getSADetails(component, singleAssetFetch);
                    }
                    else 
                    {
                        singleAssetFetch = true;
                        this.getSADetails(component,singleAssetFetch);
                    }
                   }
                else 
                {
                    if (component.get("v.reportType") == 'History')
                        component.set("v.numOfRows", component.get("v.numOfRowsCase"));
                    else
                    	component.set("v.numOfRows", component.get("v.numOfRowsSA"));
                }
                break;
                //Final Step - Prepare WO and show option to download report
            case 3:
                component.set("v.isStep0", false);
                component.set("v.isStep1", false);
                component.set("v.isStep2", false);
                component.set("v.isStep3", true);
                component.set("v.stepTitle", 'Generate Report');
                var ID = component.get("v.id");
                if (backPressed != true)
                {
                if (ID.substring(0, 3) !== '02i')
                {
                    singleAssetFetch = false;
                	this.getWODetails(component, singleAssetFetch);
                }
                else 
                {
                 	singleAssetFetch = true;
                	this.getWODetails(component, singleAssetFetch);   
                }
                }
                break;
        }
        
    },
    getAccountData : function( component) {
        //Show spinner
        this.showSpinner(component);
        var action = component.get("c.GetAccountData");
        action.setParams({ 
            
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var accResult = response.getReturnValue();
                component.set("v.Step0Result", accResult.accountWrapper);
                //console.log('Rows:' + accResult.accountWrapper.length );
                if (typeof accResult.accountWrapper !== 'undefined' || accResult.accountWrapper !== null) 
                {        
   				   component.set("v.numOfRows", accResult.accountWrapper.length);
                   component.set("v.numOfRowsAccount", accResult.accountWrapper.length);
				}
                var result = JSON.stringify(response.getReturnValue());
                this.hideSpinner(component);
            }
        });
        
        $A.enqueueAction(action);
    }, 
    getAssetData : function( component) {
        //Show spinner
        this.showSpinner(component);
        var selectedAccount ='';   
        var selectedAccRecordType ='';  
        var accountResult = JSON.parse (JSON.stringify(component.get("v.Step0Result")));
        var searchAssetText = component.get("v.searchAssetsKeyword");
        var i;
        //Prepare list of selected assets
        for(i=0;i<accountResult.length;i++){
            if (accountResult[i].selected == true)
            {    
                selectedAccount = accountResult[i].acc.Id;
                selectedAccRecordType = accountResult[i].acc.RecordType.Name;
                break;
            }
        }
         
        component.set("v.id",selectedAccount);   
        component.set("v.recordType",selectedAccRecordType);
        var sObjectId = component.get("v.id");     
        var sObjectRT = component.get("v.recordType");
        
        var action = component.get("c.GetAssetData");
        action.setParams({ 
            sObjectId : sObjectId,
            sObjectRT : sObjectRT, 
            searchAssetText: searchAssetText,
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var masResult = response.getReturnValue();
                component.set("v.Step1Result", masResult.mas);
                component.set("v.Step1ResultJSON", masResult.masterJSON);
                component.set("v.isSelectAllAssets", false);
                //Console.log('Rows' + masResult.mas.assetWrapper);
                if (typeof masResult.mas.assetWrapper !== 'undefined' || masResult.mas.assetWrapper !== null) {
					component.set("v.numOfRows", masResult.mas.assetWrapper.length);
                    component.set("v.numOfRowsAsset", masResult.mas.assetWrapper.length);                    
				}
                var result = JSON.stringify(response.getReturnValue());
                this.hideSpinner(component);
            }
        });
        
        $A.enqueueAction(action);
    }, 
    getCaseDetails : function(component, singleAssetFetch) {
        var selectedAssets =''; 
        var serviceStartDate;
        var serviceEndDate; 
        
        if (singleAssetFetch === false)
        {
            var assetResult = JSON.parse (JSON.stringify(component.get("v.Step1Result")));
            var assets = assetResult.assetWrapper;
            //Show spinner
            this.showSpinner(component);
            var i;
            //Prepare list of selected assets
            for(i=0;i<assets.length;i++){
                if (assets[i].selected == true)
                {
                    if (assets[i].asse.Id != 'undefined')
                    {
                        selectedAssets = selectedAssets + assets[i].asse.Id + ',';
                    }
                }
            }
            //Remove last comma
            var n = selectedAssets.lastIndexOf(",");
            selectedAssets=selectedAssets.substring(0,n); 
            //Validation -  If no assets were selected 
            if (selectedAssets == '')
            {
            	component.set("v.validationError", 'Please select assets before moving to next step.');
            	component.set("v.stepNumber", 1);
                component.set("v.isStep0", false);
                component.set("v.isStep1", true);
                component.set("v.isStep2", false);
                component.set("v.isStep3", false);
                this.hideSpinner(component);
            	return;
            }
        }
        else 
        {
            selectedAssets = component.get("v.id");
        }
        
        //Prepare Service Start and End Date 
        if (component.get("v.serviceStartDate") == null && component.get("v.serviceEndDate") == null)
        { //Set Dates - Start Date to 180 days back and End Date as Today's Date        
            var date = new Date();
            component.set("v.serviceEndDate", date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate());
            date.setDate(date.getDate() - 180);
            component.set("v.serviceStartDate", date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate());
        }
        //Prepare Start and End Date for Call to Server
        var stDate = component.get("v.serviceStartDate");
        var endDate = component.get("v.serviceEndDate");
        serviceStartDate = stDate.toString();
        serviceEndDate = endDate.toString();
        
        var action = component.get("c.GetCaseDetailsData");
        action.setParams({ 
            sObjectId : component.get("v.id"),
            sObjectRT : component.get("v.recordType"), 
            selectedAssets: selectedAssets, 
            serviceStartDate: serviceStartDate,
            serviceEndDate: serviceEndDate
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.Step2Result", response.getReturnValue());
                component.set("v.isSelectAllCases", false);
                if (typeof response.getReturnValue() !== 'undefined' || response.getReturnValue() !== null) {
					component.set("v.numOfRows", response.getReturnValue().length);
                    component.set("v.numOfRowsCase", response.getReturnValue().length);
				}
                var result = JSON.parse(JSON.stringify(response.getReturnValue()));
                //component.set("v.serviceStartDate", result.serviceStartDate);
                //component.set("v.serviceEndDate", result.serviceEndDate);
                this.hideSpinner(component);
            }
        });
        
        $A.enqueueAction(action);
        
        
    }, 
    getSADetails : function(component, singleAssetFetch) {
        var selectedAssets =''; 
        var serviceStartDate;
        var serviceEndDate; 
        var assetResult;
        var assets;
        var sPageURL = decodeURIComponent(window.location);
        var n = sPageURL.indexOf('/apex');
        var strBaseUrl = sPageURL.substring(0,n) + '/s/' ;
        component.set("v.serviceAppointmentPageURL", strBaseUrl);
        //Show spinner
        this.showSpinner(component);
        var i;
        if (singleAssetFetch)
        {
            selectedAssets = component.get("v.id");
        }
        else
        {
            
            assetResult = JSON.parse (JSON.stringify(component.get("v.Step1Result")));
            assets = assetResult.assetWrapper;
            //Prepare list of selected assets
            for(i=0;i<assets.length;i++){
                if (assets[i].selected == true)
                {
                    if (assets[i].asse.Id != 'undefined')
                    {
                       selectedAssets = selectedAssets + assets[i].asse.Id + ',';
                    }
                }
            }
            //Remove last comma
            var n = selectedAssets.lastIndexOf(",");
            selectedAssets=selectedAssets.substring(0,n);
            //Validation -  If no assets were selected 
            if (selectedAssets == '')
            {
            	component.set("v.validationError", 'Please select assets before moving to next step.');
            	component.set("v.stepNumber", 1);
                component.set("v.isStep0", false);
                component.set("v.isStep1", true);
                component.set("v.isStep2", false);
                component.set("v.isStep3", false);
                this.hideSpinner(component);
            	return;
            }
        }
        if (component.get("v.serviceStartDate") == null && component.get("v.serviceEndDate") == null)
        { //Set Dates - Start Date to 30 days back and End Date as Today's Date        
            var date = new Date();
            component.set("v.serviceEndDate", date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate());
            date.setDate(date.getDate() - 180);
            component.set("v.serviceStartDate", date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate());
        }
        //Prepare Start and End Date for Call to Server
        var stDate = component.get("v.serviceStartDate");
        var endDate = component.get("v.serviceEndDate");
        serviceStartDate = stDate.toString();
        serviceEndDate = endDate.toString();
        var action = component.get("c.GetSADetailsData");        
        action.setParams({ 
            sObjectId : component.get("v.id"),
            sObjectRT : component.get("v.recordType"), 
            selectedAssets: selectedAssets, 
            serviceStartDate: serviceStartDate,
            serviceEndDate: serviceEndDate
        });        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.Step2Result", response.getReturnValue());
                if (typeof response.getReturnValue() !== 'undefined' || response.getReturnValue() !== null) {
					component.set("v.numOfRows", response.getReturnValue().length);
                    component.set("v.numOfRowsSA", response.getReturnValue().length);
				}
                var result = JSON.parse(JSON.stringify(response.getReturnValue()));
                this.hideSpinner(component);
            }
        });
        $A.enqueueAction(action);
    },
    getWODetails : function(component, singleAssetFetch) {
        var selectedCases ='';         
        var caseResult = JSON.parse (JSON.stringify(component.get("v.Step2Result")));
        var cases = caseResult.caseWrapper;
        var i;
        //Show spinner
        this.showSpinner(component);
        
        //Prepare list of selected assets
        for(i=0;i<cases.length;i++){
            if (cases[i].selected == true)
            {
                selectedCases = selectedCases + cases[i].caseVal.Id + ',';
            }
        }
        //Remove last comma
        var n = selectedCases.lastIndexOf(",");
        selectedCases=selectedCases.substring(0,n); 
        //Validation -  If no cases were selected 
        if (selectedCases == '')
        {
            component.set("v.validationError", 'Please select cases before moving to next step.');
            component.set("v.stepNumber", 2);
            component.set("v.isStep0", false);
            component.set("v.isStep1", false);
            component.set("v.isStep2", true);
            component.set("v.isStep3", false);
            this.hideSpinner(component);
            return;
        }
        
        if (singleAssetFetch == false )
        {
        //Prepare list of Selected Assets 
        var assetResult = JSON.parse (JSON.stringify(component.get("v.Step1Result")));
        var assets = assetResult.assetWrapper;
        var i;
        var selectedAssets;
        //Prepare list of selected assets
        for(i=0;i<assets.length;i++){
            if (assets[i].selected == true)
            {
                if (assets[i].asse.Id != 'undefined')
                {
                    //console.log("assets[i].asse.Id: " + assets[i].asse.Id);
                    selectedAssets = selectedAssets + assets[i].asse.Id + ',';
                }
            }
        }
        //Remove last comma
        var n = selectedAssets.lastIndexOf(",");
        selectedAssets=selectedAssets.substring(0,n); 
        }
        else 
        {
            selectedAssets = component.get("v.id");
        }
        
        var action = component.get("c.GetWODetailsData");
        
        action.setParams({ 
            sObjectId : component.get("v.id"),
            sObjectRT : component.get("v.recordType"), 
            selectedCases : selectedCases,
            strCaseStepResult : JSON.stringify(component.get("v.Step2Result")),
            strAssetStepResult : component.get("v.Step1ResultJSON"),
            selectedAssets : selectedAssets,
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                //component.set("v.Step3Result", response.getReturnValue());
                component.set("v.Step3ResultJSON", response.getReturnValue());
                
                var result = JSON.parse(JSON.stringify(response.getReturnValue()));                
                //console.log("Step3Result:" + JSON.stringify(response.getReturnValue()) );
                this.hideSpinner(component);
            }
        });
        
        $A.enqueueAction(action);
        
    }, 
    selectAllAssets: function (component, event, helper) {
      var assetResult = JSON.parse (JSON.stringify(component.get("v.Step1Result")));
      var assets = assetResult.assetWrapper;
        var i;
        for(i=0;i<assets.length;i++){
            assets[i].selected = true;
        }
        //Set back component.set to make it relect on UI...
        component.set("v.Step1Result",assetResult);
    },
    showSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    }
    
    
})