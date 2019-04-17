		
		 /*$(document).ready(function()
				{
					if ($.fn.DataTable.isDataTable( '.display' ) ) return;
					
					$('.display').DataTable({
	                        bsortable : true,
	                        deferRender: true,
	                        bJQueryUI: true
	                });
	                console.log('======HELLO====READY====');
	                
				});*/
				                      
                function buttonsEnabled(enabled) {
               		console.log('======inside enable========');
                    //var $buttons = jQuery(document.getElementById('{!$Component.cmdId}'));
                    var $buttons = jQuery(document.getElementsByClassName('cmdbutton'));
                    if (enabled === false) {
                        $buttons.toggleClass('btnDisabled', true).attr('disabled', 'disabled');
                    } else {
                        $buttons.toggleClass('btnDisabled', false).attr('disabled', null);
                    } 
                    
                }
				
        var curPopupWindow;
        /*function openMemoPopup(userType)
        {
            console.log('==elLength======',document.getElementById('imgId'));
            buttonsEnabled(true);
            if(curPopupWindow == null)
            { 
                if(userType == 'EXRep') {
                    var likeString = document.getElementById('{!$Component.formId.pgblock.pbsId.existingRepsId}').value;
                }
                else if(userType == 'NewRep'){
                    var likeString = document.getElementById('{!$Component.formId.pgblock.pbsId.newReps}').value;
                }
                
                console.log('==likeString======',likeString);
                var strUserType;
                var url = "/apex/SL_CustomLookup?likestring="+likeString+"&sObjectType=User"+"&strUserType="+ userType;
                openWind(url);
            }
            else
            {
                curPopupWindow.close();
                curPopupWindow = null;
            }
            return false; 
        }
            
        function openWind(URL)
        {
            curPopupWindow  = window.open(URL, "_blank","width=500, height=550,dependent=no,toolbar=no,status=no,directories=no,menubar=no,scrollbars=1,resizable=no", true);               
        }
          curPopupWindow = null;
             
        function userDetails(Id,userType,Name)
        {   
            console.log('=inuserdetails===');
            var UserName;
            var UserNameNew;
            var inputHid;
            if(userType == 'EXRep') {
                
                UserName = document.getElementById('{!$Component.formId.pgblock.pbsId.existingRepsId}');
                UserName.value = Name;
                console.log('==UserName al======',document.getElementById('{!$Component.formId.pgblock.pbsId.existingRepsId}').value);
                
                existingReps(Id);
            }
            if(userType == 'NewRep') {
                
                UserNameNew = document.getElementById('{!$Component.formId.pgblock.pbsId.newReps}');
                UserNameNew.value = Name;
                
                inputHid = document.getElementById('{!$Component.formId.pgblock.pbsId.theHiddenInput}');
                inputHid.value = Id;
                console.log('====inputHid.value====',inputHid.value);
            }
            
            curPopupWindow.close();
            curPopupWindow = null;
            
        }
        
            
        function refresh(){
            buttonsEnabled(false);
            var string = document.getElementById('{!$Component.formId.pgblock.showmsg}').innerText;
            if(string =='') {
               var UserNameToRefresh = document.getElementById('{!$Component.formId.pgblock.pbsId.newReps}');
               UserNameToRefresh.value = '';
            }
            if ($.fn.DataTable.isDataTable( '.display' ) ) return;
            $('.display').DataTable({
                    bsortable : true,
                    bJQueryUI: true
            });
	       console.log('==========inrefresh====dtable===');
        }
        
        function refresh2(){
            
            var ExUserNameToRefresh = document.getElementById('{!$Component.formId.pgblock.pbsId.existingRepsId}');
            ExUserNameToRefresh.value = '';
            
            var NewUserNameToRefresh = document.getElementById('{!$Component.formId.pgblock.pbsId.newReps}');
            NewUserNameToRefresh.value = '';
            
            if ($.fn.DataTable.isDataTable( '.display' ) ) return;
            $('.display').DataTable({
                bsortable : true,
                deferRender: true,
                bJQueryUI: true
            });
            console.log('==========inrefresh2=====dt===');
            
        }*/
        window.onload = function() {
          buttonsEnabled(false);
        };
            
    
        function callSearch(Id,UserType,e)
		{
			var checkEvent = e;
			if(checkEvent.keyCode == 13)
			{
				openMemoPopup(UserType);
				return false;  
			}
		} 
		
        function selectAllCheckboxes(obj,receivedInputID){
            buttonsEnabled(true);
            var inputCheckBox = document.getElementsByTagName("input");                  
            for(var i=0; i<inputCheckBox.length; i++){          
                if(inputCheckBox[i].id.indexOf(receivedInputID)!=-1){                                     
                    inputCheckBox[i].checked = obj.checked;
                }
            }
        }
        
        function convertdatatable(){
          console.log('======HELLO====convertdatatable====');  
            if ($.fn.DataTable.isDataTable( '.display' ) ) return;
					
					$('.display').DataTable({
	                        bsortable : true,
	                        deferRender: true,
	                        bJQueryUI: true
	                });
	                console.log('======END====convertdatatable====');
            
        }
       
   