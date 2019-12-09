@IsTest
private class GenMigrationControllerTest {

	@IsTest
	static void test_isGenInstalled() {
		System.runAs(UserMock.createDocuSignAdministrator()) {

			Test.startTest();
			Boolean isGenInstalled = GenMigrationApplication.verifyGenPackageInstalled();
			GenMigrationController.isGenPackageInstalled();
			System.assertEquals(isGenInstalled, GenMigrationApplication.verifyGenPackageInstalled());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_initiateUserMigration() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			User u1 = UserMock.createUser(UserInfo.getProfileId(), UUID.randomUUID().toString() + '@unit.test', null, false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), UUID.randomUUID().toString() + '@unit.test', null, false);
			User u3 = UserMock.createUser(UserInfo.getProfileId(), UUID.randomUUID().toString() + '@unit.test', null, false);

			PermissionSet psGenTemplate = new PermissionSet(name = 'DocuSign_Gen_Template_Configuration', Label = 'DocuSign_Gen_Template_Configuration');
			insert psGenTemplate;
			PermissionSet psGenUser = new PermissionSet(name = 'DocuSign_Gen_User', Label = 'DocuSign_Gen_User');
			insert psGenUser;

			if (Collection.isNotEmpty(new Set<Id> { psGenUser.Id, psGenTemplate.Id }) && Collection.isNotEmpty(new Set<Id> { u1.Id, u2.Id, u3.Id })) {
				insert new List<PermissionSetAssignment> {
					new PermissionSetAssignment(AssigneeId = u1.Id, PermissionSetId = psGenTemplate.ID),
					new PermissionSetAssignment(AssigneeId = u2.Id, PermissionSetId = psGenTemplate.ID),
					new PermissionSetAssignment(AssigneeId = u3.Id, PermissionSetId = psGenTemplate.ID),
					new PermissionSetAssignment(AssigneeId = u1.Id, PermissionSetId = psGenUser.ID),
					new PermissionSetAssignment(AssigneeId = u2.Id, PermissionSetId = psGenUser.ID),
					new PermissionSetAssignment(AssigneeId = u3.Id, PermissionSetId = psGenUser.ID)
				};
			}

			Test.startTest();
			if (GenMigrationApplication.verifyGenPackageInstalled()) {
				Id returnUserBatchId = GenMigrationController.initiateUserMigration();
				System.assertEquals(returnUserBatchId, GenMigrationSettings__c.getOrgDefaults().UserMigrationBatchId__c);
			}
			System.assert(Permissions.isDocuSignAdministrator());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_initiateTemplateMigration() {
		System.runAs(UserMock.createDocuSignAdministrator()) {

			Test.startTest();
			try {
				if (GenMigrationApplication.verifyGenPackageInstalled()) {
					Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new List<String> { GenMigrationApplication.namespacePrefix + 'Template_Configuration__c' });
					if (results.get(0).getSobjectType() == null) {
						return;
					} else {
						Schema.SObjectType getSobjectInstance = results.get(0).getSobjectType();
						SObject templateConfiguration = getSobjectInstance.newSObject();
						templateConfiguration.put('Name', 'Gen Template Configuration');
						templateConfiguration.put(GenMigrationApplication.namespacePrefix + 'Sample__c', false);
						insert templateConfiguration;
					}

					Id returnBatchId = GenMigrationController.initiateTemplateMigration();
					System.assertEquals(returnBatchId, GenMigrationSettings__c.getOrgDefaults().TemplateMigrationBatchId__c);
				}
			} catch (Exception e) {

			}
			Test.stopTest();
		}
	}

	// Negative Scenarios
	@IsTest
	static void test_GenPackageNotInstalled() {
		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			try {
				GenMigrationController.isGenPackageInstalled();
				throw new AssertException('Excepted: Login user must have Docusign Administrator Permission');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_isNotDocusignAdminForUserMigration() {
		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			try {
				GenMigrationController.initiateUserMigration();
				throw new AssertException('Excepted: Login user must have Docusign Administrator Permission for User Migration');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_isNotDocusignAdminForTemplateMigration() {
		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			try {
				GenMigrationController.initiateTemplateMigration();
				throw new AssertException('Excepted: Login user must have Docusign Administrator Permission for Template Migration');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}
}