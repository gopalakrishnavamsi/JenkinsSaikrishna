@IsTest
public class AccountServiceTest {

	@IsTest
	static void test_getDocuSignUrl_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Url result = AccountService.getDocuSignUrl();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_getDocuSignUrl_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AccountService.getDocuSignUrl();
				throw new AssertException('Expected getDocuSignUrl to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.UnauthorizedPageAccess, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSettings_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				AccountService.getSettings();
				throw new AssertException('Expected getSettings to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSettings_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			AccountSettings result = AccountService.getSettings();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_saveSettings_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AccountService.saveSettings(null);
				throw new AssertException('Expected save to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveSettings_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			UUID ssId = UUID.randomUUID();
			AccountSettings s = new AccountSettings(
				12345,
				new List<String> { 'er1', 'er2' },
				new List<String> { 'dr1', 'dr2' },
				new List<String> { 'rr1', 'rr2' },
				'CompoundMatchBeginning',
				ssId,
				true);

			Test.startTest();
			AccountSettings result = AccountService.saveSettings(s);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!(result === s));
			System.assertEquals(12345, result.calloutTimeout);
			System.assertEquals(new List<String> { 'er1', 'er2' }, result.entityResolvers);
			System.assertEquals(new List<String> { 'dr1', 'dr2' }, result.documentResolvers);
			System.assertEquals(new List<String> { 'rr1', 'rr2' }, result.recipientResolvers);
			System.assertEquals(Recipient.SearchBehavior.CompoundMatchBeginning.name(), result.recipientSearchBehavior);
			System.assertEquals(ssId, result.systemSenderId);
		}
	}

	@IsTest
	static void test_executePostInstallScripts_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				AccountService.executePostInstallScripts();
				throw new AssertException('Expected executePostInstallScripts to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_executePostInstallScripts_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			PostInstallResults result = AccountService.executePostInstallScripts();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
		}
	}
}
