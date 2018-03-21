public class ValidationException extends Exception {

	public ValidationException(final String message, final Object details) {
		this(message + (details == null ? '' : '\n' + details));
	}
}
