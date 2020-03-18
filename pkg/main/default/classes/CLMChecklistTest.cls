@IsTest
public class CLMChecklistTest {

	@IsTest
	public static void getCurrentUserExperience() {
		Test.startTest();
		String result = CLMChecklist.getCurrentUserExperience();
		System.assertNotEquals(null, result);
		Test.stopTest();
	}

	@IsTest
	public static void getProgressStatus_Authorized() {
		User clmAdmin = UserMock.createClmAdministrator(false);
		System.runAs(clmAdmin) {
			Test.startTest();
			User_Activity__c newState1 = new User_Activity__c();
			newState1.Name = '1';
			insert newState1;
			User_Activity__c newState2 = new User_Activity__c();
			newState2.Name = '2';
			insert newState2;
			List<User_Activity__c> result = CLMChecklist.getProgressStatus();
			System.assertEquals(2, result.size());
			Test.stopTest();
		}
	}

	@IsTest
	public static void getProgressStatus_Unauthorized() {
		User nonDocuSignUser = UserMock.createUser();
		System.runAs(nonDocuSignUser) {
			Test.startTest();
			try {
				CLMChecklist.getProgressStatus();
				throw new AssertException('Expected failure when fetching admin setup progress');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeClmAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	public static void test_setProgressStatus_unauthorized() {
		System.runAs(UserMock.createClmUser()) {
			Test.startTest();
			try {
				CLMChecklist.setProgressStatus('1', true);
				throw new AssertException('Expected UnauthorizedException');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeClmAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	public static void test_setProgressStatus_insert() {
		System.runAs(UserMock.createClmAdministrator()) {
			Test.startTest();
			CLMChecklist.setProgressStatus('1', true);
			Test.stopTest();

			User_Activity__c ua = User_Activity__c.getValues('1');
			System.assertNotEquals(null, ua);
			System.assertEquals('1', ua.Name);
		}
	}

	@IsTest
	public static void test_setProgressStatus_delete() {
		System.runAs(UserMock.createClmAdministrator()) {
			User_Activity__c newStep = new User_Activity__c();
			newStep.Name = 'InstallChecklistStep1';
			insert newStep;

			Test.startTest();
			CLMChecklist.setProgressStatus('InstallChecklistStep1', false);
			Test.stopTest();

			System.assertEquals(null, User_Activity__c.getValues('1'));
		}
	}
}
