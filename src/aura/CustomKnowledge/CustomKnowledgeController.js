({
    /*function that reads the url parameters and fetches articles on load*/
    doInit : function(component, event, helper) {
        var strSelectedArticleTypes ='';
        var strCategory = '';
        var strParentCategory = '';
        var action = component.get('c.fetchConfigData'); 
       	action.setCallback(this, function(response) { 
        component.set("v.configSetting", response.getReturnValue());
           
       	});
		$A.enqueueAction(action);
        
        var getUrlParameter = function getUrlParameter(sParam){
            var sPageURL = decodeURIComponent(window.location.search.substring(1)),
                sURLVariables = sPageURL.split('&'),
                sParameterName,
                i;
            console.log('url is'+window.location.pathname);
            for (i = 0; i < sURLVariables.length; i++){
                sParameterName = sURLVariables[i].split('=');
                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                }
            }
        };
        
        var urlArtType = getUrlParameter('ArticleType');
        var urlCategory = getUrlParameter('category');
        if(urlCategory != '' && urlCategory != null){
            urlCategory = urlCategory.replace('+',' ');  
            component.set("v.SelCategoryName", urlCategory.replace('__c', '').replace('_', ' '));
            component.set("v.urlCategory", urlCategory);
            
        }
        
        if(urlArtType != '' && urlArtType != null){
            urlArtType = urlArtType.replace('+',' ');    
            component.set("v.urlArticletype", urlArtType);
            strSelectedArticleTypes = urlArtType;
            component.set("v.isUrlPassed", true);
        }
        
        var searchstr = getUrlParameter('searchtext');
        if(searchstr != '' && searchstr != null){
            searchstr = searchstr.replace('+',' ');
        }
        
        // Prepare Parameter for Helper Function Call
        var initEvent = 'Y';
        var page = component.get("v.page") || 1;
        var recordToDisply = component.get("v.numofrecordsonpage");
        var strSearchString ;
        if(searchstr != '' && searchstr != null){
            strSearchString = searchstr;
        }else{
            strSearchString = component.get("v.searchKeyword");
        }
        component.set("v.DisplayTitle", true);
        
        //Call Helper Function
        helper.getArticles(component, strSearchString,strCategory,strParentCategory,strSelectedArticleTypes, initEvent, page, recordToDisply,urlCategory);
    }, 
    
    /*Gets invoked on Search button click*/
    handleClick : function(component, event, helper) {
        // Prepare Parameter for Helper Function Call
        component.set("v.DisplayTitle", false);
        var initEvent = 'N';
        var strSearchString = component.get("v.searchKeyword");
        var page =  1;
        var recordToDisply = component.get("v.numofrecordsonpage");
        //Get Selected Data Category and it's parent
        var nodeName;
        var strCategory;
        var strParentCategory;
        var urlCategory = '';
        var strTreeCategory = component.get("v.selTreeNodeValue");
        var isURLPassed = component.get("v.isUrlPassed");
        if (isURLPassed == true)
            urlCategory = component.get("v.urlCategory");
        console.log('On Search selTreeNodeValue: ' + strTreeCategory);
        if (typeof(strTreeCategory) == 'undefined' && strTreeCategory == null){
            strCategory = '';
            strParentCategory = '';
        }else{
            nodeName = strTreeCategory.split("~");
            strCategory = nodeName[0];
            strParentCategory = nodeName[1];
        }
        
        //Get Selected Article Types
        var strSelArticleTypes = ''; 
        var str = [];
        str = component.get("v.value");
        strSelArticleTypes = str.join(','); 
        
        //Call Helper Function
        helper.getArticles(component, strSearchString,strCategory,strParentCategory,strSelArticleTypes, initEvent,  page, recordToDisply,urlCategory);
    }, 
    /*Gets invoked on Enter Key Pressed in Searchbox*/
    onKeyUp: function(component, event, helper){
        //checks for "enter" key
        var vc = event.getParam('keyCode') ;
        //console.log('Key ' + vc);
        if (event.getParam('keyCode')===13) {
            component.set("v.DisplayTitle", false);
            var initEvent = 'N';
            var strSearchString = component.get("v.searchKeyword");
            var page =  1;
            var recordToDisply = component.get("v.numofrecordsonpage");
            //Get Selected Data Category and it's parent
            var nodeName;
            var strCategory;
            var strParentCategory;
            var urlCategory = '';
            var strTreeCategory = component.get("v.selTreeNodeValue");
            var isURLPassed = component.get("v.isUrlPassed");
            if (isURLPassed == true)
                urlCategory = component.get("v.urlCategory");
            //console.log('On Search selTreeNodeValue: ' + strTreeCategory);
            if (typeof(strTreeCategory) == 'undefined' && strTreeCategory == null){
                strCategory = '';
                strParentCategory = '';
            }else{
                nodeName = strTreeCategory.split("~");
                strCategory = nodeName[0];
                strParentCategory = nodeName[1];
            }
            
            //Get Selected Article Types
            var strSelArticleTypes = ''; 
            var str = [];
            str = component.get("v.value");
            strSelArticleTypes = str.join(','); 
            
            //Call Helper Function
            helper.getArticles(component, strSearchString,strCategory,strParentCategory,strSelArticleTypes, initEvent,  page, recordToDisply,urlCategory);
        }
    },
    /*Gets invoked on the Data Category selection*/
    handleSelect : function(component, event, helper) {
        // Prepare Parameter for Helper Function Call
        component.set("v.DisplayTitle", false);
        var initEvent = 'N';
        var strSearchString = component.get("v.searchKeyword");
        //Reset Page to 1 when clicked on Tree
        var page = 1;
        var recordToDisply = component.get("v.numofrecordsonpage");        
        //Get Selected Data Category and it's parent
        var nodeName;
        var strCategory;
        var strParentCategory;
        var urlCategory ='';
        // US-0006257 Changes, Added variable strCategoryLabel to fetch category label
		var strCategoryLabel;
        var strTreeCategory = event.getParam('name');
        //store data category tree node value, when filter is cleared it will be set to blank
        component.set("v.selTreeNodeValue", strTreeCategory);
        var isURLPassed = component.get("v.isUrlPassed");
        if (isURLPassed == true)
            urlCategory = component.get("v.urlCategory");
        //console.log('set value for selTreeNodeValue:' + strTreeCategory);
        if (typeof(strTreeCategory) == 'undefined' && strTreeCategory == null){
            strCategory = '';
            strParentCategory = '';
            strCategoryLabel = '';
        }else{
            //console.log('Tree Clicked:' + strTreeCategory);
            nodeName = strTreeCategory.split("~");
            strCategory = nodeName[0];
            strParentCategory = nodeName[1];
            // US-0006257 Changes, Assign Category Label to strCategoryLabel and set to "v.SelCategoryName"
            strCategoryLabel = nodeName[2];
            component.set("v.SelCategoryName", strCategoryLabel);    
            component.set("v.urlCategory", '');
        }       
        
        //Get Selected Article Types
        var strSelArticleTypes = ''; 
        var str = [];
        str = component.get("v.value");
        strSelArticleTypes = str.join(',');  
        //Call Helper Function
        helper.getArticles(component, strSearchString,strCategory,strParentCategory,strSelArticleTypes, initEvent,  page, recordToDisply,urlCategory);
    },
    
    /*Navigations*/
    navigate: function(component, event, helper) {
        // Prepare For Navigation  
        var page = component.get("v.page") || 1;
        var direction = event.getSource().get("v.label");
        var recordToDisply = component.get("v.numofrecordsonpage");
        var urlCategory = '';
        // set the current page  
        page = direction === "Prev" ? (page - 1) : (page + 1);
        var initEvent = 'N';
        var strSearchString = component.get("v.searchKeyword");
        var recordToDisply = component.get("v.numofrecordsonpage");
        
        //Get Selected Data Category and it's parent
        var nodeName;
        var strCategory;
        var strParentCategory;
        var strTreeCategory = component.get("v.selTreeNodeValue");
        var isURLPassed = component.get("v.isUrlPassed");
        if (isURLPassed == true)
            urlCategory = component.get("v.urlCategory");
        if (typeof(strTreeCategory) == 'undefined' && strTreeCategory == null){
            strCategory = '';
            strParentCategory = '';
        }else{
            nodeName = strTreeCategory.split("~");
            strCategory = nodeName[0];
            strParentCategory = nodeName[1];
        }
        
        //Get Selected Article Types
        var strSelArticleTypes = ''; 
        var str = [];
        str = component.get("v.value");
        strSelArticleTypes = str.join(',');
        // call the helper function
        helper.getArticles(component, strSearchString, strCategory, strParentCategory,strSelArticleTypes, initEvent, page, recordToDisply,urlCategory);
    }, 
    
    /*Gets invoked when filters are removed each time*/
    clearFilter : function(component, event, helper) {
        //Clear Category Filter
        component.set("v.SelectedCategory",'');
        component.set("v.ParentCategory",'');
        component.set("v.SelCategoryName", '');
        component.set("v.urlCategory", '');
        component.set("v.selTreeNodeValue", '');
        var initEvent = 'N';
        var strSearchString = component.get("v.searchKeyword");
        //Set Data Category and it's parent value to blank
        var strCategory = '';
        var strParentCategory = '';
        //Reset Page when Clicked on Search       
        var page =  1;
        var recordToDisply = component.get("v.numofrecordsonpage");               
        //Get Selected Article Types
        var strSelArticleTypes = ''; 
        var str = [];
        str = component.get("v.value");
        strSelArticleTypes = str.join(',');
        // call the helper function
        helper.getArticles(component, strSearchString,strCategory,strParentCategory,strSelArticleTypes, initEvent,  page, recordToDisply,'');
    }, 
    
    /*Gets invoked on the Article Type selection*/
    handleArticleTypeSelection : function(component, event, helper) {
        //Prepare to call Controller 
        component.set("v.DisplayTitle", false);
        var initEvent = 'N';
        var strSearchString = component.get("v.searchKeyword");
        //Reset Page to 1 when clicked
        var page = 1;
        var recordToDisply = component.get("v.numofrecordsonpage");
        //Get Selected Data Category and it's parent
        var nodeName;
        var strCategory;
        var strParentCategory;
        var urlCategory = '';
        var strTreeCategory = component.get("v.selTreeNodeValue");
        var isURLPassed = component.get("v.isUrlPassed");
        if (isURLPassed == true)
            urlCategory = component.get("v.urlCategory"); 
        //console.log('Data Category Already Selected: ' + strTreeCategory);
        if (typeof(strTreeCategory) == 'undefined' && strTreeCategory == null){
            strCategory = '';
            strParentCategory = '';
        }
        else{
            nodeName = strTreeCategory.split("~");
            strCategory = nodeName[0];
            strParentCategory = nodeName[1];
        }
        
        //Get Selected Article Types
        var strSelArticleTypes;
        var str = [];
        str = component.get("v.value");
        strSelArticleTypes = str.join(','); 
        //console.log('selected articles: ' + str + ' strCategory: ' + strCategory);
        //Call the helper function
        helper.getArticles(component, strSearchString,strCategory,strParentCategory, strSelArticleTypes, initEvent,  page, recordToDisply,urlCategory);
    }
})