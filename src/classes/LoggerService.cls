/**
 * This class is responsible for writing errors, warnings, info and debug statements to logs.
 */
public class LoggerService {

	private static LoggerService self;
	private static final Integer HEAP_LOG_PERCENTAGE_LIMIT = 80;

	public Boolean logAllOnErrorLevel { get; set; }
	public String totalLog { get; private set; }

	/**
	 * LoggerService Constructor.
	 */
	private LoggerService() {
		this.totalLog = '';
		this.logAllOnErrorLevel = false;
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
	 * This method builds and logs a message at error logging level using the provided
	 * Exception and additional information string.
	 * @param e Exception object to log
	 * @param additionalInfo String to log
	 */
	public void exception(final Exception e, final String additionalInfo) {
		String fullMessage = '';
		if (String.isNotBlank(additionalInfo)) {
			fullMessage += additionalInfo + '\n';
		}
		if (e != null) {
			fullMessage += String.format('{0}: {1}\n{2}', new List<String> {
				e.getTypeName(),
				e.getMessage(),
				e.getStackTraceString()
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
		try {
			if (String.isEmpty(message)) {
				return;
			}
			final System.LoggingLevel correctedLevel = logAllOnErrorLevel ? System.Logginglevel.ERROR : level;
			System.debug(correctedLevel, message);
			final Boolean hasEnoughtHeapFreeSpace = LoggerService.getHeapPercentUsage() < HEAP_LOG_PERCENTAGE_LIMIT;
			final Boolean logLevelIsError = correctedLevel == System.Logginglevel.ERROR;
			final Boolean collectThisLog = hasEnoughtHeapFreeSpace || logLevelIsError;
			if (collectThisLog) {
				final String msg = formatMessage(level, message);
				//Double check if we have enough memory to store to log message
				if ((Limits.getHeapSize() + msg.length()) < Limits.getLimitHeapSize()) {
					this.totalLog += msg;
				}
			}
		} catch (Exception e) {
			// logger should be exception safe anyway
		}
	}

	/**
	 * This method format the message with level name and line breaks.
	 * @param level System.LoggingLevel
	 * @param message String to log
	 */
	private String formatMessage(final System.LoggingLevel level, final String message) {
		String levelName = 'UNK: ';
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
	private static Integer getHeapPercentUsage() {
		final Decimal usagePart = Limits.getHeapSize() / Limits.getLimitHeapSize();
		return (Integer)usagePart.round(System.Roundingmode.DOWN) * 100;
	}
}
