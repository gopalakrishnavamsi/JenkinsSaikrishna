@isTest
public class CLMApexUtilityTest {
	@isTest
	public static void getCurrentUserExperience() {
		Test.startTest();
		String result = CLMApexUtility.getCurrentUserExperience();
		Test.stopTest();
		System.assertNotEquals(null, result);
	}

	@isTest
	public static void getNamespace() {
		Test.startTest();
		String result = CLMApexUtility.getNamespace();
		Test.stopTest();
		System.assertNotEquals(null, result);
	}

	@isTest
	public static void verifyIsClmAdmin_success() {
		System.runAs(UserMock.createClmAdministrator()) {
			Test.startTest();
			Boolean result = CLMApexUtility.verifyIsClmAdmin();
			Test.stopTest();
			System.assertEquals(true, result);
			System.assertNotEquals(null, result);
		}
	}

	@isTest
	public static void verifyIsClmAdmin_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				Boolean result = CLMApexUtility.verifyIsClmAdmin();
				throw new AssertException('Expected Clm Admin check to fail.');
			} catch (Exception ae) {
				System.assertNotEquals(null, ae);
				System.assertEquals(Label.MustBeClmAdministrator, ae.getMessage());
			}
			Test.stopTest();
		}
	}
}