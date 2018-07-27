@IsTest
private class PostInstallTest {

	@IsTest
	static void test_generateEmail() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			PostInstallResults pir = new PostInstallResults();
			pir.endStepFailure('STEP1', new DocuSignException('FAILURE1'));
			pir.endStepSuccess('STEP2');
			pir.skipStep('STEP3', 'SKIP3');
			pir.endStepFailure('STEP4', new DocuSignException('FAILURE4'));
			List<String> toAddresses = new List<String> { 'test1@unit.test', 'test2@unit.test' };

			Test.startTest();
			Messaging.SingleEmailMessage result = PostInstall.generateEmail(pir, toAddresses,
				UserInfo.getOrganizationId(), new Version(6, 9));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(toAddresses, result.getToAddresses());
			System.assert(String.isNotBlank(result.getSubject()));
			System.assert(String.isNotBlank(result.getPlainTextBody()));
		}
	}

	@IsTest
	static void test_notify() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			PostInstallResults pir = new PostInstallResults();
			pir.endStepFailure('STEP1', new DocuSignException('FAILURE1'));
			pir.endStepSuccess('STEP2');
			pir.skipStep('STEP3', 'SKIP3');
			pir.endStepFailure('STEP4', new DocuSignException('FAILURE4'));
			List<String> toAddresses = new List<String> { 'test1@unit.test', 'test2@unit.test' };

			Test.startTest();
			Boolean result = PostInstall.notify(pir, UserInfo.getOrganizationId(), UserInfo.getUserId(),
				new Version(6, 9));
			Test.stopTest();

			System.assert(result);
		}
	}

	@IsTest
	static void test_assignDocuSignAdministratorPermissionSet() {
		System.runAs(TestUtils.createUser()) {

			Test.startTest();
			PostInstallResults result1 = PostInstall.assignDocuSignAdministratorPermissionSet(UserInfo.getUserId());
			PostInstallResults result2 = PostInstall.assignDocuSignAdministratorPermissionSet(null);
			Test.stopTest();

			System.assert(Permissions.isDocuSignAdministrator());
			System.assertNotEquals(null, result1);
			System.assert(result1.success);
			System.assertEquals(1, result1.count);
			List<PostInstallResults.Step> s = result1.getSteps();
			System.assertNotEquals(null, s);
			System.assertEquals(1, s.size());
			System.assertNotEquals(null, s[0]);
			System.assertEquals(1, s[0].sequence);
			System.assertEquals(Label.AssignAdminPermissionSet, s[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SUCCESS, s[0].status);

			System.assertNotEquals(null, result2);
			System.assert(result2.success);
			System.assertEquals(1, result2.count);
			s = result2.getSteps();
			System.assertNotEquals(null, s);
			System.assertEquals(1, s.size());
			System.assertNotEquals(null, s[0]);
			System.assertEquals(1, s[0].sequence);
			System.assertEquals(Label.AssignAdminPermissionSet, s[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SKIPPED, s[0].status);
			System.assertEquals(Label.UserMustBeProvided, (String)s[0].context);
		}
	}

	@IsTest
	static void test_initializeAccountSettings_new() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			PostInstallResults result = PostInstall.initializeAccountSettings();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			List<PostInstallResults.Step> steps = result.getSteps();
			System.assertNotEquals(null, steps);
			System.assertEquals(1, steps.size());
			System.assertNotEquals(null, steps[0]);
			System.assertEquals(Label.InitializeAccountSettings, steps[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SUCCESS, steps[0].status);

			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
			System.assertNotEquals(null, settings);
			System.assertNotEquals(null, settings.Id);
			System.assertEquals(null, settings.Environment__c);
			System.assertEquals(null, settings.BaseUrl__c);
			System.assertEquals(null, settings.AccountId__c);
			System.assert(settings.UseSendOnBehalfOf__c);
			System.assertEquals(null, settings.Username__c);
			System.assertEquals(null, settings.Password__c);
			System.assertEquals(0, settings.Features__c);
			System.assertEquals(null, settings.FeaturesLastChecked__c);
			System.assertEquals(60, settings.FeaturesCheckFrequency__c);
			System.assertEquals(60000, settings.CalloutTimeout__c);
			System.assertEquals('name,alias,username,email,DSProSFUsername__c,userroleid,managerid', settings.ManageUserFields__c);
			System.assertEquals(Application.classNamespacePrefix + 'DefaultEntityResolver', settings.EntityResolvers__c);
			System.assertEquals(Application.classNamespacePrefix + 'DefaultDocumentResolver', settings.DocumentResolvers__c);
			System.assertEquals(Application.classNamespacePrefix + 'DefaultRecipientResolver', settings.RecipientResolvers__c);
		}
	}

	@IsTest
	static void test_initializeAccountSettings_upgrade() {
		System.runAs(TestUtils.createUser()) {
			String password = UUID.randomUUID().toString();
			String accountId = UUID.randomUUID().toString();
			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
			settings.Environment__c = 'unit.test';
			settings.BaseUrl__c = 'https://unit.test';
			settings.AccountId__c = accountId;
			settings.Username__c = 'u@unit.test';
			settings.Password__c = password;
			settings.EntityResolvers__c = 'Resolver1,Resolver2';
			settings.DocumentResolvers__c = 'Resolver1,Resolver2';
			settings.RecipientResolvers__c = 'Resolver1,Resolver2';
			insert settings;

			Test.startTest();
			PostInstallResults result = PostInstall.initializeAccountSettings();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			List<PostInstallResults.Step> steps = result.getSteps();
			System.assertNotEquals(null, steps);
			System.assertEquals(1, steps.size());
			System.assertNotEquals(null, steps[0]);
			System.assertEquals(Label.InitializeAccountSettings, steps[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SKIPPED, steps[0].status);

			settings = AccountSettings__c.getOrgDefaults();
			System.assertNotEquals(null, settings);
			System.assertNotEquals(null, settings.Id);
			System.assertEquals('unit.test', settings.Environment__c);
			System.assertEquals('https://unit.test', settings.BaseUrl__c);
			System.assertEquals(accountId, settings.AccountId__c);
			System.assert(settings.UseSendOnBehalfOf__c);
			System.assertEquals('u@unit.test', settings.Username__c);
			System.assertEquals(password, settings.Password__c);
			System.assertEquals(0, settings.Features__c);
			System.assertEquals(null, settings.FeaturesLastChecked__c);
			System.assertEquals(60, settings.FeaturesCheckFrequency__c);
			System.assertEquals(60000, settings.CalloutTimeout__c);
			System.assertEquals('name,alias,username,email,DSProSFUsername__c,userroleid,managerid', settings.ManageUserFields__c);
			System.assertEquals('Resolver1,Resolver2', settings.EntityResolvers__c);
			System.assertEquals('Resolver1,Resolver2', settings.DocumentResolvers__c);
			System.assertEquals('Resolver1,Resolver2', settings.RecipientResolvers__c);
		}
	}

	@IsTest
	static void test_initializeSettings_envelope_new() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			PostInstallResults result = PostInstall.initializeSettings(
				Label.InitializeEnvelopeSettings, EnvelopeSettings__c.getOrgDefaults());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			List<PostInstallResults.Step> steps = result.getSteps();
			System.assertNotEquals(null, steps);
			System.assertEquals(1, steps.size());
			System.assertNotEquals(null, steps[0]);
			System.assertEquals(Label.InitializeEnvelopeSettings, steps[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SUCCESS, steps[0].status);
		}
	}

	@IsTest
	static void test_initializeSettings_envelope_upgrade() {
		System.runAs(TestUtils.createUser()) {
			insert EnvelopeSettings__c.getOrgDefaults();

			Test.startTest();
			PostInstallResults result = PostInstall.initializeSettings(
				Label.InitializeEnvelopeSettings, EnvelopeSettings__c.getOrgDefaults());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			List<PostInstallResults.Step> steps = result.getSteps();
			System.assertNotEquals(null, steps);
			System.assertEquals(1, steps.size());
			System.assertNotEquals(null, steps[0]);
			System.assertEquals(Label.InitializeEnvelopeSettings, steps[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SKIPPED, steps[0].status);
		}
	}

	@IsTest
	static void test_initializeSettings_Chatter_new() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			PostInstallResults result = PostInstall.initializeSettings(
				Label.InitializeChatterSettings, ChatterSettings__c.getOrgDefaults());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			List<PostInstallResults.Step> steps = result.getSteps();
			System.assertNotEquals(null, steps);
			System.assertEquals(1, steps.size());
			System.assertNotEquals(null, steps[0]);
			System.assertEquals(Label.InitializeChatterSettings, steps[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SUCCESS, steps[0].status);
		}
	}

	@IsTest
	static void test_initializeSettings_Chatter_upgrade() {
		System.runAs(TestUtils.createUser()) {
			insert ChatterSettings__c.getOrgDefaults();

			Test.startTest();
			PostInstallResults result = PostInstall.initializeSettings(
				Label.InitializeChatterSettings, ChatterSettings__c.getOrgDefaults());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			List<PostInstallResults.Step> steps = result.getSteps();
			System.assertNotEquals(null, steps);
			System.assertEquals(1, steps.size());
			System.assertNotEquals(null, steps[0]);
			System.assertEquals(Label.InitializeChatterSettings, steps[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SKIPPED, steps[0].status);
		}
	}

	@IsTest
	static void test_createDefaultRecipientRoles_new() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			PostInstallResults result = PostInstall.createDefaultRecipientRoles();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			List<PostInstallResults.Step> steps = result.getSteps();
			System.assertNotEquals(null, steps);
			System.assertEquals(1, steps.size());
			System.assertNotEquals(null, steps[0]);
			System.assertEquals(Label.CreateDefaultRecipientRoles, steps[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SUCCESS, steps[0].status);

			List<RoleSettings__c> settings = RoleSettings__c.getAll().values();
			System.assertNotEquals(null, settings);
			System.assertEquals(4, settings.size());
			for (RoleSettings__c r : settings) {
				if (r.Name == 'Signer 1') {
					System.assertEquals(1, Integer.valueOf(r.Value__c));
				} else if (r.Name == 'Signer 2') {
					System.assertEquals(2, Integer.valueOf(r.Value__c));
				} else if (r.Name == 'Signer 3') {
					System.assertEquals(3, Integer.valueOf(r.Value__c));
				} else if (r.Name == 'Signer 4') {
					System.assertEquals(4, Integer.valueOf(r.Value__c));
				} else {
					throw new AssertException('Unexpected role: ' + r.Name + ' (' + r.Value__c + ')');
				}
			}
		}
	}

	@IsTest
	static void test_createDefaultRecipientRoles_upgrade() {
		System.runAs(TestUtils.createUser()) {
			insert new List<RoleSettings__c> {
				new RoleSettings__c(Name = 'Role A', Value__c = 1),
				new RoleSettings__c(Name = 'Role B', Value__c = 2)
			};

			Test.startTest();
			PostInstallResults result = PostInstall.createDefaultRecipientRoles();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			List<PostInstallResults.Step> steps = result.getSteps();
			System.assertNotEquals(null, steps);
			System.assertEquals(1, steps.size());
			System.assertNotEquals(null, steps[0]);
			System.assertEquals(Label.CreateDefaultRecipientRoles, steps[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SKIPPED, steps[0].status);

			List<RoleSettings__c> settings = RoleSettings__c.getAll().values();
			System.assertNotEquals(null, settings);
			System.assertEquals(2, settings.size());
			for (RoleSettings__c r : settings) {
				if (r.Name == 'Role A') {
					System.assertEquals(1, Integer.valueOf(r.Value__c));
				} else if (r.Name == 'Role B') {
					System.assertEquals(2, Integer.valueOf(r.Value__c));
				} else {
					throw new AssertException('Unexpected role: ' + r.Name + ' (' + r.Value__c + ')');
				}
			}
		}
	}

	@IsTest
	static void test_shouldExecute() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			// Always returns true
			System.assert(new PostInstall().shouldExecute(null, null, null, false, false));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_execute() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			PostInstallResults result = new PostInstall().execute(UserInfo.getOrganizationId(), UserInfo.getUserId(),
				new Version(6, 9), false, true);
			Test.stopTest();

			System.assert(Permissions.isDocuSignAdministrator());
			System.assertNotEquals(null, result);
			System.assert(result.success);
			System.assert(result.count >= 1); // At least permission set assignment
		}
	}

	@IsTest
	static void test_install() {
		System.runAs(TestUtils.createUser()) {

			Test.startTest();
			Test.testInstall(new PostInstall(), Application.version);
			Test.stopTest();

			AccountSettings__c s1 = AccountSettings__c.getOrgDefaults();
			System.assertNotEquals(null, s1.ManageUserFields__c);
			System.assert(Permissions.isDocuSignAdministrator());
		}
	}
}
