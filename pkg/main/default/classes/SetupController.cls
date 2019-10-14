public with sharing class SetupController extends Controller {

	private static final Integer USER_LIMIT = 10000;

	@AuraEnabled(Cacheable = true)
	public static LoginInformation getLogin() {
		try {
			Permissions.verifyIsDocuSignAdministrator();

			if (Credentials.isAccountValid()) {
				Credentials c = Credentials.getInstance();
				AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
				// TODO: Handle trial accounts
				return new LoginInformation(
					c.user.id,
					c.user.name,
					c.account.email,
					settings.IsPlatformAuthorized__c,
					new List<LoginInformation.Account> {
						new LoginInformation.Account(
							c.account.id,
							c.account.accountNumber,
							c.account.name,
							c.environment.eSignatureBaseUrl == null
								? null : c.environment.eSignatureBaseUrl.toExternalForm(),
							true)
					});
			} else {
				return new LoginInformation(
					null,
					UserInfo.getName(),
					UserInfo.getUserEmail(),
					false,
					null);
			}
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get login status.');
		}
	}

	@RemoteAction
	public static String beginOAuth(
		final String target,
		final String environment,
		final String otherUrl) {

		//since spaces are being replaced with + and this is breaking scopes we will replace + with %20
		return AuthService.getLoginUrl(
			target,
			DocuSign.parseEnvironment(environment),
			String.isBlank(otherUrl) ? null : new Url(otherUrl)).toExternalForm().replace('+', '%20');
	}

	@RemoteAction
	public static LoginInformation completeOAuth(
		final String authorizationCode,
		final String state,
		final String errorCode,
		final String errorMessage) {

		if (String.isBlank(errorCode)) {
			return AuthService.redeemCode(authorizationCode, state);
		} else {
			return AuthService.redeemError(errorCode, errorMessage, state);
		}
	}

	@RemoteAction
	public static String beginSpringOAuth(final String state) {
		return AuthService.getSpringOAuthUrl(state).toExternalForm();
	}

	@RemoteAction
	public static SpringOAuthLoginInformation completeSpringOAuth(final String authorizationCode) {
		return AuthService.completeSpringOAuth(authorizationCode);
	}

	@AuraEnabled
	public static LoginInformation setAccount(
		final String environment,
		final String otherUrl,
		final Long accountNumber) {

		try {
			return AuthService.setAccount(
				DocuSign.parseEnvironment(environment),
				String.isBlank(otherUrl) ? null : new Url(otherUrl),
				accountNumber);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to select account');
		}
	}

	@AuraEnabled
	public static LoginInformation logout(final Boolean resetUsers) {
		try {
			AuthService.resetAccount(resetUsers);
			return new LoginInformation(
				null,
				UserInfo.getName(),
				UserInfo.getUserEmail(),
				false,
				new List<LoginInformation.Account>());
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to log out of DocuSign.');
		}
	}

	@AuraEnabled
	public static List<Account.User> addUsers(final String users, final String roles) {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			if (users == null || String.isBlank(users)) throw new DocuSignException(Label.UndefinedArgument);

			List<Account.User> usersList = new List<Account.User>();
			for (Account.User user : (List<Account.User>)JSON.deserialize(users, List<Account.User>.class)) {
				usersList.add(new Account.User(
					null,
					user.sourceId,
					user.email,
					user.firstName,
					user.lastName,
					null,
					null,
					user.canManageAccount,
					null,
					null,
					APIError.none
				));
			}

			Map<String, String> rolesMap = (Map<String, String>)JSON.deserialize(roles, Map<String, String>.class);
			List<Account.User> updatedUsers = UserService.addUsers(usersList, rolesMap);

			if (Collection.isNotEmpty(updatedUsers) && updatedUsers[0].hasError) {
				throw new APIException(updatedUsers[0].error);
			}

			return updatedUsers;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to add DocuSign account users.');
		}
	}

	@AuraEnabled
	public static List<Account.User> removeUsers(final String usersToRemove) {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			if (usersToRemove == null || String.isBlank(usersToRemove)) throw new DocuSignException(Label.UndefinedArgument);

			List<Account.User> usersToRemoveList = new List<Account.User>();
			List<Map<String, String>> usersToRemoveDeserializedList = (List<Map<String, String>>)JSON.deserialize(usersToRemove, List<Map<String, String>>.class);
			for (Map<String, String> userToRemoveMapping : usersToRemoveDeserializedList) {
				usersToRemoveList.add(new Account.User(
					UUID.parse(userToRemoveMapping.get('id')),
					userToRemoveMapping.get('sourceId')
				));
			}
			UserService.removeUsers(usersToRemoveList, true);

			return UserService.getUsers(USER_LIMIT);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to remove DocuSign account users.');
		}
	}

	@AuraEnabled
	public static List<Account.User> editUserPermissions(final String usersIdsToEdit, final String roles) {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			if (usersIdsToEdit == null || String.isBlank(usersIdsToEdit)) throw new DocuSignException(Label.UndefinedArgument);
			if (roles == null || String.isBlank(roles)) throw new DocuSignException(Label.UndefinedArgument);

			Map<String, String> rolesMap = (Map<String, String>)JSON.deserialize(roles, Map<String, String>.class);
			Set<Id> userIdSet = (Set<Id>)JSON.deserialize(usersIdsToEdit, Set<Id>.class);
			return UserService.updateUserRoles(userIdSet, rolesMap);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to edit permissions for users.');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static List<Profile> getProfiles() {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			Permissions.verifyIsQueryable(Profile.getSObjectType(), new List<String> {
				'Id', 'Name'
			});
			return [SELECT Id, Name FROM Profile ORDER BY Name LIMIT 50000];
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get profiles');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static List<PermissionSet> getPermissionSets() {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			Permissions.verifyIsQueryable(PermissionSet.getSObjectType(), new List<String> {
				'Id', 'Label', 'IsOwnedByProfile', 'Name'
			});
			return [SELECT Id, Label FROM PermissionSet WHERE IsOwnedByProfile = FALSE ORDER BY Name LIMIT 50000];
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get permission sets');
		}
	}

	//return a list of filtered SF users to be added
	@AuraEnabled
	public static List<User> filterSFUsers(String jsonString) {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			if (jsonString == null || String.isBlank(jsonString)) throw new DocuSignException(Label.UndefinedArgument);
			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
				'Id', 'FirstName', 'LastName', 'Email', 'ProfileId',
				Application.namespacePrefix + 'Username__c',
				Application.namespacePrefix + 'Provisioned__c',
				Application.namespacePrefix + 'Status__c'
			});

			Permissions.verifyIsQueryable(Profile.getSObjectType(), new List<String> {
				'Id', 'Name'
			});

			Permissions.verifyIsQueryable(PermissionSetAssignment.getSObjectType(), new List<String> {
				'Id', 'PermissionSetId', 'AssigneeId'
			});

			Map<String, Object> parsedRes = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
			List<Object> filters = (List<Object>)parsedRes.get('filters');
			String name = '';
			String profileId = '';
			String permSetId = '';

			String soqlQuery = 'SELECT Id, FirstName, LastName, Email, Profile.Name' +
				' FROM User' +
				' WHERE Username__c = null' +
				' AND Provisioned__c = null' +
				' AND Status__c = null' +
				' AND IsActive = true';

			for (Object filter : filters) {
				Map<String, Object> filterMap = (Map<String, Object>)filter;

				if ((String)filterMap.get('type') == 'User') {
					name = '%' + String.escapeSingleQuotes((String)filterMap.get('value')) + '%';
					soqlQuery += ' AND (Name LIKE :name OR Email LIKE :name)';
				}

				if ((String)filterMap.get('type') == 'Profile') {
					profileId = String.escapeSingleQuotes((String)filterMap.get('value'));
					soqlQuery += ' AND ProfileId = :profileId';
				}

				if ((String)filterMap.get('type') == 'Permission Set') {
					permSetId = String.escapeSingleQuotes((String)filterMap.get('value'));
					//use a sub query to determine if these users have the specified perm set
					soqlQuery += ' AND Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :permSetId)';
				}
			}

			soqlQuery += ' LIMIT 50';

			return Database.query(soqlQuery);

		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to filter Salesforce users.');
		}
	}

	@AuraEnabled
	public static List<Account.User> getUsers() {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			return UserService.getUsers(USER_LIMIT);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to read DocuSign account users.');
		}
	}

	@AuraEnabled
	public static Boolean addTrialGen() {
		try {
			List<Product> ps = AccountProducts.getInstance().startTrials(new Set<String> { Product.GEN });
			AccountProducts.save();
			return Collection.size(ps) == 1;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to add Gen Trial.');
		}
	}

	@AuraEnabled
	public static Boolean addTrialNegotiate() {
		try {
			List<Product> ps = AccountProducts.getInstance().startTrials(
				new Set<String> { Product.GEN, Product.NEGOTIATE });
			AccountProducts.save();
			return Collection.size(ps) == 2;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to add Negotiate Trial.');
		}
	}

	@AuraEnabled
	public static Boolean doPlatformAuthorizationSettingsExist() {
		try {
			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
			return (settings != null && String.isNotBlank(settings.ScmWebBaseUrl__c));

		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to check Platform Authorization settings.');
		}
	}

	@AuraEnabled
	public static List<Product> getProductsOnAccount() {
		try {
			return AccountProducts.getProducts();

		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to check Products on account.');
		}
	}

	@AuraEnabled
	public static String getProductRoles() {
		try {
			return JSON.serialize(Product.getValidProductRoles());

		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to check Products on account.');
		}
	}

	@AuraEnabled
	public static string getNewGenTemplateUrl(){
		try {
			Permissions.verifyIsDocuSignAdministrator();
			return GenService.getNewGenTemplateUrl().toExternalForm();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get url for creating new gen template');
		}	
	}

	@AuraEnabled
	public static List<Gen.GenTemplateDisplay> getGenTemplates(){
		try {
			Permissions.verifyIsDocuSignAdministrator();
			return GenService.queryGenTemplatesForDisplay();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get gen templates');
		}	
	}
}
