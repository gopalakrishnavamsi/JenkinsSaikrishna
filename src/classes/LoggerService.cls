/**
 * This class is responsible for writing errors, warnings, info and debug statements to logs.
 */
public class LoggerService {

	private static LoggerService self;
	private static final Integer HEAP_LOG_PERCENTAGE_LIMIT = 80;

	public Boolean useInMemoryLog { get; private set; }
	public String inMemoryLog { get; private set; }

	/**
	 * LoggerService Constructor.
	 */
	private LoggerService() {
		this.useInMemoryLog = false; // Disabled for now.
		this.inMemoryLog = '';
	}

	public static LoggerService getInstance() {
		if (self == null) {
			self = new LoggerService();
		}
		return self;
	}

	/**
	 * This method builds and logs a message at error logging level using the provided Exception.
	 * @param e Exception object to log
	 */
	public void exception(final Exception e) {
		this.exception(e, '');
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
			if (this.useInMemoryLog) writeToInMemoryLog(level, message);
		}
	}

	private void writeToInMemoryLog(final System.LoggingLevel level, final String message) {
		Integer heapSize = Limits.getHeapSize();
		Integer limitHeapSize = Limits.getLimitHeapSize();
		Boolean hasEnoughHeapSpace = LoggerService.getHeapPercentUsage(heapSize, limitHeapSize) < HEAP_LOG_PERCENTAGE_LIMIT;
		if (hasEnoughHeapSpace || level == System.LoggingLevel.ERROR) {
			String msg = formatMessage(level, message);
			// Double check if we have enough memory to store to log message
			// FIXME: This is broken as Strings are immutable. This will add way more to the heap than what's calculated.
			if ((heapSize + (msg.length() * 4)) < limitHeapSize) {
				this.inMemoryLog += msg;
			}
		}
	}

	/**
	 * This method format the message with level name and line breaks.
	 * @param level System.LoggingLevel
	 * @param message String to log
	 */
	private String formatMessage(final System.LoggingLevel level, final String message) {
		String levelName;
		if (level == System.LoggingLevel.ERROR) {
			levelName = 'ERR: ';
		} else if (level == System.LoggingLevel.WARN) {
			levelName = 'WAR: ';
		} else if (level == System.LoggingLevel.INFO) {
			levelName = 'INF: ';
		} else /* assuming (level == LoggerService.LoggingLevel.DEBUG) */ {
			levelName = 'DBG: ';
		}
		return levelName + message + '\n';
	}

	/**
	 * This method calculates the heap percentage used using Salesforce Limits api.
	 * @return Integer heap percentage used
	 */
	private static Integer getHeapPercentUsage(final Integer heapSize, final Integer limitHeapSize) {
		Decimal usagePart = heapSize / limitHeapSize;
		return (Integer)usagePart.round(System.RoundingMode.DOWN) * 100;
	}
}
