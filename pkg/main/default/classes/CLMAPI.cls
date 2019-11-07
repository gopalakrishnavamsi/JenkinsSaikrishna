public with sharing class CLMAPI extends ScmAPI {
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

	private CLMAPI(final Url baseUrl, final String api, final String apiVersion) {
		super(new Url (baseUrl, String.format('/{0}/{1}/',
		                                      new List<String> {
			api,
			apiVersion
		})));
	}

	public static CLMAPI getInstance() {
		if (self == null) {
			Url baseUrl = AccountProducts.getInstance().getScmAuthBaseUrl();
			if (baseUrl == null) {
				LoggerService.getInstance().error('SCM auth base URL is not configured');
				throw new DocuSignException(Label.CLMNotConfigured);
			}
			self = new CLMAPI(baseUrl, API, API_VERSION);
		}
		return self;
	}

	private static Url getResourceAuthUrl() {
		Url resourceUrl = AccountProducts.getInstance().getScmWebBaseUrl();
		if (resourceUrl == null) {
			LoggerService.getInstance().error('SCM web base URL is not configured');
			throw new DocuSignException(Label.MissingDocuSignCLMSettings);
		}
		return resourceUrl;
	}

	public Url getClmUrl(CLMService.SubstitutedParams eosValues) {
		QueryString queryParams =  new QueryString(new Map<String, String> {SFOID => eosValues.salesforceObjectId, SFON => eosValues.salesforceFolderName, SFOT => eosValues.salesforceObjectType, EOSPATH => eosValues.externalObjectStoragePath});
		String spec = String.format('{0}?{1}', new List<String> {POST_REQ_PATH_FOLDER_VIEW, queryParams.toString()});
		Url formattedPostReqUrl = new Url(getResourceAuthUrl(), spec);
		Credentials c = Credentials.getInstance();
		accountId = c.account.Id;
		final RestAPI.Response response = post(
			new List<Object> {String.valueOf(accountId), GET_SESSION_URL},
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
			new List<Object> {String.valueOf(accountId), GET_SESSION_URL},
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
