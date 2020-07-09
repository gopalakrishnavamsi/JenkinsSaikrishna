public with sharing class ConnectAPI extends ESignatureAPI {

	private final String accessToken;
	private Map<String, String> defaultHeaders;

	private ConnectAPI(
		final Url baseUrl,
		final UUID accountId,
		final String accessToken) {

		super(baseUrl, 'v2.1', accountId);

		this.accessToken = accessToken;
	}

	public static ConnectAPI getInstance(
		final Url baseUrl,
		final UUID accountId,
		final String accessToken) {

		if (baseUrl == null || UUID.isEmpty(accountId)) throw new DocuSignException(Label.UndefinedArgument);

		if (!DocuSign.isValidUrl(baseUrl)) throw new DocuSignException(Label.InvalidEnvironment);

		return new ConnectAPI(baseUrl, accountId, accessToken);
	}

	override protected Map<String, String> getDefaultHeaders() {
		if (this.defaultHeaders == null) {
			this.defaultHeaders = new Map<String, String> {
				'Content-Type' => 'application/json',
				'Accept' => 'application/json',
				'Authorization' => 'Bearer '
					+ (String.isBlank(this.accessToken) ? AuthService.getAccessToken() : this.accessToken)
			};
		}
		return this.defaultHeaders;
	}

	@TestVisible
	private class APIConfiguration {

		public String connectId;
		public String name;
		public String urlToPublishTo;
		public String configurationType;
		public String allowEnvelopePublish;
		public String enableLog;
		public String includeDocuments;
		public String includeCertificateOfCompletion;
		public String requiresAcknowledgement;
		public String requireMutualTls;
		public String signMessageWithX509Certificate;
		public String useSoapInterface;
		public String includeTimeZoneInformation;
		public String includeEnvelopeVoidReason;
		public String includeSenderAccountasCustomField;
		public List<String> envelopeEvents;
		public List<String> recipientEvents;
		public String allUsers;
		public String includeDocumentFields;

		public APIConfiguration(
			final String name,
			final Url publishUrl) {

			this(null, name, publishUrl);
		}

		public APIConfiguration(
			final Long id,
			final String name,
			final Url publishUrl) {

			this.connectId = String.valueOf(id);
			this.name = name;
			this.urlToPublishTo = publishUrl == null ? null : publishUrl.toExternalForm();
			this.configurationType = 'custom';
			this.allowEnvelopePublish = 'true';
			this.enableLog = 'true';
			this.includeDocuments = 'true';
			this.includeCertificateOfCompletion = 'true';
			this.requiresAcknowledgement = 'true';
			this.requireMutualTls = 'true';
			this.signMessageWithX509Certificate = 'true';
			this.useSoapInterface = 'false';
			this.includeTimeZoneInformation = 'true';
			this.includeEnvelopeVoidReason = 'true';
			this.includeSenderAccountasCustomField = 'true';
			// Event names are case-sensitive in API, so cannot use Envelope.STATUS_* or Recipient.STATUS_* constants.
			this.envelopeEvents = new List<String> {
				'Sent', 'Delivered', 'Completed', 'Declined', 'Voided'
			};
			this.recipientEvents = new List<String> {
				'Sent', 'Delivered', 'Completed', 'Declined', 'AuthenticationFailed', 'AutoResponded'
			};
			this.allUsers = 'true';
			this.includeDocumentFields = 'true';
		}
	}

	@TestVisible
	private class APIConfigurations {
		public List<APIConfiguration> configurations;

		public APIConfiguration getConfiguration(final Url publishUrl) {
			APIConfiguration result = null;
			if (publishUrl != null && this.configurations != null) {
				String url = publishUrl.toExternalForm();
				for (APIConfiguration c : this.configurations) {
					if (c != null && c.urlToPublishTo == url) {
						result = c;
						break;
					}
				}
			}
			return result;
		}
	}

	private static Long getId(final APIConfiguration config) {
		return config != null && String.isNotBlank(config.connectId) ? Long.valueOf(config.connectId) : null;
	}

	@TestVisible
	private APIConfiguration getConfiguration(
		final Url publishUrl,
		final Integer timeout) {

		if (publishUrl == null) throw new DocuSignException(Label.UndefinedArgument);

		RestAPI.Response response = this.get(
			'connect',
			timeout);
		if (response.hasError) {
			this.log.error('Failed to retrieve Connect configuration: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return ((APIConfigurations)JSON.deserialize(response.body, APIConfigurations.class))
			.getConfiguration(publishUrl);
	}

	@TestVisible
	private static Boolean shouldUpdate(
		final APIConfiguration config,
		final Url publishUrl) {

		return config != null
			&& String.isNotBlank(config.connectId)
			&& config.urlToPublishTo == (publishUrl == null ? null : publishUrl.toExternalForm())
			&& (config.configurationType != 'custom'
			|| config.allowEnvelopePublish != 'true'
			|| config.enableLog != 'true'
			|| config.includeDocuments != 'true'
			|| config.includeCertificateOfCompletion != 'true'
			|| config.requiresAcknowledgement != 'true'
			|| config.requireMutualTls != 'true'
			|| config.signMessageWithX509Certificate != 'true'
			|| config.useSoapInterface != 'false'
			|| config.includeTimeZoneInformation != 'true'
			|| config.includeEnvelopeVoidReason != 'true'
			|| config.includeSenderAccountasCustomField != 'true'
			|| config.envelopeEvents != new List<String> { 'Sent', 'Delivered', 'Completed', 'Declined', 'Voided' }
			|| config.recipientEvents != new List<String> { 'Sent', 'Delivered', 'Completed', 'Declined', 'AuthenticationFailed', 'AutoResponded' }
			|| config.allUsers != 'true'
			|| config.includeDocumentFields != 'true');
	}

	@TestVisible
	private Long updateConfiguration(
		final Long id,
		final String name,
		final Url publishUrl,
		final Integer timeout) {

		if (id == null || String.isBlank(name) || publishUrl == null) throw new DocuSignException(Label.UndefinedArgument);

		RestAPI.Response response = this.put(
			new List<Object> { 'connect' },
			JSON.serialize(new APIConfiguration(
				id,
				name,
				publishUrl)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to update Connect configuration: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return getId((APIConfiguration)JSON.deserialize(response.body, APIConfiguration.class));
	}

	public Long createConfiguration(
		final String name,
		final Url publishUrl) {

		return this.createConfiguration(name, publishUrl, RestAPI.defaultTimeout);
	}

	public Long createConfiguration(
		final String name,
		final Url publishUrl,
		final Integer timeout) {

		if (String.isBlank(name) || publishUrl == null) throw new DocuSignException(Label.UndefinedArgument);

		// Possible to create duplicate configs, so first see if we have one matching the target URL. No point in
		// forwarding the events twice to the same listener.
		APIConfiguration config = this.getConfiguration(publishUrl, timeout);
		Long result = getId(config);
		if (result == null) {
			RestAPI.Response response = this.post(
				'connect',
				JSON.serialize(new APIConfiguration(
					name,
					publishUrl)),
				timeout);
			if (response.hasError) {
				this.log.error('Failed to create Connect configuration: ' + response.error.toString());
				throw new APIException(response.error);
			}

			result = getId((APIConfiguration)JSON.deserialize(response.body, APIConfiguration.class));
		} else if (shouldUpdate(config, publishUrl)) { // Verify the config has the appropriate settings.
			result = this.updateConfiguration(result, name, publishUrl, timeout);
		}

		return result;
	}
}
