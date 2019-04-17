({
    /*Fetch articles based on Article Types and Data Category selection*/
	getArticles : function(component, strSearchString,strCategory, strParentCategory,strSelArticleTypes, initEvent, page, 
                           recordToDisply,urlCategory) {
        var numArticleSummaryChars = component.get("v.ArticleSummaryChars");
        var numOfRecords = component.get("v.LimitNumOfRowsFirstLoad");
        console.log('Keypress handled helper' );
        //Show spinner
        this.showSpinner(component);
        
        //Preapre to call Apex Controller
        var action = component.get("c.FetchArticles");
		action.setParams({ 
			searchVar : strSearchString,
			CategoryString : strCategory, 
            ParentCategory : strParentCategory,
            SelArticleTypes: strSelArticleTypes,
            RecordType : component.get("v.articletype"), 
            StrPageNumber : page.toString() ,
            StrRecordToDisply : recordToDisply.toString(),
            ArticleSummaryChars : numArticleSummaryChars.toString(),
            LimitNumOfRecords: numOfRecords.toString(),
            urlCategoryStr : urlCategory
		});
		
        action.setCallback(this, function(response){
            // hide spinner when response coming from server 
            this.hideSpinner(component);
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.ReturnedObject", response.getReturnValue());
                component.set("v.page", response.getReturnValue().page);
                if (response.getReturnValue().page == 1){
                    component.set("v.total", response.getReturnValue().total);
                    component.set("v.pages", Math.ceil(response.getReturnValue().total / recordToDisply));
                    component.set("v.SelectedCategory", strCategory);
                    component.set("v.ParentCategory", strParentCategory);
                    // US-0006257 Changes, Commented below line as "v.SelCategoryName" is getting set from controller.js
                    //component.set("v.SelCategoryName", strCategory.replace('__c', '').replace('_', ' '));              
                }
            }
            
            if (initEvent == 'Y'){
                //This section only execute as part of initial load 
                var action3 = component.get("c.getFilters");
                action3.setCallback(this, function(response){
                    var state = response.getState();
                    if(state === 'SUCCESS'){
                        //Get values for Data Category Tree
                        component.set('v.items', response.getReturnValue().DataCategories);
                        var categorylist =[];
                        var datacats =  response.getReturnValue().DataCategories;
                        
                        console.log('datalist>>>>>',datacats);
                       //Fetching Article Type Filters
                       var opts = [];
                       var ArTypes = response.getReturnValue().ArTyps;
                       for(var i=0;i<ArTypes.length;i++){
                            opts.push({
                                label: ArTypes[i],
                                value: ArTypes[i]
                            });
                        }
                       component.set("v.options",opts);
                        
                       var isURLPassed = component.get("v.isUrlPassed");
                       if (isURLPassed == true)
                           component.set("v.value", component.get("v.urlArticletype"));
                       
                    }
                    else{
                        alert('Error has occured, please contact system administrator.');
                    }
             	});
                $A.enqueueAction(action3);    
			}
        });
        $A.enqueueAction(action);
	}, 
    
    /*Displays spinner on the action invoke*/
    showSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
	
    /*Hides spinner on the action completions*/
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    }
    
})