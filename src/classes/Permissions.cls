/**
 * Contains permissions-related operations.
 */
public with sharing class Permissions {

	private static final Permissions.Database DB = new Permissions.Database();
	private static final SObjectType TYPE_PERMISSION_SET_ASSIGNMENT = PermissionSetAssignment.getSObjectType();
	@TestVisible
	private static final Boolean IS_FLS_SUPPORTED;
	private static final Map<String, DescribeFieldResult> FIELD_DESCRIBE_MAP = new Map<String, DescribeFieldResult>();
	@TestVisible
	private static final String DOCUSIGN_ADMINISTRATOR = 'DocuSign_Administrator';
	@TestVisible
	private static final String DOCUSIGN_USER = 'DocuSign_User';
	private static Map<String, Id> permissionSetMap = null;
	private static Set<Id> permissionSetIds = null;
	private static Id dsAdministratorPermissionSetId = null;
	private static Id dsUserPermissionSetId = null;
	private static final Map<Id, Boolean> dsAdmins = new Map<Id, Boolean>();
	private static final Map<Id, Boolean> dsUsers = new Map<Id, Boolean>();

	static {
		String orgType = null;
		List<Organization> orgs = [SELECT Id, OrganizationType FROM Organization LIMIT 1];
		if (Collection.isNotEmpty(orgs)) {
			orgType = orgs[0].organizationType;
		}
		IS_FLS_SUPPORTED = (orgType == 'Developer Edition' || orgType == 'Enterprise Edition' || orgType == 'Unlimited Edition');
	}

	@TestVisible
	private with sharing class Database {

		private Boolean upsertPermissionSetAssignments(final Id permissionSetId, final Set<Id> userIds) {
			Permissions.verifyIsCreateable(TYPE_PERMISSION_SET_ASSIGNMENT, new List<String> {
				'PermissionSetId', 'AssigneeId'
			});
			// Doesn't actually update during upsert. It just doesn't fail to insert if the assignment already exists.

			Boolean result = false;
			if (String.isNotBlank(permissionSetId) && Collection.isNotEmpty(userIds)) {
				List<PermissionSetAssignment> ps = new List<PermissionSetAssignment>();
				for (Id userId : userIds) {
					ps.add(new PermissionSetAssignment(PermissionSetId = permissionSetId, AssigneeId = userId));
				}
				upsert ps;
				result = true;
			}
			return result;
		}

		private Boolean deletePermissionSetAssignments(final Set<Id> userIds) {
			Permissions.verifyIsDeletable(TYPE_PERMISSION_SET_ASSIGNMENT);

			Boolean result = false;
			if (Collection.isNotEmpty(userIds)) {
				List<PermissionSetAssignment> ps = [
					SELECT Id, AssigneeId, PermissionSetId
					FROM PermissionSetAssignment
					WHERE (PermissionSetId = :getDocuSignUserPermissionSetId()
					OR PermissionSetId = :getDocuSignAdministratorPermissionSetId())
					AND AssigneeId IN :userIds
				];
				delete ps;
				result = true;
			}
			return result;
		}

		public List<PermissionSetAssignment> queryPermissionSetAssignments(final Id userId, final Set<Id> permissionSetIds) {
			return [
				SELECT Id
				FROM PermissionSetAssignment
				WHERE AssigneeId = :userId
				AND PermissionSetId IN :permissionSetIds
			];
		}

		public Map<String, Id> queryPermissionSetIds() {
			Map<String, Id> result = new Map<String, Id>();
			for (PermissionSet p : [
				SELECT Id, Name
				FROM PermissionSet
				WHERE Name = :DOCUSIGN_ADMINISTRATOR
				OR Name = :DOCUSIGN_USER
			]) {
				result.put(p.name, p.Id);
			}
			return result;
		}

		public Id queryOwner(final Id envelopeId) {
			List<Envelope__c> es = [
				SELECT OwnerId
				FROM Envelope__c
				WHERE Id = :envelopeId
				LIMIT 1
			];
			if (es == null || es.isEmpty()) {
				throw new DocuSignException(Label.EnvelopeNotFound);
			}
			return es[0].OwnerId;
		}

		public Id queryOwner(final UUID dsEnvelopeId) {
			Id ownerId = null;
			List<Envelope__c> es = [
				SELECT OwnerId
				FROM Envelope__c
				WHERE DocuSignId__c = :String.valueOf(dsEnvelopeId)
				LIMIT 1
			];
			if (es != null && !es.isEmpty()) {
				ownerId = es[0].OwnerId;
			}
			return ownerId;
		}
	}

	@TestVisible
	private static Map<String, Id> getPermissionSetMap() {
		if (permissionSetMap == null) {
			permissionSetMap = DB.queryPermissionSetIds();
			permissionSetIds = new Set<Id>(permissionSetMap.values());
		}
		return permissionSetMap;
	}

	@TestVisible
	private static Set<Id> getPermissionSetIds() {
		if (permissionSetIds == null) {
			permissionSetMap = DB.queryPermissionSetIds();
			permissionSetIds = new Set<Id>(permissionSetMap.values());
		}
		return permissionSetIds;
	}

	@TestVisible
	private static Id getDocuSignAdministratorPermissionSetId() {
		if (dsUserPermissionSetId == null) {
			dsUserPermissionSetId = getPermissionSetMap().get(DOCUSIGN_ADMINISTRATOR);
		}
		return dsUserPermissionSetId;
	}

	@TestVisible
	private static Id getDocuSignUserPermissionSetId() {
		if (dsAdministratorPermissionSetId == null) {
			dsAdministratorPermissionSetId = getPermissionSetMap().get(DOCUSIGN_USER);
		}
		return dsAdministratorPermissionSetId;
	}

	/**
	 * Checks whether the current user is assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return <code>true</code> if the current user is a DocuSign for Salesforce administrator, <code>false</code>
	 * otherwise.
	 */
	public static Boolean isDocuSignAdministrator() {
		return isDocuSignAdministrator(UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isDocuSignAdministrator(final Id userId) {
		Boolean result = false;

		if (String.isNotBlank(userId)) {
			final Boolean value = dsAdmins.get(userId);
			if (value != null) {
				result = value;
			} else {
				result = Collection.isNotEmpty(DB.queryPermissionSetAssignments(userId,
					new Set<Id> { getDocuSignAdministratorPermissionSetId() }));
				dsAdmins.put(userId, result);
			}
		}
		return result;
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not assigned the
	 * <code>DocuSign Administrator</code> permission set.
	 */
	public static void verifyIsDocuSignAdministrator() {
		verifyIsDocuSignAdministrator(UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsDocuSignAdministrator(final Id userId) {
		if (String.isBlank(userId) || !isDocuSignAdministrator(userId))
			throw UnauthorizedException.notDocuSignAdministrator();
	}

	/**
	 * Checks whether the current user is assigned the <code>DocuSign User</code> or
	 * <code>DocuSign Administrator</code> permission set.
	 *
	 * @return <code>true</code> if the current user is a DocuSign for Salesforce user, <code>false</code>
	 * otherwise.
	 */
	public static Boolean isDocuSignUser() {
		return isDocuSignUser(UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isDocuSignUser(final Id userId) {
		Boolean result = false;
		if (String.isNotBlank(userId)) {
			final Boolean value = dsUsers.get(userId);
			if (value != null) {
				result = value;
			} else {
				result = Collection.isNotEmpty(DB.queryPermissionSetAssignments(userId, getPermissionSetIds()));
				dsUsers.put(userId, result);
			}
		}
		return result;
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not assigned the
	 * <code>DocuSign User</code> or <code>DocuSign Administrator</code> permission set.
	 */
	public static void verifyIsDocuSignUser() {
		verifyIsDocuSignUser(UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsDocuSignUser(final Id userId) {
		if (String.isBlank(userId) || !isDocuSignUser(userId)) throw UnauthorizedException.notDocuSignUser();
	}

	/**
	 * Assigns the <code>DocuSign User</code> permission set to one or more users.
	 *
	 * @param userIds The user IDs.
	 *
	 * @return <code>true</code> if the permission set assignments were successful, <code>false</code> otherwise.
	 */
	public static Boolean assignDocuSignUserPermissionSet(final Set<Id> userIds) {
		Boolean result = Collection.isNotEmpty(userIds);
		if (result) {
			result &= DB.upsertPermissionSetAssignments(getDocuSignUserPermissionSetId(), userIds);
			for (Id userId : userIds) {
				dsUsers.put(userId, true);
			}
		}
		return result;
	}

	/**
	 * Assigns the <code>DocuSign Administrator</code> permission set to one or more users.
	 *
	 * @param userIds The user IDs.
	 *
	 * @return <code>true</code> if the permission set assignments were successful, <code>false</code> otherwise.
	 */
	public static Boolean assignDocuSignAdministratorPermissionSet(final Set<Id> userIds) {
		Boolean result = Collection.isNotEmpty(userIds);
		if (result) {
			result &= DB.upsertPermissionSetAssignments(getDocuSignAdministratorPermissionSetId(), userIds);
			for (Id userId : userIds) {
				dsUsers.put(userId, true);
				dsAdmins.put(userId, true);
			}
		}
		return result;
	}

	/**
	 * Removes the <code>DocuSign Administrator</code> and <code>DocuSign User</code> permission sets from one or more
	 * users.
	 *
	 * @param userIds The user IDs.
	 *
	 * @return <code>true</code> if the permission set removals were successful, <code>false</code> otherwise.
	 */
	public static Boolean removeDocuSignPermissionSets(final Set<Id> userIds) {
		Boolean result = Collection.isNotEmpty(userIds);
		if (result) {
			DB.deletePermissionSetAssignments(userIds);
			for (Id userId : userIds) {
				dsAdmins.remove(userId);
				dsUsers.remove(userId);
			}
		}
		return result;
	}

	/**
	 * Checks whether the current user is the owner of an envelope. Involves a SOQL query.
	 *
	 * @param envelopeId The envelope ID.
	 *
	 * @return <code>true</code> if the current user owns the envelope, <code>false</code> otherwise.
	 */
	public static Boolean isOwner(final Id envelopeId) {
		return String.isNotBlank(envelopeId) && isOwner(envelopeId, UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isOwner(final Id envelopeId, final Id userId) {
		if (String.isNotBlank(envelopeId) && String.isNotBlank(userId)) {
			Id ownerId = DB.queryOwner(envelopeId);
			return ownerId == null || userId == ownerId;
		}
		return false;
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not the owner of the envelope.
	 *
	 * @param envelopeId The envelope ID.
	 */
	public static void verifyIsOwner(final Id envelopeId) {
		verifyIsOwner(envelopeId, UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsOwner(final Id envelopeId, final Id userId) {
		if (!isOwner(envelopeId, userId)) throw UnauthorizedException.notEnvelopeOwner();
	}

	/**
	 * Checks whether the current user is the owner of an envelope. Involves a SOQL query.
	 *
	 * @param dsEnvelopeId The DocuSign envelope ID.
	 *
	 * @return <code>true</code> if the current user owns the envelope, <code>false</code> otherwise.
	 */
	public static Boolean isOwner(final UUID dsEnvelopeId) {
		return dsEnvelopeId != null && isOwner(dsEnvelopeId, UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isOwner(final UUID dsEnvelopeId, final Id userId) {
		if (dsEnvelopeId != null && String.isNotBlank(userId)) {
			return userId == DB.queryOwner(dsEnvelopeId);
		}
		return false;
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not the owner of the envelope.
	 *
	 * @param dsEnvelopeId The DocuSign envelope ID.
	 */
	public static void verifyIsOwner(final UUID dsEnvelopeId) {
		verifyIsOwner(dsEnvelopeId, UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsOwner(final UUID dsEnvelopeId, final Id userId) {
		if (!isOwner(dsEnvelopeId, userId)) throw UnauthorizedException.notEnvelopeOwner();
	}

	@TestVisible
	private static DescribeFieldResult describeField(final String objectName, final String fieldName,
		final SObjectField field) {

		if (field == null) return null;

		String key = objectName + '.' + fieldName;
		if (!FIELD_DESCRIBE_MAP.containsKey(key)) {
			FIELD_DESCRIBE_MAP.put(key, field.getDescribe());
		}
		return FIELD_DESCRIBE_MAP.get(key);
	}

	/**
	 * Requested field-level access:
	 * <ul>
	 *     <li><code>Createable</code></li>
	 *     <li><code>Deletable</code></li>
	 *     <li><code>Queryable</code></li>
	 *     <li><code>Updateable</code></li>
	 *     <li><code>Filterable</code></li>
	 *     <li><code>Unencrypted</code></li>
	 * </ul>
	 */
	public enum FlsAccess {
		Createable, Deletable, Queryable, Updateable, Filterable, Unencrypted
	}

	/**
	 * The status of the field-level access request:
	 * <ul>
	 *     <li><code>OK</code></li>
	 *     <li><code>BadRequest</code></li>
	 *     <li><code>NotFound</code></li>
	 *     <li><code>Unauthorized</code></li>
	 * </ul>
	 */
	public enum FlsStatus {
		OK, BadRequest, NotFound, Unauthorized
	}

	/**
	 * The result of a field-level access request.
	 */
	public class FlsResult {
		/**
		 * The name of the object or field that was checked.
		 */
		public String name { get; private set; }
		/**
		 * The status of the access request.
		 */
		public FlsStatus status { get; private set; }
		/**
		 * Read-only property indicating whether the request was authorized.
		 */
		public Boolean isAuthorized {
			get {
				return status == FlsStatus.OK;
			}
		}

		/**
		 * Constructs a field-level access request result.
		 *
		 * @param name The name of the object or field that was checked.
		 * @param status The status of the access request.
		 */
		public FlsResult(final String name, final FlsStatus status) {
			this.name = name;
			this.status = status;
		}

		/**
		 * Generates a string representation of the field-level access request result.
		 *
		 * @return The string representation of the field-level access request result.
		 */
		override public String toString() {
			if (this.status != FlsStatus.Unauthorized && this.status != FlsStatus.OK) {
				return String.format('{0} ({1})', new List<String> { this.name, this.status.name() });
			}
			return this.name;
		}
	}

	/**
	 * The combined results of an object and field-level access requests.
	 */
	public class FlsResults {
		/**
		 * The access requested.
		 */
		public FlsAccess requestedAccess { get; private set; }
		/**
		 * Whether or not the request was authorized.
		 */
		public Boolean isAuthorized { get; private set; }
		/**
		 * The result of the object access request.
		 */
		public FlsResult objectResult { get; private set; }
		/**
		 * The results of the field access requests.
		 */
		public List<FlsResult> fieldResults { get; private set; }

		/**
		 * Constructs the results of object and field-level access requests.
		 *
		 * @param requestedAccess The access requested.
		 * @param isAuthorized Whether or not the request was authorized.
		 * @param objectResult The result of the object access request.
		 * @param fieldResults The results of the field access requests.
		 */
		public FlsResults(final FlsAccess requestedAccess, final Boolean isAuthorized, final FlsResult objectResult,
			final List<FlsResult> fieldResults) {

			this.requestedAccess = requestedAccess;
			this.isAuthorized = isAuthorized;
			this.objectResult = objectResult == null ? new FlsResult(Label.Unknown, FlsStatus.NotFound) : objectResult;
			this.fieldResults = fieldResults == null ? new List<FlsResult>() : fieldResults;
		}

		@TestVisible
		private List<FlsResult> filterUnauthorizedFields() {
			List<FlsResult> ufs = new List<FlsResult>();
			if (fieldResults != null) {
				for (FlsResult fr : fieldResults) {
					if (!fr.isAuthorized) {
						ufs.add(fr);
					}
				}
			}
			return ufs;
		}

		/**
		 * Generates a localized, combined error message if the request was unauthorized.
		 *
		 * @return The error message.
		 */
		public String getErrorMessage() {
			String message = '';
			if (!isAuthorized) {
				if (!objectResult.isAuthorized) {
					if (requestedAccess == FlsAccess.Queryable) {
						message = Label.CannotQueryObject + ' ' + objectResult.name;
					} else if (requestedAccess == FlsAccess.Updateable) {
						message = Label.CannotUpdateObject + ' ' + objectResult.name;
					} else if (requestedAccess == FlsAccess.Createable) {
						message = Label.CannotCreateObject + ' ' + objectResult.name;
					} else {
						message = Label.CannotDeleteObject + ' ' + objectResult.name;
					}
				} else {
					List<FlsResult> unauthorizedFields = filterUnauthorizedFields();
					if (requestedAccess == FlsAccess.Queryable) {
						message = String.format(Label.CannotQueryFields_2, new List<String> { objectResult.name, Collection.mkString(unauthorizedFields, ', ') });
					} else if (requestedAccess == FlsAccess.Updateable) {
						message = String.format(Label.CannotUpdateFields_2, new List<String> { objectResult.name, Collection.mkString(unauthorizedFields, ', ') });
					} else if (requestedAccess == FlsAccess.Createable) {
						message = String.format(Label.CannotCreateFields_2, new List<String> { objectResult.name, Collection.mkString(unauthorizedFields, ', ') });
					} else if (requestedAccess == FlsAccess.Filterable) {
						message = String.format(Label.CannotFilterFields_2, new List<String> { objectResult.name, Collection.mkString(unauthorizedFields, ', ') });
					} else { // encrypted
						message = String.format(Label.EncryptedFields_2, new List<String> { objectResult.name, Collection.mkString(unauthorizedFields, ', ') });
					}
				}
			}
			return message;
		}
	}

	@TestVisible
	private static FlsResult getFlsResult(final FlsAccess requestedAccess, final String fieldName,
		final DescribeFieldResult fieldDescribe) {

		if (String.isBlank(fieldName)) return new FlsResult(fieldName, FlsStatus.BadRequest);
		if (fieldDescribe == null) return new FlsResult(fieldName, FlsStatus.NotFound);

		// Can only check queryable (accessible), updateable, and createable for fields
		FlsStatus status = FlsStatus.BadRequest;
		if (requestedAccess == FlsAccess.Queryable) {
			status = fieldDescribe.isAccessible() ? FlsStatus.OK : FlsStatus.Unauthorized;
		} else if (requestedAccess == FlsAccess.Updateable) {
			status = fieldDescribe.isUpdateable() ? FlsStatus.OK : FlsStatus.Unauthorized;
		} else if (requestedAccess == FlsAccess.Createable) {
			status = fieldDescribe.isCreateable() ? FlsStatus.OK : FlsStatus.Unauthorized;
		} else if (requestedAccess == FlsAccess.Filterable) {
			status = fieldDescribe.isFilterable() ? FlsStatus.OK : FlsStatus.Unauthorized;
		} else if (requestedAccess == FlsAccess.Unencrypted) {
			// isEncrypted can return null
			status = !(fieldDescribe.isEncrypted() == true) ? FlsStatus.OK : FlsStatus.Unauthorized;
		}
		return new FlsResult(fieldName, status);
	}

	@TestVisible
	private static FlsResult getFlsResult(final FlsAccess requestedAccess, final String objectName,
		final DescribeSObjectResult objectDescribe) {

		if (String.isBlank(objectName)) return new FlsResult(objectName, FlsStatus.BadRequest);
		if (objectDescribe == null) return new FlsResult(objectName, FlsStatus.NotFound);

		FlsStatus status = FlsStatus.BadRequest;
		if (requestedAccess == FlsAccess.Queryable) {
			status = objectDescribe.isAccessible() ? FlsStatus.OK : FlsStatus.Unauthorized;
		} else if (requestedAccess == FlsAccess.Updateable) {
			status = objectDescribe.isUpdateable() ? FlsStatus.OK : FlsStatus.Unauthorized;
		} else if (requestedAccess == FlsAccess.Createable) {
			status = objectDescribe.isCreateable() ? FlsStatus.OK : FlsStatus.Unauthorized;
		} else if (requestedAccess == FlsAccess.Deletable) {
			status = objectDescribe.isDeletable() ? FlsStatus.OK : FlsStatus.Unauthorized;
		} else { // Filterable or Unencrypted are only at the field level
			status = FlsStatus.OK;
		}
		return new FlsResult(objectName, status);
	}

	@TestVisible
	private static FlsResults getFlsResults(final FlsAccess requestedAccess, final SObjectType type,
		final List<String> fieldNames) {

		if (type == null) {
			return new FlsResults(requestedAccess, false, new FlsResult(Label.Unknown, FlsStatus.BadRequest),
				new List<FlsResult>());
		}

		String objectName = String.valueOf(type);
		DescribeSObjectResult objectDescribe = type.getDescribe();
		if (objectDescribe == null) {
			return new FlsResults(requestedAccess, false, new FlsResult(objectName, FlsStatus.NotFound),
				new List<FlsResult>());
		}

		return getFlsResults(requestedAccess, objectName, objectDescribe, fieldNames,
			Collection.isNotEmpty(fieldNames) ? objectDescribe.fields.getMap() : null);
	}

	@TestVisible
	private static FlsResults getFlsResults(final FlsAccess requestedAccess, final String objectName,
		final DescribeSObjectResult objectDescribe, final List<String> fieldNames,
		final Map<String, SObjectField> fieldMap) {

		if (String.isBlank(objectName)) {
			return new FlsResults(requestedAccess, false, new FlsResult(Label.Unknown, FlsStatus.BadRequest),
				new List<FlsResult>());
		}

		FlsResult objectResult = getFlsResult(requestedAccess, objectName, objectDescribe);
		Boolean isAuthorized = objectResult.isAuthorized;
		List<FlsResult> fieldResults = new List<FlsResult>();
		if (Collection.isNotEmpty(fieldNames) && Collection.isNotEmpty(fieldMap)) {
			for (String f : fieldNames) {
				if (String.isBlank(f)) {
					isAuthorized = false;
					fieldResults.add(new FlsResult(Label.Unknown, FlsStatus.BadRequest));
				} else {
					SObjectField sof = fieldMap.get(f);
					if (sof == null && f.endsWith('__c')) {
						sof = fieldMap.get(Application.namespacePrefix + f);
						f = sof == null ? f : Application.namespacePrefix + f;
					}
					FlsResult fieldResult = getFlsResult(requestedAccess, f, describeField(objectName, f, sof));
					isAuthorized &= fieldResult.isAuthorized;
					fieldResults.add(fieldResult);
				}
			}
		}

		return new FlsResults(requestedAccess, isAuthorized, objectResult, fieldResults);
	}

	/**
	 * Tests whether an object and its fields are createable by the current user.
	 *
	 * @param objectName The object name.
	 * @param fieldNames The field names.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isCreateable(final SObjectType type, final List<String> fieldNames) {
		if (!IS_FLS_SUPPORTED) return new FlsResults(FlsAccess.Createable, true, null, null);

		return getFlsResults(FlsAccess.Createable, type, fieldNames);
	}

	/**
	 * Tests whether an object and its fields are createable by the current user. If not, an
	 * <code>UnauthorizedException</code> is thrown.
	 *
	 * @param objectName The object name.
	 * @param fieldNames The field names.
	 */
	public static void verifyIsCreateable(final SObjectType type, final List<String> fieldNames) {
		FlsResults results = isCreateable(type, fieldNames);
		if (!results.isAuthorized) throw new UnauthorizedException(results.getErrorMessage());
	}

	/**
	 * Tests whether an object is deletable by the current user.
	 *
	 * @param objectName The object name.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isDeletable(final SObjectType type) {
		if (!IS_FLS_SUPPORTED) return new FlsResults(FlsAccess.Deletable, true, null, null);

		return getFlsResults(FlsAccess.Deletable, type, null);
	}

	/**
	 * Tests whether an object is deletable by the current user. If not, an <code>UnauthorizedException</code> is
	 * thrown.
	 *
	 * @param objectName The object name.
	 */
	public static void verifyIsDeletable(final SObjectType type) {
		FlsResults results = isDeletable(type);
		if (!results.isAuthorized) throw new UnauthorizedException(results.getErrorMessage());
	}

	/**
	 * Tests whether an object and its fields are queryable by the current user.
	 *
	 * @param objectName The object name.
	 * @param fieldNames The field names.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isQueryable(final SObjectType type, final List<String> fieldNames) {
		if (!IS_FLS_SUPPORTED) return new FlsResults(FlsAccess.Queryable, true, null, null);

		return getFlsResults(FlsAccess.Queryable, type, fieldNames);
	}

	/**
	 * Tests whether an object and its fields are queryable by the current user. If not, an
	 * <code>UnauthorizedException</code> is thrown.
	 *
	 * @param objectName The object name.
	 * @param fieldNames The field names.
	 */
	public static void verifyIsQueryable(final SObjectType type, final List<String> fieldNames) {
		FlsResults results = isQueryable(type, fieldNames);
		if (!results.isAuthorized) throw new UnauthorizedException(results.getErrorMessage());
	}

	/**
	 * Tests whether an object and its fields are updateable by the current user.
	 *
	 * @param objectName The object name.
	 * @param fieldNames The field names.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isUpdateable(final SObjectType type, final List<String> fieldNames) {
		if (!IS_FLS_SUPPORTED) return new FlsResults(FlsAccess.Updateable, true, null, null);

		return getFlsResults(FlsAccess.Updateable, type, fieldNames);
	}

	/**
	 * Tests whether an object and its fields are updateable by the current user. If not, an
	 * <code>UnauthorizedException</code> is thrown.
	 *
	 * @param objectName The object name.
	 * @param fieldNames The field names.
	 */
	public static void verifyIsUpdateable(final SObjectType type, final List<String> fieldNames) {
		FlsResults results = isUpdateable(type, fieldNames);
		if (!results.isAuthorized) throw new UnauthorizedException(results.getErrorMessage());
	}

	/**
	 * Tests whether an object's fields are filterable.
	 *
	 * @param objectName The object name.
	 * @param fieldNames The field names.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isFilterable(final SObjectType type, final List<String> fieldNames) {
		if (!IS_FLS_SUPPORTED) return new FlsResults(FlsAccess.Filterable, true, null, null);

		return getFlsResults(FlsAccess.Filterable, type, fieldNames);
	}

	/**
	 * Tests whether an object's fields are filterable. If not, an <code>UnauthorizedException</code> is thrown.
	 *
	 * @param objectName The object name.
	 * @param fieldNames The field names.
	 */
	public static void verifyIsFilterable(final SObjectType type, final List<String> fieldNames) {
		FlsResults results = isFilterable(type, fieldNames);
		if (!results.isAuthorized) throw new UnauthorizedException(results.getErrorMessage());
	}

	/**
	 * Tests whether an object's fields are unencrypted.
	 *
	 * @param objectName The object name.
	 * @param fieldNames The field names.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isUnencrypted(final SObjectType type, final List<String> fieldNames) {
		if (!IS_FLS_SUPPORTED) return new FlsResults(FlsAccess.Unencrypted, true, null, null);

		return getFlsResults(FlsAccess.Unencrypted, type, fieldNames);
	}

	/**
	 * Tests whether an object's fields are unencrypted. If not, an <code>UnauthorizedException</code> is thrown.
	 *
	 * @param objectName The object name.
	 * @param fieldNames The field names.
	 */
	public static void verifyIsUnencrypted(final SObjectType type, final List<String> fieldNames) {
		FlsResults results = isUnencrypted(type, fieldNames);
		if (!results.isAuthorized) throw new UnauthorizedException(results.getErrorMessage());
	}
}
