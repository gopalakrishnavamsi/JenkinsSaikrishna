@isTest
public class CLMApexUtilityTest {
	@isTest
	public static void getCurrentUserExperience_authorized(){
		System.runAs(UserMock.createClmAdministrator()){
			Test.startTest();
			String result = CLMApexUtility.getCurrentUserExperience();
			Test.stopTest();
			System.assertNotEquals(null, result);
		}
	}

	@isTest
	public static void getCurrentUserExperience_unauthorized(){
		System.runAs(UserMock.createUser()){
			Test.startTest();
			try {
				String result = CLMApexUtility.getCurrentUserExperience();
				throw new AssertException('Expected failure when fetching current user experience.');
			} catch (AuraHandledException ae) {
				System.assertNotEquals(null, ae);
			}
			Test.stopTest();
		}
	}
}