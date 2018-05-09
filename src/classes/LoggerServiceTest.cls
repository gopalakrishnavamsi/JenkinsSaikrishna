@IsTest(isParallel = true)
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
	static void test_fine() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.log(System.LoggingLevel.FINE, 'FINE');
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}

	@IsTest
	static void test_finer() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.log(System.LoggingLevel.FINER, 'FINER');
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}

	@IsTest
	static void test_finest() {
		LoggerService logger = LoggerService.getInstance();

		Test.startTest();
		logger.log(System.LoggingLevel.FINEST, 'FINEST');
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
		logger.log(System.LoggingLevel.FINE, '');
		logger.log(System.LoggingLevel.FINER, '');
		logger.log(System.LoggingLevel.FINEST, '');
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
		logger.log(System.LoggingLevel.FINE, null);
		logger.log(System.LoggingLevel.FINER, null);
		logger.log(System.LoggingLevel.FINEST, null);
		Test.stopTest();

		System.assertNotEquals(null, logger);
	}
}
