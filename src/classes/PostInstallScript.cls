public interface PostInstallScript {

	Boolean shouldExecute(Id organizationId, Id installerId, Version previousVersion, Boolean isPush,
		Boolean isUpgrade);

	PostInstallResults execute(Id organizationId, Id installerId, Version previousVersion, Boolean isPush,
		Boolean isUpgrade);
}
