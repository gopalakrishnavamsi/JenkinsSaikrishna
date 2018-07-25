public with sharing class SetupController extends Controller {

	public String state { get; set; }

	public SetupController() {
		List<Setup__mdt> md = [SELECT State__c FROM Setup__mdt WHERE DeveloperName = 'State' LIMIT 1];
		this.state = Collection.isNotEmpty(md) && String.isNotBlank(md[0].State__c) ? md[0].State__c : '';
	}

	@TestVisible
	private static Environment.Target getTarget(final String s) {
		Environment.Target result = Environment.Target.Other;
		if (String.isBlank(s)) {
			result = Environment.Target.Invalid;
		} else if (s == 'prod' || s == 'production') {
			result = Environment.Target.Production;
		} else if (s == 'demo') {
			result = Environment.Target.Demo;
		} else if (s == 'stage') {
			result = Environment.Target.Stage;
		}
		return result;
	}

	@AuraEnabled
	public static AccountService.LoginResult login(final String dsUsername, final String dsPassword,
		final String dsEnvironment, final String dsUrl, final Long dsAccountNumber) {

		try {
			return AccountService.login(dsUsername, dsPassword, getTarget(dsEnvironment),
				String.isBlank(dsUrl) ? null : new Url(dsUrl), dsAccountNumber);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to log into DocuSign.');
		}
	}

	@AuraEnabled
	public static Account getAccount() {
		try {
			return AccountService.getAccount();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to read DocuSign account.');
		}
	}

	@AuraEnabled
	public static void logout(final Boolean resetUsers) {
		try {
			AccountService.resetCredentials(resetUsers);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to log out of DocuSign.');
		}
	}

	@AuraEnabled
	public static Account.Membership startTrial(final String email) {
		try {
			Account.Trial trial = AccountService.prepareTrial(email);
			return AccountService.createTrial(trial.acceptTermsAndConditions());
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to create DocuSign trial.');
		}
	}

	@AuraEnabled
	public static List<Account.User> addUser(final Id sourceId, final String email, final String firstName,
		final String lastName, final Boolean canManageAccount) {

		try {
			return AccountService.addUsers(new List<Account.User> {
				new Account.User(sourceId, email, email, firstName, lastName, canManageAccount)
			});
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to add DocuSign account users.');
		}
	}

	@AuraEnabled
	public static List<Account.User> removeUser(final Id sourceId, final String username) {
		try {
			return AccountService.removeUsers(new List<Account.User> {
				new Account.User(sourceId, username)
			}, true);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to remove DocuSign account users.');
		}
	}

	@AuraEnabled
	public static List<Account.User> getUsers() {
		try {
			return AccountService.getUsers();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to read DocuSign account users.');
		}
	}

	// TODO: Why do we need this method? Remove if possible.
	@AuraEnabled
	public static User getUser(final Id userId) {
		try {
			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> { 'Id', 'Email', 'FirstName', 'LastName' });

			return [SELECT Id, Email, FirstName, LastName FROM User WHERE Id = :userId LIMIT 1];
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to read user.');
		}
	}

	// TODO: Can we get rid of custom metadata state?
	@AuraEnabled
	public static Id saveState(final String state) {
		try {
			Metadata.CustomMetadata setupMetadata = new Metadata.CustomMetadata();
			setupMetadata.fullName = Application.namespacePrefix + 'Setup__mdt.State';
			setupMetadata.label = 'State';

			Metadata.CustomMetadataValue body = new Metadata.CustomMetadataValue();
			body.field = Application.namespacePrefix + 'State__c';
			body.value = state;
			setupMetadata.values.add(body);

			return deployMetadata(setupMetadata);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to save setup state.');
		}
	}

	private static Id deployMetadata(final MetaData.CustomMetadata setupMetadata) {
		Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
		mdContainer.addMetadata(setupMetadata);
		return Test.isRunningTest() ? null : Metadata.Operations.enqueueDeployment(mdContainer, new MetadataDeployCallback());
	}
}
