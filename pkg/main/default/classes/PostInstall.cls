/**
 * Note: Post-install scripts break when invoking with/without sharing classes, so need to duplicate some code here.
 */
public class PostInstall implements InstallHandler, PostInstallScript {

	private static final LoggerService LOG = LoggerService.getInstance();

	private final Boolean forceExecute;

	public PostInstall() {
		this(false);
	}

	public PostInstall(final Boolean forceExecute) {
		this.forceExecute = forceExecute;
	}

	@TestVisible
	private static Boolean notify(final PostInstallResults results, final Id organizationId,
		final Id installerId, final Version previousVersion) {

		Boolean result = true;
		try {
			List<String> toAddresses = new List<String> {
				[
					SELECT NotificationEmail__c
					FROM Organization__mdt
					WHERE DeveloperName = 'Default'
					LIMIT 1
				].NotificationEmail__c
			};
			result &= sendEmail(generateEmail(results, toAddresses, organizationId, previousVersion));
		} catch (Exception ex) {
			result = false;
			LOG.exception(ex, 'Could not send email to org ' + organizationId + ' user ' + installerId);
		}
		return result;
	}

	@TestVisible
	private static Messaging.SingleEmailMessage generateEmail(final PostInstallResults results,
		final List<String> toAddresses, final Id organizationId, final Version previousVersion) {

		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setToAddresses(toAddresses);
		email.setSubject(String.format(Label.PostInstallEmailSubject_1, new List<String> {
			[SELECT Name FROM Organization WHERE Id = :organizationId].Name
		}));
		email.setPlainTextBody(String.format(Label.PostInstallEmailBody_4.replace('\\n', '\n'), new List<String> {
			organizationId,
			previousVersion == null ? Label.None : String.valueOf(previousVersion),
			String.valueOf(Application.version),
			String.valueOf(results)
		}));

		return email;
	}

	@TestVisible
	private static Boolean sendEmail(final Messaging.SingleEmailMessage email) {
		Boolean result = true;
		try {
			// Don't try to send email while testing
			List<Messaging.SendEmailResult> results = Test.isRunningTest()
				? new List<Messaging.SendEmailResult>()
				: Messaging.sendEmail(new List<Messaging.Email> { email });
			List<String> errors = new List<String>();
			for (Messaging.SendEmailResult r : results) {
				if (!r.success) {
					for (Messaging.SendEmailError e : r.getErrors()) {
						errors.add(e.getMessage());
					}
				}
			}
			if (Collection.isNotEmpty(errors)) {
				result = false;
				LOG.error('Failed to send email:\n' + Collection.mkString(errors, '\n'));
			}
		} catch (Exception ex) {
			result = false;
			LOG.exception(ex, String.format(
				'Could not send email.\nTo: {0}\nSubject: {1}\nBody:\n{2}',
				new List<String> {
					String.join(email.getToAddresses(), ', '),
					email.getSubject(),
					email.getPlainTextBody()
				}));
		}
		return result;
	}

	// This must be executed in a future to avoid mixed DML errors.
	@Future
	private static void assignPermissionSets(final Id userId) {
		List<PermissionSet> pss = [
			SELECT Id
			FROM PermissionSet
			WHERE Name = 'DocuSign_Administrator'
		];
		if (userId != null && Collection.isNotEmpty(pss)) {
			try {
				List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
				for (PermissionSet ps : pss) {
					psas.add(new PermissionSetAssignment(
						PermissionSetId = ps.Id,
						AssigneeId = userId));
				}
				upsert psas;
			} catch (Exception ex) {
				if (ex instanceof DmlException && ((DmlException)ex).getDmlStatusCode(0) == 'DUPLICATE_VALUE') {
					LOG.info('Permission set already assigned to user ' + userId);
				} else {
					LOG.exception(ex, 'Failed to add permission set to user ' + userId);
					throw ex;
				}
			}
		}
	}

	@TestVisible
	private static PostInstallResults assignDocuSignAdministratorPermissionSet(final Id userId) {
		PostInstallResults results = new PostInstallResults();
		if (userId != null) {
			try {
				assignPermissionSets(userId);
				results.endStepSuccess(Label.AssignAdminPermissionSet, userId);
			} catch (Exception ex) {
				results.endStepFailure(Label.AssignAdminPermissionSet, ex);
			}
		} else {
			results.skipStep(Label.AssignAdminPermissionSet, Label.UserMustBeProvided);
		}
		return results;
	}

