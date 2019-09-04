@IsTest
private class PostInstallTest {

	@IsTest
	static void test_generateEmail() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
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
		System.runAs(UserMock.createDocuSignAdministrator()) {
			PostInstallResults pir = new PostInstallResults();
			pir.endStepFailure('STEP1', new DocuSignException('FAILURE1'));
			pir.endStepSuccess('STEP2');
			pir.skipStep('STEP3', 'SKIP3');
			pir.endStepFailure('STEP4', new DocuSignException('FAILURE4'));

			Test.startTest();
			Boolean result = PostInstall.notify(pir, UserInfo.getOrganizationId(), UserInfo.getUserId(),
				new Version(6, 9));
			Test.stopTest();

			System.assert(result);
		}
	}

	@IsTest
	static void test_assignDocuSignAdministratorPermissionSet() {
		System.runAs(UserMock.createUser()) {

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
		System.runAs(UserMock.createUser()) {
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
			System.assertEquals(null, settings.AccountBaseUrl__c);
			System.assertEquals(null, settings.ProvisioningBaseUrl__c);
			System.assertEquals(null, settings.ESignatureBaseUrl__c);
			System.assertEquals(null, settings.AccountId__c);
			System.assertEquals(null, settings.Email__c);
			System.assertEquals(null, settings.SystemSenderId__c);
			System.assertEquals(null, settings.ProductsLastChecked__c);
			System.assertEquals(60, settings.ProductsCheckFrequency__c);
			System.assertEquals(60000, settings.CalloutTimeout__c);
			System.assertNotEquals(null, settings.EncryptionKey__c);
			System.assertEquals(Application.classNamespacePrefix + 'DefaultEntityResolver', settings.EntityResolvers__c);
			System.assertEquals(Application.classNamespacePrefix + 'DefaultDocumentResolver', settings.DocumentResolvers__c);
			System.assertEquals(Application.classNamespacePrefix + 'DefaultRecipientResolver', settings.RecipientResolvers__c);
		}
	}

	@IsTest
	static void test_initializeAccountSettings_upgrade() {
		System.runAs(UserMock.createUser()) {
			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
			settings.Environment__c = 'unit.test';
			settings.AccountBaseUrl__c = 'https://account.unit.test';
			settings.ProvisioningBaseUrl__c = 'https://api.unit.test';
			settings.ESignatureBaseUrl__c = 'https://esign.unit.test';
			settings.AccountId__c = UUID.randomUUID().toString();
			settings.Email__c = 'u@unit.test';
			settings.SystemSenderId__c = UUID.randomUUID().toString();
			settings.EncryptionKey__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
			settings.EntityResolvers__c = 'Resolver1,Resolver2';
			settings.DocumentResolvers__c = 'Resolver1,Resolver2';
			settings.RecipientResolvers__c = 'Resolver1,Resolver2';
			settings.ProductsLastChecked__c = Datetime.now();
			settings.ProductsCheckFrequency__c = 60;
			settings.CalloutTimeout__c = 9999;
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

			AccountSettings__c s2 = AccountSettings__c.getOrgDefaults();
			System.assertNotEquals(null, s2);
			System.assertNotEquals(null, s2.Id);
			System.assertEquals(settings.Environment__c, s2.Environment__c);
			System.assertEquals(settings.AccountBaseUrl__c, s2.AccountBaseUrl__c);
			System.assertEquals(settings.ProvisioningBaseUrl__c, s2.ProvisioningBaseUrl__c);
			System.assertEquals(settings.ESignatureBaseUrl__c, s2.ESignatureBaseUrl__c);
			System.assertEquals(settings.AccountId__c, s2.AccountId__c);
			System.assertEquals(settings.Email__c, s2.Email__c);
			System.assertEquals(settings.SystemSenderId__c, s2.SystemSenderId__c);
			System.assertEquals(settings.CalloutTimeout__c, s2.CalloutTimeout__c);
			System.assertEquals(settings.EncryptionKey__c, s2.EncryptionKey__c);
			System.assertEquals(settings.EntityResolvers__c, s2.EntityResolvers__c);
			System.assertEquals(settings.DocumentResolvers__c, s2.DocumentResolvers__c);
			System.assertEquals(settings.RecipientResolvers__c, s2.RecipientResolvers__c);
		}
	}

	@IsTest
	static void test_initializeSettings_envelope_new() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			PostInstallResults result = PostInstall.initializeSettings(new Map<String, SObject> {
				Label.InitializeEnvelopeSettings => EnvelopeSettings__c.getOrgDefaults()
			});
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
		System.runAs(UserMock.createUser()) {
			insert EnvelopeSettings__c.getOrgDefaults();

			Test.startTest();
			PostInstallResults result = PostInstall.initializeSettings(new Map<String, SObject> {
				Label.InitializeEnvelopeSettings => EnvelopeSettings__c.getOrgDefaults()
			});
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
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			PostInstallResults result = PostInstall.initializeSettings(new Map<String, SObject> {
				Label.InitializeChatterSettings => ChatterSettings__c.getOrgDefaults()
			});
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
		System.runAs(UserMock.createUser()) {
			insert ChatterSettings__c.getOrgDefaults();

			Test.startTest();
			PostInstallResults result = PostInstall.initializeSettings(new Map<String, SObject> {
				Label.InitializeChatterSettings => ChatterSettings__c.getOrgDefaults()
			});
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
	static void test_initializeSettings_bulk() {
		System.runAs(UserMock.createUser()) {
			insert ChatterSettings__c.getOrgDefaults();

			Test.startTest();
			PostInstallResults result = PostInstall.initializeSettings(new Map<String, SObject> {
				Label.InitializeEnvelopeSettings => EnvelopeSettings__c.getOrgDefaults(),
				Label.InitializeChatterSettings => ChatterSettings__c.getOrgDefaults()
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			List<PostInstallResults.Step> steps = result.getSteps();
			System.assertEquals(2, Collection.size(steps));
			System.assertNotEquals(null, steps[0]);
			System.assertEquals(Label.InitializeEnvelopeSettings, steps[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SUCCESS, steps[0].status);
			System.assertNotEquals(null, steps[1]);
			System.assertEquals(Label.InitializeChatterSettings, steps[1].name);
			System.assertEquals(PostInstallResults.StepStatus.SKIPPED, steps[1].status);
		}
	}

	@IsTest
	static void test_createDefaultRecipientRoles_new() {
		System.runAs(UserMock.createUser()) {
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
		System.runAs(UserMock.createUser()) {
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
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			// Always returns true
			System.assert(new PostInstall().shouldExecute(null, null, null, false, false));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_execute() {
		System.runAs(UserMock.createUser()) {
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
		System.runAs(UserMock.createUser()) {

			Test.startTest();
			Test.testInstall(new PostInstall(), Application.version);
			Test.stopTest();

			AccountSettings__c s1 = AccountSettings__c.getOrgDefaults();
			System.assertNotEquals(null, s1);
			System.assertNotEquals(null, s1.Id);
			System.assertNotEquals(null, s1.DocumentResolvers__c);
			System.assertNotEquals(null, s1.EntityResolvers__c);
			System.assertNotEquals(null, s1.RecipientResolvers__c);
			System.assert(Permissions.isDocuSignAdministrator());
		}
	}

	@isTest
	static void test_createDefaultCLMObjMappings_mappings_do_not_exist() {
		System.assertEquals(null, EOS_Type__c.getOrgDefaults().Name);

		Test.startTest();
		PostInstallResults result = PostInstall.createDefaultCLMObjMappings();
		Test.stopTest();

		System.assertNotEquals(null, result);
	}

	@isTest
	static void test_createDefaultCLMObjMappings_mappings_exist() {
		EOS_Type__c eos_1 = EOS_Type__c.getOrgDefaults();
		eos_1.FolderName__c = UUID.randomUUID().toShortString();
		eos_1.Path__c = UUID.randomUUID().toShortString();
		eos_1.FolderNameFormat__c = UUID.randomUUID().toShortString();
		eos_1.Variables__c = UUID.randomUUID().toShortString();
		eos_1.PathFormat__c = UUID.randomUUID().toShortString();
		eos_1.Name = UUID.randomUUID().toShortString();
		insert eos_1;

		EOS_Type__c eos_2 = new EOS_Type__c();
		eos_2.FolderName__c = UUID.randomUUID().toShortString();
		eos_2.Path__c = UUID.randomUUID().toShortString();
		eos_2.FolderNameFormat__c = UUID.randomUUID().toShortString();
		eos_2.Variables__c = UUID.randomUUID().toShortString();
		eos_2.PathFormat__c = UUID.randomUUID().toShortString();
		eos_2.Name = UUID.randomUUID().toShortString();
		insert eos_2;

		Test.startTest();
		PostInstallResults result = PostInstall.createDefaultCLMObjMappings();
		Test.stopTest();

		System.assertEquals(PostInstallResults.StepStatus.SKIPPED, result.getSteps()[0].status);
	}
}
