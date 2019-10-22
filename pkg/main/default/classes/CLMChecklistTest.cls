@isTest
public class CLMChecklistTest {
	@isTest
	public static void getCurrentUserExperience() {
		Test.startTest();
		String result = CLMChecklist.getCurrentUserExperience();
		System.assertNotEquals(null, result);
		Test.stopTest();
	}


	@isTest
	public static void getProgressStatus_Authorized() {
		User clmAdmin = UserMock.createClmAdministrator(false);
		System.runAs(clmAdmin) {
			Test.startTest();
			User_Activity__c newState1=new User_Activity__c();
			newState1.Name='1';
			insert newState1;
			User_Activity__c newState2=new User_Activity__c();
			newState2.Name='2';
			insert newState2;
			List<User_Activity__c> result = CLMChecklist.getProgressStatus();
			system.assertEquals(2, result.size());
			Test.stopTest();
		}
	}

	@isTest
	public static void getProgressStatus_UnAuthorized() {
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

	@isTest
	public static void setProgressStatus_Authorized() {
		User_Activity__c newState=new User_Activity__c();
		newState.Name='1';
		insert newState;
		Test.startTest();
		User clmAdmin = UserMock.createClmAdministrator();
		System.runAs(clmAdmin) {
			CLMChecklist.setProgressStatus(newState.Name);
		}
		Test.stopTest();
	}

	@isTest
	public static void setProgressStatus_UnAuthorized() {
		User nonDocuSignUser = UserMock.createUser();
		System.runAs(nonDocuSignUser) {
			Test.startTest();
			try {
				CLMChecklist.setProgressStatus('1');
				throw new AssertException('Expected UnauthorizedException');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeClmAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}

	}

	@isTest
	public static void setProgressStatusWithInsert() {
		User clmAdmin = UserMock.createClmAdministrator();
		System.runAs(clmAdmin) {
			Test.startTest();
			User_Activity__c newState=new User_Activity__c();
			newState.Name='1';
			insert newState;
			CLMChecklist.setProgressStatus(newState.Name);
			Test.stopTest();
		}
	}

	@isTest
	public static void setProgressStatusWithoutInsert() {
		User clmAdmin = UserMock.createClmAdministrator();
		System.runAs(clmAdmin) {
			Test.startTest();
			CLMChecklist.setProgressStatus('1');
			Test.stopTest();
		}
	}
}