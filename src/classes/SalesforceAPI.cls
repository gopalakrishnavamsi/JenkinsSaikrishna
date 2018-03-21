/** 
 * This class represents the Salesforce Service responsible for making REST API calls.
 * This includes describeglobal and describeSobject call to populate dropdowns in Related to salesforce section while creating 
 new custom tag.
 */
public class SalesforceAPI extends RestAPI {

	private static SalesforceAPI self = null;
	private static final String remoteSite = Url.getSalesforceBaseUrl().toExternalForm();
	private static final Url baseURL = new Url(Url.getSalesforceBaseUrl(), '/services/data/v' +
		Salesforce.API_VERSION + '/');
	private final Map<String, String> defaultHeaders;

	@TestVisible
	private SalesforceAPI() {
		super();

		this.defaultHeaders = new Map<String, String> {
			'Accept' => 'application/json',
			'Authorization' => 'Bearer ' + UserInfo.getSessionId()
		};
	}

	public static SalesforceAPI getInstance() {
		if (self == null) {
			self = new SalesforceAPI();
		}
		return self;
	}

	override protected APIError getError(final HttpResponse response) {
		APIError e = super.getError(response);
		if (e != APIError.none) {
			final Integer statusCode = response.getStatusCode();
			final String contentType = response.getHeader('Content-Type');
			final Boolean isJson = String.isNotBlank(contentType) && contentType.startsWith('application/json');
			final String body = response.getBody();

			if (statusCode >= 400) {
				this.log.error('Failure response (' + statusCode + ') received for request:\n' + body);
				if (statusCode >= 500) {// Internal Force.com error
					e = new APIError(APIErrorCode.SALESFORCE_API_ERROR, Label.Unknown);
				} else if (isJson) { // Try parsing "standard" SFDC API error
					List<SalesforceError> sfe;
					try {
						sfe = (List<SalesforceError>)JSON.deserialize(body, List<SalesforceError>.class);
					} catch (Exception ex) {
						this.log.warn('Could not parse error response as JSON: ' + ex.getMessage());
					}
					if (sfe != null && !sfe.isEmpty()) {
						// TODO: handle multiple errors
						e = sfe[0].toExternalForm();
					}
				} else { // Who knows
					this.log.warn('Could not parse error response as JSON. Content-Type = ' + contentType);
					e = new APIError(APIErrorCode.SALESFORCE_API_ERROR, Label.SalesforceApiErrorUnexpectedResponse);
				}
			} else if (!isJson) {
				this.log.error('Could not parse success response as JSON. Content-Type = ' + contentType);
				e = new APIError(APIErrorCode.SALESFORCE_API_ERROR, Label.SalesforceApiErrorUnexpectedResponse);
			}
		}
		return e;
	}

	@TestVisible
	private RestAPI.Response get(final String resource, final Integer timeout) {
		return get(new List<Object> { resource }, timeout);
	}

	private RestAPI.Response get(final List<Object> path, final Integer timeout) {
		try {
			return super.get(baseURL, path, QueryString.empty, this.defaultHeaders, timeout);
		} catch (CalloutException ex) {
			this.log.error('Salesforce API CalloutException: ' + ex.getMessage());
			if (ex.getMessage().contains(remoteSite)) {
				// Going out on a limb: maybe a remote site setting issue? No good way to check the exception message due to localization.
				throw new Salesforce.MetadataApiNotSupportedException(String.format(
					Label.RemoteSiteMissing_1,
					new List<String> { remoteSite }));
			}
			throw new APIException(String.format(Label.SalesforceApiError_1, new List<String> { ex.getMessage() }));
		} catch (Exception ex) {
			this.log.error('Salesforce API error (' + ex.getTypeName() + '): ' + ex.getMessage());
			throw new APIException(String.format(
				Label.SalesforceApiError_1,
				new List<String> { ex.getMessage() }));
		}
	}

	private class SalesforceError {
		public String message { get; set; }
		public String errorCode { get; set; }

		public APIError toExternalForm() {
			return new APIError(APIErrorCode.BAD_REQUEST, String.format('[{0}] {1}',
				new List<String> { errorCode, message }));
		}
	}

	private class MergeObject {
		public String name;
		public String label;
		public Boolean updateable;

		public Salesforce.MergeObject toExternalForm() {
			return new Salesforce.MergeObject(this.name, this.label, this.updateable);
		}
	}

