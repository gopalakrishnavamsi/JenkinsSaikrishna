@IsTest
private class OrgServiceTest {

	@IsTest
	static void test_getOrgSettings_success() {
		System.runAs(UserMock.createDocuSignUser(true)) {
			Test.startTest();
			List<String> testResults = OrgService.getOrgSettings();
			OrgService.OrgSettings settings = ((OrgService.OrgSettings)JSON.deserialize(testResults[0], OrgService.OrgSettings.class));
			System.assertNotEquals(settings.accountId, null);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getOrgSettings_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				OrgService.getOrgSettings();
				throw new AssertException('Expected getOrgSettings to fail');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}
}