/**
* This class contains unit tests for validating the behavior of Apex class LoggerService.
*/
@IsTest
private class LoggerServiceTest {
	private static final String TEST_EXCEPTION_MESSAGE = 'Test exception';
	private static final DocuSignException TEST_EXCEPTION = new DocuSignException(TEST_EXCEPTION_MESSAGE);

	static testMethod void test_constructor() {
		Test.startTest();
		LoggerService logger = LoggerService.getInstance();
		Test.stopTest();

		System.assert(logger.totalLog == '');
		System.assert(!logger.LogAllOnErrorLevel);
	}

	static testMethod void test_exception() {
		Test.startTest();
		LoggerService logger = LoggerService.getInstance();
		try {
			throw TEST_EXCEPTION;
		} catch (Exception e) {
			logger.exception(e, 'Somewhere happened');
		}
		Test.stopTest();

		System.assert(logger.totalLog.contains('Somewhere happened'));
		System.assert(logger.totalLog.contains(DocuSignException.class.getName()));
		System.assert(logger.totalLog.contains(TEST_EXCEPTION_MESSAGE));
	}

	static testMethod void test_exception_only() {
		Test.startTest();
		LoggerService logger = LoggerService.getInstance();
		try {
			throw TEST_EXCEPTION;
		} catch (Exception e) {
			logger.exception(e);
		}
		Test.stopTest();

		System.assert(logger.totalLog.contains(DocuSignException.class.getName()));
		System.assert(logger.totalLog.contains(TEST_EXCEPTION_MESSAGE));
	}

	static testMethod void test_exception_null() {
		Test.startTest();
		LoggerService logger = LoggerService.getInstance();
		try {
			throw TEST_EXCEPTION;
		} catch (Exception e) {
			logger.exception(null);
		}
		Test.stopTest();

		System.assertEquals('', logger.totalLog);
	}

	static testMethod void test_exception_nullAll() {
		Test.startTest();
		LoggerService logger = LoggerService.getInstance();
		try {
			throw TEST_EXCEPTION;
		} catch (Exception e) {
			logger.exception(null, null);
		}
		Test.stopTest();

		System.assertEquals('', logger.totalLog);
	}

	static testMethod void test_exception_null_and_empty() {
		Test.startTest();
		LoggerService logger = LoggerService.getInstance();
		try {
			throw TEST_EXCEPTION;
		} catch (Exception e) {
			logger.exception(null, '');
		}
		Test.stopTest();

		System.assertEquals('', logger.totalLog);
	}

	static testMethod void test_exception_nullAdditionalInfo() {
		Test.startTest();
		LoggerService logger = LoggerService.getInstance();
		try {
			throw TEST_EXCEPTION;
		} catch (Exception e) {
			logger.exception(e, null);
		}
		Test.stopTest();

		System.assert(logger.totalLog.contains(DocuSignException.class.getName()));
		System.assert(logger.totalLog.contains(TEST_EXCEPTION_MESSAGE));
	}

	static testMethod void test_exception_emptyAdditionalInfo() {
		Test.startTest();
		LoggerService logger = LoggerService.getInstance();
		try {
			throw TEST_EXCEPTION;
		} catch (Exception e) {
			logger.exception(e, '');
		}
		Test.stopTest();

		System.assert(logger.totalLog.contains(DocuSignException.class.getName()));
		System.assert(logger.totalLog.contains(TEST_EXCEPTION_MESSAGE));
	}

	static testMethod void test_noexception_butAdditionalInfo() {
		Test.startTest();
		LoggerService logger = LoggerService.getInstance();
		try {
			throw TEST_EXCEPTION;
		} catch (Exception e) {
			logger.exception(null, 'Somewhat');
		}
		Test.stopTest();

		System.assert(logger.totalLog.contains('Somewhat'));
	}

	static testMethod void test_error() {
		LoggerService logger = LoggerService.getInstance();
		Test.startTest();
		logger.error('ERROR1');
		logger.log(System.LoggingLevel.ERROR, 'ERROR2');
		Test.stopTest();

		System.assertEquals('ERR: ERROR1\nERR: ERROR2\n', logger.totalLog);
	}

	static testMethod void test_warning() {
		LoggerService logger = LoggerService.getInstance();
		Test.startTest();
		logger.warn('WARNING1');
		logger.log(System.LoggingLevel.WARN, 'WARNING2');
		Test.stopTest();

		System.assertEquals('WAR: WARNING1\nWAR: WARNING2\n', logger.totalLog);
	}

	static testMethod void test_info() {
		LoggerService logger = LoggerService.getInstance();
		Test.startTest();
		logger.info('INFO1');
		logger.log(System.LoggingLevel.INFO, 'INFO2');
		Test.stopTest();

		System.assertEquals('INF: INFO1\nINF: INFO2\n', logger.totalLog);
	}

	static testMethod void test_debug() {
		LoggerService logger = LoggerService.getInstance();
		Test.startTest();
		logger.debug('DEBUG1');
		logger.log(System.LoggingLevel.DEBUG, 'DEBUG2');
		Test.stopTest();

		System.assertEquals('DBG: DEBUG1\nDBG: DEBUG2\n', logger.totalLog);
	}

	static testMethod void test_fine() {
		LoggerService logger = LoggerService.getInstance();
		Test.startTest();
		logger.log(System.LoggingLevel.FINE, 'FINE');
		Test.stopTest();

		System.assertEquals('DBG: FINE\n', logger.totalLog);
	}

	static testMethod void test_finer() {
		LoggerService logger = LoggerService.getInstance();
		Test.startTest();
		logger.log(System.LoggingLevel.FINER, 'FINER');
		Test.stopTest();

		System.assertEquals('DBG: FINER\n', logger.totalLog);
	}

	static testMethod void test_finest() {
		LoggerService logger = LoggerService.getInstance();
		Test.startTest();
		logger.log(System.LoggingLevel.FINEST, 'FINEST');
		Test.stopTest();

		System.assertEquals('DBG: FINEST\n', logger.totalLog);
	}

	static testMethod void test_emptymessage() {
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
		logger.log(System.LoggingLevel.FINE, '');
		logger.log(System.LoggingLevel.FINER, '');
		logger.log(System.LoggingLevel.FINEST, '');
		Test.stopTest();

		System.assertEquals('', logger.totalLog);
	}

	static testMethod void test_nullmessage() {
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
		logger.log(System.LoggingLevel.FINE, null);
		logger.log(System.LoggingLevel.FINER, null);
		logger.log(System.LoggingLevel.FINEST, null);
		Test.stopTest();

		System.assertEquals('', logger.totalLog);
	}
}
