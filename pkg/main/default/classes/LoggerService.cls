/**
 * This class is responsible for writing errors, warnings, info and debug statements to logs.
 */
public with sharing class LoggerService {

	private static LoggerService self;
	@TestVisible
	private static final LoggerService.Database DB = new LoggerService.Database();
	private static Pattern versionPattern = null;
	private static LoggingLevel level = null;

	public class LogEntry {
		public Id id { get; private set; }
		public Version version { get; private set; }
		public LoggingLevel severity { get; private set; }
		public String message { get; private set; }
		public String className { get; private set; }
		public String methodName { get; private set; }

		public LogEntry(
			final Id id,
			final Version version,
			final LoggingLevel severity,
			final String message,
			final String className,
			final String methodName) {

			this.id = id;
			this.version = version;
			this.severity = severity;
			this.message = message;
			this.className = className;
			this.methodName = methodName;
		}
	}

	private static Version parseVersion(final String s) {
		if (String.isBlank(s)) return null;

		if (versionPattern == null) versionPattern = Pattern.compile('^(\\d+)\\.(\\d+)(\\.(\\d+))?$');

		Version result = null;
		Matcher m = versionPattern.matcher(s);
		if (m.matches()) {
			if (String.isNotBlank(m.group(4))) { // major.minor.patch (group 3 is optional group)
				result = new Version(
					Integer.valueOf(m.group(1)),
					Integer.valueOf(m.group(2)),
					Integer.valueOf(m.group(4)));
			} else { // major.minor
				result = new Version(
					Integer.valueOf(m.group(1)),
					Integer.valueOf(m.group(2)));
			}
		}
		return result;
	}

	private static LoggingLevel parseLoggingLevel(final String s) {
		LoggingLevel result;
		switch on s {
			when 'ERROR' {
				result = LoggingLevel.ERROR;
			} when 'WARN' {
				result = LoggingLevel.WARN;
			} when 'INFO' {
				result = LoggingLevel.INFO;
			} when else {
				result = LoggingLevel.DEBUG;
			}
		}
		return result;
	}

	private class Database {

		private Log__c convert(final LogEntry logEntry) {
			if (logEntry == null) return null;

			return new Log__c(
				Class__c = logEntry.className,
				Message__c = logEntry.message,
				Method__c = logEntry.methodName,
				Severity__c = String.valueOf(logEntry.severity),
				Version__c = String.valueOf(logEntry.version));
		}

		private List<Log__c> convert(final List<LogEntry> logEntries) {
			List<Log__c> result = new List<Log__c>();
			if (logEntries != null) {
				for (LogEntry le : logEntries) {
					result.add(convert(le));
				}
			}
			return result;
		}

		@TestVisible
		private LogEntry convert(final Log__c log) {
			if (log == null) return null;

			return new LogEntry(
				log.Id,
				parseVersion(log.Version__c),
				parseLoggingLevel(log.Severity__c),
				log.Message__c,
				log.Class__c,
				log.Method__c);
		}

		private List<LogEntry> convert(final List<Log__c> logs) {
			List<LogEntry> result = new List<LogEntry>();
			if (logs != null) {
				for (Log__c l : logs) {
					result.add(convert(l));
				}
			}
			return result;
		}

		public List<LogEntry> insertEntries(final List<LogEntry> logEntries) {
			Permissions.verifyIsCreateable(Log__c.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'Class__c',
				Application.namespacePrefix + 'Message__c',
				Application.namespacePrefix + 'Method__c',
				Application.namespacePrefix + 'Severity__c',
				Application.namespacePrefix + 'Version__c'
			});

			if (Collection.isEmpty(logEntries)) return logEntries;

			List<Log__c> les = convert(logEntries);
			insert les;

			return convert(les);
		}
	}

	public static LoggerService getInstance() {
		if (self == null) {
			self = new LoggerService();
		}
		return self;
	}

	@TestVisible
	private static String getMessage(
		final Exception ex,
		final String context) {

		String result = '';
		if (String.isNotBlank(context)) {
			result += context + '\n';
		}
		if (ex != null) {
			result += String.format('{0}: {1}\n{2}', new List<String> {
				ex.getTypeName(),
				ex.getMessage(),
				ex.getStackTraceString()
			});
		}
		return result;
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
	public void exception(
		final Exception ex,
		final String context) {

		String message = getMessage(ex, context);
		if (String.isNotBlank(message)) {
			this.error(message);
		}
	}

	/**
	 * Writes an error message to the debug log and creates a log record. Callers must ensure the transaction is not
	 * rolled back because of unhandled exceptions.
	 *
	 * @param ex The exception to log.
	 * @param context Additional context to log.
	 * @param className The class logging the message.
	 * @param methodName The method logging the message.
	 */
	public void exception(
		final Exception ex,
		final String context,
		final String className,
		final String methodName) {

		String message = getMessage(ex, context);
		if (String.isNotBlank(message)) {
			this.log(new LogEntry(
				null,
				Application.version,
				LoggingLevel.ERROR,
				message,
				className,
				methodName));
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
	 * Writes an error message to the debug log and creates a log record. Callers must ensure the transaction is not
	 * rolled back because of unhandled exceptions.
	 *
	 * @param message The message to log.
	 * @param className The class logging the message.
	 * @param methodName The method logging the message.
	 */
	public void error(
		final String message,
		final String className,
		final String methodName) {

		if (String.isNotBlank(message)) {
			this.log(new LogEntry(
				null,
				Application.version,
				LoggingLevel.ERROR,
				message,
				className,
				methodName));
		}
	}

	/**
	 * This method builds and logs a message at warning logging level using the provided message.
	 * @param message String to log
	 */
	public void warn(final String message) {
		this.log(System.LoggingLevel.WARN, message);
	}

	/**
	 * Writes a warning message to the debug log and creates a log record. Callers must ensure the transaction is not
	 * rolled back because of unhandled exceptions.
	 *
	 * @param message The message to log.
	 * @param className The class logging the message.
	 * @param methodName The method logging the message.
	 */
	public void warn(
		final String message,
		final String className,
		final String methodName) {

		if (String.isNotBlank(message)) {
			this.log(new LogEntry(
				null,
				Application.version,
				LoggingLevel.WARN,
				message,
				className,
				methodName));
		}
	}

	/**
	 * This method builds and logs a message at info logging level using the provided message.
	 * @param message String to log
	 */
	public void info(final String message) {
		this.log(System.LoggingLevel.INFO, message);
	}

	/**
	 * Writes an info message to the debug log and creates a log record. Callers must ensure the transaction is not
	 * rolled back because of unhandled exceptions.
	 *
	 * @param message The message to log.
	 * @param className The class logging the message.
	 * @param methodName The method logging the message.
	 */
	public void info(
		final String message,
		final String className,
		final String methodName) {

		if (String.isNotBlank(message)) {
			this.log(new LogEntry(
				null,
				Application.version,
				LoggingLevel.INFO,
				message,
				className,
				methodName));
		}
	}

	/**
	 * This method builds and logs a message at debug logging level using the provided message.
	 * @param message String to log
	 */
	public void debug(final String message) {
		this.log(System.LoggingLevel.DEBUG, message);
	}

	/**
	 * Writes a debug message to the debug log and creates a log record. Callers must ensure the transaction is not
	 * rolled back because of unhandled exceptions.
	 *
	 * @param message The message to log.
	 * @param className The class logging the message.
	 * @param methodName The method logging the message.
	 */
	public void debug(
		final String message,
		final String className,
		final String methodName) {

		if (String.isNotBlank(message)) {
			this.log(new LogEntry(
				null,
				Application.version,
				LoggingLevel.DEBUG,
				message,
				className,
				methodName));
		}
	}

	@TestVisible
	private void log(
		final System.LoggingLevel level,
		final String message) {

		if (String.isNotBlank(message)) {
			System.debug(level, message);
		}
	}

	private static Boolean shouldLog(final LoggingLevel severity) {
		if (level == null) {
			LogSettings__c ls = LogSettings__c.getInstance();
			level = String.isBlank(ls.Level__c) ? LoggingLevel.NONE : parseLoggingLevel(ls.Level__c);
		}

		return severity != null
			&& level != LoggingLevel.NONE
			&& severity.ordinal() >= level.ordinal();
	}

	@TestVisible
	private LogEntry log(final LogEntry logEntry) {
		if (logEntry == null) return null;

		this.log(logEntry.severity, logEntry.message);

		if (!shouldLog(logEntry.severity)) return logEntry;

		try {
			return (LogEntry)Collection.head(DB.insertEntries(new List<LogEntry> { logEntry }));
		} catch (Exception ex) {
			this.log(LoggingLevel.ERROR, getMessage(ex, 'Failed to create log record.'));
			return logEntry;
		}
	}
}
