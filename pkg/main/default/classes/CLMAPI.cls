public with sharing class CLMAPI extends DocuSignAPI {
	private static final String API = 'api';
	private static final String API_VERSION = 'v1';
	private static final String GET_SESSION_URL = 'GetSessionUrl';
	private Map<String, String> defaultHeaders = null;
	private static CLMAPI self = null;
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

	private static Url getResourceAuthUrl(){
		//TODO: replace hardcoded string with appropriate auth url
		return new Url('https://qana11.springcm.com/atlas/');
	}

	@TestVisible
	override protected Map<String,String> getDefaultHeaders(){
		if (this.defaultHeaders == null) {
			this.defaultHeaders = new Map<String, String> {
				'Content-Type' => 'application/json',
				'Accept' => 'application/json',
				'Authorization' => 'Bearer ' + AuthService.getAccessTokenWithClmScope()
			};
		}
		return this.defaultHeaders;
	}

	public String getAPIResponse(String formattedPostReqUrl){
		Credentials c = Credentials.getInstance();
		final RestAPI.Response response = post(
			getBaseUrl(),
			new List<Object> {String.valueOf(c.account.Id), GET_SESSION_URL},
			QueryString.empty,
			this.getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'url' => formattedPostReqUrl
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to fetch response: ' + response.error);
			throw new APIException(response.error);
		}
		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return (String)body.get('Url');
	}

	public static Url createFormattedPostReqUrl(QueryString queryParams, String postReqUrlPath){
		String spec = String.format('{0}?{1}', new List<String> {postReqUrlPath, queryParams.toString()});
		Url formattedUrl = new Url(getResourceAuthUrl(), spec);
		System.debug('formattedUrl: '+formattedUrl);
		return formattedUrl;
	}
}	