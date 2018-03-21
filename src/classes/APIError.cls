public virtual class APIError {
	public static final APIError none = new APIError(APIErrorCode.SUCCESS, null);
	public static final APIError generic = new APIError(APIErrorCode.FAILURE, null);

	public Integer code { get; private set; }
	public String description { get; private set; }

	public APIError(final Integer code, final String description) {
		this.code = code;
		this.description = String.isNotBlank(description) ? description : '';
	}

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

	override public Integer hashCode() {
		return this.code;
	}

	public Boolean equals(Object obj) {
		if (this === obj) return true;

		if (obj == null || !(obj instanceof APIError)) return false;

		return this.code == ((APIError)obj).code;
	}

	override public String toString() {
		return this.description;
	}
}
