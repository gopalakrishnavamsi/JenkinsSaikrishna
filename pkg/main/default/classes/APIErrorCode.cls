public class APIErrorCode {

	// Not an exhaustive list, but should include anything returned by DS APIs at least.
	//public static final Integer INVALID = -1;
	public static final Integer SUCCESS = 0;
	public static final Integer FAILURE = 1;
	public static final Integer BAD_REQUEST = 400;
	public static final Integer UNAUTHORIZED = 401;
	public static final Integer NOT_FOUND = 404;
	public static final Integer UNSUPPORTED_MEDIA_TYPE = 415;
	public static final Integer UNPROCESSABLE_ENTITY = 422;
	public static final Integer INTERNAL_SERVER_ERROR = 500;
	//public static final Integer HTTP_ERROR_OTHER = 1000;
	public static final Integer NULL_RESPONSE = 1001;
	public static final Integer INVALID_CONTENT_TYPE = 1002;
	public static final Integer ACCOUNT_LACKS_PERMISSIONS = 1003;
	public static final Integer USER_ALREADY_EXISTS_IN_ACCOUNT = 1004;
	public static final Integer UNKNOWN_RECIPIENT = 1005;
	public static final Integer USER_PENDING = 1006;
	public static final Integer UNKNOWN_USER = 1007;
	public static final Integer INVALID_RECIPIENT_SEQUENCE = 1008;
	public static final Integer DATABASE_ERROR = 1009;
	public static final Integer METADATA_API_NOT_SUPPORTED = 1010;
	public static final Integer TRIAL_ACCOUNT_EXPIRED = 1011;
	public static final Integer FAILED_TO_MEET_21_CFR_PART_11 = 1012;
	public static final Integer USER_NOT_ACTIVATED = 1013;
	public static final Integer HOURLY_API_LIMIT_EXCEEDED = 1014;
	public static final Integer INVALID_DOCUMENT = 1015;
	public static final Integer INVALID_SIGNING_GROUP = 1015;
	public static final Integer INVALID_RECIPIENT = 1016;
	public static final Integer CONSENT_REQUIRED = 1017;
	public static final Integer INVALID_GRANT = 1018;
	public static final Integer INVALID_OPERATION = 1019;
}
