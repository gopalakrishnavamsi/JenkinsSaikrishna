public with sharing class NegotiateAPI extends DocuSignAPI {
    // TODO: move common logic between GEN and Negotiate to parent class
    public static final String PATH_FOLDER = 'folders';

    private static NegotiateAPI self = null;

    private NegotiateAPI(final Url baseUrl) {
        super(new Url(baseUrl, '')); // TODO: use Negotiate baseURL, if any
    }

    public static NegotiateAPI getInstance() {
        if (self == null) {
            self = new NegotiateAPI(Credentials.getInstance().environment.scmApiBaseUrl); // TODO: as of now using Gen's
        }
        return self;
    }

    public class Error extends APIError {
        public UUID referenceId { get; private set; }

        public Error(
                final Integer code,
                final UUID referenceId,
                final String description) {

            super(code, description);

            this.referenceId = referenceId;
        }

        override public String toString() {
            return String.format(Label.ApiError_3, new List<String>{
                    String.valueOf(this.code),
                    this.description,
                    String.valueOf(this.referenceId)
            });
        }
    }

    @TestVisible
    override protected virtual APIError getError(final HttpResponse response) {
        APIError e = APIError.none;
        Integer statusCode = response.getStatusCode();
        if (statusCode >= 400) {
            String body = response.getBody();
            try {
                Map<String, Object> error = (Map<String, Object>) ((Map<String, Object>) JSON.deserializeUntyped(body))
                        .get('Error');
                e = new NegotiateAPI.Error(
                        error.containsKey('ErrorCode') ? (Integer) error.get('ErrorCode') : statusCode,
                        UUID.tryParse((String) error.get('ReferenceId')),
                        error.containsKey('UserMessage') ? (String) error.get('UserMessage') : response.getStatus());
                this.log.warn('Negotiate API error: ' + e);
            } catch (Exception ex) {
                this.log.exception(ex, 'Failed to parse Negotiate API error. Response body:\n' + body);
                e = new APIError(statusCode, response.getStatus());
            }
        }
        return e;
    }

    @TestVisible
    private class EosInfo {

        public String name ;
        public String objectId;
        public String objectType ;

        EosInfo(String objectName, String objectId, String objectType) {
            this.name = objectName;
            this.objectId = objectId;
            this.objectType = objectType;
        }
    }

    // Create EOS folder in SpringCM Space
    public String createEOSFolder(String objectName, String objectId, String objectType) {

        RestAPI.Response response = post(
                getBaseUrl(),
                new List<String> {PATH_FOLDER},
                QueryString.empty,
                getDefaultHeaders(),
                JSON.serialize(new Map<String, Object> {
                        'EosInfo' => new EosInfo(objectName, objectId, objectType)
                }),
                RestAPI.defaultTimeout);
        if (response.hasError) {
            this.log.error('Failed to create EOS folder: ' + response.error);
            throw new APIException(response.error);
        }

        Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
        return ((String)body.get('Href')).substringAfterLast('/');
    }

    //Get All Agreements from an EOS folder
}
