@isTest
public class BoxGroupTests {
	public static testmethod void testDeleteGroup() {
    	String mockResponseBody = '{}';
    	Test.setMock(HttpCalloutMock.class, new BoxTestMockCallout(mockResponseBody, 'No Content', 204));
    	
    	BoxApiConnection api = new BoxApiConnection('accesstoken');
    	BoxGroup groupToDelete = new BoxGroup(api, '5000948880');
    	
    	Test.startTest();
    	Boolean deleteGroupResult = groupToDelete.deleteGroup();
    	Test.stopTest();
    	
    	System.assertEquals(true, deleteGroupResult);
    }
    
    public static testmethod void testGetGroup() {
    	String mockResponseBody = '{ "type": "group", "id": "255224", "name": "Everyone","created_at": "2014-09-15T13:15:35-07:00","modified_at": "2014-09-15T13:15:35-07:00"}';
    	Test.setMock(HttpCalloutMock.class, new BoxTestMockCallout(mockResponseBody, 'OK', 200));
    	
    	BoxApiConnection api = new BoxApiConnection('accesstoken');
    	BoxGroup groupToGet = new BoxGroup(api, '5000948880');
    	
    	Test.startTest();
    	BoxGroup.Info groupInfo = groupToGet.getGroup();
        //Added by Nikhil
        String mockResponseBody2 = '{"type":"folder","id":"11446498","sequence_id":"1","etag":"1","name":"Pictures","created_at":"2012-12-12T10:53:43-08:00","modified_at":"2012-12-12T11:15:04-08:00","description":"Some pictures I took","size":629644,"path_collection":{"total_count":1,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"}]},"created_by":{"type":"user","id":"17738362","name":"sean rose","login":"sean@box.com"},"modified_by":{"type":"user","id":"17738362","name":"sean rose","login":"sean@box.com"},"owned_by":{"type":"user","id":"17738362","name":"sean rose","login":"sean@box.com"},"shared_link":{"url":"https://www.box.com/s/vspke7y05sb214wjokpk","download_url":null,"vanity_url":null,"is_password_enabled":false,"unshared_at":null,"download_count":0,"preview_count":0,"access":"open","permissions":{"can_download":true,"can_preview":true}},"folder_upload_email":{"access":"open","email":"upload.Picture.k13sdz1@u.box.com"},"parent":{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},"item_status":"active","item_collection":{"total_count":1,"entries":[{"type":"file","id":"5000948880","sequence_id":"3","etag":"3","sha1":"134b65991ed521fcfe4724b7d814ab8ded5185dc","name":"tigers.jpeg"}],"offset":0,"limit":100}}';
    	BoxFolder.Info folderInfo = new BoxFolder.Info(mockResponseBody2);
        BoxGroup.Info emailAliasInfo3 = new BoxGroup.Info(folderInfo);
    	Test.stopTest();
    	
    	System.assertEquals('Everyone', groupInfo.getValue('name'));
    }
    
    public static testmethod void testCreate() {
    	String mockResponseBody = '{ "type": "group", "id": "255224", "name": "Everyone","created_at": "2014-09-15T13:15:35-07:00","modified_at": "2014-09-15T13:15:35-07:00"}';
    	Test.setMock(HttpCalloutMock.class, new BoxTestMockCallout(mockResponseBody, 'OK', 200));
    	
    	BoxApiConnection api = new BoxApiConnection('accesstoken');
    	
    	Test.startTest();
    	BoxGroup.Info groupInfo = BoxGroup.createGroup(api, 'Everyone');
    	Test.stopTest();
    	
    	System.assertEquals('Everyone', groupInfo.getValue('name'));
    }
    
    public static testmethod void testUpdate() {
    	String mockResponseBody = '{ "type": "group", "id": "255224", "name": "New Group Name","created_at": "2014-09-15T13:15:35-07:00","modified_at": "2014-09-15T13:15:35-07:00"}';
    	Test.setMock(HttpCalloutMock.class, new BoxTestMockCallout(mockResponseBody, 'OK', 200));
    	
    	BoxApiConnection api = new BoxApiConnection('accesstoken');
    	
    	Test.startTest();
    	BoxGroup.Info groupInfo = BoxGroup.updateGroup(api, 'New Group Name');
    	Test.stopTest();
    	
    	System.assertEquals('New Group Name', groupInfo.getValue('name'));
    }
}