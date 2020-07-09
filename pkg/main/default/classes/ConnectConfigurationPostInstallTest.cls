@IsTest
private class ConnectConfigurationPostInstallTest {

	@IsTest
	static void test_isConnectEnabled_disabled() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			ProductSettings__c ps = ProductSettings__c.getInstance(Product.ESIGNATURE);
			ps.Features__c = 0;
			update ps;

			Test.startTest();
			System.assert(!ConnectConfigurationPostInstall.isConnectEnabled());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_isConnectEnabled_enabled() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			ProductSettings__c ps = ProductSettings__c.getInstance(Product.ESIGNATURE);
			ps.Features__c = 33;
			update ps;

			Test.startTest();
			System.assert(ConnectConfigurationPostInstall.isConnectEnabled());
			Test.stopTest();
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
		System.runAs(UserMock.createDocuSignAdministrator()) {
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
			System.assertEquals(Label.PostInstallCriteriaNotMet, result.getSteps()[0].context);
		}
	}

	@IsTest
	static void test_execute_success() {
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
