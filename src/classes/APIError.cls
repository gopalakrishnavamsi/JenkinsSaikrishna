/**
 * Represents an error returned by an API.
 */
public virtual class APIError {
	/**
	 * Constant for no error.
	 */
	public static final APIError none = new APIError(APIErrorCode.SUCCESS, null);
	/**
	 * Constant for a generic error.
	 */
	public static final APIError generic = new APIError(APIErrorCode.FAILURE, null);

	/**
	 * The error code.
	 */
	public Integer code { get; private set; }
	/**
	 * The error description.
	 */
	public String description { get; private set; }

	/**
	 * Constructs an API error.
	 *
	 * @param code The error code.
	 * @param description The error description.
	 */
	public APIError(final Integer code, final String description) {
		this.code = code;
		this.description = String.isNotBlank(description) ? description : '';
	}

	/**
	 * Factory method to construct an API error from an exception.
	 *
	 * @param ex The exception.
	 *
	 * @return An API error with <code>code</code> and <code>description</code> based on the exception type.
	 */
	public static APIError fromException(final Exception ex) {
		APIError error;
		if (ex instanceof APIException) {
			error = ((APIException)ex).error;
		} else if (ex instanceof ValidationException) {
			error = new APIError(APIErrorCode.BAD_REQUEST, ex.getMessage());
		} else if (ex instanceof UnauthorizedException) {
			error = new APIError(APIErrorCode.UNAUTHORIZED, ex.getMessage());
		} else if (ex instanceof DmlException) {
			if (ex.getMessage().contains('storage limit exceeded')) {
				error = new APIError(APIErrorCode.DATABASE_ERROR, Label.SalesforceOrgStorageLimitExceeded);
			} else {
				error = new APIError(APIErrorCode.DATABASE_ERROR, ex.getMessage());
			}
		} else if (ex instanceof Salesforce.MetadataApiNotSupportedException) {
			error = new APIError(APIErrorCode.METADATA_API_NOT_SUPPORTED, ex.getMessage());
		} else {
			error = new APIError(APIErrorCode.FAILURE, ex.getMessage());
		}
		return error;
	}

	/**
	 * Generates a hash code for the API error based on <code>code</code>.
	 *
	 * @return The generated hash code.
	 */
	override public Integer hashCode() {
		return this.code;
	}

	/**
	 * Tests whether an object is equal to an API error based on <code>code</code>.
	 *
	 * @param obj The object for which to test equality.
	 *
	 * @return <code>true</code> if the object equals the API error, <code>false</code> otherwise.
	 */
	public Boolean equals(Object obj) {
		if (this === obj) return true;

		if (obj == null || !(obj instanceof APIError)) return false;

		return this.code == ((APIError)obj).code;
	}

	/**
	 * Returns the string representation of the API error.
	 *
	 * @return The API error <code>description</code>.
	 */
	override public String toString() {
		return this.description;
	}
}
