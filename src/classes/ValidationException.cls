public class ValidationException extends Exception {

	public Object details { get; private set; }

	public ValidationException(final String message, final Object details) {
		this(message + (details == null ? '' : '\n' + details));
		this.details = details;
	}
}
