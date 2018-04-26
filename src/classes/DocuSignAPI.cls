/*
 * This class is responsible for consuming the DocuSign REST APIs. This adheres to the following rules:
 * 	1) Do not leak internal API representations, error messages, etc. These are difficult to use or unnecessarily
 * 		fragile representations that often do not make sense for our use cases. Always return canonical DocuSign.*
 * 		types from public methods.
 * 	2) Do not expose more methods than we are actually using. These extra methods require unit tests and maintenance
 * 		in addition to bloating our package.
 * 	3) Do not construct Urls or JSON by hand. This exposes potential security issues with URL rewriting or JSON
 * 		injection. There are appropriate helper methods to do this safely.
 * 	4) Avoid special-casing any API calls. Use defaults wherever possible such as base URL and headers.
 * 	5) Avoid noisy logging. Log only failures with enough information to troubleshoot the issue.
 * 	6) Never log secrets or other sensitive information: password, token, or PII logging is strictly prohibited. Do not
 * 		log complete requests or responses as they may contain the above.
 * 	7) Avoid creating new callouts. First check if the information required is already returned by an existing API call.
 */
public with sharing virtual class DocuSignAPI extends RestAPI {

	private static DocuSignAPI self = null;
	private static final String SUCCESS = 'SUCCESS';
	private static final String INVALID_PASSWORD = 'INVALID_PASSWORD';
	private static final String INVALID_TOKEN = 'AUTHORIZATION_INVALID_TOKEN';
	private static final String AUTH_FAILED = 'USER_AUTHENTICATION_FAILED';
	private static final String PARTNER_AUTHENTICATION_FAILED = 'PARTNER_AUTHENTICATION_FAILED';

	@TestVisible
	private transient final Map<String, String> defaultHeaders;
	@TestVisible
	protected transient final String legacyAuthHeader;
	@TestVisible
	protected transient final Url baseUrl;
	private transient Url accountBaseUrl;
	@TestVisible
	protected transient final Environment environment;
	private final UUID accountId;

	// Serialization object for legacyAuthHeader
	@TestVisible
	private class LegacyCredentials {
		@TestVisible
		private String Username;
		@TestVisible
		private String Password;
		@TestVisible
		private String IntegratorKey;
		@TestVisible
		private String SendOnBehalfOf;

		public LegacyCredentials(
			final String username,
			final String password,
			final String sendOnBehalfOfId) {

			this.IntegratorKey = Application.INTEGRATOR_KEY;
			this.Username = String.isBlank(username) ? '' : username;
			this.Password = String.isBlank(password) ? '' : password;

			if (String.isNotBlank(sendOnBehalfOfId) && this.Username != sendOnBehalfOfId) {
				this.SendOnBehalfOf = sendOnBehalfOfId;
			}
		}
	}

	@TestVisible
	protected DocuSignAPI(final Credentials apiCredentials) {
		super();

		if (apiCredentials == null || apiCredentials.environment == null || apiCredentials.environment.baseUrl == null)
			throw new DocuSignException(Label.AccountNotConfigured);

		this.environment = apiCredentials.environment;
		this.baseUrl = apiCredentials.environment.baseUrl;
		this.legacyAuthHeader = JSON.serialize(
			new LegacyCredentials(
				apiCredentials.username,
				apiCredentials.password,
				apiCredentials.sendOnBehalfOf));
		this.defaultHeaders = new Map<String, String> {
			'Content-Type' => 'application/json',
			'Accept' => 'application/json',
			'X-DocuSign-Authentication' => this.legacyAuthHeader
		};
		this.accountId = apiCredentials.accountId;
	}

	public static DocuSignAPI getInstance() {
		if (self == null) {
			self = new DocuSignAPI(Credentials.getInstance());
		}
		return self;
	}

	@TestVisible
	protected virtual Url getBaseUrl() {
		if (accountBaseUrl == null) {
			if (this.accountId == null) {
				throw new DocuSignException(Label.AccountNotConfigured);
			}
			accountBaseUrl = new Url(this.baseUrl, '/restapi/v2/accounts/' + this.accountId + '/');
		}
		return accountBaseUrl;
	}

	@TestVisible
	protected virtual Map<String, String> getDefaultHeaders() {
		return this.defaultHeaders;
	}

	protected virtual RestAPI.Response get(final List<Object> path, final QueryString queryString, final Integer timeout) {
		return super.get(getBaseUrl(), path, queryString, getDefaultHeaders(), timeout);
	}

	protected virtual RestAPI.Response get(final String path, final Integer timeout) {
		return super.get(getBaseUrl(), new List<Object> { path }, QueryString.empty, getDefaultHeaders(), timeout);
	}

	protected virtual RestAPI.Response get(final String path, final QueryString queryString, final Integer timeout) {
		return super.get(getBaseUrl(), new List<Object> { path }, queryString, getDefaultHeaders(), timeout);
	}

	protected virtual RestAPI.Response post(final String path, final String body, final Integer timeout) {
		return super.post(getBaseUrl(), new List<Object> { path }, QueryString.empty, getDefaultHeaders(), body, timeout);
	}

	protected virtual RestAPI.Response post(final List<Object> path, final String body, final Integer timeout) {
		return super.post(getBaseUrl(), path, QueryString.empty, getDefaultHeaders(), body, timeout);
	}

	protected virtual RestAPI.Response put(final List<Object> path, final String body, final Integer timeout) {
		return super.put(getBaseUrl(), path, QueryString.empty, getDefaultHeaders(), body, timeout);
	}

	protected virtual RestAPI.Response put(final List<Object> path, final QueryString queryString, final String body, final Integer timeout) {
		return super.put(getBaseUrl(), path, queryString, getDefaultHeaders(), body, timeout);
	}

	protected virtual RestAPI.Response del(final List<Object> path, final Integer timeout) {
		return super.del(getBaseUrl(), path, QueryString.empty, getDefaultHeaders(), null, timeout);
	}

	protected virtual RestAPI.Response del(final String path, final String body, final Integer timeout) {
		return super.del(getBaseUrl(), new List<Object> { path }, QueryString.empty, getDefaultHeaders(), body, timeout);
	}

	// UGH. Apex doesn't allow protected inner classes, so we either leak an API implementation-specific type or
	// duplicate code :(
	public class Error extends APIError {
		public String docuSignCode { get; private set; }

		public Error(final Integer code, final String docuSignCode, final String description) {
			super(code, description);
			this.docuSignCode = docuSignCode;
		}
	}

	public class ErrorDetails {
		public String errorCode;
		public String message;

		public APIError toExternalForm() {
			if (errorCode == SUCCESS) {
				return APIError.none;
			} else if (errorCode == INVALID_PASSWORD || errorCode == INVALID_TOKEN || errorCode == AUTH_FAILED
				|| errorCode == PARTNER_AUTHENTICATION_FAILED) {

				return new Error(APIErrorCode.UNAUTHORIZED, errorCode, message);
			} else {
				return new Error(APIErrorCode.BAD_REQUEST, errorCode, message);
			}
		}
	}

	@TestVisible
	override protected virtual APIError getError(final HttpResponse response) {
		APIError e = super.getError(response);
		if (e != APIError.none) {
			if (e.code == APIErrorCode.BAD_REQUEST) {
				final String body = response.getBody();
				try {
					e = ((DocuSignAPI.ErrorDetails)JSON.deserialize(body, DocuSignAPI.ErrorDetails.class)).toExternalForm();
					this.log.warn('Received error from DocuSign API: [' + ((DocuSignAPI.Error)e).docuSignCode + '] ' + e.description);
				} catch (Exception ex) {
					this.log.warn('Failed to parse 400 BAD_REQUEST as DocuSign error. Response body:\n' + body);
				}
			} else if (e.code == APIErrorCode.UNAUTHORIZED) {
				this.log.warn('User is unauthorized: ' + UserInfo.getUserEmail() + '\n' + response.getBody());
				throw UnauthorizedException.mayRequireActivation();
			}
		}
		this.log.info('DocuSign trace token: ' + response.getHeader('X-DocuSign-TraceToken'));
		return e;
	}

	public Boolean ping() {
		return this.ping(RestAPI.defaultTimeout);
	}

	public Boolean ping(final Integer timeout) {
		Boolean result = false;
		try {
			super.get(
				baseUrl,
				new List<Object> { 'service_information' },
				QueryString.empty,
				new Map<String, String>(),
				timeout);
			result = true;
		} catch (CalloutException ex) {
			this.log.warn('GET /service_information call failed: ' + ex.getMessage());
		}
		return result;
	}
}
