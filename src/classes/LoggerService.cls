/**
 * This class is responsible for writing errors, warnings, info and debug statements to logs.
 */
public class LoggerService {

	private static LoggerService self;

	public static LoggerService getInstance() {
		if (self == null) {
			self = new LoggerService();
		}
		return self;
	}

	/**
	 * This method builds and logs a message at error logging level using the provided Exception.
	 * @param ex Exception object to log
	 */
	public void exception(final Exception ex) {
		this.exception(ex, '');
	}

	/**
	 * This method builds and logs a message at error logging level using the provided exception and additional context.
	 *
	 * @param ex The exception to log.
	 * @param context Additional context to log.
	 */
	public void exception(final Exception ex, final String context) {
		String fullMessage = '';
		if (String.isNotBlank(context)) {
			fullMessage += context + '\n';
		}
		if (ex != null) {
			fullMessage += String.format('{0}: {1}\n{2}', new List<String> {
				ex.getTypeName(),
				ex.getMessage(),
				ex.getStackTraceString()
			});
		}
		if (String.isNotBlank(fullMessage)) {
			this.error(fullMessage);
		}
	}

	/**
	 * This method builds and logs a message at error logging level using the provided message.
	 * @param message String to log
	 */
	public void error(final String message) {
		this.log(System.LoggingLevel.ERROR, message);
	}

	/**
	 * This method builds and logs a message at warning logging level using the provided message.
	 * @param message String to log
	 */
	public void warn(final String message) {
		this.log(System.LoggingLevel.WARN, message);
	}

	/**
	 * This method builds and logs a message at info logging level using the provided message.
	 * @param message String to log
	 */
	public void info(final String message) {
		this.log(System.LoggingLevel.INFO, message);
	}

	/**
	 * This method builds and logs a message at debug logging level using the provided message.
	 * @param message String to log
	 */
	public void debug(final String message) {
		this.log(System.LoggingLevel.DEBUG, message);
	}

	/**
	 * This method logs the provided message and the level specified while honoring heap limits.
	 * @param level System.LoggingLevel
	 * @param message String to log
	 */
	public void log(final System.LoggingLevel level, final String message) {
		if (String.isNotBlank(message)) {
			System.debug(level, message);
		}
	}
}
