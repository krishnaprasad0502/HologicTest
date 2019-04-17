@IsTest
public class BoxUploadEmailTests {
   public static testmethod void testParseAccess() {
    System.assertEquals(BoxUploadEmail.Access.OPEN, BoxUploadEmail.parseAccess('open'));
    System.assertEquals(BoxUploadEmail.Access.COLLABORATORS, BoxUploadEmail.parseAccess('collaborators'));
   }
     
    public static testmethod void testGetAccessAsString() {
    System.assertEquals('open', BoxUploadEmail.getAccessAsString(BoxUploadEmail.Access.OPEN));
    System.assertEquals('collaborators', BoxUploadEmail.getAccessAsString(BoxUploadEmail.Access.COLLABORATORS));
    }
    
    public static testmethod void testParseMember() {
        BoxApiConnection api = new BoxApiConnection('accesstoken');
		BoxUploadEmail uploadEmail = new BoxUploadEmail(api,'10543463');
		BoxUploadEmail.Info uploadEmailInfo = new BoxUploadEmail.Info();
				
		Test.startTest();
		uploadEmailInfo.parseMember('access', 'open');
	    uploadEmailInfo.parseMember('email', 'test@box.com');
        Test.stopTest();

		System.assertEquals(BoxUploadEmail.Access.OPEN, uploadEmailInfo.access);
		System.assertEquals('test@box.com', uploadEmailInfo.email);		
        
        //Added by Nikhil - Hexaware
        String mockResponseBody2 = '{"type":"folder","id":"11446498","sequence_id":"1","etag":"1","name":"Pictures","created_at":"2012-12-12T10:53:43-08:00","modified_at":"2012-12-12T11:15:04-08:00","description":"Some pictures I took","size":629644,"path_collection":{"total_count":1,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"}]},"created_by":{"type":"user","id":"17738362","name":"sean rose","login":"sean@box.com"},"modified_by":{"type":"user","id":"17738362","name":"sean rose","login":"sean@box.com"},"owned_by":{"type":"user","id":"17738362","name":"sean rose","login":"sean@box.com"},"shared_link":{"url":"https://www.box.com/s/vspke7y05sb214wjokpk","download_url":null,"vanity_url":null,"is_password_enabled":false,"unshared_at":null,"download_count":0,"preview_count":0,"access":"open","permissions":{"can_download":true,"can_preview":true}},"folder_upload_email":{"access":"open","email":"upload.Picture.k13sdz1@u.box.com"},"parent":{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},"item_status":"active","item_collection":{"total_count":1,"entries":[{"type":"file","id":"5000948880","sequence_id":"3","etag":"3","sha1":"134b65991ed521fcfe4724b7d814ab8ded5185dc","name":"tigers.jpeg"}],"offset":0,"limit":100}}';
    	BoxFolder.Info folderInfo = new BoxFolder.Info(mockResponseBody2);
        BoxUploadEmail.Info emailAliasInfo3 = new BoxUploadEmail.Info(folderInfo);
        emailAliasInfo3.addValue('name', 'Tv Enterprise');
        emailAliasInfo3.addValue('name', folderInfo);
    }
     
}