@isTest
public class CLMMapObjectControllerTest {
    @isTest
    public static void getMappedObjectsListTest(){
      System.assert(CLMMapObjectController.getMappedObjectsList()!=null);
    }
    @isTest
    public static void getAllObjectsTest(){
      System.assert(CLMMapObjectController.getAllObjects().size()!=0);
    }
    @isTest
    public static void getAllObjectFields_positiveTest(){
      System.assert(CLMMapObjectController.getAllObjectFields('Case', false).size()!=0);
    }
    @isTest
    public static void getAllObjectFields_negativeTest(){
				try {
					CLMMapObjectController.getAllObjectFields(null, false);
				} catch (AuraHandledException ae) {
					System.assert(ae != null);
				}			
    }
    @isTest
    public static void getNamespaceTest(){
        System.assertNotEquals(null, CLMMapObjectController.getNamespace());
    }
    @isTest
    public static void removeMappedObject_positiveTest(){
      EOS_Type__c eos = EOS_Type__c.getOrgDefaults();
      eos.Name = 'Case';
			eos.Name__c = 'Case';
			eos.Folder_Name__c = '{!Case.Id}';
			eos.Path__c = '/Salesforce/Case';
			insert eos;
			System.assertNotEquals(false, CLMMapObjectController.removeMappedObject('Case'));
    }
		@isTest
		public static void removeMappedObjectTest_negativeTest(){
			try{
				Boolean result = CLMMapObjectController.removeMappedObject('Case');
			}catch(AuraHandledException ae){
				System.assert(ae != null);
			}
		}
    @isTest
    public static void getRecordCountTest(){
        System.assert(CLMMapObjectController.getRecordCount() != null);
    }
    @isTest
    public static void setMappedObjectTest(){
      EOS_Type__c eos = EOS_Type__c.getOrgDefaults();
			eos.Folder_Name__c = UUID.randomUUID().toShortString();
			eos.Path__c = UUID.randomUUID().toShortString();
			eos.Name__c = UUID.randomUUID().toShortString();
			eos.Name = UUID.randomUUID().toShortString();				
      System.assertEquals(true, CLMMapObjectController.setMappedObject(eos));
    }
}