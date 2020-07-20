@IsTest
private class TroubleShootingControllerTest {

	@IsTest
	static void test_getLoginInformation_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			TroubleShootingController.LoginInformation result = TroubleShootingController.getLoginInformation();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('connected', result.status);
			System.assert(String.isNotEmpty(result.accountEmail));
			System.assert(String.isNotEmpty(result.environment));
		}
	}

	@IsTest
	static void test_getLoginInformation_unAuthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				TroubleShootingController.getLoginInformation();
				throw new AssertException('Expected getLoginInformation to fail');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

}