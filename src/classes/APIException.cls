public class APIException extends Exception {

	public APIError error { get; private set; }

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
