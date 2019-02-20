@IsTest
private class SettingsControllerTest {

	@IsTest
	static void test_constructor() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			SettingsController result = new SettingsController();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Application.lightningNamespace, result.namespace);
			System.assertEquals(Salesforce.getLightningHost(), result.lightningHost);
			System.assertEquals(Salesforce.getVisualforceHost(), result.visualforceHost);
		}
	}

	@IsTest
	static void test_getSettings_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			SettingsController.Settings result = SettingsController.getSettings();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.account);
			System.assertNotEquals(null, result.availableSystemSenders);
		}
	}

	@IsTest
	static void test_getSettings_error() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SettingsController.getSettings();
				throw new AssertException('Expected getSettings to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveSettings_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			AccountSettings result = SettingsController.saveSettings(JSON.serialize(AccountSettings.getInstance()));
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_saveSettings_error() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SettingsController.saveSettings('{}');
				throw new AssertException('Expected saveSettings to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}
}
