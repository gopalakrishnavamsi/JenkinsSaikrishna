@IsTest
private class ConnectServiceTest {

	@IsTest
	static void test_getListenerUrl_invalid_arguments() {
		Test.startTest();
		try {
			ConnectService.getListenerUrl(null);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getListenerUrl_invalid_site() {
		Test.startTest();
		System.assertEquals(null, ConnectService.getListenerUrl(new Url('https://unit.test.docusign.net/')));
		Test.stopTest();
	}

	@IsTest
	static void test_getListenerUrl_prod_na() {
		String listenerUrl = 'https://na.act-event.docusign.com/listeners/connect-salesforce';

		Test.startTest();
		Url result1 = ConnectService.getListenerUrl(new Url('https://www.docusign.net/'));
		Url result2 = ConnectService.getListenerUrl(new Url('https://na1.docusign.net/'));
		Url result3 = ConnectService.getListenerUrl(new Url('https://na2.docusign.net/'));
		Url result4 = ConnectService.getListenerUrl(new Url('https://na3.docusign.net/'));
		Url result5 = ConnectService.getListenerUrl(new Url('https://na4.docusign.net/'));
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assertEquals(listenerUrl, result1.toExternalForm());

		System.assertNotEquals(null, result2);
		System.assertEquals(listenerUrl, result2.toExternalForm());

		System.assertNotEquals(null, result3);
		System.assertEquals(listenerUrl, result3.toExternalForm());

		System.assertNotEquals(null, result4);
		System.assertEquals(listenerUrl, result4.toExternalForm());

		System.assertNotEquals(null, result5);
		System.assertEquals(listenerUrl, result5.toExternalForm());
	}

	@IsTest
	static void test_getListenerUrl_prod_eu() {
		String listenerUrl = 'https://eu.act-event.docusign.com/listeners/connect-salesforce';

		Test.startTest();
		Url result = ConnectService.getListenerUrl(new Url('https://eu.docusign.net/'));
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(listenerUrl, result.toExternalForm());
	}

	@IsTest
	static void test_getListenerUrl_prod_au() {
		String listenerUrl = 'https://au.act-event.docusign.com/listeners/connect-salesforce';

		Test.startTest();
		Url result = ConnectService.getListenerUrl(new Url('https://au.docusign.net/'));
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(listenerUrl, result.toExternalForm());
	}

	@IsTest
	static void test_getListenerUrl_prod_ca() {
		String listenerUrl = 'https://ca.act-event.docusign.com/listeners/connect-salesforce';

		Test.startTest();
		Url result = ConnectService.getListenerUrl(new Url('https://ca.docusign.net/'));
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(listenerUrl, result.toExternalForm());
	}

	@IsTest
	static void test_getListenerUrl_demo() {
		String listenerUrl = 'https://act-event-d.docusign.com/listeners/connect-salesforce';

		Test.startTest();
		Url result = ConnectService.getListenerUrl(new Url('https://dEmO.docusign.net/'));
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(listenerUrl, result.toExternalForm());
	}

	@IsTest
	static void test_getListenerUrl_stage() {
		String listenerUrl = 'https://act-event-s.docusign.com/listeners/connect-salesforce';

		Test.startTest();
		Url result = ConnectService.getListenerUrl(new Url('https://Stage.docusign.net/'));
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(listenerUrl, result.toExternalForm());
	}

	@IsTest
	static void test_getListenerUrl_hqtest() {
		String listenerUrl = 'https://act-event.dev.docusign.net/listeners/connect-salesforce';

		Test.startTest();
		Url result1 = ConnectService.getListenerUrl(new Url('https://HQTEST0.dev.docusign.net/'));
		Url result2 = ConnectService.getListenerUrl(new Url('https://HQTEST1.dev.docusign.net/'));
		Url result3 = ConnectService.getListenerUrl(new Url('https://HQTEST2.dev.docusign.net/'));
		Url result4 = ConnectService.getListenerUrl(new Url('https://HQTEST3.dev.docusign.net/'));
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assertEquals(listenerUrl, result1.toExternalForm());

		System.assertNotEquals(null, result2);
		System.assertEquals(listenerUrl, result2.toExternalForm());

		System.assertNotEquals(null, result3);
		System.assertEquals(listenerUrl, result3.toExternalForm());

		System.assertNotEquals(null, result4);
		System.assertEquals(listenerUrl, result4.toExternalForm());
	}

	@IsTest
	static void test_createConfiguration_invalid_arguments() {
		Url baseUrl = new Url('https://unit.test.docusign.net/');
		UUID accountId = UUID.randomUUID();
		String accessToken = 'unit.test';

		Test.startTest();
		try {
			ConnectService.createConfiguration(null, accountId, accessToken);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			ConnectService.createConfiguration(baseUrl, null, accessToken);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			ConnectService.createConfiguration(null, UUID.empty, accessToken);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_createConfiguration_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				ConnectService.createConfiguration();
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createConfiguration_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Long result = ConnectService.createConfiguration();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_asyncCreateConfiguration_noop() {
		Test.startTest();
		ConnectService.asyncCreateConfiguration();
		Test.stopTest();

		System.assertEquals(false, AccountSettings__c.getOrgDefaults().CreateConnectConfiguration__c);
	}

	@IsTest
	static void test_asyncCreateConfiguration_error() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.CreateConnectConfiguration__c = true;
		insert s;
		LogSettings__c ss = LogSettings__c.getInstance();
		ss.Level__c = LoggingLevel.ERROR.name();
		insert ss;

		Test.startTest();
		ConnectService.asyncCreateConfiguration();
		Test.stopTest();

		System.assertEquals(true, AccountSettings__c.getOrgDefaults().CreateConnectConfiguration__c);
		List<Log__c> ls = [
			SELECT Id, TransactionId__c, EntityId__c, SourceId__c, Version__c, Severity__c, Message__c, Class__c,
				Method__c
			FROM Log__c
		];
		System.assertEquals(1, Collection.size(ls));
		LoggerService.LogEntry le = LoggerService.DB.convert(ls[0]);
		System.assertNotEquals(null, le);
		System.assertNotEquals(null, le.context);
		System.assertNotEquals(null, le.context.transactionId);
		System.assertEquals(null, le.context.entityId);
		System.assertEquals(null, le.context.sourceId);
		System.assert(String.isNotBlank(le.message));
		System.assert(le.message.startsWith(Label.ConnectConfigurationError));
		System.assertEquals(String.valueOf(ConnectService.class), le.context.className);
		System.assertEquals('asyncCreateConfiguration', le.context.methodName);
	}

	@IsTest
	static void test_asyncCreateConfiguration_connect_disabled() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.CreateConnectConfiguration__c = true;
			update s;
			ProductSettings__c ps = ProductSettings__c.getInstance(Product.ESIGNATURE);
			ps.Features__c = 0;
			update ps;

			Test.startTest();
			ConnectService.asyncCreateConfiguration();
			Test.stopTest();

			System.assertEquals(false, AccountSettings__c.getOrgDefaults().CreateConnectConfiguration__c);
		}
	}

	@IsTest
	static void test_asyncCreateConfiguration_connect_enabled() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.CreateConnectConfiguration__c = true;
			update s;
			ProductSettings__c ps = ProductSettings__c.getInstance(Product.ESIGNATURE);
			ps.Features__c = 32;
			update ps;

			Test.startTest();
			ConnectService.asyncCreateConfiguration();
			Test.stopTest();

			System.assertEquals(false, AccountSettings__c.getOrgDefaults().CreateConnectConfiguration__c);
		}
	}
}
