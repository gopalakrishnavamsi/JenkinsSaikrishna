@IsTest
private class LoggerServiceTest {

	private static final DocuSignException TEST_EXCEPTION = new DocuSignException('Test exception');

	@IsTest
	static void test_getInstance() {
		Test.startTest();
		LoggerService result1 = LoggerService.getInstance();
		LoggerService result2 = LoggerService.getInstance();
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1 === result2);
	}

	@IsTest
	static void test_exception() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.exception(TEST_EXCEPTION, 'Exception');
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}

	@IsTest
	static void test_exception_null_and_blank() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.exception(null);
		logger.exception(null, '');
		logger.exception(null, null);
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}

	@IsTest
	static void test_exception_blank_context() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.exception(TEST_EXCEPTION);
		logger.exception(TEST_EXCEPTION, null);
		logger.exception(TEST_EXCEPTION, '');
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}

	@IsTest
	static void test_exception_null_exception() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.exception(null, 'Exception');
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}

	@IsTest
	static void test_error() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.error('ERROR1');
		logger.log(System.LoggingLevel.ERROR, 'ERROR2');
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}

	@IsTest
	static void test_warning() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.warn('WARNING1');
		logger.log(System.LoggingLevel.WARN, 'WARNING2');
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}

	@IsTest
	static void test_info() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.info('INFO1');
		logger.log(System.LoggingLevel.INFO, 'INFO2');
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}

	@IsTest
	static void test_debug() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.debug('DEBUG1');
		logger.log(System.LoggingLevel.DEBUG, 'DEBUG2');
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}

	@IsTest
	static void test_empty_message() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.error('');
		logger.debug('');
		logger.warn('');
		logger.debug('');
		logger.log(System.LoggingLevel.ERROR, '');
		logger.log(System.LoggingLevel.DEBUG, '');
		logger.log(System.LoggingLevel.WARN, '');
		logger.log(System.LoggingLevel.INFO, '');
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}

	@IsTest
	static void test_null_message() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.error(null);
		logger.debug(null);
		logger.warn(null);
		logger.debug(null);
		logger.log(System.LoggingLevel.ERROR, null);
		logger.log(System.LoggingLevel.DEBUG, null);
		logger.log(System.LoggingLevel.WARN, null);
		logger.log(System.LoggingLevel.INFO, null);
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}

	@IsTest
	static void test_Database_insertEntries_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				LoggerService.DB.insertEntries(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(UnauthorizedException.AccessRequirement.SecurityPermission, ex.requirement);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_Database_insertEntries_success() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			LoggerService.LogEntry le1 = new LoggerService.LogEntry(
				null,
				new Version(2, 5, 1),
				LoggingLevel.DEBUG,
				'message1',
				'class1',
				'method1');
			LoggerService.LogEntry le2 = new LoggerService.LogEntry(null,
				new Version(2, 5),
				LoggingLevel.INFO,
				'message2',
				'class2',
				'method2');
			LoggerService.LogEntry le3 = new LoggerService.LogEntry(null,
				new Version(2, 6),
				LoggingLevel.WARN,
				'message3',
				'class3',
				'method3');
			LoggerService.LogEntry le4 = new LoggerService.LogEntry(null,
				new Version(2, 6, 3),
				LoggingLevel.ERROR,
				'message4',
				'class4',
				'method4');

			Test.startTest();
			List<LoggerService.LogEntry> result = LoggerService.DB.insertEntries(new List<LoggerService.LogEntry> {
				le1, le2, le3, le4
			});
			Test.stopTest();

			System.assertEquals(4, Collection.size(result));
			for (LoggerService.LogEntry le : result) {
				System.assertNotEquals(null, le);
				System.assertNotEquals(null, le.id);
			}
			System.assertEquals(4, Database.countQuery('SELECT COUNT() FROM ' + Application.namespacePrefix + 'Log__c'));
		}
	}

	@IsTest
	static void test_log_null() {
		Test.startTest();
		System.assertEquals(null, LoggerService.getInstance().log(null));
		Test.stopTest();
	}

	@IsTest
	static void test_log_exception() {
		System.runAs(UserMock.createUser()) {
			LogSettings__c ls = LogSettings__c.getOrgDefaults();
			ls.Level__c = LoggingLevel.WARN.name();
			insert ls;
			LoggerService.LogEntry le = new LoggerService.LogEntry(null,
				new Version(2, 6),
				LoggingLevel.WARN,
				'message',
				'class',
				'method');

			Test.startTest();
			LoggerService.LogEntry result = LoggerService.getInstance().log(le);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(null, result.id);
			System.assertEquals(0, Database.countQuery('SELECT COUNT() FROM ' + Application.namespacePrefix + 'Log__c'));
		}
	}

	@IsTest
	static void test_log_should_not_log() {
		System.runAs(UserMock.createUser()) {
			LogSettings__c ls = LogSettings__c.getOrgDefaults();
			ls.Level__c = LoggingLevel.ERROR.name();
			insert ls;
			LoggerService.LogEntry le = new LoggerService.LogEntry(null,
				new Version(2, 6),
				LoggingLevel.WARN,
				'message',
				'class',
				'method');

			Test.startTest();
			LoggerService.LogEntry result = LoggerService.getInstance().log(le);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(null, result.id);
			System.assertEquals(0, Database.countQuery('SELECT COUNT() FROM ' + Application.namespacePrefix + 'Log__c'));
		}
	}

	@IsTest
	static void test_log_should_log() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			LogSettings__c ls = LogSettings__c.getOrgDefaults();
			ls.Level__c = LoggingLevel.WARN.name();
			insert ls;
			LoggerService.LogEntry le = new LoggerService.LogEntry(null,
				new Version(2, 6),
				LoggingLevel.WARN,
				'message',
				'class',
				'method');

			Test.startTest();
			LoggerService.LogEntry result = LoggerService.getInstance().log(le);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(1, Database.countQuery('SELECT COUNT() FROM ' + Application.namespacePrefix + 'Log__c'));
		}
	}

	@IsTest
	static void test_exception_log_entry() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			LogSettings__c ls = LogSettings__c.getOrgDefaults();
			ls.Level__c = LoggingLevel.WARN.name();
			insert ls;
			DocuSignException ex = new DocuSignException('exception message');

			Test.startTest();
			LoggerService.getInstance().exception(
				ex,
				'context',
				'class',
				'method');
			Test.stopTest();

			LoggerService.LogEntry le = LoggerService.DB.convert((Log__c)Collection.head([
				SELECT Id, Class__c, Message__c, Method__c, Severity__c, Version__c
				FROM Log__c
				LIMIT 1
			]));
			System.assertNotEquals(null, le);
			System.assertNotEquals(null, le.id);
			System.assertEquals(Application.version, le.version);
			System.assertEquals(LoggingLevel.ERROR, le.severity);
			System.assertEquals(LoggerService.getMessage(ex, 'context'), le.message);
			System.assertEquals('class', le.className);
			System.assertEquals('method', le.methodName);
		}
	}

	@IsTest
	static void test_error_log_entry() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			LogSettings__c ls = LogSettings__c.getOrgDefaults();
			ls.Level__c = LoggingLevel.WARN.name();
			insert ls;

			Test.startTest();
			LoggerService.getInstance().error(
				'message',
				'class',
				'method');
			Test.stopTest();

			LoggerService.LogEntry le = LoggerService.DB.convert((Log__c)Collection.head([
				SELECT Id, Class__c, Message__c, Method__c, Severity__c, Version__c
				FROM Log__c
				LIMIT 1
			]));
			System.assertNotEquals(null, le);
			System.assertNotEquals(null, le.id);
			System.assertEquals(Application.version, le.version);
			System.assertEquals(LoggingLevel.ERROR, le.severity);
			System.assertEquals('message', le.message);
			System.assertEquals('class', le.className);
			System.assertEquals('method', le.methodName);
		}
	}

	@IsTest
	static void test_warn_log_entry() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			LogSettings__c ls = LogSettings__c.getOrgDefaults();
			ls.Level__c = LoggingLevel.WARN.name();
			insert ls;

			Test.startTest();
			LoggerService.getInstance().warn(
				'message',
				'class',
				'method');
			Test.stopTest();

			LoggerService.LogEntry le = LoggerService.DB.convert((Log__c)Collection.head([
				SELECT Id, Class__c, Message__c, Method__c, Severity__c, Version__c
				FROM Log__c
				LIMIT 1
			]));
			System.assertNotEquals(null, le);
			System.assertNotEquals(null, le.id);
			System.assertEquals(Application.version, le.version);
			System.assertEquals(LoggingLevel.WARN, le.severity);
			System.assertEquals('message', le.message);
			System.assertEquals('class', le.className);
			System.assertEquals('method', le.methodName);
		}
	}

	@IsTest
	static void test_info_log_entry() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			LogSettings__c ls = LogSettings__c.getOrgDefaults();
			ls.Level__c = LoggingLevel.DEBUG.name();
			insert ls;

			Test.startTest();
			LoggerService.getInstance().info(
				'message',
				'class',
				'method');
			Test.stopTest();

			LoggerService.LogEntry le = LoggerService.DB.convert((Log__c)Collection.head([
				SELECT Id, Class__c, Message__c, Method__c, Severity__c, Version__c
				FROM Log__c
				LIMIT 1
			]));
			System.assertNotEquals(null, le);
			System.assertNotEquals(null, le.id);
			System.assertEquals(Application.version, le.version);
			System.assertEquals(LoggingLevel.INFO, le.severity);
			System.assertEquals('message', le.message);
			System.assertEquals('class', le.className);
			System.assertEquals('method', le.methodName);
		}
	}

	@IsTest
	static void test_debug_log_entry() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			LogSettings__c ls = LogSettings__c.getOrgDefaults();
			ls.Level__c = LoggingLevel.DEBUG.name();
			insert ls;

			Test.startTest();
			LoggerService.getInstance().debug(
				'message',
				'class',
				'method');
			Test.stopTest();

			LoggerService.LogEntry le = LoggerService.DB.convert((Log__c)Collection.head([
				SELECT Id, Class__c, Message__c, Method__c, Severity__c, Version__c
				FROM Log__c
				LIMIT 1
			]));
			System.assertNotEquals(null, le);
			System.assertNotEquals(null, le.id);
			System.assertEquals(Application.version, le.version);
			System.assertEquals(LoggingLevel.DEBUG, le.severity);
			System.assertEquals('message', le.message);
			System.assertEquals('class', le.className);
			System.assertEquals('method', le.methodName);
		}
	}
}
