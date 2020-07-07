public class ConnectConfigurationPostInstall implements PostInstallScript {

	@TestVisible
	@Future(Callout = true)
	private static void createConfiguration() {
		try {
			if (AccountProducts.getInstance().isConnectEnabled()) {
				Credentials creds = Credentials.getInstance();
				AuthService.createConnectConfiguration(
					creds.environment.eSignatureBaseUrl,
					creds.account.id,
					creds.isTokenValid ? creds.token.token : null);
			} else {
				LoggerService.getInstance().warn(
					Label.ConnectNotEnabled,
					new LoggerService.LogContext(
						UUID.randomUUID(),
						null,
						null,
						String.valueOf(ConnectConfigurationPostInstall.class),
						'createConfiguration'));
			}
		} catch (Exception ex) {
			LoggerService.getInstance().exception(
				ex,
				Label.ConnectConfigurationError,
				new LoggerService.LogContext(
					UUID.randomUUID(),
					null,
					null,
					String.valueOf(ConnectConfigurationPostInstall.class),
					'createConfiguration'));
		} finally {
			LoggerService.getInstance().flush();
			AccountProducts.save();
		}
	}

	public Boolean shouldExecute(
		final Id organizationId,
		final Id installerId,
		final Version previousVersion,
		final Boolean isPush,
		final Boolean isUpgrade) {

		// Only execute if upgrading from < v2.5
		return isUpgrade
			&& previousVersion != null
			&& previousVersion.major() <= 2
			&& previousVersion.minor() < 5;
	}

	public PostInstallResults execute(
		final Id organizationId,
		final Id installerId,
		final Version previousVersion,
		final Boolean isPush,
		final Boolean isUpgrade) {

		if (!this.shouldExecute(organizationId, installerId, previousVersion, isPush, isUpgrade)) {
			return new PostInstallResults().skipStep(Label.CreateConnectConfiguration, Label.PostInstallCriteriaNotMet);
		}

		PostInstallResults result = new PostInstallResults();
		try {
			if (Credentials.isAccountValid()) {
				createConfiguration();
				result.endStepSuccess(Label.CreateConnectConfiguration);
			} else {
				result.skipStep(Label.CreateConnectConfiguration, Label.AccountNotConfigured);
			}
		} catch (Exception ex) {
			result.endStepFailure(Label.CreateConnectConfiguration, ex);
		}
		return result;
	}
}
