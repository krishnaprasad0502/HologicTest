({
    /*Initialization of comppnent and setting default values*/
	doInit :  function(component, event, helper) {
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

        //set the src param value to my src attribute
        var id =  getUrlParameter('id');
        
        var action = component.get("c.FetchKnowledge");
        action.setParams({ 
            id : id
        });
		
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log(' data is:' + JSON.stringify(response.getReturnValue()));
                var obj = JSON.parse(JSON.stringify(response.getReturnValue()));
                console.log(obj.Link);
                component.set("v.title", obj.Title);
                component.set("v.summary", obj.Summary);
                //component.set ("v.link", obj.Link );
                component.set("v.link","https://app.box.com/embed/s/fq4hcyld2wfpxm6vs0cufepmg4dqaqaj?view=list&sortColumn=date");
                var Fields = [];
                Fields = obj.Fields;
                var htmlFieldString = '';
                for (var i=0; i<Fields.length; i++)
                {
                    var aField = Fields[i];
                    var aFieldObject = JSON.parse(JSON.stringify(aField));
                    var Label = aFieldObject.label;
                    var Value = aFieldObject.value;
                    var htmlString = '<div class="slds-border_bottom slds-p-top_small slds-p-bottom_small">' + Label + ': ' + Value + '</div>';
                    htmlFieldString =  htmlFieldString + htmlString;
                }
                component.set ("v.htmlFields", Fields);
            }
        });
        $A.enqueueAction(action);
	}
})