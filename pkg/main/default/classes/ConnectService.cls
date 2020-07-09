public with sharing class ConnectService {

	/**
	 * Creates a DocuSign Connect configuration.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The DocuSign Connect configuration ID or <code>null</code> if the configuration could not be created.
	 */
	public static Long createConfiguration() {
		Permissions.verifyIsDocuSignAdministrator();

		try {
			if (!AccountProducts.getInstance().isConnectEnabled()) throw new DocuSignException(Label.ConnectNotEnabled);

			Credentials creds = Credentials.getInstance();
			return createConfiguration(
				creds.environment.eSignatureBaseUrl,
				creds.account.id,
				creds.isTokenValid ? creds.token.token : null);
		} finally {
			AccountProducts.save();
		}
	}

	/*
	This is a hack-y way to determine the appropriate Connect listener endpoint. Ideally, the endpoint would be
	returned in the e_sign product activation properties or the OAuth userinfo response. Or if the URLs
	were not site-specific in prod and we can just use Environment custom metadata.
 */
	@TestVisible
	private static Url getListenerUrl(final Url eSignatureBaseUrl) {
		if (eSignatureBaseUrl == null) throw new DocuSignException(Label.UndefinedArgument);

		String site = eSignatureBaseUrl.getHost().substringBefore('.').toLowerCase();
		Url result = null;
		switch on site {
			when 'www', 'na1', 'na2', 'na3', 'na4' {
				result = new Url('https://na.act-event.docusign.com/listeners/connect-salesforce');
			} when 'eu' {
				result = new Url('https://eu.act-event.docusign.com/listeners/connect-salesforce');
			} when 'au' {
				result = new Url('https://au.act-event.docusign.com/listeners/connect-salesforce');
			} when 'ca' {
				result = new Url('https://ca.act-event.docusign.com/listeners/connect-salesforce');
			} when 'demo' {
				result = new Url('https://act-event-d.docusign.com/listeners/connect-salesforce');
			} when 'stage' {
				result = new Url('https://act-event-s.docusign.com/listeners/connect-salesforce');
			} when 'hqtest0', 'hqtest1', 'hqtest2', 'hqtest3' {
				result = new Url('https://act-event.dev.docusign.net/listeners/connect-salesforce');
			} when else {
				LoggerService.getInstance().warn('Could not map eSignature site '
					+ site + ' to an ACT Framework Connect listener.');
			}
		}
		return result;
	}

	// For internal use only.
	public static Long createConfiguration(
		final Url eSignatureBaseUrl,
		final UUID accountId,
		final String accessToken) {

		if (eSignatureBaseUrl == null || UUID.isEmpty(accountId)) throw new DocuSignException(Label.UndefinedArgument);

		Long result = null;
		Url listenerUrl = getListenerUrl(eSignatureBaseUrl);
		if (listenerUrl != null) {
			result = ConnectAPI.getInstance(
				eSignatureBaseUrl,
				accountId,
				accessToken)
				.createConfiguration(
					Application.name,
					listenerUrl);
		}
		return result;
	}

	// For internal use only.
	@Future(Callout = true)
	public static void asyncCreateConfiguration() {
		AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
		if (!settings.CreateConnectConfiguration__c) return;

		try {
			if (AccountProducts.getInstance().isConnectEnabled()) {
				Credentials creds = Credentials.getInstance();
				createConfiguration(
					creds.environment.eSignatureBaseUrl,
					creds.account.id,
					creds.isTokenValid ? creds.token.token : null);
			}

			settings.CreateConnectConfiguration__c = false;
			update settings;
		} catch (Exception ex) {
			LoggerService.getInstance().exception(
				ex,
				Label.ConnectConfigurationError,
				new LoggerService.LogContext(
					UUID.randomUUID(),
					UUID.tryParse(settings.AccountId__c),
					null,
					String.valueOf(ConnectService.class),
					'asyncCreateConfiguration'));
		} finally {
			LoggerService.getInstance().flush();
			AccountProducts.save();
		}
	}
}
