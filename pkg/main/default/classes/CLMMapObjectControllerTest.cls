@isTest
public class CLMMapObjectControllerTest {
	@isTest
	public static void getMappedObjectsListTest_authorized() {
		System.runAs(UserMock.createClmAdministrator()) {
			Test.startTest();
			Map<String, EOS_Type__c> result = CLMMapObjectController.getMappedObjectsList();
			Test.stopTest();
			System.assertNotEquals(null, result);
		}
	}

	@isTest
	public static void getMappedObjectsListTest_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				CLMMapObjectController.getMappedObjectsList();
				throw new AssertException('Expected failure when fetching mapped objects list.');
			} catch (AuraHandledException ae) {
				System.assertNotEquals(null, ae);
			}
			Test.stopTest();
		}
	}

	@isTest
	public static void getAllObjectsTest_authorized() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			List<MergeObject> result = CLMMapObjectController.getAllObjects();
			Test.stopTest();
			System.assertNotEquals(null, result);
		}
	}

	@isTest
	public static void getAllObjectsTest_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				CLMMapObjectController.getAllObjects();
				throw new AssertException('Expected failure when fetching all objects.');
			} catch (AuraHandledException ae) {
				System.assertNotEquals(null, ae);
			}
			Test.stopTest();
		}
	}

	@isTest
	public static void getAllObjectFieldsTest_authorized() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			List<MergeField> result = CLMMapObjectController.getAllObjectFields('Case', false);
			Test.stopTest();
			System.assertNotEquals(null, result);
		}
	}

	@isTest
	public static void getAllObjectFields_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				CLMMapObjectController.getAllObjectFields(null, false);
				throw new AssertException('Expected failure when fetching all object fields.');
			} catch (AuraHandledException ae) {
				System.assertNotEquals(null, ae);
			}
			Test.stopTest();
		}
	}

	@isTest
	public static void removeMappedObjectTest_authorized() {
		System.runAs(UserMock.createClmAdministrator()) {
			String objToRemove = UUID.randomUUID().toShortString();
			EOS_Type__c eos = EOS_Type__c.getOrgDefaults();
			eos.Name = objToRemove;
			eos.FolderName__c = objToRemove;
			eos.Path__c = objToRemove;
			insert eos;
			Test.startTest();
			Boolean result = CLMMapObjectController.removeMappedObject(objToRemove);
			Test.stopTest();
			System.assertNotEquals(null, result);
		}
	}

	@isTest
	public static void removeMappedObjectTest_unauthorized() {
		System.runAs(UserMock.createUser()) {
			String objToRemove = UUID.randomUUID().toShortString();
			Test.startTest();
			try {
				CLMMapObjectController.removeMappedObject(objToRemove);
				throw new AssertException('Expected failure when removing existing mapping.');
			} catch (AuraHandledException ae) {
				System.assertNotEquals(null, ae);
			}
			Test.stopTest();
		}
	}

	@isTest
	public static void getRecordCountTest_authorized() {
		System.runAs(UserMock.createClmAdministrator()) {
			Test.startTest();
			Integer result = CLMMapObjectController.getRecordCount();
			Test.stopTest();
			System.assertNotEquals(null, result);
		}
	}

	@isTest
	public static void getRecordCountTest_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				CLMMapObjectController.getRecordCount();
				throw new AssertException('Expected failure when fetching mapping records count.');
			} catch (AuraHandledException ae) {
				System.assertNotEquals(null, ae);
			}
			Test.stopTest();
		}
	}

	@isTest
	public static void setMappedObjectTest_authorized() {
		System.runAs(UserMock.createClmAdministrator()) {
			EOS_Type__c eos = EOS_Type__c.getOrgDefaults();
			eos.FolderName__c = UUID.randomUUID().toShortString();
			eos.Path__c = UUID.randomUUID().toShortString();
			eos.Name = UUID.randomUUID().toShortString();
			Test.startTest();
			Boolean result = CLMMapObjectController.setMappedObject(eos);
			Test.stopTest();
			System.assertNotEquals(false, result);
		}
	}

	@isTest
	public static void setMappedObjectTest_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				EOS_Type__c eos = EOS_Type__c.getOrgDefaults();
				eos.FolderName__c = UUID.randomUUID().toShortString();
				eos.Path__c = UUID.randomUUID().toShortString();
				eos.Name = UUID.randomUUID().toShortString();
				CLMMapObjectController.setMappedObject(eos);
				throw new AssertException('Expected failure when inserting mapping.');
			} catch (AuraHandledException ae) {
				System.assertNotEquals(null, ae);
			}
			Test.stopTest();
		}
	}
}