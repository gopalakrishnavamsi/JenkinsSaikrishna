/**
 * Exceptions raised by the DocuSign API.
 */
global class APIException extends Exception {
	/**
	 * The underlying API error that triggered the exception.
	 */
	global APIError error { get; private set; }

	public APIException(final APIError error) {
		if (error == null) {
			this(Label.SalesforceApiErrorUnexpectedResponse);
			this.error = APIError.generic;
		} else {
			this(error.toString());
			this.error = error;
		}
	}
}
