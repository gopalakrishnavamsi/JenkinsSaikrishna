public with sharing class Permissions {

	private static final Permissions.Database DB = new Permissions.Database();
	@TestVisible
	private static final Boolean IS_FLS_SUPPORTED;
	private static final Map<String, SObjectType> GLOBAL_SCHEMA = Schema.getGlobalDescribe();
	private static final Map<String, DescribeSObjectResult> OBJECT_DESCRIBE_MAP = new Map<String, DescribeSObjectResult>();
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
			Permissions.verifyIsCreateable('PermissionSetAssignment', new List<String> {
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
			Permissions.verifyIsDeletable('PermissionSetAssignment');

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

	public static Id getDocuSignAdministratorPermissionSetId() {
		if (dsUserPermissionSetId == null) {
			dsUserPermissionSetId = getPermissionSetMap().get(DOCUSIGN_ADMINISTRATOR);
		}
		return dsUserPermissionSetId;
	}

	public static Id getDocuSignUserPermissionSetId() {
		if (dsAdministratorPermissionSetId == null) {
			dsAdministratorPermissionSetId = getPermissionSetMap().get(DOCUSIGN_USER);
		}
		return dsAdministratorPermissionSetId;
	}

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

	public static void verifyIsDocuSignAdministrator() {
		verifyIsDocuSignAdministrator(UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsDocuSignAdministrator(final Id userId) {
		if (String.isBlank(userId) || !isDocuSignAdministrator(userId))
			throw UnauthorizedException.notDocuSignAdministrator();
	}

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

	public static void verifyIsDocuSignUser() {
		verifyIsDocuSignUser(UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsDocuSignUser(final Id userId) {
		if (String.isBlank(userId) || !isDocuSignUser(userId)) throw UnauthorizedException.notDocuSignUser();
	}

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

	public static void verifyIsOwner(final Id envelopeId) {
		verifyIsOwner(envelopeId, UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsOwner(final Id envelopeId, final Id userId) {
		if (!isOwner(envelopeId, userId)) throw UnauthorizedException.notEnvelopeOwner();
	}

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

	public static void verifyIsOwner(final UUID dsEnvelopeId) {
		verifyIsOwner(dsEnvelopeId, UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsOwner(final UUID dsEnvelopeId, final Id userId) {
		if (!isOwner(dsEnvelopeId, userId)) throw UnauthorizedException.notEnvelopeOwner();
	}

	@TestVisible
	private static DescribeSObjectResult describeObject(final String objectName) {
		if (String.isBlank(objectName)) return null;

		if (!OBJECT_DESCRIBE_MAP.containsKey(objectName)) {
			SObjectType sobjectType = GLOBAL_SCHEMA.get(objectName);
			OBJECT_DESCRIBE_MAP.put(objectName, sobjectType == null ? null : sobjectType.getDescribe());
		}
		return OBJECT_DESCRIBE_MAP.get(objectName);
	}

	@TestVisible
	private static DescribeFieldResult describeField(final String objectName, final String fieldName, final SObjectField field) {
		if (field == null) return null;

		String key = objectName + '.' + fieldName;
		if (!FIELD_DESCRIBE_MAP.containsKey(key)) {
			FIELD_DESCRIBE_MAP.put(key, field.getDescribe());
		}
		return FIELD_DESCRIBE_MAP.get(key);
	}

	public enum FlsAccess {
		Createable, Deletable, Queryable, Updateable, Filterable, Unencrypted
	}

	public enum FlsStatus {
		OK, BadRequest, NotFound, Unauthorized
	}

	public class FlsResult {
		public String name {
			get;
			private set;
		}
		public FlsStatus status {
			get;
			private set;
		}
		public Boolean isAuthorized {
			get {
				return status == FlsStatus.OK;
			}
		}

		public FlsResult(final String name, final FlsStatus status) {
			this.name = name;
			this.status = status;
		}

		override public String toString() {
			if (this.status != FlsStatus.Unauthorized && this.status != FlsStatus.OK) {
				return String.format('{0} ({1})', new List<String> { this.name, this.status.name() });
			}
			return this.name;
		}
	}

	public class FlsResults {
		public FlsAccess requestedAccess {
			get;
			private set;
		}
		public Boolean isAuthorized {
			get;
			private set;
		}
		public FlsResult objectResult {
			get;
			private set;
		}
		public List<FlsResult> fieldResults {
			get;
			private set;
		}

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
	private static FlsResults getFlsResults(final FlsAccess requestedAccess, final String objectName,
		final List<String> fieldNames) {

		if (String.isBlank(objectName)) {
			return new FlsResults(requestedAccess, false, new FlsResult(Label.Unknown, FlsStatus.BadRequest),
				new List<FlsResult>());
		}

		String resolvedName = Application.resolveType(objectName);
		DescribeSObjectResult objectDescribe = describeObject(resolvedName);
		if (objectDescribe == null) {
			return new FlsResults(requestedAccess, false, new FlsResult(resolvedName, FlsStatus.NotFound),
				new List<FlsResult>());
		}

		return getFlsResults(requestedAccess, resolvedName, objectDescribe, fieldNames,
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

	public static FlsResults isCreateable(final String objectName, final List<String> fieldNames) {
		if (!IS_FLS_SUPPORTED) return new FlsResults(FlsAccess.Createable, true, null, null);

		return getFlsResults(FlsAccess.Createable, objectName, fieldNames);
	}

	public static void verifyIsCreateable(final String objectName, final List<String> fieldNames) {
		FlsResults results = isCreateable(objectName, fieldNames);
		if (!results.isAuthorized) throw new UnauthorizedException(results.getErrorMessage());
	}

	public static FlsResults isDeletable(final String objectName) {
		if (!IS_FLS_SUPPORTED) return new FlsResults(FlsAccess.Deletable, true, null, null);

		return getFlsResults(FlsAccess.Deletable, objectName, null);
	}

	public static void verifyIsDeletable(final String objectName) {
		FlsResults results = isDeletable(objectName);
		if (!results.isAuthorized) throw new UnauthorizedException(results.getErrorMessage());
	}

	public static FlsResults isQueryable(final String objectName, final List<String> fieldNames) {
		if (!IS_FLS_SUPPORTED) return new FlsResults(FlsAccess.Queryable, true, null, null);

		return getFlsResults(FlsAccess.Queryable, objectName, fieldNames);
	}

	public static void verifyIsQueryable(final String objectName, final List<String> fieldNames) {
		FlsResults results = isQueryable(objectName, fieldNames);
		if (!results.isAuthorized) throw new UnauthorizedException(results.getErrorMessage());
	}

	public static FlsResults isUpdateable(final String objectName, final List<String> fieldNames) {
		if (!IS_FLS_SUPPORTED) return new FlsResults(FlsAccess.Updateable, true, null, null);

		return getFlsResults(FlsAccess.Updateable, objectName, fieldNames);
	}

	public static void verifyIsUpdateable(final String objectName, final List<String> fieldNames) {
		FlsResults results = isUpdateable(objectName, fieldNames);
		if (!results.isAuthorized) throw new UnauthorizedException(results.getErrorMessage());
	}

	public static FlsResults isFilterable(final String objectName, final List<String> fieldNames) {
		if (!IS_FLS_SUPPORTED) return new FlsResults(FlsAccess.Filterable, true, null, null);

		return getFlsResults(FlsAccess.Filterable, objectName, fieldNames);
	}

	public static void verifyIsFilterable(final String objectName, final List<String> fieldNames) {
		FlsResults results = isFilterable(objectName, fieldNames);
		if (!results.isAuthorized) throw new UnauthorizedException(results.getErrorMessage());
	}

	public static FlsResults isUnencrypted(final String objectName, final List<String> fieldNames) {
		if (!IS_FLS_SUPPORTED) return new FlsResults(FlsAccess.Unencrypted, true, null, null);

		return getFlsResults(FlsAccess.Unencrypted, objectName, fieldNames);
	}

	public static void verifyIsUnencrypted(final String objectName, final List<String> fieldNames) {
		FlsResults results = isUnencrypted(objectName, fieldNames);
		if (!results.isAuthorized) throw new UnauthorizedException(results.getErrorMessage());
	}
}
