@IsTest
private class MetadataControllerTest {

	@IsTest
	static void test_getConfiguration_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataController.getConfiguration();
				throw new AssertException('Expected getConfiguration to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getConfiguration_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			MetadataController.Configuration result = MetadataController.getConfiguration();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Layout.ACTION_NAME_SEND, result.sendActionName);
			System.assert(Collection.isNotEmpty(result.commonObjects));
			System.assert(Collection.isNotEmpty(result.allObjects));
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
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			List<Layout> result = MetadataController.getLayouts('Contact');
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_updateLayouts_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataController.updateLayouts('Contact', '[]', null);
				throw new AssertException('Expected updateLayouts to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateLayouts_success() {
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			List<Layout> layouts = new List<Layout> {
				new Layout(
					Contact.getSObjectType(),
					UserInfo.getOrganizationId(),
					'ns',
					'n1',
					new List<Layout.Action> {
						new Layout.Action(
							Layout.ACTION_TYPE_SEND,
							Layout.ACTION_NAME_SEND)
					}),
				new Layout(
					Contact.getSObjectType(),
					UserInfo.getOrganizationId(),
					'ns',
					'n2',
					new List<Layout.Action> {
						new Layout.Action(
							Layout.ACTION_TYPE_SEND,
							Layout.ACTION_NAME_SEND)
					})
			};

			Test.startTest();
			List<Layout> result = MetadataController.updateLayouts('Contact', JSON.serialize(layouts), null);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
		}
	}

	@IsTest
	static void test_getGenActionName_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			String genActionName = MetadataController.getGenActionName();
			Test.stopTest();

			System.assert(String.isNotBlank(genActionName));
		}
	}

	@IsTest
	static void test_getGenActionName_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataController.getGenActionName();
				throw new AssertException('Expected getGenActionName to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}
}
