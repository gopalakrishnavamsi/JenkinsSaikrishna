/**
 * Constants for API error codes.
 */
global class APIErrorCode {
	// Not an exhaustive list, but should include anything returned by DS APIs at least.
	//public static final Integer INVALID = -1;
	/**
	 * No error occurred.
	 */
	global static final Integer SUCCESS = 0;
	/**
	 * An unspecified error occurred.
	 */
	global static final Integer FAILURE = 1;
	public static final Integer BAD_REQUEST = 400;
	public static final Integer UNAUTHORIZED = 401;
	public static final Integer NOT_FOUND = 404;
	public static final Integer UNSUPPORTED_MEDIA_TYPE = 415;
	public static final Integer UNPROCESSABLE_ENTITY = 422;
	public static final Integer INTERNAL_SERVER_ERROR = 500;
	//public static final Integer HTTP_ERROR_OTHER = 1000;
	public static final Integer NULL_RESPONSE = 1001;
	public static final Integer INVALID_CONTENT_TYPE = 1002;
	/**
	 * The account does not have access to a DocuSign feature.
	 */
	global static final Integer ACCOUNT_LACKS_PERMISSIONS = 1003;
	/**
	 * The user is already a member of the account.
	 */
	global static final Integer USER_ALREADY_EXISTS_IN_ACCOUNT = 1004;
	/**
	 * The envelope recipient is unknown.
	 */
	global static final Integer UNKNOWN_RECIPIENT = 1005;
	/**
	 * The user is in a pending activation state.
	 */
	global static final Integer USER_PENDING = 1006;
	/**
	 * The user is unknown to DocuSign.
	 */
	global static final Integer UNKNOWN_USER = 1007;
	/**
	 * The recipient sequence is invalid for the envelope.
	 */
	global static final Integer INVALID_RECIPIENT_SEQUENCE = 1008;
	public static final Integer DATABASE_ERROR = 1009;
	public static final Integer METADATA_API_NOT_SUPPORTED = 1010;
	/**
	 * The DocuSign trial has expired.
	 */
	global static final Integer TRIAL_ACCOUNT_EXPIRED = 1011;
	public static final Integer FAILED_TO_MEET_21_CFR_PART_11 = 1012;
	/**
	 * The user has not yet been activated in DocuSign.
	 */
	global static final Integer USER_NOT_ACTIVATED = 1013;
	/**
	 * The hourly API limit has been exceeded for the DocuSign account.
	 */
	global static final Integer HOURLY_API_LIMIT_EXCEEDED = 1014;
	/**
	 * The envelope document is invalid.
	 */
	global static final Integer INVALID_DOCUMENT = 1015;
	/**
	 * The envelope recipient is invalid.
	 */
	global static final Integer INVALID_RECIPIENT = 1016;
	/**
	 * The user has not granted consent to be impersonated by this application.
	 */
	global static final Integer CONSENT_REQUIRED = 1017;
	public static final Integer INVALID_GRANT = 1018;
	public static final Integer INVALID_OPERATION = 1019;
	public static final Integer UNDEFINED_REQUEST_BODY = 1020;
	public static final Integer INVALID_JSON = 1021;
	/**
	 * The envelope recipient signing group is invalid.
	 */
	global static final Integer INVALID_SIGNING_GROUP = 1022;
}