	@TestVisible
	private static PostInstallResults initializeSettings(final Map<String, SObject> settingsMap) {
		PostInstallResults result = new PostInstallResults();
		if (Collection.isNotEmpty(settingsMap)) {
			for (String stepName : settingsMap.keySet()) {
				SObject settings = settingsMap.get(stepName);
				if (settings.Id == null) {
					try {
						insert settings;
						result.endStepSuccess(stepName);
					} catch (Exception ex) {
						result.endStepFailure(stepName, ex);
					}
				} else {
					result.skipStep(stepName, Label.AlreadyComplete);
				}
			}
		}
		return result;
	}

	@TestVisible
	private static PostInstallResults initializeAccountSettings() {
		PostInstallResults result = new PostInstallResults();
		AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
		if (settings.Id == null) {
			try {
				settings.EncryptionKey__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
				settings.EntityResolvers__c = Application.classNamespacePrefix + 'DefaultEntityResolver';
				settings.DocumentResolvers__c = Application.classNamespacePrefix + 'DefaultDocumentResolver';
				settings.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
				insert settings;
				result.endStepSuccess(Label.InitializeAccountSettings);
			} catch (Exception ex) {
				result.endStepFailure(Label.InitializeAccountSettings, ex);
			}
		} else {
			result.skipStep(Label.InitializeAccountSettings, Label.AlreadyComplete);
		}
		return result;
	}

	@TestVisible
	private static PostInstallResults createDefaultRecipientRoles() {
		PostInstallResults result = new PostInstallResults();
		try {
			Map<String, RoleSettings__c> existingRoleSettings = RoleSettings__c.getAll();
			if (existingRoleSettings == null || existingRoleSettings.size() <= 0) {
				// Add Signers 1-4 roles
				insert new List<RoleSettings__c> {
					new RoleSettings__c(Name = 'Signer 1', Value__c = 1),
					new RoleSettings__c(Name = 'Signer 2', Value__c = 2),
					new RoleSettings__c(Name = 'Signer 3', Value__c = 3),
					new RoleSettings__c(Name = 'Signer 4', Value__c = 4)
				};
				result.endStepSuccess(Label.CreateDefaultRecipientRoles);
			} else {
				result.skipStep(Label.CreateDefaultRecipientRoles, Label.AlreadyComplete);
			}
		} catch (Exception ex) {
			result.endStepFailure(Label.CreateDefaultRecipientRoles, ex);
		}
		return result;
	}

	@TestVisible
	private PostInstallResults executeScript(final String name, final PostInstallScript script, final Id organizationId,
		final Id installerId, final Version previousVersion, final Boolean isPush, final Boolean isUpgrade) {

		PostInstallResults results = new PostInstallResults();
		if (this.forceExecute || script.shouldExecute(organizationId, installerId, previousVersion, isPush, isUpgrade)) {
			try {
				results.addResults(
					name,
					script.execute(organizationId, installerId, previousVersion, isPush, isUpgrade));
			} catch (Exception ex) {
				results.endStepFailure(name, ex);
			}
		} else {
			results.skipStep(name, Label.PostInstallCriteriaNotMet);
		}
		return results;
	}

	public void onInstall(final InstallContext context) {
		PostInstallResults results = execute(
			context == null ? UserInfo.getOrganizationId() : context.organizationId(),
			context == null ? UserInfo.getUserId() : context.installerId(),
			context == null ? null : context.previousVersion(),
			context == null ? null : context.isPush(),
			context == null ? null : context.isUpgrade());

		LOG.info((results != null && results.success ? 'SUCCESS\n' : 'FAILURE\n') + results);
		if (Application.isManaged) {
			notify(results,
				context == null ? UserInfo.getOrganizationId() : context.organizationId(),
				context == null ? null : context.installerId(),
				context == null ? null : context.previousVersion());
		}
	}

	public Boolean shouldExecute(final Id organizationId, final Id installerId, final Version previousVersion,
		final Boolean isPush, final Boolean isUpgrade) {

		return true; // Always execute container script
	}

	public PostInstallResults execute(final Id organizationId, final Id installerId, final Version previousVersion,
		final Boolean isPush, final Boolean isUpgrade) {

		PostInstallResults results = new PostInstallResults();

		results.addResults(assignDocuSignAdministratorPermissionSet(installerId));
		results.addResults(initializeAccountSettings());
		results.addResults(initializeSettings(new Map<String, SObject> {
			Label.InitializeEnvelopeSettings => EnvelopeSettings__c.getOrgDefaults(),
			Label.InitializeChatterSettings => ChatterSettings__c.getOrgDefaults()
		}));
		results.addResults(createDefaultRecipientRoles());

		results.addResults(executeScript(Label.PostInstall2, new PostInstall2(), organizationId, installerId,
			previousVersion, isPush, isUpgrade));

		return results;
	}
}