/*--------------------------------------------------------------------------------------------------------------
Author:         Kasmoor Reddy
Company:        Apps Associates
Description:    Class which supports the VFPage 'GenerateEstimate' to generate the pdf document
                from the work order record.
Test Class:     GenerateEstimate_Test

History:
<Date>          <Authors Name>         <Brief Description of Change>
08/17/2017      Kasmoor Reddy          Initial Creation(US3314)
----------------------------------------------------------------------------------------------------------------*/
public with sharing class GenerateEstimate{
// Variable declaration
public WorkOrder parentWorkOrder { get; set; }
public WorkOrder WorkOrderDetails { get; set; }    
public date For_Date { get; set; }
public string Quote_Status { get; set; }
public string Address_City { get; set; }
public string Address_State { get; set; }
public String Address_Zip { get; set; }
public List<WorkOrderLineItem> WorkOrderLineItemlist { get; set; } 
public decimal totalcount {set;get;}   
public string contractnum {set;get;} 
public static string printtable {set;get;}
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Constructor for Variable initializion and fetching all the details of
                 work order and line items to generate the estimation pdf.
    Returns:     N/A
      
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    08/17/2017      Kasmoor Reddy             Initial Creation(US3314)
-----------------------------------------------------------------------------------*/

    public GenerateEstimate (ApexPages.StandardController stdController) {
        this.parentWorkOrder = (WorkOrder) stdController.getRecord();
        For_Date  =system.today();
        Quote_Status = 'New';
        totalcount=0;
        //getting the workorder details
        WorkOrderDetails = [select id,WorkOrderNumber,Contact.Name,Case.CaseNumber,Contact.Phone,Asset.Product2.Name,Asset.Product2.Description,Asset.Account.Parent.Name,Asset.Bill_To_Location__r.City__c,Asset.Bill_To_Location__r.State__c,Asset.Bill_To_Location__r.Zip_Code__c,Asset.SerialNumber,Asset.Customer_Account__r.AccountNumber,Entitlement.ServiceContract.ContractNumber,Entitlementid,Case.PO_Number__c,Description,(select id,Product2.Name,Description,Quantity,UnitPrice,TotalPrice,Product2.QuantityUnitOfMeasure,PricebookEntry.Product2.Name from WorkOrderLineItems where RecordTypeId =: GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Estimate') )  from WorkOrder  where id=: parentWorkOrder.id];
        
        if(WorkOrderDetails.Entitlementid != null){
            contractnum = WorkOrderDetails.Entitlement.ServiceContract.ContractNumber;
        }else{
            contractnum = 'No Contract';
        }
        Address_City = WorkOrderDetails.Asset.Bill_To_Location__r.City__c;
        Address_State = WorkOrderDetails.Asset.Bill_To_Location__r.State__c;
        Address_Zip = WorkOrderDetails.Asset.Bill_To_Location__r.Zip_Code__c;
        
        WorkOrderLineItemlist = new List<WorkOrderLineItem>();
        //getting the workorderlineitem details    
 
        for(WorkOrderLineItem woli:WorkOrderDetails.WorkOrderLineItems)
        {
            if(woli.TotalPrice != null || woli.TotalPrice == 0 ){
               totalcount+=woli.TotalPrice;
            }
            if(woli.Description == null || woli.Description == ''){
                woli.Description = ' ';
            }
            WorkOrderLineItemlist.add(woli);
        }
       getTableBody(WorkOrderLineItemlist);         
    }
    /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Constructing the htmltable body for the list of workorderlineitems to display
                 on visualforce page.
    Returns:     N/A
      
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    08/17/2017      Kasmoor Reddy             Initial Creation(US3314)
-----------------------------------------------------------------------------------*/
    public static void getTableBody(List<WorkOrderLineItem> WorkOrderLineItemlist){
    //creating the header to the table
    string tablehead='<tr align=\"center\"><td>Product</td><td>Description</td><td>UOM</td><td>Qty</td><td>Unit Price</td><td>Charge</td></tr>';
    string tablehead1='<tr align=\"center\" ><td>Product</td><td>Description</td><td>UOM</td><td>Qty</td><td>Unit Price</td><td>Charge</td></tr>';
    
    // setting the html body    
    String htmlBody = '';
    htmlBody+='<table border=\"1\" width=\"100%\">';
    htmlBody+=tablehead;

    integer i=0;
    integer temp=0;
    boolean addheader=false;
        for(WorkOrderLineItem  workorderitem: WorkOrderLineItemlist)
        {
               i++;
               if(i==7)
               {
                 addheader=true;
                 temp=i+10;
               }
               else if(temp==i)
               {
                 addheader=true;
                 temp=i+10;
               }
               if(addheader==true)
               {
                 htmlBody+='</table>';
                 htmlBody+='<table border=\"1\" style=\"page-break-before:always\" width=\"100%\">';
                 htmlBody+=tablehead1;
                 htmlBody+='<tr align=\"center\">';
                 
                 htmlBody+='<td>'+workorderitem.Product2.Name+'</td>';
                 htmlBody+='<td>'+workorderitem.Description+'</td>';
                 htmlBody+='<td>'+workorderitem.PricebookEntry.Product2.Name+'</td>';
                 htmlBody+='<td>'+workorderitem.Quantity+'</td>';
                 htmlBody+='<td>'+workorderitem.UnitPrice+'</td>';
                 htmlBody+='<td>'+workorderitem.TotalPrice+'</td>';
                 htmlBody+='</tr>';
                 addheader=false;
               }
               else
               {
                  htmlBody+='<tr align=\"center\">';
                  
                  htmlBody+='<td>'+workorderitem.Product2.Name+'</td>';
                  htmlBody+='<td>'+workorderitem.Description+'</td>';
                  htmlBody+='<td>'+workorderitem.PricebookEntry.Product2.Name+'</td>';
                  htmlBody+='<td>'+workorderitem.Quantity+'</td>';
                  htmlBody+='<td>'+workorderitem.UnitPrice+'</td>';
                  htmlBody+='<td>'+workorderitem.TotalPrice+'</td>';
                  htmlBody+='</tr>';
               }
        }

    htmlBody+='</table>';
    printtable=htmlBody;
    }
 
 }