public with sharing class GenMigrationApplication {

	private static final String GEN_PACKAGE_NAMESPACE = 'dsgen';
	private static final Id GEN_PACKAGE_ID = '0335A000001645T';
	private static final String GEN_NAMESPACE_PREFIX = 'dsgen__';

	public static String namespacePrefix {
		get {
			return GEN_NAMESPACE_PREFIX;
		}
	}

	private static final String USER_QUERY = 'SELECT Id, CanManageAccount__c, ' + namespacePrefix + 'Docusign_Admin__c, ' + namespacePrefix + 'Docusign_Status__c, ' + namespacePrefix + 'DocuSign_Invitation_Date__c, ' + namespacePrefix + 'Docusign_User_Id__c, ' +
		+' Provisioned__c, Status__c, Username__c FROM User WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name IN ( \'DocuSign_Gen_Template_Configuration\' , \'DocuSign_Gen_User\' ))';

	public static List<Sobject> getGenUsers() {
		Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
			'Id',
			namespacePrefix + 'Docusign_Admin__c', 'email',
			namespacePrefix + 'DocuSign_Invitation_Date__c',
			namespacePrefix + 'Docusign_Status__c',
			namespacePrefix + 'Docusign_User_Id__c',
			'CanManageAccount__c',
			'Provisioned__c',
			'Status__c',
			'Username__c'
		});
		Permissions.verifyIsQueryable(PermissionSetAssignment.getSObjectType(), new List<String> { 'Id', 'permissionsetId' });
		return DATABASE.QUERY(USER_QUERY);
	}

	public static GenMigrationSettings__c getGenSettings() {
		return GenMigrationSettings__c.getOrgDefaults();
	}

	public static Boolean verifyGenPackageInstalled() {
		try {
			return UserInfo.isCurrentUserLicensedForPackage(GEN_PACKAGE_ID) && UserInfo.isCurrentUserLicensed(GEN_PACKAGE_NAMESPACE);
		} catch (Exception e) {
			return false;
		}
	}
}