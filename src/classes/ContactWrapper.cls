/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Wrapper class to display Contacts list with a checkbox    
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>       <Brief Description of Change>
    06/15/2017      Kasmoor Reddy        Initial Creation (US2752)
-----------------------------------------------------------------------------------*/
global class ContactWrapper {
  public Boolean isSelected {get;set;}
  public Contact cont{get;set;}        
    public ContactWrapper(Contact cont,Boolean isSelected)
    {
        this.cont= cont;
        this.isSelected= isSelected;
    }
}