	private class MergeObjects {
		public String encoding; // HACK: For some reason the deserializer fails if this property is not included. Odd.
		public List<SalesforceAPI.MergeObject> sobjects;

		public List<Salesforce.MergeObject> toExternalForm() {
			List<Salesforce.MergeObject> mergeObjects = new List<Salesforce.MergeObject>();

			if (sobjects != null) {
				for (SalesforceAPI.MergeObject mo : sobjects) {
					mergeObjects.add(mo.toExternalForm());
				}
			}

			return mergeObjects;
		}
	}

	public List<Salesforce.MergeObject> getMergeObjects() {
		return this.getMergeObjects(RestAPI.defaultTimeout);
	}

	public List<Salesforce.MergeObject> getMergeObjects(final Integer timeout) {
		final RestAPI.Response response = get('sobjects', timeout);
		if (response.hasError) {
			this.log.error('Failed to get sobjects: ' + response.error.toString());
			throw new APIException(response.error);
		}
		return ((SalesforceAPI.MergeObjects)JSON.deserialize(response.body, SalesforceAPI.MergeObjects.class)).toExternalForm();
	}

	private class MergeField {
		public String type;
		public String name;
		public String label;
		public Boolean updateable;
		public String relationshipName;
		public List<String> referenceTo;
		public List<SalesforceAPI.MergeFieldPicklist> picklistValues;
	}

	private class MergeFieldChildRelationship {
		public String relationshipName;
		public String childSObject;
	}

	private class MergeFieldPicklist {
		public String label;
	}

	private class MergeFields {
		public List<SalesforceAPI.MergeField> fields;
		public List<SalesforceAPI.MergeFieldChildRelationship> childRelationships;

		public List<Salesforce.MergeField> toExternalForm(final Integer level) {
			// FIXME: Ugly. A lot of fragile or magic code here. Can easily change something and break upstream dependencies.
			List<Salesforce.MergeField> mergeFields = new List<Salesforce.MergeField>();

			if (fields != null) {
				for (SalesforceAPI.MergeField mf : fields) {
					if (mf.type != 'id') {
						List<String> picklistValues = null;
						if (mf.type == 'picklist' && mf.picklistValues != null) {
							picklistValues = new List<String>();
							for (SalesforceAPI.MergeFieldPicklist plv : mf.picklistValues) {
								picklistValues.add(plv.label);
							}
						}

						if (mf.type == 'reference') {
							if (level != 3) {
								mergeFields.add(new Salesforce.MergeField(
									level,
									mf.type,
									String.isNotBlank(mf.relationshipName) ? mf.relationshipName : (String.isNotBlank(mf.label) ? mf.label.replace(' ', '') : ''),
									String.isNotBlank(mf.label) ? mf.label : '',
									mf.referenceTo[0],
									picklistValues,
									mf.updateable));
							}
						} else {
							mergeFields.add(new Salesforce.MergeField(
								level,
								mf.type,
								String.isNotBlank(mf.name) ? mf.name : '',
								String.isNotBlank(mf.label) ? mf.label : '',
								String.isNotBlank(mf.name) ? mf.name : '',
								picklistValues,
								mf.updateable));
						}
					}
				}
			}

			if (level != 3 && level != 2 && childRelationships != null) {
				for (SalesforceAPI.MergeFieldChildRelationship mf : childRelationships) {
					if (String.isNotBlank(mf.relationshipName)) {
						mergeFields.add(new Salesforce.MergeField(
							level,
							'child_relationship',
							mf.relationshipName,
							mf.relationshipName,
							mf.childSObject,
							null,
							true));
					}
				}
			}

			return mergeFields;
		}
	}

	public List<Salesforce.MergeField> getMergeFields(final String objectName, final Integer level) {
		return this.getMergeFields(objectName, level, RestAPI.defaultTimeout);
	}

	public List<Salesforce.MergeField> getMergeFields(final String objectName, final Integer level, final Integer timeout) {
		final RestAPI.Response response = get(new List<Object> { 'sobjects', objectName, 'describe' }, timeout);
		if (response.hasError) {
			this.log.error('Failed to get level ' + level + ' fields for ' + objectName + ': ' + response.error.toString());
			throw new APIException(response.error);
		}
		return ((SalesforceAPI.MergeFields)JSON.deserialize(response.body, SalesforceAPI.MergeFields.class)).toExternalForm(level);
	}
}
