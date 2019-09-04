public with sharing class CLMAPI extends DocuSignAPI {
	private static final String API = 'api';
	private static final String API_VERSION = 'v1';
	private static final String GET_SESSION_URL = 'GetSessionUrl';
	private UUID accountId;
	private static CLMAPI self = null;
	private static final String SFOID='sfoid';
	private static final String SFON='sfon';
	private static final String SFOT='sfot';
	private static final String EOSPATH='eosPath';
	private static final String AID='aid';
	private static final String POST_REQ_PATH_FOLDER_VIEW = 'EOS/GetEosInformation.aspx';
	private static final String POST_REQ_PATH_DOC_GEN = 'Admin/DocLauncherConfig';
	private static final String POST_REQ_PATH_WORKFLOW = 'workflow';
	//TODO: Replace AUTH_BASE_URL with appropriate value from custom setting
	private static String AUTH_BASE_URL = 'https://authqa.springcm.com';

	private CLMAPI(final Url baseUrl, final String api, final String apiVersion) {
		super(new Url (baseUrl, String.format('/{0}/{1}/',
											new List<String> {
				api,
				apiVersion
			})));
	}

	public static CLMAPI getInstance() {
		if (self == null) {
			//TODO: replace authBaseUrl with appropriate custom setting value
			Url authBaseUrl = new Url(AUTH_BASE_URL);
			self = new CLMAPI(authBaseUrl, API, API_VERSION);
		}
		return self;
	}

	private static Url getResourceAuthUrl() {
		//TODO: replace hardcoded string with appropriate auth url
		return new Url('https://qana11.springcm.com/atlas/');
	}

	public Url getClmUrl(CLMService.SubstitutedParams eosValues) {
		QueryString queryParams =  new QueryString(new Map<String, String> {SFOID => eosValues.salesforceObjectId, SFON => eosValues.salesforceFolderName, SFOT => eosValues.salesforceObjectType, EOSPATH => eosValues.externalObjectStoragePath});
		String spec = String.format('{0}?{1}', new List<String> {POST_REQ_PATH_FOLDER_VIEW, queryParams.toString()});
		Url formattedPostReqUrl = new Url(getResourceAuthUrl(), spec);
		Credentials c = Credentials.getInstance();
		accountId = c.account.Id;
		final RestAPI.Response response = post(
			getBaseUrl(),
			new List<Object> {String.valueOf(accountId), GET_SESSION_URL},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'url' => formattedPostReqUrl.toExternalForm()
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to fetch response: ' + response.error);
			throw new APIException(response.error);
		}
		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return new Url(String.valueOf(body.get('Url')));
	}

	public Url getDocGenUrl() {
		Credentials c = Credentials.getInstance();
		accountId = c.account.Id;
		QueryString queryParams =  new QueryString(new Map<String, String> {AID => String.valueOf(c.account.accountNumber)});
		String spec = String.format('{0}?{1}', new List<String> {POST_REQ_PATH_DOC_GEN, queryParams.toString()});
		Url formattedPostReqUrl = new Url(getResourceAuthUrl(), spec);
		final RestAPI.Response response = post(
			getBaseUrl(),
			new List<Object> {String.valueOf(accountId), GET_SESSION_URL},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'url' => formattedPostReqUrl.toExternalForm()
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to fetch response: ' + response.error);
			throw new APIException(response.error);
		}
		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return new Url(String.valueOf(body.get('Url')));
	}

	public Url getWorkflowUrl() {
		Credentials c = Credentials.getInstance();
		accountId = c.account.Id;
		QueryString queryParams =  new QueryString(new Map<String, String> {AID => String.valueOf(c.account.accountNumber)});
		String spec = String.format('{0}?{1}', new List<String> {POST_REQ_PATH_WORKFLOW, queryParams.toString()});
		Url formattedPostReqUrl = new Url(getResourceAuthUrl(), spec);
		final RestAPI.Response response = post(
			getBaseUrl(),
			new List<Object> {String.valueOf(accountId), GET_SESSION_URL},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'url' => formattedPostReqUrl.toExternalForm()
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to fetch response: ' + response.error);
			throw new APIException(response.error);
		}
		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return new Url(String.valueOf(body.get('Url')));
	}
}