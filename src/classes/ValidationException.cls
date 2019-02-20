/**
 * Exceptions raised when an object fails to validate. For example, when an invalid <code>dfsle.Envelope</code> is
 * passed to the <code>dfsle.EnvelopeService.sendEnvelope</code> method.
 */
global class ValidationException extends Exception {
	/**
	 * Details of the failed validation. In most cases, this will be an instance of <code>dfsle.ValidationResult</code>.
	 */
	global Object details { get; private set; }

	public ValidationException(final String message, final Object details) {
		this(message + (details == null ? '' : '\n' + details));
		this.details = details;
	}
}
