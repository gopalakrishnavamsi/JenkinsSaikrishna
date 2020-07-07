@IsTest
private class ConnectConfigurationPostInstallTest {

	@IsTest
	static void test_createConfiguration_connect_disabled() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			ProductSettings__c ps = ProductSettings__c.getInstance(Product.ESIGNATURE);
			ps.Features__c = 0;
			update ps;

			Test.startTest();
			ConnectConfigurationPostInstall.createConfiguration();
			Test.stopTest();

			List<Log__c> logs = [
				SELECT Severity__c, Message__c, TransactionId__c, EntityId__c, SourceId__c, Class__c, Method__c
				FROM Log__c
			];
			System.assertEquals(1, Collection.size(logs));
			Log__c log = logs[0];
			System.assertNotEquals(null, log);
			System.assertEquals(LoggingLevel.WARN.name(), log.Severity__c);
			System.assertEquals(Label.ConnectNotEnabled, log.Message__c);
			System.assertNotEquals(null, log.TransactionId__c);
			System.assertEquals(null, log.EntityId__c);
			System.assertEquals(null, log.SourceId__c);
			System.assertEquals(String.valueOf(ConnectConfigurationPostInstall.class), log.Class__c);
			System.assertEquals('createConfiguration', log.Method__c);
		}
	}

	@IsTest
	static void test_createConfiguration_error() {
		DocuSignAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			ConnectConfigurationPostInstall.createConfiguration();
			Test.stopTest();

			List<Log__c> logs = [
				SELECT Severity__c, Message__c, TransactionId__c, EntityId__c, SourceId__c, Class__c, Method__c
				FROM Log__c
			];
			System.assertEquals(1, Collection.size(logs));
			Log__c log = logs[0];
			System.assertNotEquals(null, log);
			System.assertEquals(LoggingLevel.ERROR.name(), log.Severity__c);
			System.assertNotEquals(null, log.Message__c);
			System.assert(log.Message__c.startsWith(Label.ConnectConfigurationError));
			System.assertNotEquals(null, log.TransactionId__c);
			System.assertEquals(null, log.EntityId__c);
			System.assertEquals(null, log.SourceId__c);
			System.assertEquals(String.valueOf(ConnectConfigurationPostInstall.class), log.Class__c);
			System.assertEquals('createConfiguration', log.Method__c);
		}
	}

	@IsTest
	static void test_createConfiguration_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			ConnectConfigurationPostInstall.createConfiguration();
			Test.stopTest();

			System.assertEquals(0, [SELECT COUNT() FROM Log__c]);
		}
	}

	@IsTest
	static void test_shouldExecute_false() {
		ConnectConfigurationPostInstall ccpi = new ConnectConfigurationPostInstall();

		Test.startTest();
		System.assert(!ccpi.shouldExecute(
			UserInfo.getOrganizationId(),
			UserInfo.getUserId(),
			new Version(2, 4),
			false,
			false));
		System.assert(!ccpi.shouldExecute(
			UserInfo.getOrganizationId(),
			UserInfo.getUserId(),
			new Version(2, 5),
			false,
			true));
		Test.stopTest();
	}

	@IsTest
	static void test_shouldExecute_true() {
		ConnectConfigurationPostInstall ccpi = new ConnectConfigurationPostInstall();

		Test.startTest();
		System.assert(ccpi.shouldExecute(
			UserInfo.getOrganizationId(),
			UserInfo.getUserId(),
			new Version(2, 4),
			false,
			true));
		Test.stopTest();
	}

	@IsTest
	static void test_execute_skip() {
		ConnectConfigurationPostInstall ccpi = new ConnectConfigurationPostInstall();

		Test.startTest();
		PostInstallResults result = ccpi.execute(
			UserInfo.getOrganizationId(),
			UserInfo.getUserId(),
			new Version(2, 6),
			false,
			true);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.success);
		System.assertEquals(1, Collection.size(result.getSteps()));
		System.assertEquals(Label.CreateConnectConfiguration, result.getSteps()[0].name);
		System.assertEquals(PostInstallResults.StepStatus.SKIPPED, result.getSteps()[0].status);
		System.assertEquals(Label.PostInstallCriteriaNotMet, result.getSteps()[0].context);
	}

	@IsTest
	static void test_execute_account_not_configured() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			ConnectConfigurationPostInstall ccpi = new ConnectConfigurationPostInstall();

			Test.startTest();
			PostInstallResults result = ccpi.execute(
				UserInfo.getOrganizationId(),
				UserInfo.getUserId(),
				new Version(2, 4),
				false,
				true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			System.assertEquals(1, Collection.size(result.getSteps()));
			System.assertEquals(Label.CreateConnectConfiguration, result.getSteps()[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SKIPPED, result.getSteps()[0].status);
			System.assertEquals(Label.AccountNotConfigured, result.getSteps()[0].context);
		}
	}

	@IsTest
	static void test_execute_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			ConnectConfigurationPostInstall ccpi = new ConnectConfigurationPostInstall();

			Test.startTest();
			PostInstallResults result = ccpi.execute(
				UserInfo.getOrganizationId(),
				UserInfo.getUserId(),
				new Version(2, 4),
				false,
				true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			System.assertEquals(1, Collection.size(result.getSteps()));
			System.assertEquals(Label.CreateConnectConfiguration, result.getSteps()[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SUCCESS, result.getSteps()[0].status);
		}
	}
}
