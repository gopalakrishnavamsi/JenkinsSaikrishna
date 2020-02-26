/**
 * Contains permissions-related operations.
 */
public with sharing class Permissions {

	@TestVisible
	private static final Permissions.Database DB = new Permissions.Database();
	private static final SObjectType TYPE_PERMISSION_SET_ASSIGNMENT = PermissionSetAssignment.getSObjectType();
	private static final Map<String, DescribeFieldResult> FIELD_DESCRIBE_MAP = new Map<String, DescribeFieldResult>();
	private static final Set<String> SPECIAL_CASE_FIELDS = new Set<String> { 'Owner', 'MasterRecord', 'Parent' };
	private static final Map<Id, Set<String>> ASSIGNMENTS = new Map<Id, Set<String>>();
	@TestVisible
	private static Boolean allowImpersonation = null;
	@TestVisible
	private static Boolean isImpersonating = null;

	// Permission set names
	public static final String DOCUSIGN_ADMINISTRATOR = 'docusign_administrator';
	public static final String DOCUSIGN_USER = 'docusign_user';
	public static final String DOCUSIGN_SENDER = 'docusign_sender';
	public static final String DOCUSIGN_GENERATOR = 'docusign_generator';
	public static final String DOCUSIGN_NEGOTIATOR = 'docusign_negotiator';
	public static final String CLM_ADMINISTRATOR = 'clm_administrator';
	public static final String CLM_USER = 'clm_user';
	public static final String CLM_VIEWER = 'clm_viewer';
	@TestVisible
	private static final Set<String> VALID_PERMISSION_SETS = new Set<String> {
		DOCUSIGN_ADMINISTRATOR, DOCUSIGN_USER, DOCUSIGN_SENDER,
		DOCUSIGN_GENERATOR,
		DOCUSIGN_NEGOTIATOR,
		CLM_ADMINISTRATOR, CLM_USER, CLM_VIEWER
	};

	@TestVisible
	private class ProductRole {
		public String product { get; private set; }
		public String role { get; private set; }

		public ProductRole(
			final String product,
			final String role) {

			this.product = product;
			this.role = role;
		}
	}

	@TestVisible
	private static Boolean isRoleSuperseded(
		final String productName,
		final String currentRole,
		final String newRole) {

		if (String.isBlank(currentRole)) return true;

		if (String.isBlank(productName)
			|| String.isBlank(newRole)
			|| (productName != Product.ESIGNATURE && productName != Product.CLM)
			|| currentRole == newRole) {

			return false;
		}

		if (productName == Product.ESIGNATURE) {
			if (currentRole == ESignatureProduct.ROLE_SENDER
				&& (newRole == ESignatureProduct.ROLE_USER
				|| newRole == ESignatureProduct.ROLE_ADMINISTRATOR)) {

				return true;
			} else if (currentRole == ESignatureProduct.ROLE_USER
				&& newRole == ESignatureProduct.ROLE_ADMINISTRATOR) {

				return true;
			}
		} else { // CLM
			if (currentRole == ClmProduct.ROLE_VIEWER
				&& (newRole == ClmProduct.ROLE_USER
				|| newRole == ClmProduct.ROLE_ADMINISTRATOR)) {

				return true;
			} else if (currentRole == ClmProduct.ROLE_USER
				&& newRole == ClmProduct.ROLE_ADMINISTRATOR) {

				return true;
			}
		}

		return false;
	}

	@TestVisible
	private with sharing class Database {

		private Map<Id, Map<String, String>> queryUserRoles(final Set<Id> userIds) {
			if (Collection.isEmpty(userIds)) return new Map<Id, Map<String, String>>();

			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
				'Id'
			});
			Permissions.verifyIsQueryable(PermissionSet.getSObjectType(), new List<String> {
				'Name'
			});

			Map<String, ProductRole> prs = new Map<String, ProductRole> {
				DOCUSIGN_ADMINISTRATOR => new ProductRole(Product.ESIGNATURE, ESignatureProduct.ROLE_ADMINISTRATOR),
				DOCUSIGN_USER => new ProductRole(Product.ESIGNATURE, ESignatureProduct.ROLE_USER),
				DOCUSIGN_SENDER => new ProductRole(Product.ESIGNATURE, ESignatureProduct.ROLE_SENDER),
				DOCUSIGN_GENERATOR => new ProductRole(Product.GEN, GenProduct.ROLE_GENERATOR),
				DOCUSIGN_NEGOTIATOR => new ProductRole(Product.NEGOTIATE, NegotiateProduct.ROLE_NEGOTIATOR),
				CLM_ADMINISTRATOR => new ProductRole(Product.CLM, ClmProduct.ROLE_ADMINISTRATOR),
				CLM_USER => new ProductRole(Product.CLM, ClmProduct.ROLE_USER),
				CLM_VIEWER => new ProductRole(Product.CLM, ClmProduct.ROLE_VIEWER)
			};
			Map<Id, Map<String, String>> result = new Map<Id, Map<String, String>>();
			for (PermissionSetAssignment psa : [
				SELECT AssigneeId, PermissionSet.Name
				FROM PermissionSetAssignment
				WHERE AssigneeId IN :userIds
				AND PermissionSet.NamespacePrefix = :Application.packageNamespace
				AND PermissionSet.Name IN :VALID_PERMISSION_SETS
			]) {
				if (String.isBlank(psa.PermissionSet.Name)) continue;

				ProductRole pr = prs.get(psa.PermissionSet.Name.toLowerCase());
				if (pr == null) continue;

				if (result.containsKey(psa.AssigneeId)) {
					String currentRole = result.get(psa.AssigneeId).get(pr.product);
					if (isRoleSuperseded(pr.product, currentRole, pr.role)) {
						result.get(psa.AssigneeId).put(pr.product, pr.role);
					}
				} else {
					result.put(psa.AssigneeId, new Map<String, String> {
						pr.product => pr.role
					});
				}
			}

			return result;
		}

		private Set<Id> queryPermissionSetIds(final Set<String> permissionSetNames) {
			Permissions.verifyIsQueryable(PermissionSet.getSObjectType(), new List<String> { 'Name' });

			Set<Id> result = new Set<Id>();
			if (Collection.isNotEmpty(permissionSetNames)) {
				for (PermissionSet ps : [
					SELECT Id
					FROM PermissionSet
					WHERE NamespacePrefix = :Application.packageNamespace
					AND Name IN :permissionSetNames
				]) {
					result.add(ps.Id);
				}
			}
			return result;
		}

		private Boolean upsertPermissionSetAssignments(
			final Set<Id> userIds,
			final Set<String> permissionSetNames) {

			Permissions.verifyIsCreateable(TYPE_PERMISSION_SET_ASSIGNMENT, new List<String> {
				'PermissionSetId', 'AssigneeId'
			});
			// Doesn't actually update during upsert. It just doesn't fail to insert if the assignment already exists.

			Boolean result = false;
			Set<Id> permissionSetIds = queryPermissionSetIds(permissionSetNames);
			if (Collection.isNotEmpty(permissionSetIds) && Collection.isNotEmpty(userIds)) {
				List<PermissionSetAssignment> ps = new List<PermissionSetAssignment>();
				for (Id userId : userIds) {
					for (Id permissionSetId : permissionSetIds) {
						ps.add(new PermissionSetAssignment(PermissionSetId = permissionSetId, AssigneeId = userId));
					}
				}
				upsert ps;
				result = true;
			}
			return result;
		}

		private Boolean deletePermissionSetAssignments(
			final Set<Id> userIds,
			final Set<String> permissionSetNames) {

			Permissions.verifyIsDeletable(TYPE_PERMISSION_SET_ASSIGNMENT);

			Boolean result = false;
			if (Collection.isNotEmpty(userIds) && Collection.isNotEmpty(permissionSetNames)) {
				delete [
					SELECT Id
					FROM PermissionSetAssignment
					WHERE PermissionSet.NamespacePrefix = :Application.packageNamespace
					AND PermissionSet.Name IN :permissionSetNames
					AND AssigneeId IN :userIds
				];
				result = true;
			}
			return result;
		}

		private Set<String> queryAssignedPermissionSets(final Id userId) {
			Set<String> result = new Set<String>();
			for (PermissionSetAssignment psa : [
				SELECT PermissionSet.Name
				FROM PermissionSetAssignment
				WHERE AssigneeId = :userId
				AND PermissionSet.NamespacePrefix = :Application.packageNamespace
				AND PermissionSet.Name IN :VALID_PERMISSION_SETS
			]) {
				result.add(psa.PermissionSet.Name.toLowerCase());
			}
			return result;
		}

		public Set<Id> queryOwners(final Set<Id> envelopeIds) {
			if (envelopeIds == null) return null;

			List<Envelope__c> es = [
				SELECT OwnerId
				FROM Envelope__c
				WHERE Id IN :envelopeIds
			];
			if (Collection.isEmpty(es)) throw new DocuSignException(Label.EnvelopeNotFound);

			Set<Id> result = new Set<Id>();
			for (Envelope__c e : es) {
				result.add(e.OwnerId);
			}
			return result;
		}

		public Set<Id> queryOwners(final Set<UUID> dsEnvelopeIds) {
			if (dsEnvelopeIds == null) return null;

			Set<String> dseIds = new Set<String>();
			for (UUID dseId : dsEnvelopeIds) {
				dseIds.add(String.valueOf(dseId));
			}

			List<Envelope__c> es = [
				SELECT OwnerId
				FROM Envelope__c
				WHERE DocuSignId__c IN :dseIds
			];
			if (Collection.isEmpty(es)) throw new DocuSignException(Label.EnvelopeNotFound);

			Set<Id> result = new Set<Id>();
			for (Envelope__c e : es) {
				result.add(e.OwnerId);
			}
			return result;
		}
	}

	@TestVisible
	private static Set<String> getAssignedPermissionSets(final Id userId) {
		Set<String> result = ASSIGNMENTS.get(userId);
		if (result == null) {
			result = DB.queryAssignedPermissionSets(userId);
			ASSIGNMENTS.put(userId, result);
		}
		return result;
	}

	/**
	 * Checks whether the current user is assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return <code>true</code> if the current user is a DocuSign eSignature administrator, <code>false</code>
	 * otherwise.
	 */
	public static Boolean isDocuSignAdministrator() {
		return isDocuSignAdministrator(UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isDocuSignAdministrator(final Id userId) {
		return String.isNotBlank(userId)
			&& getAssignedPermissionSets(userId).contains(DOCUSIGN_ADMINISTRATOR);
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not assigned the
	 * <code>DocuSign Administrator</code> permission set.
	 */
	public static void verifyIsDocuSignAdministrator() {
		verifyIsDocuSignAdministrator(UserInfo.getUserId());
	}

	public static void verifyIsDocuSignAdministratorOrGenerator() {
		if (!isDocuSignAdministrator() && !isDocuSignGenerator()) {
			throw new UnauthorizedException(
				Label.MustBeAdministratorOrGenerator,
				UnauthorizedException.AccessRequirement.SecurityPermission);
		}
	}

	@TestVisible
	private static void verifyIsDocuSignAdministrator(final Id userId) {
		if (String.isBlank(userId) || !isDocuSignAdministrator(userId)) {
			throw UnauthorizedException.notDocuSignAdministrator();
		}
	}

	/**
	 * Checks whether the current user is assigned the <code>DocuSign User</code> or
	 * <code>DocuSign Administrator</code> permission set.
	 *
	 * @return <code>true</code> if the current user is a DocuSign eSignature user, <code>false</code>
	 * otherwise.
	 */
	public static Boolean isDocuSignUser() {
		return isDocuSignUser(UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isDocuSignUser(final Id userId) {
		Set<String> pss = getAssignedPermissionSets(userId);
		return String.isNotBlank(userId)
			&& (pss.contains(DOCUSIGN_ADMINISTRATOR)
			|| pss.contains(DOCUSIGN_USER));
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
	 * Checks whether the current user is assigned the <code>DocuSign Sender</code>,
	 * <code>DocuSign User</code>, or <code>DocuSign Administrator</code> permission set.
	 *
	 * @return <code>true</code> if the current user is a DocuSign eSignature sender, <code>false</code>
	 * otherwise.
	 */
	public static Boolean isDocuSignSender() {
		return isDocuSignSender(UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isDocuSignSender(final Id userId) {
		Set<String> pss = getAssignedPermissionSets(userId);
		return String.isNotBlank(userId)
			&& (pss.contains(DOCUSIGN_ADMINISTRATOR)
			|| pss.contains(DOCUSIGN_USER)
			|| pss.contains(DOCUSIGN_SENDER));
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not assigned the
	 * <code>DocuSign Sender</code>, <code>DocuSign User</code>, or <code>DocuSign Administrator</code> permission set.
	 */
	public static void verifyIsDocuSignSender() {
		verifyIsDocuSignSender(UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsDocuSignSender(final Id userId) {
		if (String.isBlank(userId) || !isDocuSignSender(userId)) throw UnauthorizedException.notDocuSignSender();
	}

	/**
	 * Checks whether the current user is assigned the <code>DocuSign Generator</code> permission set.
	 *
	 * @return <code>true</code> if the current user is a DocuSign Gen document generator, <code>false</code>
	 * otherwise.
	 */
	public static Boolean isDocuSignGenerator() {
		return isDocuSignGenerator(UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isDocuSignGenerator(final Id userId) {
		return String.isNotBlank(userId)
			&& getAssignedPermissionSets(userId).contains(DOCUSIGN_GENERATOR);
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not assigned the
	 * <code>DocuSign Generator</code> permission set.
	 */
	public static void verifyIsDocuSignGenerator() {
		verifyIsDocuSignGenerator(UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsDocuSignGenerator(final Id userId) {
		if (String.isBlank(userId) || !isDocuSignGenerator(userId)) throw UnauthorizedException.notDocuSignGenerator();
	}

	/**
	 * Checks whether the current user is assigned the <code>DocuSign Negotiator</code> permission set.
	 *
	 * @return <code>true</code> if the current user is a DocuSign Negotiate document negotiator,
	 * <code>false</code> otherwise.
	 */
	public static Boolean isDocuSignNegotiator() {
		return isDocuSignNegotiator(UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isDocuSignNegotiator(final Id userId) {
		return String.isNotBlank(userId)
			&& getAssignedPermissionSets(userId).contains(DOCUSIGN_NEGOTIATOR);
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not assigned the
	 * <code>DocuSign Negotiator</code> permission set.
	 */
	public static void verifyIsDocuSignNegotiator() {
		verifyIsDocuSignNegotiator(UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsDocuSignNegotiator(final Id userId) {
		if (String.isBlank(userId) || !isDocuSignNegotiator(userId)) {
			throw UnauthorizedException.notDocuSignNegotiator();
		}
	}

	/**
	 * Checks whether the current user is assigned the <code>CLM Administrator</code> permission set.
	 *
	 * @return <code>true</code> if the current user is a DocuSign CLM administrator,
	 * <code>false</code> otherwise.
	 */
	public static Boolean isClmAdministrator() {
		return isClmAdministrator(UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isClmAdministrator(final Id userId) {
		return String.isNotBlank(userId)
			&& getAssignedPermissionSets(userId).contains(CLM_ADMINISTRATOR);
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not assigned the
	 * <code>CLM Administrator</code> permission set.
	 */
	public static void verifyIsClmAdministrator() {
		verifyIsClmAdministrator(UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsClmAdministrator(final Id userId) {
		if (String.isBlank(userId) || !isClmAdministrator(userId)) {
			throw UnauthorizedException.notClmAdministrator();
		}
	}

	/**
	 * Checks whether the current user is assigned the <code>CLM User</code> or <code>CLM Administrator</code>
	 * permission set.
	 *
	 * @return <code>true</code> if the current user is a DocuSign CLM user,
	 * <code>false</code> otherwise.
	 */
	public static Boolean isClmUser() {
		return isClmUser(UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isClmUser(final Id userId) {
		Set<String> pss = getAssignedPermissionSets(userId);
		return String.isNotBlank(userId)
			&& (pss.contains(CLM_ADMINISTRATOR)
			|| pss.contains(CLM_USER));
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not assigned the
	 * <code>CLM User</code> or <code>CLM Administrator</code> permission set.
	 */
	public static void verifyIsClmUser() {
		verifyIsClmUser(UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsClmUser(final Id userId) {
		if (String.isBlank(userId) || !isClmUser(userId)) {
			throw UnauthorizedException.notClmUser();
		}
	}

	/**
	 * Checks whether the current user is assigned the <code>CLM Viewer</code>, <code>CLM User</code>, or
	 * <code>CLM Administrator</code> permission set.
	 *
	 * @return <code>true</code> if the current user is a DocuSign CLM viewer,
	 * <code>false</code> otherwise.
	 */
	public static Boolean isClmViewer() {
		return isClmViewer(UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isClmViewer(final Id userId) {
		Set<String> pss = getAssignedPermissionSets(userId);
		return String.isNotBlank(userId)
			&& (pss.contains(CLM_ADMINISTRATOR)
			|| pss.contains(CLM_USER)
			|| pss.contains(CLM_VIEWER));
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not assigned the
	 * <code>CLM Viewer</code>, <code>CLM User</code>, or <code>CLM Administrator</code> permission set.
	 */
	public static void verifyIsClmViewer() {
		verifyIsClmViewer(UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsClmViewer(final Id userId) {
		if (String.isBlank(userId) || !isClmViewer(userId)) {
			throw UnauthorizedException.notClmViewer();
		}
	}

	@TestVisible
	private static Set<Id> filterNotCurrentUserId(final Set<Id> userIds) {
		Id currentUserId = UserInfo.getUserId();
		Set<Id> result = new Set<Id>();
		if (userIds != null) {
			for (Id uId : userIds) {
				if (uId != currentUserId) result.add(uId);
			}
		}
		return result;
	}

	@TestVisible
	private static Set<Id> verifyMaximumBatchSize(
		final Set<Id> userIds,
		final Integer maximumSize) {

		if (userIds == null) return new Set<Id>();

		Integer max = maximumSize <= 0 ? Application.batchLimit : maximumSize;
		Integer size = userIds.size();
		if (size > max) {
			throw new DocuSignException(String.format(Label.MaximumBatchSizeExceeded_2,
				new List<Object> { size, max }));
		}
		return userIds;
	}

	/**
	 * Removes all DocuSign permission sets from one or more users.
	 *
	 * @param userIds The user IDs.
	 *
	 * @return <code>true</code> if the permission set removals were successful, <code>false</code> otherwise.
	 */
	public static Boolean clear(final Set<Id> userIds) {
		Boolean result = false;
		if (Collection.isNotEmpty(userIds)) {
			Id currentUserId = UserInfo.getUserId();
			Boolean hasCurrentUser = userIds.contains(currentUserId);
			Set<String> psns = new Set<String>(VALID_PERMISSION_SETS);
			result |= DB.deletePermissionSetAssignments(
				verifyMaximumBatchSize(filterNotCurrentUserId(userIds), Application.batchLimit),
				psns);
			if (hasCurrentUser) { // Ensure current user does not lose admin permissions.
				psns.remove(DOCUSIGN_ADMINISTRATOR);
				psns.remove(CLM_ADMINISTRATOR);
				result |= DB.deletePermissionSetAssignments(
					new Set<Id> { currentUserId },
					psns);
			}
			for (Id userId : userIds) {
				ASSIGNMENTS.remove(userId);
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
		return String.isNotBlank(envelopeId) && isOwner(new Set<Id> { envelopeId }, UserInfo.getUserId());
	}

	/**
	 * Checks whether the current user is the owner of multiple envelopes. Involves a SOQL query.
	 *
	 * @param envelopeIds The envelope IDs.
	 *
	 * @return <code>true</code> if the current user owns all of the envelopes, <code>false</code> otherwise.
	 */
	public static Boolean isOwner(final Set<Id> envelopeIds) {
		return envelopeIds != null && isOwner(envelopeIds, UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isOwner(final Set<Id> envelopeIds, final Id userId) {
		if (envelopeIds == null) return false;

		Set<Id> ownerIds = DB.queryOwners(envelopeIds);
		for (Id ownerId : ownerIds) {
			if (ownerId != userId) return false;
		}
		return true;
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not the owner of the envelope.
	 *
	 * @param envelopeId The envelope ID.
	 */
	public static void verifyIsOwner(final Id envelopeId) {
		verifyIsOwner(new Set<Id> { envelopeId }, UserInfo.getUserId());
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not the owner of all the envelopes.
	 *
	 * @param envelopeIds The envelope IDs.
	 */
	public static void verifyIsOwner(final Set<Id> envelopeIds) {
		verifyIsOwner(envelopeIds, UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsOwner(final Set<Id> envelopeIds, final Id userId) {
		if (!isOwner(envelopeIds, userId)) throw UnauthorizedException.notEnvelopeOwner();
	}

	/**
	 * Checks whether the current user is the owner of an envelope. Involves a SOQL query.
	 *
	 * @param dsEnvelopeId The DocuSign envelope ID.
	 *
	 * @return <code>true</code> if the current user owns the envelope, <code>false</code> otherwise.
	 */
	public static Boolean isOwner(final UUID dsEnvelopeId) {
		return dsEnvelopeId != null && isOwner(new Set<UUID> { dsEnvelopeId }, UserInfo.getUserId());
	}

	/**
	 * Checks whether the current user is the owner of multiple envelopes. Involves a SOQL query.
	 *
	 * @param dsEnvelopeIds The DocuSign envelope IDs.
	 *
	 * @return <code>true</code> if the current user owns all of the envelopes, <code>false</code> otherwise.
	 */
	public static Boolean isOwner(final Set<UUID> dsEnvelopeIds) {
		return dsEnvelopeIds != null && isOwner(dsEnvelopeIds, UserInfo.getUserId());
	}

	@TestVisible
	private static Boolean isOwner(final Set<UUID> dsEnvelopeIds, final Id userId) {
		if (dsEnvelopeIds == null) return false;

		Set<Id> ownerIds = DB.queryOwners(dsEnvelopeIds);
		for (Id ownerId : ownerIds) {
			if (ownerId != userId) return false;
		}
		return true;
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not the owner of the envelope.
	 *
	 * @param dsEnvelopeId The DocuSign envelope ID.
	 */
	public static void verifyIsOwner(final UUID dsEnvelopeId) {
		verifyIsOwner(new Set<UUID> { dsEnvelopeId }, UserInfo.getUserId());
	}

	/**
	 * Throws an <code>UnauthorizedException</code> if the current user is not the owner of all of the envelopes.
	 *
	 * @param dsEnvelopeIds The DocuSign envelope IDs.
	 */
	public static void verifyIsOwner(final Set<UUID> dsEnvelopeIds) {
		verifyIsOwner(dsEnvelopeIds, UserInfo.getUserId());
	}

	@TestVisible
	private static void verifyIsOwner(final Set<UUID> dsEnvelopeIds, final Id userId) {
		if (!isOwner(dsEnvelopeIds, userId)) throw UnauthorizedException.notEnvelopeOwner();
	}

	@TestVisible
	private static DescribeFieldResult describeField(
		final String objectName,
		final String fieldName,
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
		if (objectDescribe == null) return new FlsResults(requestedAccess, false, new FlsResult(objectName, FlsStatus.NotFound), new List<FlsResult>());

		return getFlsResults(requestedAccess, objectName, objectDescribe, fieldNames,
			Collection.isNotEmpty(fieldNames) ? objectDescribe.fields.getMap() : null);
	}

	@TestVisible
	private static String formatIdPointingField(final String fieldName) {
		return String.format('{0}Id', new List<String> { fieldName }).toLowerCase();
	}

	@TestVisible
	private static FlsResults getFlsResults(
		final FlsAccess requestedAccess,
		final String objectName,
		final DescribeSObjectResult objectDescribe,
		final List<String> fieldNames,
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
					// Using a value that is contained in SPECIAL_CASE_FIELDS, returns bad query, so we need to format it.
					if (SPECIAL_CASE_FIELDS.contains(f)) f = formatIdPointingField(f);
					SObjectField sof = fieldMap.get(f);
					if (sof == null && !objectDescribe.isCustom() && !f.endsWith('__c') && Salesforce.exists(f)) {
						// In the event we have a lookup field with the same name as the master object.
						f = formatIdPointingField(f);
						sof = fieldMap.get(f);
					} else if (sof == null && f.endsWith('__c')) {
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
	 * @param type The Salesforce object type.
	 * @param fieldNames The field names.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isCreateable(final SObjectType type, final List<String> fieldNames) {
		if (!Salesforce.isFlsSupported) return new FlsResults(FlsAccess.Createable, true, null, null);

		return getFlsResults(FlsAccess.Createable, type, fieldNames);
	}

	/**
	 * Tests whether an object and its fields are createable by the current user. If not, an
	 * <code>UnauthorizedException</code> is thrown.
	 *
	 * @param type The Salesforce object type.
	 * @param fieldNames The field names.
	 */
	public static void verifyIsCreateable(final SObjectType type, final List<String> fieldNames) {
		FlsResults results = isCreateable(type, fieldNames);
		if (!results.isAuthorized) throw UnauthorizedException.missingSecurityPermission(results.getErrorMessage());
	}

	/**
	 * Tests whether an object is deletable by the current user.
	 *
	 * @param type The Salesforce object type.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isDeletable(final SObjectType type) {
		if (!Salesforce.isFlsSupported) return new FlsResults(FlsAccess.Deletable, true, null, null);

		return getFlsResults(FlsAccess.Deletable, type, null);
	}

	/**
	 * Tests whether an object is deletable by the current user. If not, an <code>UnauthorizedException</code> is
	 * thrown.
	 *
	 * @param type The Salesforce object type.
	 */
	public static void verifyIsDeletable(final SObjectType type) {
		FlsResults results = isDeletable(type);
		if (!results.isAuthorized) throw UnauthorizedException.missingSecurityPermission(results.getErrorMessage());
	}

	/**
	 * Tests whether an object is queryable by the current user.
	 *
	 * @param type The Salesforce object type.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isQueryable(final SObjectType type) {
		return isQueryable(type, null);
	}

	/**
	 * Tests whether an object and its fields are queryable by the current user.
	 *
	 * @param type The Salesforce object type.
	 * @param fieldNames The field names.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isQueryable(final SObjectType type, final List<String> fieldNames) {
		if (!Salesforce.isFlsSupported) return new FlsResults(FlsAccess.Queryable, true, null, null);

		return getFlsResults(FlsAccess.Queryable, type, fieldNames);
	}

	/**
	 * Tests whether an object is queryable by the current users. Using this method implies that FLS is enforced
	 * elsewhere, by a SOQL <code>WITH SECURITY ENFORCED</code> clause or <code>Security.stripInaccessible</code>.
	 *
	 * @param type The Salesforce object type.
	 */
	public static void verifyIsQueryable(final SObjectType type) {
		FlsResults results = isQueryable(type, null);
		if (!results.isAuthorized) throw UnauthorizedException.missingSecurityPermission(results.getErrorMessage());
	}

	/**
	 * Tests whether an object and its fields are queryable by the current user. If not, an
	 * <code>UnauthorizedException</code> is thrown.
	 *
	 * @param type The Salesforce object type.
	 * @param fieldNames The field names.
	 */
	public static void verifyIsQueryable(final SObjectType type, final List<String> fieldNames) {
		FlsResults results = isQueryable(type, fieldNames);
		if (!results.isAuthorized) throw UnauthorizedException.missingSecurityPermission(results.getErrorMessage());
	}

	/**
	 * Tests whether an object and its fields are updateable by the current user.
	 *
	 * @param type The Salesforce object type.
	 * @param fieldNames The field names.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isUpdateable(final SObjectType type, final List<String> fieldNames) {
		if (!Salesforce.isFlsSupported) return new FlsResults(FlsAccess.Updateable, true, null, null);

		return getFlsResults(FlsAccess.Updateable, type, fieldNames);
	}

	/**
	 * Tests whether an object and its fields are updateable by the current user. If not, an
	 * <code>UnauthorizedException</code> is thrown.
	 *
	 * @param type The Salesforce object type.
	 * @param fieldNames The field names.
	 */
	public static void verifyIsUpdateable(final SObjectType type, final List<String> fieldNames) {
		FlsResults results = isUpdateable(type, fieldNames);
		if (!results.isAuthorized) throw UnauthorizedException.missingSecurityPermission(results.getErrorMessage());
	}

	/**
	 * Tests whether an object's fields are filterable.
	 *
	 * @param type The Salesforce object type.
	 * @param fieldNames The field names.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isFilterable(final SObjectType type, final List<String> fieldNames) {
		if (!Salesforce.isFlsSupported) return new FlsResults(FlsAccess.Filterable, true, null, null);

		return getFlsResults(FlsAccess.Filterable, type, fieldNames);
	}

	/**
	 * Tests whether an object's fields are filterable. If not, an <code>UnauthorizedException</code> is thrown.
	 *
	 * @param type The Salesforce object type.
	 * @param fieldNames The field names.
	 */
	public static void verifyIsFilterable(final SObjectType type, final List<String> fieldNames) {
		FlsResults results = isFilterable(type, fieldNames);
		if (!results.isAuthorized) throw UnauthorizedException.missingSecurityPermission(results.getErrorMessage());
	}

	/**
	 * Tests whether an object's fields are unencrypted.
	 *
	 * @param type The Salesforce object type.
	 * @param fieldNames The field names.
	 *
	 * @return The results of the access request.
	 */
	public static FlsResults isUnencrypted(final SObjectType type, final List<String> fieldNames) {
		if (!Salesforce.isFlsSupported) return new FlsResults(FlsAccess.Unencrypted, true, null, null);

		return getFlsResults(FlsAccess.Unencrypted, type, fieldNames);
	}

	/**
	 * Tests whether an object's fields are unencrypted. If not, an <code>UnauthorizedException</code> is thrown.
	 *
	 * @param type The Salesforce object type.
	 * @param fieldNames The field names.
	 */
	public static void verifyIsUnencrypted(final SObjectType type, final List<String> fieldNames) {
		FlsResults results = isUnencrypted(type, fieldNames);
		if (!results.isAuthorized) throw UnauthorizedException.missingSecurityPermission(results.getErrorMessage());
	}

	@TestVisible
	private static Set<String> reducePermissionSets(final Set<String> permissionSetNames) {
		Set<String> result = new Set<String>();

		if (Collection.isNotEmpty(permissionSetNames)) {
			Set<String> lcNames = new Set<String>();
			for (String psn : permissionSetNames) {
				lcNames.add(psn != null ? psn.toLowerCase() : psn);
			}

			Boolean hasDSUser = permissionSetNames.contains(DOCUSIGN_USER);
			Boolean hasDSAdmin = permissionSetNames.contains(DOCUSIGN_ADMINISTRATOR);
			Boolean hasClmUser = permissionSetNames.contains(CLM_USER);
			Boolean hasClmAdmin = permissionSetNames.contains(CLM_ADMINISTRATOR);

			for (String psName : permissionSetNames) {
				if (!VALID_PERMISSION_SETS.contains(psName)) {
					throw new DocuSignException(String.format(Label.InvalidPermissionSet_1,
						new List<String> { psName }));
				}

				// For eSignature or CLM, only use most permissive set specified
				if (psName == DOCUSIGN_SENDER && (hasDSUser || hasDSAdmin)) continue;
				if (psName == DOCUSIGN_USER && hasDSAdmin) continue;
				if (psName == CLM_VIEWER && (hasClmUser || hasClmAdmin)) continue;
				if (psName == CLM_USER && hasClmAdmin) continue;

				result.add(psName);
				// DFS-6110: Add DS admin permission set for CLM admins.
				if (psName == CLM_ADMINISTRATOR && !hasDSAdmin) result.add(DOCUSIGN_ADMINISTRATOR);
			}
		}
		return result;
	}

	public static Boolean assignPermissionSets(
		final Set<Id> userIds,
		final Set<String> permissionSets) {

		Boolean result = false;
		if (Collection.isNotEmpty(userIds) && Collection.isNotEmpty(permissionSets)) {
			result = DB.upsertPermissionSetAssignments(userIds, permissionSets);
			for (Id userId : userIds) {
				ASSIGNMENTS.remove(userId);
			}
		}
		return result;
	}

	@TestVisible
	private static Set<String> getPermissionSetNames(final Map<String, String> productRoles) {
		Map<String, Map<String, String>> psMap = new Map<String, Map<String, String>> {
			Product.ESIGNATURE => new Map<String, String> {
				ESignatureProduct.ROLE_ADMINISTRATOR => DOCUSIGN_ADMINISTRATOR,
				ESignatureProduct.ROLE_USER => DOCUSIGN_USER,
				ESignatureProduct.ROLE_SENDER => DOCUSIGN_SENDER
			},
			Product.GEN => new Map<String, String> {
				GenProduct.ROLE_GENERATOR => DOCUSIGN_GENERATOR
			},
			Product.NEGOTIATE => new Map<String, String> {
				NegotiateProduct.ROLE_NEGOTIATOR => DOCUSIGN_NEGOTIATOR
			},
			Product.CLM => new Map<String, String> {
				ClmProduct.ROLE_ADMINISTRATOR => CLM_ADMINISTRATOR,
				ClmProduct.ROLE_USER => CLM_USER,
				ClmProduct.ROLE_VIEWER => CLM_VIEWER
			}
		};

		Set<String> result = new Set<String>();
		if (productRoles != null) {
			for (String p : productRoles.keySet()) {
				if (!psMap.containsKey(p)) throw new DocuSignException(Label.UnsupportedProducts);
				String psn = psMap.get(p).get(productRoles.get(p));
				if (String.isBlank(psn)) throw new DocuSignException(Label.UnsupportedProductRoles);
				result.add(psn);
			}
		}
		return result;
	}

	private class UserRoles {
		public Set<Id> userIds { get; private set; }
		public Map<String, String> productRoles { get; private set; }

		public UserRoles(
			final Set<Id> userIds,
			final Map<String, String> productRoles) {

			this.userIds = userIds;
			this.productRoles = productRoles;
		}
	}

	@TestVisible
	private static Boolean updateCurrentUserPermissionSets(final Set<String> permissionSets) {
		Id currentUserId = UserInfo.getUserId();
		Set<Id> userIds = new Set<Id> { currentUserId };
		Set<String> currentNames = getAssignedPermissionSets(currentUserId);
		Set<String> targetNames = new Set<String>();
		for (String ps : permissionSets) {
			if (String.isNotBlank(ps)) targetNames.add(ps.toLowerCase());
		}

		// If target roles do not contain current role and current role is non-admin, remove.
		Set<String> toRemove = Collection.difference(currentNames, targetNames);
		// Do not remove any admin role for current user
		toRemove.remove(DOCUSIGN_ADMINISTRATOR);
		toRemove.remove(CLM_ADMINISTRATOR);

		// If current roles do not contain target role, add unless superseded by a more permissive role.
		Set<String> toAdd = Collection.difference(targetNames, currentNames);
		// Do not add any lesser-privileged roles for eSignature or CLM.
		toAdd.remove(DOCUSIGN_USER);
		toAdd.remove(DOCUSIGN_SENDER);
		toAdd.remove(CLM_USER);
		toAdd.remove(CLM_VIEWER);

		ASSIGNMENTS.remove(UserInfo.getUserId());

		Boolean result = DB.deletePermissionSetAssignments(userIds, toRemove);
		return DB.upsertPermissionSetAssignments(userIds, toAdd) || result;
	}

	@Future
	private static void replaceRoles(final String rolesJson) {
		UserRoles urs = (UserRoles)JSON.deserialize(rolesJson, UserRoles.class);
		if (urs != null && urs.userIds != null) {
			Set<String> permissionSets = reducePermissionSets(getPermissionSetNames(urs.productRoles));
			if (urs.userIds.contains(UserInfo.getUserId())) {
				updateCurrentUserPermissionSets(permissionSets); // special treatment for current user
			}

			Set<Id> userIds = filterNotCurrentUserId(urs.userIds);
			if (Collection.isNotEmpty(userIds)) {
				DB.deletePermissionSetAssignments(userIds, VALID_PERMISSION_SETS);
				DB.upsertPermissionSetAssignments(userIds, permissionSets);
			}

			for (Id userId : urs.userIds) {
				ASSIGNMENTS.remove(userId);
			}
		}
	}

	public static Boolean replaceRoles(
		final Set<Id> userIds,
		final Map<String, String> productRoles) {

		Set<Id> uIds = verifyMaximumBatchSize(userIds, Application.batchLimit);
		if (Collection.isNotEmpty(uIds)) {
			replaceRoles(JSON.serialize(new UserRoles(uIds, productRoles)));
			return true;
		}
		return false;
	}

	public static Map<Id, Map<String, String>> getUserRoles(final Set<Id> userIds) {
		return DB.queryUserRoles(userIds);
	}

	public static Boolean isImpersonating() {
		if (Test.isRunningTest()) {
			// Auth.SessionManagement.getCurrentSession() fails in unit tests in some cases
			isImpersonating = isImpersonating == null ? false : isImpersonating;
		} else if (isImpersonating == null) {
			Map<String, String> session = Auth.SessionManagement.getCurrentSession();
			isImpersonating = session.get('SessionType') == 'SubstituteUser';
			if (!isImpersonating) { // Fallback to parent session
				String parentSessionId = session.get('ParentId');
				if (String.isNotBlank(parentSessionId)) {
					AuthSession parentSession = (AuthSession)Collection.head([
						SELECT SessionType
						FROM AuthSession
						WHERE Id = :parentSessionId
						LIMIT 1
					]);
					isImpersonating = parentSession != null && parentSession.SessionType == 'SubstituteUser';
				}
			}
		}
		return isImpersonating;
	}

	public static Boolean isImpersonationAllowed() {
		if (allowImpersonation == null) {
			try {
				allowImpersonation = FeatureManagement.checkPackageBooleanValue('AllowImpersonation');
			} catch (Exception ex) {
				LoggerService.getInstance().exception(ex,
					'FMA AllowImpersonation value not found. Defaulting to false');
				allowImpersonation = false;
			}
		}
		return allowImpersonation;
	}

	// Example:
	// User A grants login access to User B. User B logs into Salesforce as User A and tries to perform a DocuSign API
	// action such as createEnvelope. If the impersonation FMA setting is false, an UnauthorizedException is thrown here
	// and User B is prohibited from taking any action that requires API access.
	public static void verifyNotImpersonating() {
		if (isImpersonating() && !isImpersonationAllowed()) {
			throw UnauthorizedException.impersonation();
		}
	}
}
