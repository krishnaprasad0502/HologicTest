({
    doInit : function(component, helper) {
        var Approval = component.get('v.Approval');
         var FieldName = component.get('v.fieldName');
        var outputText = component.find("outputTextId");
        var QuoteLIne=component.get('v.QuoteLIne');
        if(Approval!='' && Approval!=null)
        {
             outputText.set("v.value",Approval[FieldName]);
            //component.set("v.Approval","");
        }
        else 
        {
            outputText.set("v.value",QuoteLIne[FieldName]);
        }
       
       
    }
})