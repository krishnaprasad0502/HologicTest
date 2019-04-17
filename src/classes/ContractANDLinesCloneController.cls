/**
    ClassName : ContractANDLinesCloneController
    Version: 1.0
**/
public with sharing class ContractANDLinesCloneController {
    
//standard controller for the record
private ApexPages.StandardController m_controller;
    
//to store value of header record
public ServiceContract m_sc1{get; set;}
   
//to store the records of the ContractLineItem object which will be deleted from database
private List<ContractLineItem> m_listOfDeletedObj2Lines;
    
//to store the list of Child Lines
public List<ConLineWrapper> ListOfConLineLines{get; set;}
    
//constructor
public ContractANDLinesCloneController(ApexPages.StandardController controller) {
        
m_controller = controller;
        
//assigning record
m_sc1 = (ServiceContract )m_controller.getRecord();
        
//if no instance exist then creating instance of deleteList
        
if(m_listOfDeletedObj2Lines == null)
m_listOfDeletedObj2Lines = new List<ContractLineItem>();
            
//when initially its null then assign it
        
if(ListOfConLineLines == null) {
            
//create instance of ContractLineItem
ListOfConLineLines = new List<ConLineWrapper>();
            
            
//getting from database and adding to wrapper list
 
for(ContractLineItem  obj2ln: [Select Asset_Created__c, AssetId, Asset.Name, Bill_To_Site_Location__c, Contract_Activated__c, Covered_Asset__c, CurrencyIsoCode, Description, Discount, EndDate, Final_Refund_Amount__c, Id, Install_Base_Instance_ID__c, Invoice_Text__c, LineItemNumber, ListPrice, Oracle_Contract_Line_ID__c,  Original_End_Date__c, ParentContractLineItemId, Preventative_Maintenance_Contact__c, PricebookEntryId, PricebookEntry.Name, Primary_Contact__c, Prorated_Amount__c, Quantity, Refund_Amount__c, SBQQSC__Account__c, SBQQSC__AdditionalDiscountAmount__c, SBQQSC__Quantity__c, ServiceContractId, Ship_To_Site_Location__c, StartDate, Status, Subtotal, Suppress_Credit__c, TotalPrice, Type__c, UnitPrice From ContractLineItem where ServiceContractId = :m_sc1.Id ]) 
                ListOfConLineLines.add(new ConLineWrapper(obj2ln));
        }
    }
    
    //to save header data
public void save() {
        try {
            //updating header data
            update m_sc1;
        }
        catch(Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    //to save both child and header data
public PageReference saveHeaderAndChild() {
        try {
            
//insert header
system.debug('m_sc1 Account = ' + m_sc1.AccountId);
system.debug('m_sc1 Start Date = ' + m_sc1.StartDate);
system.debug('m_sc1 End Date = ' + m_sc1.EndDate);
system.debug('m_sc1 Id  = ' + m_sc1.Id);


Date today = system.today();
           
ServiceContract ob2 = new ServiceContract();

ob2.Name = m_sc1.Name;    
ob2.AccountId = m_sc1.AccountId;    
ob2.StartDate = m_sc1.StartDate;    
ob2.EndDate = m_sc1.EndDate;    
ob2.Pricebook2Id = '01s61000003U25D';
ob2.ApprovalStatus = 'Draft';
ob2.Renewed_From_Service_Contract__c = m_sc1.Id;
ob2.Bill_To_Account__c = m_sc1.Bill_To_Account__c;
ob2.Ship_To_Account__c = m_sc1.Ship_To_Account__c;

ob2.Bill_To_Site_Location__c = m_sc1.Bill_To_Site_Location__c;
ob2.Ship_To_Site_Location__c = m_sc1.Ship_To_Site_Location__c;
ob2.Contract_Source__c = m_sc1.Contract_Source__c;
ob2.Transaction_Type__c = m_sc1.Transaction_Type__c;
ob2.Payment_Term__c = m_sc1.Payment_Term__c;
ob2.PO_Number__c = m_sc1.PO_Number__c; 
ob2.Contract_Group__c = m_sc1.Contract_Group__c; 
ob2.Accounting_Rule__c = m_sc1.Accounting_Rule__c;
ob2.Invoicing_Rule__c = m_sc1.Invoicing_Rule__c;
ob2.Operating_Unit__c = m_sc1.Operating_Unit__c;
ob2.Internal_Contact__c = m_sc1.Internal_Contact__c;          
ob2.Description = m_sc1.Description;
insert ob2;

system.debug('Ob2 Id = ' +ob2.Id);            
            
//to store for upsert
List<ContractLineItem> listOfObj2LinesToUpdate = new List<ContractLineItem>();

List<ContractLineItem> contractLineListInsert1 = new List<ContractLineItem>();

// Scrolling through the lines.

for(ConLineWrapper obj2LinesWrapper : ListOfConLineLines){

system.debug('obj2LinesWrapper.obj2Line = ' + obj2LinesWrapper.obj2Line);
if (obj2LinesWrapper.selected == TRUE){
ContractLineItem cl1 = new ContractLineItem();

cl1.ServiceContractId = ob2.Id;
cl1.AssetId = obj2LinesWrapper.obj2Line.AssetId;
cl1.UnitPrice = obj2LinesWrapper.obj2Line.UnitPrice;
cl1.PricebookEntryId = obj2LinesWrapper.obj2Line.PricebookEntryId;
cl1.Quantity = obj2LinesWrapper.obj2Line.SBQQSC__Quantity__c;
cl1.SBQQSC__Quantity__c = obj2LinesWrapper.obj2Line.Quantity;
cl1.StartDate = obj2LinesWrapper.obj2Line.StartDate;
cl1.EndDate = obj2LinesWrapper.obj2Line.EndDate;

contractLineListInsert1.add(cl1);
}
}

if(contractLineListInsert1.size()>0) insert contractLineListInsert1;
            
//deleting lines from database
delete m_listOfDeletedObj2Lines;
            
//re-initializing delete list
            
m_listOfDeletedObj2Lines = new List<ContractLineItem>();
  
PageReference scPage = new PageReference('/'+ob2.Id);
scPage.setRedirect(true);
return scPage;          
}
        catch(Exception e)
        {
            ApexPages.addMessages(e);
            return null;
        }
    }
    
  /*  
//to save child data
public void saveChildLines() {
        //to store Lines for upsert
        List<ContractLineItem> listOfObj2LinesToUpdate = new List<ContractLineItem>();
        
        try {
            //getting the line items records
            for(ConLineWrapper obj2LinesWrapper : ListOfConLineLines)
                listOfObj2LinesToUpdate.add(obj2LinesWrapper.obj2Line);
            
            //upserting lines
            upsert listOfObj2LinesToUpdate;
            
            //deleting lines from database
            delete m_listOfDeletedObj2Lines;
            
            //re-initializing delete list
            m_listOfDeletedObj2Lines = new List<ContractLineItem>();
        } catch(Exception e) {
            ApexPages.addMessages(e);
        }
    }
 */   
    
//method to add Line to Apex Page
/*
public void addLine() {
        ListOfConLineLines.add(new ConLineWrapper(new ContractLineItem(ServiceContractId= m_sc1.Id)));
    }
    
    //method to delete child lines from Apex Page
    public void deleteChildLines() {
        //to store the lines which are not selected
        List<ConLineWrapper> newListOfConLineLines = new List<ConLineWrapper>();
        
        try {
            //getting selected lines and adding them to delete list and not selected lines to new List
            for(ConLineWrapper obj2LinesWrapper : ListOfConLineLines) {
                if(obj2LinesWrapper.selected == true) {
                    if(obj2LinesWrapper.obj2Line.Id != null)
                        m_listOfDeletedObj2Lines.add(obj2LinesWrapper.obj2Line);
                }
                else
                    newListOfConLineLines.add(obj2LinesWrapper);
            }
            
            //assigning new list to our WrapperLineList
            ListOfConLineLines = newListOfConLineLines;
        }
        catch(Exception e)
        {
            ApexPages.addMessages(e);
        }
    }
*/    
    //method to set all child lines to yes
 /*   
public void setAllChildLinesToYes() {
        //getting selected lines and adding them to update list 
        for(ConLineWrapper obj2LinesWrapper : ListOfConLineLines) {
            //setting to Yes
            if(obj2LinesWrapper.selected == true)
                obj2LinesWrapper.obj2Line.Business_Process__c = 'Yes';
        }
    }
*/
    
    //wrapper class for ContractLineItem object
    
public class ConLineWrapper {
        
   public ContractLineItem obj2Line {get; set;}
   public Boolean selected {get; set;}
        
        public ConLineWrapper(ContractLineItem obj2ln) {
            obj2Line = obj2ln;
            selected = false;
        }
    }
}