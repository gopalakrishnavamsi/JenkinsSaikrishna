@IsTest
private class MetadataControllerTest {

	@IsTest
	static void test_getSalesforceObjects_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataController.getSalesforceObjects();
				throw new AssertException('Expected getSalesforceObjects to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSalesforceObjects_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			MetadataController.MergeObjects result = MetadataController.getSalesforceObjects();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(Collection.isNotEmpty(result.common));
			System.assert(Collection.isNotEmpty(result.all));
		}
	}

	@IsTest
	static void test_getLayouts_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataController.getLayouts('Lead');
				throw new AssertException('Expected getLayouts to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLayouts_success() {
		Test.setMock(WebServiceMock.class, new MetadataAPIMock());
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			List<Layout> result = MetadataController.getLayouts('Contact');
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_addSendButton_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataController.addSendButton('Account', false, '[]');
				throw new AssertException('Expected addSendButton to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addSendButton_success() {
		Test.setMock(WebServiceMock.class, new MetadataAPIMock());
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			List<Layout> layouts = new List<Layout> {
				new Layout(Schema.Account.getSObjectType(), null, 'ns', 'n')
			};

			Test.startTest();
			Boolean result = MetadataController.addSendButton('Account', true, JSON.serialize(layouts));
			Test.stopTest();

			System.assert(result);
		}
	}

	@IsTest
	static void test_removeSendButton_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataController.removeSendButton('Account', false, '[]');
				throw new AssertException('Expected removeSendButton to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_removeSendButton_success() {
		Test.setMock(WebServiceMock.class, new MetadataAPIMock());
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			List<Layout> layouts = new List<Layout> {
				new Layout(Schema.Account.getSObjectType(), null, 'ns', 'n')
			};

			Test.startTest();
			Boolean result = MetadataController.removeSendButton('Account', true, JSON.serialize(layouts));
			Test.stopTest();

			System.assert(result);
		}
	}
}
